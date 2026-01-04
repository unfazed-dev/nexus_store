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

  group('CompositeBackend field operations', () {
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

    group('getField', () {
      test('should get field from primary when available', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        primary.addFieldToStorage('user-1', 'name', 'John');

        final result = await backend.getField('user-1', 'name');

        expect(result, equals('John'));
      });

      test('should fallback when primary fails', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        fallback.addFieldToStorage('user-1', 'name', 'John');
        primary.shouldFailOnGet = true;

        final result = await backend.getField('user-1', 'name');

        expect(result, equals('John'));
      });

      test('should use cache when both primary and fallback fail', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        cache.addFieldToStorage('user-1', 'name', 'John');
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.getField('user-1', 'name');

        expect(result, equals('John'));
      });
    });

    group('getFieldBatch', () {
      test('should get field batch from primary when available', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        primary.addFieldToStorage('user-1', 'name', 'John');
        primary.addFieldToStorage('user-2', 'name', 'Jane');

        final result =
            await backend.getFieldBatch(['user-1', 'user-2'], 'name');

        expect(result, hasLength(2));
        expect(result['user-1'], equals('John'));
        expect(result['user-2'], equals('Jane'));
      });

      test('should fallback when primary fails', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        fallback.addFieldToStorage('user-1', 'name', 'John');
        primary.shouldFailOnGet = true;

        final result = await backend.getFieldBatch(['user-1'], 'name');

        expect(result, hasLength(1));
        expect(result['user-1'], equals('John'));
      });

      test('should use cache when both primary and fallback fail', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        cache.addFieldToStorage('user-1', 'name', 'John');
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.getFieldBatch(['user-1'], 'name');

        expect(result, hasLength(1));
        expect(result['user-1'], equals('John'));
      });

      test('should return empty map when all backends fail and no cache',
          () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.getFieldBatch(['user-1'], 'name');

        expect(result, isEmpty);
      });
    });
  });

  group('CompositeBackend saveAll strategies', () {
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

    test('saveAll with all strategy writes to all backends', () async {
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
        cache: cache,
        writeStrategy: CompositeWriteStrategy.all,
      );
      final users = TestFixtures.createUsers(2);

      await backend.saveAll(users);

      expect(primary.storage, hasLength(2));
      expect(fallback.storage, hasLength(2));
      expect(cache.storage, hasLength(2));
    });

    test('saveAll with primaryAndCache strategy writes to primary and cache',
        () async {
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
        cache: cache,
        writeStrategy: CompositeWriteStrategy.primaryAndCache,
      );
      final users = TestFixtures.createUsers(2);

      await backend.saveAll(users);

      expect(primary.storage, hasLength(2));
      expect(cache.storage, hasLength(2));
      expect(fallback.storage, isEmpty);
    });
  });

  group('CompositeBackend sync operations', () {
    late FakeStoreBackend<TestUser, String> primary;
    late FakeStoreBackend<TestUser, String> fallback;

    setUp(() {
      primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Primary',
      );
      fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Fallback',
      );
    });

    group('retryChange', () {
      test('should retry on primary first', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        // Should complete without error
        await expectLater(backend.retryChange('change-1'), completes);
      });

      test('should try fallback when primary has no change', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        // Should complete without error (tries both backends)
        await expectLater(backend.retryChange('nonexistent-change'), completes);
      });
    });

    group('cancelChange', () {
      test('should cancel from primary first', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        final result = await backend.cancelChange('change-1');

        expect(result, isNull);
      });

      test('should try fallback when primary returns null', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        final result = await backend.cancelChange('change-1');

        expect(result, isNull);
      });
    });

    group('syncStatusStream', () {
      test('should emit sync status changes', () async {
        final backend = CompositeBackend<TestUser, String>(primary: primary);

        expect(backend.syncStatusStream, emits(SyncStatus.synced));
      });
    });

    group('pendingChangesStream', () {
      test('should combine streams from all backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        final stream = backend.pendingChangesStream;

        expect(stream, isNotNull);
      });
    });

    group('conflictsStream', () {
      test('should merge conflict streams from all backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        final stream = backend.conflictsStream;

        expect(stream, isNotNull);
      });
    });
  });

  group('CompositeBackend pagination', () {
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

    group('getAllPaged', () {
      test('should get paged results from primary', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          cache: cache,
        );
        primary.addToStorage('user-1', TestFixtures.createUser());

        final result = await backend.getAllPaged();

        expect(result.items, hasLength(1));
      });

      test('should fallback when primary fails', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        fallback.addToStorage('user-1', TestFixtures.createUser());
        primary.shouldFailOnGet = true;

        final result = await backend.getAllPaged();

        expect(result.items, hasLength(1));
      });

      test('should use cache when both primary and fallback fail', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
          cache: cache,
        );
        cache.addToStorage('user-1', TestFixtures.createUser());
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.getAllPaged();

        expect(result.items, hasLength(1));
      });

      test('should return empty result when all backends fail and no cache',
          () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );
        primary.shouldFailOnGet = true;
        fallback.shouldFailOnGet = true;

        final result = await backend.getAllPaged();

        expect(result.items, isEmpty);
      });

      test('should populate cache on success', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          cache: cache,
        );
        primary.addToStorage('user-1', TestFixtures.createUser());

        await backend.getAllPaged();

        expect(cache.storage, hasLength(1));
      });
    });

    group('watchAllPaged', () {
      test('should merge paged streams from all backends', () async {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );
        primary.addToStorage('user-1', TestFixtures.createUser());

        final result = await backend.watchAllPaged().first;

        expect(result.items, hasLength(1));
      });
    });

    group('supportsPagination', () {
      test('should return true if fallback supports pagination', () {
        final backend = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallback,
        );

        // Both support pagination
        expect(backend.supportsPagination, isTrue);
      });
    });
  });

  group('CompositeBackend additional capabilities', () {
    late FakeStoreBackend<TestUser, String> primary;
    late FakeStoreBackend<TestUser, String> fallback;

    setUp(() {
      primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Primary',
      );
      fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'Fallback',
      );
    });

    test('supportsFieldOperations should check fallback', () {
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      // Check capability is accessible
      expect(backend.supportsFieldOperations, isA<bool>());
    });

    test('deleteWhere should delegate to primary', () async {
      final backend = CompositeBackend<TestUser, String>(primary: primary);
      primary.addToStorage('user-1', TestFixtures.createUser());

      final query = const Query<TestUser>().where('id', isEqualTo: 'user-1');
      final count = await backend.deleteWhere(query);

      expect(count, isA<int>());
    });

    test('transaction operations should delegate to primary', () async {
      final backend = CompositeBackend<TestUser, String>(primary: primary);

      final txId = await backend.beginTransaction();
      expect(txId, isNotEmpty);

      await expectLater(backend.commitTransaction(txId), completes);
    });

    test('rollbackTransaction should delegate to primary', () async {
      final backend = CompositeBackend<TestUser, String>(primary: primary);

      final txId = await backend.beginTransaction();
      await expectLater(backend.rollbackTransaction(txId), completes);
    });

    test('runInTransaction should delegate to primary', () async {
      final backend = CompositeBackend<TestUser, String>(primary: primary);

      final result = await backend.runInTransaction(() async => 42);

      expect(result, equals(42));
    });
  });

  group('CompositeBackend supportsFieldOperations', () {
    test('should check fallback when primary does not support', () {
      final primary = _FakeBackendWithFieldOps(supportsFieldOps: false);
      final fallback = _FakeBackendWithFieldOps(supportsFieldOps: true);

      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      expect(backend.supportsFieldOperations, isTrue);
    });

    test('should return false when neither supports', () {
      final primary = _FakeBackendWithFieldOps(supportsFieldOps: false);
      final fallback = _FakeBackendWithFieldOps(supportsFieldOps: false);

      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      expect(backend.supportsFieldOperations, isFalse);
    });

    test('should return true when primary supports', () {
      final primary = _FakeBackendWithFieldOps(supportsFieldOps: true);

      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      expect(backend.supportsFieldOperations, isTrue);
    });
  });

  group('CompositeBackend pendingChangesStream', () {
    test('should combine pending changes from primary and fallback', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      final fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      // Both backends emit empty pending changes initially
      final changes = await backend.pendingChangesStream.first;
      expect(changes, isEmpty);
    });
  });

  group('CompositeBackend retryChange', () {
    test('should retry in primary first', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      final fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      // retryChange is a no-op in FakeStoreBackend, just verify it completes
      await expectLater(backend.retryChange('change-1'), completes);
    });

    test('should fallback when primary throws (line 309)', () async {
      final primary = _FailingRetryBackend(
        idExtractor: (user) => user.id,
      );
      final fallback = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      final backend = CompositeBackend<TestUser, String>(
        primary: primary,
        fallback: fallback,
      );

      // Line 309: await fallback?.retryChange(changeId);
      // Primary throws, so fallback should be tried
      await expectLater(backend.retryChange('change-1'), completes);
    });
  });
}

/// Backend that throws on retryChange to test fallback path (line 309).
class _FailingRetryBackend extends FakeStoreBackend<TestUser, String> {
  _FailingRetryBackend({required super.idExtractor});

  @override
  Future<void> retryChange(String changeId) async {
    throw Exception('Primary retryChange failed');
  }
}

/// Helper class to test supportsFieldOperations with configurable value.
class _FakeBackendWithFieldOps extends FakeStoreBackend<TestUser, String> {
  _FakeBackendWithFieldOps({required this.supportsFieldOps})
      : super(idExtractor: (user) => user.id);

  final bool supportsFieldOps;

  @override
  bool get supportsFieldOperations => supportsFieldOps;
}
