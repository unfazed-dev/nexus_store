import 'package:test/test.dart';
import 'package:nexus_store/src/cache/eviction_strategy.dart';
import 'package:nexus_store/src/cache/memory_config.dart';
import 'package:nexus_store/src/cache/memory_manager.dart';
import 'package:nexus_store/src/cache/memory_metrics.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/cache/size_estimator.dart';

void main() {
  group('MemoryManager', () {
    late MemoryManager<Map<String, dynamic>, String> manager;

    setUp(() {
      manager = MemoryManager<Map<String, dynamic>, String>(
        config: MemoryConfig(
          maxCacheBytes: 1000,
          moderateThreshold: 0.7,
          criticalThreshold: 0.9,
          evictionBatchSize: 2,
          strategy: EvictionStrategy.lru,
        ),
        sizeEstimator: FixedSizeEstimator(100),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    group('recordItem', () {
      test('adds item to tracking', () {
        manager.recordItem('item1', {'name': 'test'});
        expect(manager.contains('item1'), isTrue);
        expect(manager.itemCount, equals(1));
      });

      test('updates total size', () {
        manager.recordItem('item1', {'name': 'test'});
        expect(manager.currentBytes, equals(100));

        manager.recordItem('item2', {'name': 'test2'});
        expect(manager.currentBytes, equals(200));
      });

      test('triggers eviction when threshold exceeded', () async {
        // Add items to exceed moderate threshold (700 bytes = 70%)
        for (var i = 0; i < 8; i++) {
          manager.recordItem('item$i', {'name': 'test$i'});
        }

        await Future.delayed(Duration(milliseconds: 10));

        // Should have triggered eviction
        expect(manager.currentLevel.isAtLeast(MemoryPressureLevel.moderate),
            isTrue);
      });
    });

    group('recordAccess', () {
      test('updates access time for existing item', () async {
        manager.recordItem('item1', {'name': 'test'});
        final time1 = manager.getLastAccessTime('item1');

        await Future.delayed(Duration(milliseconds: 10));

        manager.recordAccess('item1');
        final time2 = manager.getLastAccessTime('item1');

        expect(time2!.isAfter(time1!), isTrue);
      });

      test('does nothing for unknown item', () {
        manager.recordAccess('unknown');
        expect(manager.contains('unknown'), isFalse);
      });
    });

    group('removeItem', () {
      test('removes item from tracking', () {
        manager.recordItem('item1', {'name': 'test'});
        expect(manager.contains('item1'), isTrue);

        manager.removeItem('item1');
        expect(manager.contains('item1'), isFalse);
      });

      test('updates total size', () {
        manager.recordItem('item1', {'name': 'test'});
        manager.recordItem('item2', {'name': 'test2'});
        expect(manager.currentBytes, equals(200));

        manager.removeItem('item1');
        expect(manager.currentBytes, equals(100));
      });
    });

    group('pin and unpin', () {
      test('pin adds item to pinned set', () {
        manager.recordItem('item1', {'name': 'test'});
        manager.pin('item1');
        expect(manager.isPinned('item1'), isTrue);
        expect(manager.pinnedIds, contains('item1'));
      });

      test('unpin removes item from pinned set', () {
        manager.recordItem('item1', {'name': 'test'});
        manager.pin('item1');
        expect(manager.isPinned('item1'), isTrue);

        manager.unpin('item1');
        expect(manager.isPinned('item1'), isFalse);
      });

      test('pinned items are excluded from eviction', () async {
        // Add and pin first item
        manager.recordItem('pinned', {'name': 'pinned'});
        manager.pin('pinned');

        // Add more items to trigger eviction
        for (var i = 0; i < 10; i++) {
          manager.recordItem('item$i', {'name': 'test$i'});
        }

        // Force eviction
        final evicted = manager.evict(count: 5);

        expect(evicted, isNot(contains('pinned')));
        expect(manager.contains('pinned'), isTrue);
      });
    });

    group('evict', () {
      test('evicts items in LRU order by default', () async {
        // Add items with delays
        manager.recordItem('old1', {'name': 'old1'});
        await Future.delayed(Duration(milliseconds: 5));
        manager.recordItem('old2', {'name': 'old2'});
        await Future.delayed(Duration(milliseconds: 5));
        manager.recordItem('new1', {'name': 'new1'});
        await Future.delayed(Duration(milliseconds: 5));
        manager.recordItem('new2', {'name': 'new2'});

        final evicted = manager.evict(count: 2);

        expect(evicted, containsAll(['old1', 'old2']));
        expect(manager.contains('old1'), isFalse);
        expect(manager.contains('old2'), isFalse);
        expect(manager.contains('new1'), isTrue);
        expect(manager.contains('new2'), isTrue);
      });

      test('evicts items in LFU order when configured', () {
        final lfuManager = MemoryManager<Map<String, dynamic>, String>(
          config: MemoryConfig(strategy: EvictionStrategy.lfu),
          sizeEstimator: FixedSizeEstimator(100),
        );

        // Add items with different access counts
        lfuManager.recordItem('rarely', {'name': 'rarely'});
        lfuManager.recordItem('often', {'name': 'often'});
        lfuManager.recordAccess('often');
        lfuManager.recordAccess('often');
        lfuManager.recordAccess('often');

        final evicted = lfuManager.evict(count: 1);

        expect(evicted, equals(['rarely']));
        expect(lfuManager.contains('rarely'), isFalse);
        expect(lfuManager.contains('often'), isTrue);

        lfuManager.dispose();
      });

      test('evicts items by size when configured', () {
        final sizeManager = MemoryManager<Map<String, dynamic>, String>(
          config: MemoryConfig(strategy: EvictionStrategy.size),
          sizeEstimator: CallbackSizeEstimator(
            (item) => item['size'] as int,
          ),
        );

        sizeManager.recordItem('small', {'size': 100});
        sizeManager.recordItem('large', {'size': 1000});
        sizeManager.recordItem('medium', {'size': 500});

        final evicted = sizeManager.evict(count: 1);

        expect(evicted, equals(['large']));
        expect(sizeManager.contains('large'), isFalse);

        sizeManager.dispose();
      });
    });

    group('evictUnpinned', () {
      test('evicts all non-pinned items', () {
        manager.recordItem('item1', {'name': 'test1'});
        manager.recordItem('item2', {'name': 'test2'});
        manager.recordItem('pinned', {'name': 'pinned'});
        manager.pin('pinned');

        manager.evictUnpinned();

        expect(manager.contains('item1'), isFalse);
        expect(manager.contains('item2'), isFalse);
        expect(manager.contains('pinned'), isTrue);
      });
    });

    group('metrics', () {
      test('returns current metrics', () {
        manager.recordItem('item1', {'name': 'test'});
        manager.recordItem('item2', {'name': 'test2'});
        manager.pin('item1');

        final metrics = manager.currentMetrics;

        expect(metrics.currentBytes, equals(200));
        expect(metrics.itemCount, equals(2));
        expect(metrics.pinnedCount, equals(1));
        expect(metrics.pinnedBytes, equals(100));
      });

      test('metricsStream emits on changes', () async {
        final metricsList = <MemoryMetrics>[];
        final sub = manager.metricsStream.listen(metricsList.add);

        manager.recordItem('item1', {'name': 'test'});

        await Future.delayed(Duration(milliseconds: 10));
        await sub.cancel();

        expect(metricsList.isNotEmpty, isTrue);
        expect(metricsList.last.itemCount, equals(1));
      });
    });

    group('pressure level', () {
      test('currentLevel reflects usage', () {
        expect(manager.currentLevel, equals(MemoryPressureLevel.none));

        // Add items to reach 70% (700 bytes)
        for (var i = 0; i < 7; i++) {
          manager.recordItem('item$i', {'name': 'test$i'});
        }
        expect(manager.currentLevel, equals(MemoryPressureLevel.moderate));
      });

      test('pressureStream emits level changes', () async {
        final levels = <MemoryPressureLevel>[];
        final sub = manager.pressureStream.listen(levels.add);

        for (var i = 0; i < 10; i++) {
          manager.recordItem('item$i', {'name': 'test$i'});
        }

        await Future.delayed(Duration(milliseconds: 10));
        await sub.cancel();

        expect(levels, isNotEmpty);
      });
    });

    group('onEviction callback', () {
      test('callback is called when items are evicted', () {
        final evictedIds = <String>[];
        final callbackManager = MemoryManager<Map<String, dynamic>, String>(
          config: MemoryConfig(
            maxCacheBytes: 1000,
            evictionBatchSize: 2,
          ),
          sizeEstimator: FixedSizeEstimator(100),
          onEviction: evictedIds.addAll,
        );

        for (var i = 0; i < 5; i++) {
          callbackManager.recordItem('item$i', {'name': 'test$i'});
        }

        callbackManager.evict(count: 2);

        expect(evictedIds, hasLength(2));

        callbackManager.dispose();
      });
    });

    group('unlimited cache', () {
      test('no eviction when maxCacheBytes is null', () {
        final unlimitedManager = MemoryManager<Map<String, dynamic>, String>(
          config: MemoryConfig(), // No maxCacheBytes
          sizeEstimator: FixedSizeEstimator(100),
        );

        for (var i = 0; i < 100; i++) {
          unlimitedManager.recordItem('item$i', {'name': 'test$i'});
        }

        expect(unlimitedManager.currentLevel, equals(MemoryPressureLevel.none));
        expect(unlimitedManager.itemCount, equals(100));

        unlimitedManager.dispose();
      });
    });
  });
}
