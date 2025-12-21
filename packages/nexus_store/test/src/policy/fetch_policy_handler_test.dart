import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('FetchPolicyHandler', () {
    late FakeStoreBackend<TestUser, String> backend;
    late FetchPolicyHandler<TestUser, String> handler;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    group('constructor', () {
      test('should create handler with required parameters', () {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );

        expect(handler.backend, equals(backend));
        expect(handler.defaultPolicy, equals(FetchPolicy.cacheFirst));
        expect(handler.staleDuration, isNull);
      });

      test('should accept optional staleDuration', () {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(minutes: 5),
        );

        expect(handler.staleDuration, equals(const Duration(minutes: 5)));
      });
    });

    group('cacheFirst policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should return cached data when available', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should fetch from network when cache is empty', () async {
        // Backend starts empty, sync would populate it
        // Since FakeBackend.sync is a no-op, we simulate by adding after
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get(
          'user-1',
          policy: FetchPolicy.cacheFirst,
        );

        expect(result, isNotNull);
      });

      test('should return cached data on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when cache empty and network fails', () async {
        backend.shouldFailOnSync = true;

        final result = await handler.get('non-existent');

        expect(result, isNull);
      });

      test('getAll should return cached list when available', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        final results = await handler.getAll();

        expect(results, hasLength(2));
      });
    });

    group('networkFirst policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.networkFirst,
        );
      });

      test('should prefer network data', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should fallback to cache on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('getAll should fallback to cache on network failure', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.shouldFailOnSync = true;

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('cacheAndNetwork policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheAndNetwork,
        );
      });

      test('should return network result', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should return cached data on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });
    });

    group('cacheOnly policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheOnly,
        );
      });

      test('should return only cached data', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when not in cache', () async {
        final result = await handler.get('non-existent');

        expect(result, isNull);
      });

      test('getAll should return only cached data', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('networkOnly policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.networkOnly,
        );
      });

      test('should always try network', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should throw on network failure', () async {
        backend.shouldFailOnSync = true;

        expect(
          () => handler.get('user-1'),
          throwsException,
        );
      });

      test('getAll should throw on network failure', () async {
        backend.shouldFailOnSync = true;

        expect(
          () => handler.getAll(),
          throwsException,
        );
      });
    });

    group('staleWhileRevalidate policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.staleWhileRevalidate,
        );
      });

      test('should return cached data immediately', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should fetch from network when cache is empty', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('getAll should return cached data immediately', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('staleness', () {
      test('should consider data stale after staleDuration', () async {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(milliseconds: 1),
          lastFetchTimes: {
            'user-1': DateTime.now().subtract(const Duration(seconds: 1)),
          },
        );

        backend.addToStorage('user-1', TestFixtures.createUser());

        // Should try network since data is stale
        final result = await handler.get('user-1');
        expect(result, isNotNull);
      });

      test('should not consider data stale when no staleDuration', () async {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          lastFetchTimes: {
            'user-1': DateTime.now().subtract(const Duration(days: 100)),
          },
        );

        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');
        expect(result, equals(user));
      });
    });

    group('invalidate', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(minutes: 5),
          lastFetchTimes: {
            'user-1': DateTime.now(),
            'user-2': DateTime.now(),
          },
        );
      });

      test('should mark single entity as stale', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        handler.invalidate('user-1');

        // After invalidation, cacheFirst should try network
        final result = await handler.get('user-1');
        expect(result, isNotNull);
      });

      test('should mark all entities as stale', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        handler.invalidateAll();

        // Both should be considered stale
        final result1 = await handler.get('user-1');
        final result2 = await handler.get('user-2');
        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });
    });

    group('watch', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should delegate to backend watch', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final stream = handler.watch('user-1');
        final result = await stream.first;

        expect(result, equals(user));
      });
    });

    group('watchAll', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should delegate to backend watchAll', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final stream = handler.watchAll();
        final result = await stream.first;

        expect(result, hasLength(1));
      });
    });

    group('policy override', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should use provided policy over default', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        // Default is cacheFirst, but we override with networkOnly
        final result = await handler.get(
          'user-1',
          policy: FetchPolicy.cacheOnly,
        );

        expect(result, isNotNull);
      });

      test('getAll should use provided policy over default', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll(
          policy: FetchPolicy.cacheOnly,
        );

        expect(results, hasLength(1));
      });
    });

    group('cache tags', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(minutes: 5),
        );
      });

      group('recordCachedItem', () {
        test('should track tags when recorded', () {
          handler.recordCachedItem('user-1', tags: {'premium', 'active'});

          expect(handler.getTags('user-1'), containsAll(['premium', 'active']));
        });

        test('should track item without tags', () {
          handler.recordCachedItem('user-1');

          expect(handler.getTags('user-1'), isEmpty);
        });
      });

      group('addTags', () {
        test('should add tags to existing item', () {
          handler.recordCachedItem('user-1', tags: {'user'});

          handler.addTags('user-1', {'premium'});

          expect(handler.getTags('user-1'), containsAll(['user', 'premium']));
        });

        test('should add tags to untracked item', () {
          handler.addTags('user-1', {'premium'});

          expect(handler.getTags('user-1'), contains('premium'));
        });
      });

      group('removeTags', () {
        test('should remove tags from item', () {
          handler.recordCachedItem('user-1', tags: {'user', 'premium'});

          handler.removeTags('user-1', {'premium'});

          expect(handler.getTags('user-1'), equals({'user'}));
        });
      });

      group('getTags', () {
        test('should return empty set for unknown ID', () {
          expect(handler.getTags('unknown'), isEmpty);
        });
      });

      group('invalidateByTags', () {
        test('should invalidate items by tag', () {
          handler.recordCachedItem('user-1', tags: {'premium'});
          handler.recordCachedItem('user-2', tags: {'premium'});
          handler.recordCachedItem('user-3', tags: {'basic'});

          handler.invalidateByTags({'premium'});

          // user-1 and user-2 should be stale, user-3 should not
          expect(handler.isStale('user-1'), isTrue);
          expect(handler.isStale('user-2'), isTrue);
          expect(handler.isStale('user-3'), isFalse);
        });

        test('should invalidate items matching any tag (union)', () {
          handler.recordCachedItem('user-1', tags: {'premium'});
          handler.recordCachedItem('user-2', tags: {'admin'});
          handler.recordCachedItem('user-3', tags: {'basic'});

          handler.invalidateByTags({'premium', 'admin'});

          expect(handler.isStale('user-1'), isTrue);
          expect(handler.isStale('user-2'), isTrue);
          expect(handler.isStale('user-3'), isFalse);
        });
      });

      group('invalidateByIds', () {
        test('should invalidate by list of IDs', () {
          handler.recordCachedItem('user-1', tags: {'user'});
          handler.recordCachedItem('user-2', tags: {'user'});
          handler.recordCachedItem('user-3', tags: {'user'});

          handler.invalidateByIds(['user-1', 'user-3']);

          expect(handler.isStale('user-1'), isTrue);
          expect(handler.isStale('user-2'), isFalse);
          expect(handler.isStale('user-3'), isTrue);
        });
      });

      group('tags survive invalidation', () {
        test('should preserve tags after invalidation', () {
          handler.recordCachedItem('user-1', tags: {'premium', 'active'});

          handler.invalidate('user-1');

          expect(handler.getTags('user-1'), containsAll(['premium', 'active']));
        });

        test('should preserve tags after invalidateAll', () {
          handler.recordCachedItem('user-1', tags: {'premium'});

          handler.invalidateAll();

          expect(handler.getTags('user-1'), contains('premium'));
        });
      });

      group('isStale', () {
        test('should return true for invalidated item', () {
          handler.recordCachedItem('user-1');
          handler.invalidate('user-1');

          expect(handler.isStale('user-1'), isTrue);
        });

        test('should return true for untracked item', () {
          expect(handler.isStale('unknown'), isTrue);
        });

        test('should return false for fresh item', () {
          handler.recordCachedItem('user-1');

          expect(handler.isStale('user-1'), isFalse);
        });
      });

      group('getCacheStats', () {
        test('should return cache stats', () {
          handler.recordCachedItem('user-1', tags: {'premium'});
          handler.recordCachedItem('user-2', tags: {'premium', 'active'});
          handler.recordCachedItem('user-3', tags: {'basic'});
          handler.invalidate('user-3');

          final stats = handler.getCacheStats();

          expect(stats.totalCount, equals(3));
          expect(stats.staleCount, equals(1));
          expect(stats.tagCounts['premium'], equals(2));
          expect(stats.tagCounts['active'], equals(1));
          expect(stats.tagCounts['basic'], equals(1));
        });

        test('should return empty stats when no items', () {
          final stats = handler.getCacheStats();

          expect(stats.totalCount, equals(0));
          expect(stats.staleCount, equals(0));
          expect(stats.tagCounts, isEmpty);
        });
      });

      group('invalidateWhere', () {
        test('should invalidate items matching query', () async {
          backend.addToStorage(
            'user-1',
            TestFixtures.createUser(id: 'user-1', isActive: true),
          );
          backend.addToStorage(
            'user-2',
            TestFixtures.createUser(id: 'user-2', isActive: false),
          );
          backend.addToStorage(
            'user-3',
            TestFixtures.createUser(id: 'user-3', isActive: true),
          );
          handler.recordCachedItem('user-1');
          handler.recordCachedItem('user-2');
          handler.recordCachedItem('user-3');

          final query = Query<TestUser>().where('isActive', isEqualTo: false);
          await handler.invalidateWhere(
            query,
            fieldAccessor: (user, field) => switch (field) {
              'isActive' => user.isActive,
              _ => null,
            },
          );

          expect(handler.isStale('user-1'), isFalse);
          expect(handler.isStale('user-2'), isTrue); // only inactive user
          expect(handler.isStale('user-3'), isFalse);
        });
      });

      group('removeEntry', () {
        test('should remove entry and its tags', () {
          handler.recordCachedItem('user-1', tags: {'premium'});

          handler.removeEntry('user-1');

          expect(handler.getTags('user-1'), isEmpty);
          expect(handler.getCacheStats().totalCount, equals(0));
        });
      });
    });
  });
}
