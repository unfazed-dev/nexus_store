import 'package:nexus_store/src/cache/eviction_strategy.dart';
import 'package:nexus_store/src/cache/memory_config.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/cache/size_estimator.dart';
import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('StoreConfig memory configuration', () {
    test('memory field is null by default', () {
      const config = StoreConfig();
      expect(config.memory, isNull);
    });

    test('memory field can be configured', () {
      const config = StoreConfig(
        memory: MemoryConfig(
          maxCacheBytes: 50 * 1024 * 1024,
          moderateThreshold: 0.7,
          criticalThreshold: 0.9,
          strategy: EvictionStrategy.lru,
        ),
      );

      expect(config.memory, isNotNull);
      expect(config.memory!.maxCacheBytes, 50 * 1024 * 1024);
      expect(config.memory!.moderateThreshold, 0.7);
      expect(config.memory!.criticalThreshold, 0.9);
      expect(config.memory!.strategy, EvictionStrategy.lru);
    });

    test('offlineFirst preset has no memory configured', () {
      expect(StoreConfig.offlineFirst.memory, isNull);
    });

    test('onlineOnly preset has no memory configured', () {
      expect(StoreConfig.onlineOnly.memory, isNull);
    });
  });

  group('NexusStore memory management', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        sizeEstimator: FixedSizeEstimator<TestUser>(1024),
        config: const StoreConfig(
          memory: MemoryConfig(
            maxCacheBytes: 10 * 1024, // 10KB for testing
            moderateThreshold: 0.5,
            criticalThreshold: 0.8,
            evictionBatchSize: 2,
            strategy: EvictionStrategy.lru,
          ),
        ),
      );

      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('pin and unpin', () {
      test('pins an item to protect from eviction', () async {
        // Save an item
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));

        // Pin the item
        store.pin('user-1');

        expect(store.isPinned('user-1'), isTrue);
        expect(store.pinnedIds, contains('user-1'));
      });

      test('unpins an item to make it eligible for eviction', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));

        store.pin('user-1');
        expect(store.isPinned('user-1'), isTrue);

        store.unpin('user-1');
        expect(store.isPinned('user-1'), isFalse);
        expect(store.pinnedIds, isNot(contains('user-1')));
      });

      test('isPinned returns false for non-pinned items', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));

        expect(store.isPinned('user-1'), isFalse);
      });

      test('pinnedIds returns all pinned items', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));
        await store.save(TestFixtures.createUser(id: 'user-3', name: 'User 3'));

        store.pin('user-1');
        store.pin('user-3');

        expect(store.pinnedIds, containsAll(['user-1', 'user-3']));
        expect(store.pinnedIds, isNot(contains('user-2')));
      });
    });

    group('memory metrics', () {
      test('memoryMetrics returns current metrics', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

        final metrics = store.memoryMetrics;

        expect(metrics, isNotNull);
        expect(metrics!.itemCount, 2);
        expect(metrics.currentBytes, greaterThan(0));
      });

      test('memoryMetrics includes pinned item counts', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

        store.pin('user-1');

        final metrics = store.memoryMetrics;

        expect(metrics!.pinnedCount, 1);
        expect(metrics.pinnedBytes, greaterThan(0));
      });

      test('memoryMetricsStream emits updates', () async {
        final metrics = <dynamic>[];
        final subscription = store.memoryMetricsStream.listen(metrics.add);

        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

        await subscription.cancel();

        // Should have emitted at least the initial state and updates
        expect(metrics, isNotEmpty);
      });
    });

    group('memory pressure', () {
      test('memoryPressure returns current level', () async {
        final level = store.memoryPressure;
        expect(level, isA<MemoryPressureLevel>());
      });

      test('memoryPressureStream emits level changes', () async {
        final levels = <MemoryPressureLevel>[];
        final subscription = store.memoryPressureStream.listen(levels.add);

        // Save items to increase memory pressure
        for (var i = 0; i < 5; i++) {
          await store.save(
            TestFixtures.createUser(id: 'user-$i', name: 'User $i'),
          );
        }

        await subscription.cancel();

        // Should have emitted at least the initial level
        expect(levels, isNotEmpty);
      });
    });

    group('eviction', () {
      test('evictCache evicts items', () async {
        // Save several items
        for (var i = 0; i < 5; i++) {
          await store.save(
            TestFixtures.createUser(id: 'user-$i', name: 'User $i'),
          );
        }

        final initialCount = store.memoryMetrics!.itemCount;

        final evicted = store.evictCache(count: 2);

        expect(evicted.length, 2);
        expect(store.memoryMetrics!.itemCount, initialCount - 2);
      });

      test('evictCache does not evict pinned items', () async {
        for (var i = 0; i < 5; i++) {
          await store.save(
            TestFixtures.createUser(id: 'user-$i', name: 'User $i'),
          );
        }

        // Pin some items
        store.pin('user-0');
        store.pin('user-1');

        final evicted = store.evictCache(count: 3);

        // Should not include pinned items
        expect(evicted, isNot(contains('user-0')));
        expect(evicted, isNot(contains('user-1')));
      });

      test('evictUnpinnedCache clears all non-pinned items', () async {
        for (var i = 0; i < 5; i++) {
          await store.save(
            TestFixtures.createUser(id: 'user-$i', name: 'User $i'),
          );
        }

        // Pin some items
        store.pin('user-0');
        store.pin('user-1');

        store.evictUnpinnedCache();

        final metrics = store.memoryMetrics!;
        // Only pinned items should remain
        expect(metrics.itemCount, 2);
        expect(metrics.pinnedCount, 2);
      });
    });

    group('integration with save/get/delete', () {
      test('save records item in memory manager', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));

        final metrics = store.memoryMetrics!;
        expect(metrics.itemCount, 1);
        expect(metrics.currentBytes, greaterThan(0));
      });

      test('get records access for LRU tracking', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

        // Access user-1
        await store.get('user-1');

        // Save more items to trigger eviction
        for (var i = 3; i < 10; i++) {
          await store.save(
            TestFixtures.createUser(id: 'user-$i', name: 'User $i'),
          );
        }

        // Evict least recently used
        final evicted = store.evictCache(count: 1);

        // user-2 should be evicted before user-1 (which was accessed more recently)
        expect(evicted, contains('user-2'));
        expect(evicted, isNot(contains('user-1')));
      });

      test('delete removes item from memory manager', () async {
        await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
        await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

        expect(store.memoryMetrics!.itemCount, 2);

        await store.delete('user-1');

        expect(store.memoryMetrics!.itemCount, 1);
      });

      test('saveAll records all items in memory manager', () async {
        await store.saveAll([
          TestFixtures.createUser(id: 'user-1', name: 'User 1'),
          TestFixtures.createUser(id: 'user-2', name: 'User 2'),
          TestFixtures.createUser(id: 'user-3', name: 'User 3'),
        ]);

        expect(store.memoryMetrics!.itemCount, 3);
      });

      test('deleteAll removes all items from memory manager', () async {
        await store.saveAll([
          TestFixtures.createUser(id: 'user-1', name: 'User 1'),
          TestFixtures.createUser(id: 'user-2', name: 'User 2'),
          TestFixtures.createUser(id: 'user-3', name: 'User 3'),
        ]);

        await store.deleteAll(['user-1', 'user-2']);

        expect(store.memoryMetrics!.itemCount, 1);
      });
    });
  });

  group('NexusStore without memory management', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        config: const StoreConfig(), // No memory config
      );

      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    test('memoryMetrics returns null when not configured', () {
      expect(store.memoryMetrics, isNull);
    });

    test('memoryPressure returns none when not configured', () {
      expect(store.memoryPressure, MemoryPressureLevel.none);
    });

    test('memoryMetricsStream returns empty stream when not configured', () {
      expect(store.memoryMetricsStream, emitsInOrder([]));
    });

    test('memoryPressureStream returns empty stream when not configured', () {
      expect(store.memoryPressureStream, emitsInOrder([]));
    });

    test('pin is no-op when not configured', () {
      store.pin('user-1');
      expect(store.isPinned('user-1'), isFalse);
    });

    test('unpin is no-op when not configured', () {
      store.unpin('user-1');
      // Should not throw
    });

    test('pinnedIds returns empty set when not configured', () {
      expect(store.pinnedIds, isEmpty);
    });

    test('evictCache returns empty list when not configured', () {
      final evicted = store.evictCache(count: 5);
      expect(evicted, isEmpty);
    });

    test('evictUnpinnedCache is no-op when not configured', () {
      store.evictUnpinnedCache();
      // Should not throw
    });
  });

  group('NexusStore with custom size estimator', () {
    late FakeStoreBackend<TestUser, String> backend;

    test('uses provided size estimator', () async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      // Custom estimator that returns 500 bytes per item
      final customEstimator = FixedSizeEstimator<TestUser>(500);

      final store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        sizeEstimator: customEstimator,
        config: const StoreConfig(
          memory: MemoryConfig(
            maxCacheBytes: 10000,
          ),
        ),
      );

      await store.initialize();

      await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
      await store.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));

      // Each item is 500 bytes, so 2 items = 1000 bytes
      expect(store.memoryMetrics!.currentBytes, 1000);

      await store.dispose();
    });

    test('defaults to FixedSizeEstimator(1024) when not provided', () async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      final store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        // No sizeEstimator provided
        config: const StoreConfig(
          memory: MemoryConfig(
            maxCacheBytes: 10000,
          ),
        ),
      );

      await store.initialize();

      await store.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));

      // Default is 1024 bytes per item
      expect(store.memoryMetrics!.currentBytes, 1024);

      await store.dispose();
    });
  });
}
