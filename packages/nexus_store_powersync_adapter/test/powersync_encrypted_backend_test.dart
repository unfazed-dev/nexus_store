import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

// Mock for the database wrapper
class MockPowerSyncDatabaseWrapper extends Mock
    implements PowerSyncDatabaseWrapper {}

// Test model
class TestUser {
  TestUser({required this.id, required this.name, this.age});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
      );

  final String id;
  final String name;
  final int? age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (age != null) 'age': age,
      };
}

// Mock classes
class MockPowerSyncDatabase extends Mock implements ps.PowerSyncDatabase {}

// Mock encryption key provider
class MockEncryptionKeyProvider extends Mock implements EncryptionKeyProvider {}

void main() {
  group('PowerSyncEncryptedBackend', () {
    late MockPowerSyncDatabase mockDb;
    late MockEncryptionKeyProvider mockKeyProvider;
    late PowerSyncEncryptedBackend<TestUser, String> backend;
    late StreamController<ps.SyncStatus> syncStatusController;

    setUp(() {
      mockDb = MockPowerSyncDatabase();
      mockKeyProvider = MockEncryptionKeyProvider();
      syncStatusController = StreamController<ps.SyncStatus>.broadcast();

      when(() => mockDb.statusStream)
          .thenAnswer((_) => syncStatusController.stream);

      when(() => mockKeyProvider.getKey()).thenAnswer((_) async => 'test-key');
    });

    tearDown(() async {
      await syncStatusController.close();
    });

    group('construction', () {
      test('creates backend with encryption key provider', () {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );

        expect(backend, isNotNull);
        expect(backend.isEncrypted, isTrue);
      });

      test('accepts optional encryption algorithm', () {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );

        expect(backend.algorithm, equals(EncryptionAlgorithm.aes256Gcm));
      });
    });

    group('backend info', () {
      setUp(() {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );
      });

      test('name returns "powersync_encrypted"', () {
        expect(backend.name, equals('powersync_encrypted'));
      });

      test('supportsOffline returns true', () {
        expect(backend.supportsOffline, isTrue);
      });

      test('supportsRealtime returns true', () {
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns true', () {
        expect(backend.supportsTransactions, isTrue);
      });

      test('isEncrypted returns true', () {
        expect(backend.isEncrypted, isTrue);
      });
    });

    group('key management', () {
      setUp(() {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );
      });

      test('initialize calls key provider', () async {
        await backend.initialize();

        verify(() => mockKeyProvider.getKey()).called(1);
      });

      test('rotateKey calls key provider with new key', () async {
        when(() => mockKeyProvider.rotateKey(any()))
            .thenAnswer((_) async => 'new-key');

        await backend.initialize();
        await backend.rotateKey('new-key');

        verify(() => mockKeyProvider.rotateKey('new-key')).called(1);
      });

      test('rotateKey throws StateError when not initialized', () async {
        expect(
          () => backend.rotateKey('new-key'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('lifecycle', () {
      setUp(() {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );
      });

      test('initialize sets up encrypted backend', () async {
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('close clears encryption key from memory', () async {
        await backend.initialize();
        await backend.close();

        // Key should be cleared - verify cleanup was called
        expect(backend.isKeyCleared, isTrue);
      });
    });

    group('uninitialized state', () {
      setUp(() {
        backend = PowerSyncEncryptedBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          keyProvider: mockKeyProvider,
        );
      });

      test('get throws StateError before initialize', () async {
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError before initialize', () async {
        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });
  });

  group('EncryptionKeyProvider', () {
    test('InMemoryKeyProvider stores and returns key', () async {
      final provider = InMemoryKeyProvider('secret-key');

      final key = await provider.getKey();

      expect(key, equals('secret-key'));
    });

    test('InMemoryKeyProvider supports key rotation', () async {
      final provider = InMemoryKeyProvider('old-key');

      final newKey = await provider.rotateKey('new-key');

      expect(newKey, equals('new-key'));
      expect(await provider.getKey(), equals('new-key'));
    });

    test('InMemoryKeyProvider clears key on dispose', () async {
      final provider = InMemoryKeyProvider('secret-key');

      await provider.dispose();

      expect(
        provider.getKey,
        throwsA(isA<StateError>()),
      );
    });
  });

  group('EncryptionAlgorithm', () {
    test('aes256Gcm is default', () {
      expect(EncryptionAlgorithm.aes256Gcm.name, equals('aes256Gcm'));
    });

    test('chacha20Poly1305 is available', () {
      expect(
        EncryptionAlgorithm.chacha20Poly1305.name,
        equals('chacha20Poly1305'),
      );
    });

    test('backend can use chacha20Poly1305 algorithm', () {
      final mockDb = MockPowerSyncDatabase();
      final syncStatusController = StreamController<ps.SyncStatus>.broadcast();
      when(() => mockDb.statusStream)
          .thenAnswer((_) => syncStatusController.stream);

      final keyProvider = MockEncryptionKeyProvider();
      when(() => keyProvider.getKey()).thenAnswer((_) async => 'test-key');

      final backend = PowerSyncEncryptedBackend<TestUser, String>(
        db: mockDb,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
        keyProvider: keyProvider,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
      );

      expect(backend.algorithm, equals(EncryptionAlgorithm.chacha20Poly1305));

      syncStatusController.close();
    });
  });

  group('PowerSyncEncryptedBackend delegation', () {
    late MockPowerSyncDatabase mockDb;
    late MockEncryptionKeyProvider mockKeyProvider;
    late PowerSyncEncryptedBackend<TestUser, String> backend;
    late StreamController<ps.SyncStatus> syncStatusController;

    setUp(() {
      mockDb = MockPowerSyncDatabase();
      mockKeyProvider = MockEncryptionKeyProvider();
      syncStatusController = StreamController<ps.SyncStatus>.broadcast();

      when(() => mockDb.statusStream)
          .thenAnswer((_) => syncStatusController.stream);
      when(() => mockKeyProvider.getKey()).thenAnswer((_) async => 'test-key');

      backend = PowerSyncEncryptedBackend<TestUser, String>(
        db: mockDb,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
        keyProvider: mockKeyProvider,
      );
    });

    tearDown(() async {
      await syncStatusController.close();
    });

    group('uninitialized checks', () {
      test('getAll throws StateError before initialize', () {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError before initialize', () {
        expect(
          () => backend.saveAll([TestUser(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError before initialize', () {
        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError before initialize', () {
        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError before initialize', () {
        expect(
          () => backend.watch('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError before initialize', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError before initialize', () {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('sync status delegation', () {
      test('syncStatus delegates to inner backend', () async {
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream delegates to inner backend', () async {
        await backend.initialize();

        expect(
          backend.syncStatusStream,
          emits(nexus.SyncStatus.synced),
        );
      });
    });

    group('pending changes delegation', () {
      test('pendingChangesCount delegates to inner backend', () async {
        await backend.initialize();

        when(() => mockDb.currentStatus).thenReturn(
          const ps.SyncStatus(connected: true, hasSynced: true),
        );

        final count = await backend.pendingChangesCount;

        expect(count, equals(0));
      });
    });

    group('initialize and close', () {
      test('initialize is idempotent', () async {
        await backend.initialize();
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('close sets isKeyCleared to true', () async {
        await backend.initialize();

        expect(backend.isKeyCleared, isFalse);

        await backend.close();

        expect(backend.isKeyCleared, isTrue);
      });
    });
  });

  group('PowerSyncEncryptedBackend with injected backend', () {
    late MockPowerSyncDatabaseWrapper mockWrapper;
    late MockEncryptionKeyProvider mockKeyProvider;
    late PowerSyncBackend<TestUser, String> innerBackend;
    late PowerSyncEncryptedBackend<TestUser, String> encryptedBackend;
    late StreamController<ps.SyncStatus> syncStatusController;

    setUp(() {
      mockWrapper = MockPowerSyncDatabaseWrapper();
      mockKeyProvider = MockEncryptionKeyProvider();
      syncStatusController = StreamController<ps.SyncStatus>.broadcast();

      when(() => mockWrapper.statusStream)
          .thenAnswer((_) => syncStatusController.stream);
      when(() => mockWrapper.currentStatus)
          .thenReturn(const ps.SyncStatus(connected: true, hasSynced: true));
      when(() => mockKeyProvider.getKey()).thenAnswer((_) async => 'test-key');

      innerBackend = PowerSyncBackend<TestUser, String>.withWrapper(
        db: mockWrapper,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
      );

      encryptedBackend =
          PowerSyncEncryptedBackend<TestUser, String>.withBackend(
        backend: innerBackend,
        keyProvider: mockKeyProvider,
      );
    });

    tearDown(() async {
      await syncStatusController.close();
    });

    group('initialized CRUD delegation', () {
      setUp(() async {
        when(() => mockWrapper.execute(any(), any()))
            .thenAnswer((_) async => []);
        when(
          () => mockWrapper.watch(any(), parameters: any(named: 'parameters')),
        ).thenAnswer((_) => Stream.value([]));
        await encryptedBackend.initialize();
      });

      test('get delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Test', 'age': 30},
          ],
        );

        final result = await encryptedBackend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
      });

      test('getAll delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Test', 'age': 30},
          ],
        );

        final results = await encryptedBackend.getAll();

        expect(results, hasLength(1));
      });

      test('watch delegates to inner backend', () async {
        when(
          () => mockWrapper.watch(any(), parameters: any(named: 'parameters')),
        ).thenAnswer(
          (_) => Stream.value([
            {'id': '1', 'name': 'Test', 'age': 30},
          ]),
        );

        final stream = encryptedBackend.watch('1');

        expect(stream, isA<Stream<TestUser?>>());
        final first = await stream.first;
        expect(first, isNotNull);
      });

      test('watchAll delegates to inner backend', () async {
        when(
          () => mockWrapper.watch(any(), parameters: any(named: 'parameters')),
        ).thenAnswer(
          (_) => Stream.value([
            {'id': '1', 'name': 'Test', 'age': 30},
          ]),
        );

        final stream = encryptedBackend.watchAll();

        expect(stream, isA<Stream<List<TestUser>>>());
        final first = await stream.first;
        expect(first, hasLength(1));
      });

      test('save delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Test', 'age': 30},
          ],
        );

        final user = TestUser(id: '1', name: 'Test', age: 30);
        final result = await encryptedBackend.save(user);

        expect(result.id, equals('1'));
      });

      // Note: saveAll delegation is tested through PowerSyncBackend tests.
      // The encrypted backend just forwards to the inner backend after
      // checking initialization, which is covered by uninitialized tests.

      test('delete delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Test', 'age': 30},
          ],
        );

        final result = await encryptedBackend.delete('1');

        expect(result, isTrue);
      });

      test('deleteAll delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any()))
            .thenAnswer((_) async => []);

        final count = await encryptedBackend.deleteAll(['1', '2']);

        expect(count, equals(2));
      });

      test('deleteWhere delegates to inner backend', () async {
        when(() => mockWrapper.execute(any(), any()))
            .thenAnswer((_) async => []);

        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'Test');
        final count = await encryptedBackend.deleteWhere(query);

        expect(count, equals(0));
      });

      test('sync delegates to inner backend', () async {
        await encryptedBackend.sync();

        expect(encryptedBackend.syncStatus, equals(nexus.SyncStatus.synced));
      });
    });

    test('withBackend constructor creates backend with custom algorithm', () {
      final backend = PowerSyncEncryptedBackend<TestUser, String>.withBackend(
        backend: innerBackend,
        keyProvider: mockKeyProvider,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
      );

      expect(backend.algorithm, equals(EncryptionAlgorithm.chacha20Poly1305));
    });
  });

  group('InMemoryKeyProvider edge cases', () {
    test('rotateKey throws after dispose', () async {
      final provider = InMemoryKeyProvider('test-key');

      await provider.dispose();

      expect(
        () => provider.rotateKey('new-key'),
        throwsA(isA<StateError>()),
      );
    });

    test('getKey works before dispose', () async {
      final provider = InMemoryKeyProvider('test-key');

      final key = await provider.getKey();

      expect(key, equals('test-key'));
    });

    test('rotateKey updates key value', () async {
      final provider = InMemoryKeyProvider('old-key');

      await provider.rotateKey('new-key');

      expect(await provider.getKey(), equals('new-key'));
    });

    test('multiple key rotations work', () async {
      final provider = InMemoryKeyProvider('key1');

      await provider.rotateKey('key2');
      await provider.rotateKey('key3');
      await provider.rotateKey('key4');

      expect(await provider.getKey(), equals('key4'));
    });

    test('dispose is idempotent', () async {
      final provider = InMemoryKeyProvider('test-key');

      await provider.dispose();
      await provider.dispose();

      expect(
        () => provider.getKey(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
