# TRACKER: Memory Management

## Status: PENDING

## Overview

Implement automatic cache eviction under memory pressure to prevent OOM crashes on low-end devices, with configurable thresholds and pinned item protection.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-039, Task 31
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `MemoryPressureLevel` enum
  - [ ] `none` - Normal operation
  - [ ] `moderate` - Start evicting
  - [ ] `critical` - Aggressive eviction
  - [ ] `emergency` - Clear all non-pinned

- [ ] Create `MemoryConfig` class
  - [ ] `maxCacheBytes: int?` - Maximum cache size
  - [ ] `moderateThreshold: double` - 0.0-1.0 (default 0.7)
  - [ ] `criticalThreshold: double` - 0.0-1.0 (default 0.9)
  - [ ] `evictionBatchSize: int` - Items per eviction (default 10)

- [ ] Create `MemoryMetrics` class
  - [ ] `currentUsage: int` - Bytes used
  - [ ] `maxUsage: int` - Peak bytes
  - [ ] `evictionCount: int`
  - [ ] `pressureLevel: MemoryPressureLevel`

### Memory Pressure Detection
- [ ] Create `MemoryPressureHandler` interface
  - [ ] `Stream<MemoryPressureLevel> get pressureStream`
  - [ ] Platform-specific implementations

- [ ] Create `FlutterMemoryPressureHandler` (nexus_store_flutter)
  - [ ] Use `WidgetsBindingObserver.didHaveMemoryPressure`
  - [ ] Map system events to pressure levels

- [ ] Create `DartMemoryPressureHandler` (pure Dart)
  - [ ] Estimate memory usage from cache size
  - [ ] Configurable thresholds

### Cache Eviction
- [ ] Create `MemoryManager` class
  - [ ] Track cache entries with size estimates
  - [ ] Implement LRU eviction
  - [ ] Support pinned items

- [ ] Implement LRU tracking
  - [ ] Track access times per entry
  - [ ] Efficient data structure (linked hash map)
  - [ ] Update on every access

- [ ] Implement eviction strategies
  - [ ] `EvictionStrategy.lru` - Least recently used
  - [ ] `EvictionStrategy.lfu` - Least frequently used
  - [ ] `EvictionStrategy.size` - Largest items first

### Pinned Items
- [ ] Add `pin(ID id)` method to NexusStore
  - [ ] Pinned items never evicted
  - [ ] Persists across pressure events

- [ ] Add `unpin(ID id)` method
  - [ ] Remove pin protection
  - [ ] Item eligible for eviction

- [ ] Add `pinnedIds` getter
  - [ ] List all pinned item IDs

### Size Estimation
- [ ] Create `SizeEstimator` interface
  - [ ] `int estimateSize(T item)`
  - [ ] Default JSON serialization-based estimate

- [ ] Implement default estimator
  - [ ] Serialize to JSON, count bytes
  - [ ] Cache estimates per item

### NexusStore Integration
- [ ] Add `memoryConfig` to `StoreConfig`
- [ ] Integrate MemoryManager with cache
- [ ] Add memory metrics to store

### Metrics & Observability
- [ ] Add memory metrics to telemetry
  - [ ] Cache size over time
  - [ ] Eviction events
  - [ ] Pressure level changes

- [ ] Add `memoryMetrics` getter to store
- [ ] Add `memoryPressureStream` to store

### Unit Tests
- [ ] `test/src/cache/memory_manager_test.dart`
  - [ ] LRU eviction order correct
  - [ ] Pinned items protected
  - [ ] Pressure levels trigger eviction
  - [ ] Size estimation works

## Files

**Source Files:**
```
packages/nexus_store/lib/src/cache/
├── memory_manager.dart         # MemoryManager class
├── memory_config.dart          # MemoryConfig
├── memory_metrics.dart         # MemoryMetrics
├── memory_pressure_handler.dart # Interface
├── eviction_strategy.dart      # EvictionStrategy enum
└── size_estimator.dart         # SizeEstimator interface

packages/nexus_store_flutter/lib/src/cache/
└── flutter_memory_pressure_handler.dart
```

**Test Files:**
```
packages/nexus_store/test/src/cache/
├── memory_manager_test.dart
├── lru_cache_test.dart
└── size_estimator_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22) - for metrics
- Flutter extension (Task 14) - for Flutter handler

## API Preview

```dart
// Configure memory management
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    memory: MemoryConfig(
      maxCacheBytes: 50 * 1024 * 1024, // 50MB
      moderateThreshold: 0.7, // Start evicting at 70%
      criticalThreshold: 0.9, // Aggressive at 90%
      evictionBatchSize: 20,
      strategy: EvictionStrategy.lru,
    ),
  ),
);

// Pin important items (never evicted)
await store.pin('current-user'); // Current user
await store.pin('settings'); // App settings

// Unpin when no longer needed
await store.unpin('current-user');

// Check pinned items
final pinned = store.pinnedIds; // ['settings']

// Monitor memory
store.memoryPressureStream.listen((level) {
  switch (level) {
    case MemoryPressureLevel.moderate:
      // Maybe show "running low on memory" indicator
      break;
    case MemoryPressureLevel.critical:
      // Pause background operations
      break;
    case MemoryPressureLevel.emergency:
      // Cache is being cleared!
      break;
  }
});

// Get current metrics
final metrics = store.memoryMetrics;
print('Cache size: ${metrics.currentUsage / 1024 / 1024} MB');
print('Evictions: ${metrics.evictionCount}');
print('Pressure: ${metrics.pressureLevel}');

// Custom size estimator for complex objects
final store = NexusStore<MediaItem, String>(
  backend: backend,
  config: StoreConfig(
    memory: MemoryConfig(
      sizeEstimator: (item) {
        // Include thumbnail size in estimate
        return item.metadata.length + (item.thumbnail?.length ?? 0);
      },
    ),
  ),
);

// Manual eviction (for testing or explicit cleanup)
await store.evictLeastRecentlyUsed(count: 10);
await store.clearUnpinnedCache();
```

## Notes

- Memory pressure APIs vary by platform
- Size estimation is approximate - actual memory usage differs
- Consider storing size estimates to avoid recalculation
- Pinned items count against cache limit
- LRU tracking has small overhead per access
- Test on actual low-memory devices
- Document that evicted items will be re-fetched when accessed
- Consider adding "soft" cache vs "hard" cache distinction
