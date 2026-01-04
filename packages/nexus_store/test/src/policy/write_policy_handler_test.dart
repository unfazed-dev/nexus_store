import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('WritePolicyHandler', () {
    late FakeStoreBackend<TestUser, String> backend;
    late WritePolicyHandler<TestUser, String> handler;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    group('constructor', () {
      test('should create handler with required parameters', () {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheAndNetwork,
        );

        expect(handler.backend, equals(backend));
        expect(handler.defaultPolicy, equals(WritePolicy.cacheAndNetwork));
      });
    });

    group('cacheAndNetwork policy', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheAndNetwork,
        );
      });

      group('save', () {
        test('should save to cache and trigger sync', () async {
          final user = TestFixtures.createUser();

          final result = await handler.save(user);

          expect(result, equals(user));
          expect(backend.storage['user-1'], equals(user));
        });

        test('should rethrow StoreError on sync failure', () async {
          backend.shouldFailOnSync = true;
          backend.errorToThrow = const NetworkError(message: 'Sync failed');

          final user = TestFixtures.createUser();

          expect(
            () => handler.save(user),
            throwsA(isA<NetworkError>()),
          );

          // Item should still be saved locally
          expect(backend.storage['user-1'], equals(user));
        });
      });

      group('saveAll', () {
        test('should save all items and trigger sync', () async {
          final users = TestFixtures.createUsers(3);

          final results = await handler.saveAll(users);

          expect(results, hasLength(3));
          expect(backend.storage, hasLength(3));
        });

        test('should rethrow on sync failure', () async {
          backend.shouldFailOnSync = true;
          backend.errorToThrow = const NetworkError(message: 'Sync failed');

          final users = TestFixtures.createUsers(2);

          expect(
            () => handler.saveAll(users),
            throwsA(isA<NetworkError>()),
          );
        });
      });

      group('delete', () {
        test('should delete from cache and trigger sync', () async {
          final user = TestFixtures.createUser();
          backend.addToStorage('user-1', user);

          final result = await handler.delete('user-1');

          expect(result, isTrue);
          expect(backend.storage.containsKey('user-1'), isFalse);
        });

        test('should return false when item not found', () async {
          final result = await handler.delete('non-existent');

          expect(result, isFalse);
        });

        test('should rethrow StoreError on delete sync failure (line 100)',
            () async {
          // Line 100: on StoreError { rethrow; } in _deleteCacheAndNetwork
          final user = TestFixtures.createUser();
          backend.addToStorage('user-1', user);
          backend.shouldFailOnSync = true;
          backend.errorToThrow =
              const NetworkError(message: 'Delete sync failed');

          expect(
            () => handler.delete('user-1'),
            throwsA(isA<NetworkError>()),
          );

          // Item should still be deleted locally even if sync failed
          expect(backend.storage.containsKey('user-1'), isFalse);
        });
      });
    });

    group('networkFirst policy', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.networkFirst,
        );
      });

      group('save', () {
        test('should save to cache and wait for sync', () async {
          final user = TestFixtures.createUser();

          final result = await handler.save(user);

          expect(result, equals(user));
          expect(backend.storage['user-1'], equals(user));
        });

        test('should throw on sync failure', () async {
          backend.shouldFailOnSync = true;
          backend.errorToThrow = Exception('Network error');

          final user = TestFixtures.createUser();

          expect(
            () => handler.save(user),
            throwsException,
          );
        });
      });

      group('saveAll', () {
        test('should save all and wait for sync', () async {
          final users = TestFixtures.createUsers(2);

          final results = await handler.saveAll(users);

          expect(results, hasLength(2));
        });

        test('should throw on sync failure', () async {
          backend.shouldFailOnSync = true;
          backend.errorToThrow = Exception('Network error');

          final users = TestFixtures.createUsers(2);

          expect(
            () => handler.saveAll(users),
            throwsException,
          );
        });
      });

      group('delete', () {
        test('should delete and wait for sync', () async {
          backend.addToStorage(
            'user-1',
            TestFixtures.createUser(),
          );

          final result = await handler.delete('user-1');

          expect(result, isTrue);
        });

        test('should throw on sync failure', () async {
          backend.addToStorage(
            'user-1',
            TestFixtures.createUser(),
          );
          backend.shouldFailOnSync = true;

          expect(
            () => handler.delete('user-1'),
            throwsException,
          );
        });
      });
    });

    group('cacheFirst policy', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheFirst,
        );
      });

      group('save', () {
        test('should save to cache immediately', () async {
          final user = TestFixtures.createUser();

          final result = await handler.save(user);

          expect(result, equals(user));
          expect(backend.storage['user-1'], equals(user));
        });

        test('should not throw on sync failure (background sync)', () async {
          backend.shouldFailOnSync = true;

          final user = TestFixtures.createUser();

          // Should not throw because sync is in background
          final result = await handler.save(user);

          expect(result, equals(user));
        });
      });

      group('saveAll', () {
        test('should save all to cache immediately', () async {
          final users = TestFixtures.createUsers(3);

          final results = await handler.saveAll(users);

          expect(results, hasLength(3));
          expect(backend.storage, hasLength(3));
        });
      });

      group('delete', () {
        test('should delete from cache immediately', () async {
          backend.addToStorage(
            'user-1',
            TestFixtures.createUser(),
          );

          final result = await handler.delete('user-1');

          expect(result, isTrue);
          expect(backend.storage.containsKey('user-1'), isFalse);
        });
      });
    });

    group('cacheOnly policy', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheOnly,
        );
      });

      group('save', () {
        test('should save only to cache', () async {
          final user = TestFixtures.createUser();

          final result = await handler.save(user);

          expect(result, equals(user));
          expect(backend.storage['user-1'], equals(user));
        });
      });

      group('saveAll', () {
        test('should save all only to cache', () async {
          final users = TestFixtures.createUsers(2);

          final results = await handler.saveAll(users);

          expect(results, hasLength(2));
        });
      });

      group('delete', () {
        test('should delete only from cache', () async {
          backend.addToStorage(
            'user-1',
            TestFixtures.createUser(),
          );

          final result = await handler.delete('user-1');

          expect(result, isTrue);
        });
      });
    });

    group('policy override', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheAndNetwork,
        );
      });

      test('should use provided policy for save', () async {
        final user = TestFixtures.createUser();

        // Default is cacheAndNetwork, override with cacheOnly
        final result = await handler.save(user, policy: WritePolicy.cacheOnly);

        expect(result, equals(user));
      });

      test('should use provided policy for saveAll', () async {
        final users = TestFixtures.createUsers(2);

        final results = await handler.saveAll(
          users,
          policy: WritePolicy.cacheOnly,
        );

        expect(results, hasLength(2));
      });

      test('should use provided policy for delete', () async {
        backend.addToStorage(
          'user-1',
          TestFixtures.createUser(),
        );

        final result = await handler.delete(
          'user-1',
          policy: WritePolicy.cacheOnly,
        );

        expect(result, isTrue);
      });
    });

    group('error handling', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheAndNetwork,
        );
      });

      test('should propagate save errors', () async {
        backend.shouldFailOnSave = true;
        backend.errorToThrow = Exception('Save failed');

        final user = TestFixtures.createUser();

        expect(
          () => handler.save(user),
          throwsException,
        );
      });

      test('should propagate delete errors', () async {
        backend.shouldFailOnDelete = true;
        backend.errorToThrow = Exception('Delete failed');

        expect(
          () => handler.delete('user-1'),
          throwsException,
        );
      });
    });

    group('background sync (cacheFirst)', () {
      setUp(() {
        handler = WritePolicyHandler(
          backend: backend,
          defaultPolicy: WritePolicy.cacheFirst,
        );
      });

      test('saveAll should not throw on background sync failure', () async {
        backend.shouldFailOnSync = true;

        final users = TestFixtures.createUsers(3);

        // Should not throw because sync is in background
        final results = await handler.saveAll(users);

        expect(results, hasLength(3));
        expect(backend.storage, hasLength(3));

        // Wait for background sync to complete (with error)
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // No exception should propagate
        expect(true, isTrue);
      });

      test('delete should not throw on background sync failure', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.shouldFailOnSync = true;

        // Should not throw because sync is in background
        final result = await handler.delete('user-1');

        expect(result, isTrue);
        expect(backend.storage.containsKey('user-1'), isFalse);

        // Wait for background sync to complete (with error)
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // No exception should propagate
        expect(true, isTrue);
      });
    });
  });
}
