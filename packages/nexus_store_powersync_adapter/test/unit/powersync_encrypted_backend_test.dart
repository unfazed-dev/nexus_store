import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/powersync_backend.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_encrypted_backend.dart';
import 'package:test/test.dart';

// =============================================================================
// MOCKS
// =============================================================================

class MockEncryptionKeyProvider extends Mock implements EncryptionKeyProvider {}

class MockPowerSyncBackend extends Mock
    implements PowerSyncBackend<TestItem, String> {}

// =============================================================================
// TEST MODEL
// =============================================================================

class TestItem {
  TestItem({required this.id, required this.name});

  // ignore: unreachable_from_main
  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// =============================================================================
// FAKES FOR REGISTERFALLABACKVALUE
// =============================================================================

// ignore: avoid_implementing_value_types
class FakeQuery extends Fake implements nexus.Query<TestItem> {}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  setUpAll(() {
    registerFallbackValue(FakeQuery());
    registerFallbackValue(<String>[]);
  });

  group('InMemoryKeyProvider', () {
    late InMemoryKeyProvider keyProvider;
    const testKey = 'test-encryption-key-256bit';

    setUp(() {
      keyProvider = InMemoryKeyProvider(testKey);
    });

    group('constructor', () {
      test('sets initial key', () async {
        final key = await keyProvider.getKey();
        expect(key, equals(testKey));
      });
    });

    group('getKey', () {
      test('returns the key when not disposed', () async {
        final key = await keyProvider.getKey();
        expect(key, equals(testKey));
      });

      test('throws StateError when disposed', () async {
        await keyProvider.dispose();

        expect(
          () => keyProvider.getKey(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('rotateKey', () {
      test('updates the key', () async {
        const newKey = 'new-encryption-key-256bit';

        final result = await keyProvider.rotateKey(newKey);

        expect(result, equals(newKey));
        expect(await keyProvider.getKey(), equals(newKey));
      });

      test('throws StateError when disposed', () async {
        await keyProvider.dispose();

        expect(
          () => keyProvider.rotateKey('any-key'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('dispose', () {
      test('clears key and marks as disposed', () async {
        await keyProvider.dispose();

        expect(
          () => keyProvider.getKey(),
          throwsA(isA<StateError>()),
        );
      });

      test('is idempotent (can call twice without error)', () async {
        await keyProvider.dispose();
        // Second call should not throw
        await keyProvider.dispose();
      });
    });
  });

  group('PowerSyncEncryptedBackend', () {
    late MockEncryptionKeyProvider mockKeyProvider;
    late MockPowerSyncBackend mockInnerBackend;
    late PowerSyncEncryptedBackend<TestItem, String> backend;

    const testKey = 'test-encryption-key';

    setUp(() {
      mockKeyProvider = MockEncryptionKeyProvider();
      mockInnerBackend = MockPowerSyncBackend();

      // Default stubs
      when(() => mockKeyProvider.getKey()).thenAnswer((_) async => testKey);
      when(() => mockInnerBackend.initialize()).thenAnswer((_) async {});
      when(() => mockInnerBackend.close()).thenAnswer((_) async {});

      backend = PowerSyncEncryptedBackend<TestItem, String>.withBackend(
        backend: mockInnerBackend,
        keyProvider: mockKeyProvider,
      );
    });

    group('backend info', () {
      test('name returns powersync_encrypted', () {
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

      test('algorithm returns configured algorithm (aes256Gcm)', () {
        expect(backend.algorithm, equals(EncryptionAlgorithm.aes256Gcm));
      });

      test('algorithm returns configured algorithm (chacha20Poly1305)', () {
        final chacha20Backend =
            PowerSyncEncryptedBackend<TestItem, String>.withBackend(
          backend: mockInnerBackend,
          keyProvider: mockKeyProvider,
          algorithm: EncryptionAlgorithm.chacha20Poly1305,
        );
        expect(
          chacha20Backend.algorithm,
          equals(EncryptionAlgorithm.chacha20Poly1305),
        );
      });

      test('isKeyCleared returns false before close()', () {
        expect(backend.isKeyCleared, isFalse);
      });

      test('isKeyCleared returns true after close()', () async {
        await backend.initialize();
        await backend.close();

        expect(backend.isKeyCleared, isTrue);
      });
    });

    group('lifecycle', () {
      group('initialize', () {
        test('gets key from provider', () async {
          await backend.initialize();

          verify(() => mockKeyProvider.getKey()).called(1);
        });

        test('initializes inner backend', () async {
          await backend.initialize();

          verify(() => mockInnerBackend.initialize()).called(1);
        });

        test('is idempotent (can call multiple times)', () async {
          await backend.initialize();
          await backend.initialize();

          // Should only initialize once
          verify(() => mockKeyProvider.getKey()).called(1);
          verify(() => mockInnerBackend.initialize()).called(1);
        });
      });

      group('close', () {
        test('clears current key', () async {
          await backend.initialize();
          await backend.close();

          expect(backend.isKeyCleared, isTrue);
        });

        test('closes inner backend', () async {
          await backend.initialize();
          await backend.close();

          verify(() => mockInnerBackend.close()).called(1);
        });

        test('sets initialized to false', () async {
          await backend.initialize();
          await backend.close();

          // Should throw StateError when trying to use after close
          expect(
            () => backend.get('any-id'),
            throwsA(isA<nexus.StateError>()),
          );
        });
      });

      group('rotateKey', () {
        test('updates key in provider', () async {
          const newKey = 'new-encryption-key';
          when(() => mockKeyProvider.rotateKey(newKey))
              .thenAnswer((_) async => newKey);

          await backend.initialize();
          await backend.rotateKey(newKey);

          verify(() => mockKeyProvider.rotateKey(newKey)).called(1);
        });

        test('throws StateError when not initialized', () {
          expect(
            () => backend.rotateKey('any-key'),
            throwsA(isA<nexus.StateError>()),
          );
        });
      });
    });

    group('read operations', () {
      final testItem = TestItem(id: 'item-1', name: 'Test');

      group('get', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.get('any-id'),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.get('item-1'))
              .thenAnswer((_) async => testItem);

          await backend.initialize();
          final result = await backend.get('item-1');

          expect(result, equals(testItem));
          verify(() => mockInnerBackend.get('item-1')).called(1);
        });
      });

      group('getAll', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.getAll(),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.getAll(query: any(named: 'query')))
              .thenAnswer((_) async => [testItem]);

          await backend.initialize();
          final result = await backend.getAll();

          expect(result, equals([testItem]));
          verify(() => mockInnerBackend.getAll(query: null)).called(1);
        });

        test('delegates with query to inner backend', () async {
          const query = nexus.Query<TestItem>();
          when(() => mockInnerBackend.getAll(query: any(named: 'query')))
              .thenAnswer((_) async => [testItem]);

          await backend.initialize();
          final result = await backend.getAll(query: query);

          expect(result, equals([testItem]));
          verify(() => mockInnerBackend.getAll(query: query)).called(1);
        });
      });

      group('watch', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.watch('any-id'),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.watch('item-1'))
              .thenAnswer((_) => Stream.value(testItem));

          await backend.initialize();
          final stream = backend.watch('item-1');

          expect(await stream.first, equals(testItem));
          verify(() => mockInnerBackend.watch('item-1')).called(1);
        });
      });

      group('watchAll', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.watchAll(),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.watchAll(query: any(named: 'query')))
              .thenAnswer((_) => Stream.value([testItem]));

          await backend.initialize();
          final stream = backend.watchAll();

          expect(await stream.first, equals([testItem]));
          verify(() => mockInnerBackend.watchAll(query: null)).called(1);
        });
      });
    });

    group('write operations', () {
      final testItem = TestItem(id: 'item-1', name: 'Test');

      group('save', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.save(testItem),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.save(testItem))
              .thenAnswer((_) async => testItem);

          await backend.initialize();
          final result = await backend.save(testItem);

          expect(result, equals(testItem));
          verify(() => mockInnerBackend.save(testItem)).called(1);
        });
      });

      group('saveAll', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.saveAll([testItem]),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.saveAll([testItem]))
              .thenAnswer((_) async => [testItem]);

          await backend.initialize();
          final result = await backend.saveAll([testItem]);

          expect(result, equals([testItem]));
          verify(() => mockInnerBackend.saveAll([testItem])).called(1);
        });
      });

      group('delete', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.delete('item-1'),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.delete('item-1'))
              .thenAnswer((_) async => true);

          await backend.initialize();
          final result = await backend.delete('item-1');

          expect(result, isTrue);
          verify(() => mockInnerBackend.delete('item-1')).called(1);
        });
      });

      group('deleteAll', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.deleteAll(['item-1', 'item-2']),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.deleteAll(any()))
              .thenAnswer((_) async => 2);

          await backend.initialize();
          final result = await backend.deleteAll(['item-1', 'item-2']);

          expect(result, equals(2));
          verify(() => mockInnerBackend.deleteAll(['item-1', 'item-2']))
              .called(1);
        });
      });

      group('deleteWhere', () {
        test('throws StateError when not initialized', () {
          const query = nexus.Query<TestItem>();
          expect(
            () => backend.deleteWhere(query),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          const query = nexus.Query<TestItem>();
          when(() => mockInnerBackend.deleteWhere(any()))
              .thenAnswer((_) async => 5);

          await backend.initialize();
          final result = await backend.deleteWhere(query);

          expect(result, equals(5));
          verify(() => mockInnerBackend.deleteWhere(query)).called(1);
        });
      });
    });

    group('sync operations', () {
      group('syncStatus', () {
        test('returns inner backend status', () {
          when(() => mockInnerBackend.syncStatus)
              .thenReturn(nexus.SyncStatus.synced);

          expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
          verify(() => mockInnerBackend.syncStatus).called(1);
        });
      });

      group('syncStatusStream', () {
        test('returns inner backend stream', () {
          when(() => mockInnerBackend.syncStatusStream)
              .thenAnswer((_) => Stream.value(nexus.SyncStatus.syncing));

          expect(backend.syncStatusStream, isA<Stream<nexus.SyncStatus>>());
          verify(() => mockInnerBackend.syncStatusStream).called(1);
        });
      });

      group('sync', () {
        test('throws StateError when not initialized', () {
          expect(
            () => backend.sync(),
            throwsA(isA<nexus.StateError>()),
          );
        });

        test('delegates to inner backend', () async {
          when(() => mockInnerBackend.sync()).thenAnswer((_) async {});

          await backend.initialize();
          await backend.sync();

          verify(() => mockInnerBackend.sync()).called(1);
        });
      });

      group('pendingChangesCount', () {
        test('returns inner backend count', () async {
          when(() => mockInnerBackend.pendingChangesCount)
              .thenAnswer((_) async => 3);

          final count = await backend.pendingChangesCount;

          expect(count, equals(3));
          verify(() => mockInnerBackend.pendingChangesCount).called(1);
        });
      });
    });
  });
}
