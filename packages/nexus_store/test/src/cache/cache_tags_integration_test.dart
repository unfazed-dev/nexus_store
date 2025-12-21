import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Cache Tags Integration', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        config: const StoreConfig(
          staleDuration: Duration(minutes: 5),
        ),
        idExtractor: (user) => user.id,
      );
      await store.initialize();
    });

    group('full workflow', () {
      test('should save with tags and retrieve tags', () async {
        final user = TestFixtures.createUser(id: 'user-1');

        await store.save(user, tags: {'premium', 'team-alpha'});

        final tags = store.getTags('user-1');
        expect(tags, containsAll(['premium', 'team-alpha']));
      });

      test('should accumulate tags on same item', () async {
        final user = TestFixtures.createUser(id: 'user-1');

        await store.save(user, tags: {'premium'});
        store.addTags('user-1', {'featured'});

        final tags = store.getTags('user-1');
        expect(tags, containsAll(['premium', 'featured']));
      });

      test('should invalidate by tags and verify staleness', () async {
        // Save users with different tags
        await store.save(
          TestFixtures.createUser(id: 'user-1'),
          tags: {'team-alpha'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-2'),
          tags: {'team-alpha'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-3'),
          tags: {'team-beta'},
        );

        // Verify none are stale initially
        expect(store.isStale('user-1'), isFalse);
        expect(store.isStale('user-2'), isFalse);
        expect(store.isStale('user-3'), isFalse);

        // Invalidate team-alpha
        store.invalidateByTags({'team-alpha'});

        // Verify team-alpha members are stale
        expect(store.isStale('user-1'), isTrue);
        expect(store.isStale('user-2'), isTrue);
        expect(store.isStale('user-3'), isFalse);
      });

      test('should preserve tags after invalidation', () async {
        await store.save(
          TestFixtures.createUser(id: 'user-1'),
          tags: {'premium'},
        );

        // Invalidate
        store.invalidate('user-1');

        // Tags should still be there
        expect(store.getTags('user-1'), contains('premium'));

        // But it should be stale
        expect(store.isStale('user-1'), isTrue);
      });

      test('should invalidate by query', () async {
        await store.save(
          TestFixtures.createUser(id: 'user-1', isActive: true),
        );
        await store.save(
          TestFixtures.createUser(id: 'user-2', isActive: false),
        );
        await store.save(
          TestFixtures.createUser(id: 'user-3', isActive: true),
        );

        // Invalidate inactive users
        await store.invalidateWhere(
          Query<TestUser>().where('isActive', isEqualTo: false),
          fieldAccessor: (user, field) => switch (field) {
            'isActive' => user.isActive,
            _ => null,
          },
        );

        // Only user-2 should be stale
        expect(store.isStale('user-1'), isFalse);
        expect(store.isStale('user-2'), isTrue);
        expect(store.isStale('user-3'), isFalse);
      });

      test('should maintain accurate cache stats', () async {
        // Save users with various tags
        await store.save(
          TestFixtures.createUser(id: 'user-1'),
          tags: {'premium', 'active'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-2'),
          tags: {'premium'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-3'),
          tags: {'basic'},
        );

        var stats = store.getCacheStats();
        expect(stats.totalCount, equals(3));
        expect(stats.staleCount, equals(0));
        expect(stats.tagCounts['premium'], equals(2));
        expect(stats.tagCounts['active'], equals(1));
        expect(stats.tagCounts['basic'], equals(1));
        expect(stats.freshCount, equals(3));
        expect(stats.stalePercentage, equals(0.0));

        // Invalidate one
        store.invalidate('user-1');

        stats = store.getCacheStats();
        expect(stats.staleCount, equals(1));
        expect(stats.freshCount, equals(2));
        expect(stats.stalePercentage, closeTo(33.33, 0.01));
      });
    });

    group('cross-tag invalidation', () {
      test('should invalidate users with any matching tag', () async {
        await store.save(
          TestFixtures.createUser(id: 'user-1'),
          tags: {'team-alpha', 'premium'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-2'),
          tags: {'team-beta', 'premium'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-3'),
          tags: {'team-alpha', 'basic'},
        );
        await store.save(
          TestFixtures.createUser(id: 'user-4'),
          tags: {'team-gamma', 'basic'},
        );

        // Invalidate by multiple tags
        store.invalidateByTags({'team-alpha', 'premium'});

        // user-1, user-2, user-3 should be stale (any of the tags match)
        expect(store.isStale('user-1'), isTrue);
        expect(store.isStale('user-2'), isTrue);
        expect(store.isStale('user-3'), isTrue);
        expect(store.isStale('user-4'), isFalse);
      });
    });

    group('tag lifecycle', () {
      test('should remove tags from item', () async {
        await store.save(
          TestFixtures.createUser(id: 'user-1'),
          tags: {'premium', 'active', 'featured'},
        );

        store.removeTags('user-1', {'featured', 'active'});

        final tags = store.getTags('user-1');
        expect(tags, contains('premium'));
        expect(tags, isNot(contains('featured')));
        expect(tags, isNot(contains('active')));
      });

      test('should handle tag operations on non-existent items', () async {
        // Should not throw
        store.addTags('non-existent', {'some-tag'});
        store.removeTags('non-existent', {'some-tag'});

        // Should return empty set
        expect(store.getTags('non-existent'), isEmpty);
      });
    });

    group('batch operations', () {
      test('should apply same tags to all batch items', () async {
        final users = [
          TestFixtures.createUser(id: 'user-1'),
          TestFixtures.createUser(id: 'user-2'),
          TestFixtures.createUser(id: 'user-3'),
        ];

        await store.saveAll(users, tags: {'batch-import', 'team-alpha'});

        for (final user in users) {
          final tags = store.getTags(user.id);
          expect(tags, containsAll(['batch-import', 'team-alpha']));
        }
      });

      test('should invalidate batch by IDs', () async {
        await store.save(TestFixtures.createUser(id: 'user-1'));
        await store.save(TestFixtures.createUser(id: 'user-2'));
        await store.save(TestFixtures.createUser(id: 'user-3'));
        await store.save(TestFixtures.createUser(id: 'user-4'));

        store.invalidateByIds(['user-1', 'user-3']);

        expect(store.isStale('user-1'), isTrue);
        expect(store.isStale('user-2'), isFalse);
        expect(store.isStale('user-3'), isTrue);
        expect(store.isStale('user-4'), isFalse);
      });
    });

    group('no idExtractor', () {
      test('should work without idExtractor but not track cache', () async {
        final storeWithoutExtractor = NexusStore<TestUser, String>(
          backend: backend,
        );
        await storeWithoutExtractor.initialize();

        // Save should work
        final user = TestFixtures.createUser(id: 'user-1');
        final saved = await storeWithoutExtractor.save(
          user,
          tags: {'premium'},
        );
        expect(saved, equals(user));

        // But tags won't be tracked (no idExtractor)
        expect(storeWithoutExtractor.getTags('user-1'), isEmpty);

        await storeWithoutExtractor.dispose();
      });
    });
  });
}
