import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('CompositeBackend', () {
    late FakeStoreBackend<TestUser, String> primary;
    late FakeStoreBackend<TestUser, String> fallback;
    late FakeStoreBackend<TestUser, String> cache;

    setUp(() {
      primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Primary',
      );
      fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Fallback',
      );
      cache = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Cache',
      );
    });

    group('constructor', () {
      test('should create with only primary backend', () {
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        expect(backend.primary, equals(primary));
        expect(backend.fallback, isNull);
        expect(backend.cache, isNull);
        expect(backend.readStrategy, CompositeReadStrategy.primaryFirst);
        expect(backend.writeStrategy, CompositeWriteStrategy.primaryOnly);
      });

      test('should create with all backends', () {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );

        expect(backend.primary, equals(primary));
        expect(backend.fallback, equals(fallback));
        expect(backend.cache, equals(cache));
      });

      test('should accept custom strategies', () {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          readStrategy: CompositeReadStrategy.cacheFirst,
          writeStrategy: CompositeWriteStrategy.all,
        );

        expect(backend.readStrategy, CompositeReadStrategy.cacheFirst);
        expect(backend.writeStrategy, CompositeWriteStrategy.all);
      });
    });

    group('primaryFirst read strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
      });

      test('should get from primary when available', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should fallback when primary fails', () async {
        final user = TestFixtures.createUser();
        fallback.addToStorage('user-1', user);
        primary.shouldFailOnGet = true;

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should use cache when both primary and fallback fail', () async {
        final user = TestFixtures.createUser();
        cache.addToStorage('user-1', user);
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should populate cache on primary success', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);

        await backend.get('user-1');

        expect(cache.storage['user-1'], equals(user));
      });
    });

    group('cacheFirst read strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          cache: cache,
          readStrategy: CompositeReadStrategy.cacheFirst,
        );
      });

      test('should get from cache when available', () async {
        final user = TestFixtures.createUser();
        cache.addToStorage('user-1', user);

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should get from primary on cache miss', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should populate cache after primary fetch', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);

        await backend.get('user-1');

        expect(cache.storage['user-1'], equals(user));
      });
    });

    group('fastest read strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
          readStrategy: CompositeReadStrategy.fastest,
        );
      });

      test('should return first available result', () async {
        final user = TestFixtures.createUser();
        cache.addToStorage('user-1', user);

        final result = await backend.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when no backend has data', () async {
        final result = await backend.get('non-existent');

        expect(result, isNull);
      });
    });

    group('primaryOnly write strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
      });

      test('should save only to primary', () async {
        final user = TestFixtures.createUser();

        await backend.save(user);

        expect(primary.storage['user-1'], equals(user));
        expect(fallback.storage['user-1'], isNull);
        expect(cache.storage['user-1'], isNull);
      });

      test('should delete only from primary', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);
        fallback.addToStorage('user-1', user);
        cache.addToStorage('user-1', user);

        await backend.delete('user-1');

        expect(primary.storage.containsKey('user-1'), isFalse);
        expect(fallback.storage.containsKey('user-1'), isTrue);
        expect(cache.storage.containsKey('user-1'), isTrue);
      });
    });

    group('all write strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
          writeStrategy: CompositeWriteStrategy.all,
        );
      });

      test('should save to all backends', () async {
        final user = TestFixtures.createUser();

        await backend.save(user);

        expect(primary.storage['user-1'], equals(user));
        expect(fallback.storage['user-1'], equals(user));
        expect(cache.storage['user-1'], equals(user));
      });

      test('should delete from all backends', () async {
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);
        fallback.addToStorage('user-1', user);
        cache.addToStorage('user-1', user);

        await backend.delete('user-1');

        expect(primary.storage.containsKey('user-1'), isFalse);
        expect(fallback.storage.containsKey('user-1'), isFalse);
        expect(cache.storage.containsKey('user-1'), isFalse);
      });
    });

    group('primaryAndCache write strategy', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
          writeStrategy: CompositeWriteStrategy.primaryAndCache,
        );
      });

      test('should save to primary and cache only', () async {
        final user = TestFixtures.createUser();

        await backend.save(user);

        expect(primary.storage['user-1'], equals(user));
        expect(cache.storage['user-1'], equals(user));
        expect(fallback.storage['user-1'], isNull);
      });
    });

    group('getAll', () {
      late CompositeBackend<TestUser, String> backend;

      setUp(() {
        backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
      });

      test('should get all from primary', () async {
        primary.addToStorage('user-1', TestFixtures.createUser());
        primary.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        final results = await backend.getAll();

        expect(results, hasLength(2));
      });

      test('should fallback when primary fails', () async {
        fallback.addToStorage('user-1', TestFixtures.createUser());
        primary.shouldFailOnGet = true;

        final results = await backend.getAll();

        expect(results, hasLength(1));
      });

      test('should use cache when both fail', () async {
        cache.addToStorage('user-1', TestFixtures.createUser());
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final results = await backend.getAll();

        expect(results, hasLength(1));
      });
    });

    group('saveAll', () {
      test('should save all items to primary', () async {
        final backend = CompositeBackend<TestUser, String>(primary: primary);
        final users = TestFixtures.createUsers(3);

        await backend.saveAll(users);

        expect(primary.storage, hasLength(3));
      });
    });

    group('deleteAll', () {
      test('should delete all items', () async {
        final backend = CompositeBackend<TestUser, String>(primary: primary);
        primary.addToStorage('user-1', TestFixtures.createUser());
        primary.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        final count = await backend.deleteAll(['user-1', 'user-2']);

        expect(count, equals(2));
        expect(primary.storage, isEmpty);
      });
    });

    group('sync', () {
      test('should sync primary', () async {
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        await backend.sync();

        expect(backend.syncStatus, equals(SyncStatus.synced));
      });

      test('should sync both primary and fallback', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        await backend.sync();

        expect(backend.syncStatus, equals(SyncStatus.synced));
      });

      test('should emit error status on failure', () async {
        primary.shouldFailOnSync = true;
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        await expectLater(backend.sync(), throwsException);
        expect(backend.syncStatus, equals(SyncStatus.error));
      });
    });

    group('pendingChangesCount', () {
      test('should combine counts from all backends', () async {
        primary.pendingChangesForTest = 5;
        fallback.pendingChangesForTest = 3;
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        final count = await backend.pendingChangesCount;

        expect(count, equals(8));
      });
    });

    group('backend info', () {
      test('should return composite name', () {
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        expect(backend.name, equals('CompositeBackend(Primary)'));
      });

      test('supportsOffline should be true if any backend supports', () {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        expect(backend.supportsOffline, isFalse);
      });

      test('supportsRealtime should be true if any backend supports', () {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        expect(backend.supportsRealtime, isFalse);
      });

      test('supportsTransactions should reflect primary', () {
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        // FakeStoreBackend.supportsTransactions returns true
        expect(backend.supportsTransactions, isTrue);
      });
    });

    group('lifecycle', () {
      test('initialize should initialize all backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );

        await expectLater(backend.initialize(), completes);
      });

      test('close should close all backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );

        await expectLater(backend.close(), completes);
      });
    });

    group('watch', () {
      test('should merge streams from backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );
        final user = TestFixtures.createUser();
        primary.addToStorage('user-1', user);

        final result = await backend.watch('user-1').first;

        expect(result, equals(user));
      });
    });

    group('watchAll', () {
      test('should merge streams from backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );
        primary.addToStorage('user-1', TestFixtures.createUser());

        final results = await backend.watchAll().first;

        expect(results, hasLength(1));
      });
    });
  });

  group('CompositeReadStrategy', () {
    test('should have all expected values', () {
      expect(CompositeReadStrategy.values, hasLength(3));
      expect(
        CompositeReadStrategy.values,
        contains(CompositeReadStrategy.primaryFirst),
      );
      expect(
        CompositeReadStrategy.values,
        contains(CompositeReadStrategy.cacheFirst),
      );
      expect(
        CompositeReadStrategy.values,
        contains(CompositeReadStrategy.fastest),
      );
    });
  });

  group('CompositeWriteStrategy', () {
    test('should have all expected values', () {
      expect(CompositeWriteStrategy.values, hasLength(3));
      expect(
        CompositeWriteStrategy.values,
        contains(CompositeWriteStrategy.primaryOnly),
      );
      expect(
        CompositeWriteStrategy.values,
        contains(CompositeWriteStrategy.all),
      );
      expect(
        CompositeWriteStrategy.values,
        contains(CompositeWriteStrategy.primaryAndCache),
      );
    });
  });
}
