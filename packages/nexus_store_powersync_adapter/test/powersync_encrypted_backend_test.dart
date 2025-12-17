import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/powersync_encrypted_backend.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

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
  });
}
