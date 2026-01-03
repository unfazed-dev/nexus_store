# TRACKER: Memory Management

## Status: COMPLETE

## Overview

Implement automatic cache eviction under memory pressure to prevent OOM crashes on low-end devices, with configurable thresholds and pinned item protection.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-039, Task 31
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `MemoryPressureLevel` enum
  - [x] `none` - Normal operation
  - [x] `moderate` - Start evicting
  - [x] `critical` - Aggressive eviction
  - [x] `emergency` - Clear all non-pinned
  - [x] Helper methods: `isAtLeast()`, `shouldEvict`, `isEmergency`

- [x] Create `EvictionStrategy` enum
  - [x] `lru` - Least recently used (default)
  - [x] `lfu` - Least frequently used
  - [x] `size` - Largest items first
  - [x] Helper properties: `isAccessBased`, `requiresAccessTracking`, `requiresFrequencyTracking`

- [x] Create `MemoryConfig` class (freezed)
  - [x] `maxCacheBytes: int?` - Maximum cache size
  - [x] `moderateThreshold: double` - 0.0-1.0 (default 0.7)
  - [x] `criticalThreshold: double` - 0.0-1.0 (default 0.9)
  - [x] `evictionBatchSize: int` - Items per eviction (default 10)
  - [x] `strategy: EvictionStrategy` - Eviction strategy (default lru)
  - [x] Presets: `defaults`, `aggressive`, `conservative`
  - [x] Helpers: `isUnlimited`, `hasValidThresholds`

- [x] Create `MemoryMetrics` class (freezed)
  - [x] `currentBytes: int` - Bytes used
  - [x] `maxBytes: int` - Peak bytes
  - [x] `evictionCount: int`
  - [x] `pinnedCount: int` - Pinned items
  - [x] `pinnedBytes: int` - Pinned item size
  - [x] `pressureLevel: MemoryPressureLevel`
  - [x] `itemCount: int` - Total tracked items
  - [x] `timestamp: DateTime`
  - [x] Computed: `usageRatio`, `unpinnedBytes`, `unpinnedCount`, `averageItemSize`
  - [x] Factory: `MemoryMetrics.empty()`

### Memory Pressure Detection
- [x] Create `MemoryPressureHandler` interface
  - [x] `Stream<MemoryPressureLevel> get pressureStream`
  - [x] `MemoryPressureLevel get currentLevel`
  - [x] `void dispose()`

- [x] Create `ThresholdMemoryPressureHandler` (pure Dart)
  - [x] Estimate memory usage from cache size
  - [x] Configurable thresholds
  - [x] `updateUsage()`, `triggerEmergency()`, `reset()`

- [x] Create `ManualMemoryPressureHandler`
  - [x] For testing and manual control
  - [x] `setLevel()` method

- [x] Create `FlutterMemoryPressureHandler` (nexus_store_flutter_widgets)
  - [x] Use `WidgetsBindingObserver.didHaveMemoryPressure`
  - [x] Map system events to pressure levels
  - [x] `setLevel()`, `reset()`, `triggerEmergency()`

### Cache Eviction
- [x] Create `LruTracker` class
  - [x] Track access times per entry
  - [x] Track access counts for LFU
  - [x] Track sizes for size-based eviction
  - [x] Efficient LinkedHashMap with O(1) operations
  - [x] `recordAccess()`, `remove()`, `contains()`
  - [x] `getEvictionCandidatesLru()`, `getEvictionCandidatesLfu()`, `getEvictionCandidatesBySize()`

- [x] Create `MemoryManager` class
  - [x] Track cache entries with size estimates
  - [x] Implement LRU/LFU/Size eviction
  - [x] Support pinned items
  - [x] `recordItem()`, `recordAccess()`, `removeItem()`
  - [x] `evict()`, `evictUnpinned()`
  - [x] Metrics stream via BehaviorSubject
  - [x] Pressure stream integration

### Pinned Items
- [x] Add `pin(ID id)` method to NexusStore
  - [x] Pinned items never evicted
  - [x] Persists across pressure events

- [x] Add `unpin(ID id)` method
  - [x] Remove pin protection
  - [x] Item eligible for eviction

- [x] Add `isPinned(ID id)` method
- [x] Add `pinnedIds` getter
  - [x] List all pinned item IDs

### Size Estimation
- [x] Create `SizeEstimator` interface
  - [x] `int estimateSize(T item)`

- [x] Create `JsonSizeEstimator`
  - [x] Serialize to JSON, count bytes
  - [x] Cache estimates with size limit

- [x] Create `FixedSizeEstimator`
  - [x] Fixed size per item

- [x] Create `CallbackSizeEstimator`
  - [x] Custom callback function

- [x] Create `CompositeSizeEstimator`
  - [x] Combine multiple estimators

### NexusStore Integration
- [x] Add `memory: MemoryConfig?` to `StoreConfig`
- [x] Add `sizeEstimator: SizeEstimator<T>?` to NexusStore constructor
- [x] Initialize MemoryManager when memory config present
- [x] Integrate with save/get/delete operations
  - [x] `save()` records item in memory manager
  - [x] `saveAll()` records all items
  - [x] `get()` records access for LRU tracking
  - [x] `delete()` removes from memory manager
  - [x] `deleteAll()` removes all from memory manager
- [x] Add eviction callback to remove from cache
- [x] Dispose MemoryManager on store dispose

### Metrics & Observability
- [x] Add `memoryMetrics` getter to store
- [x] Add `memoryMetricsStream` to store
- [x] Add `memoryPressure` getter to store
- [x] Add `memoryPressureStream` to store
- [x] Add `evictCache()` method for manual eviction
- [x] Add `evictUnpinnedCache()` method

### Exports
- [x] Export all memory classes from `nexus_store.dart`
  - [x] eviction_strategy.dart
  - [x] lru_tracker.dart
  - [x] memory_config.dart
  - [x] memory_manager.dart
  - [x] memory_metrics.dart
  - [x] memory_pressure_handler.dart
  - [x] memory_pressure_level.dart
  - [x] size_estimator.dart
- [x] Export FlutterMemoryPressureHandler from `nexus_store_flutter_widgets.dart`

### Unit Tests
- [x] `test/src/cache/memory_pressure_level_test.dart` (21 tests)
- [x] `test/src/cache/eviction_strategy_test.dart` (13 tests)
- [x] `test/src/cache/memory_config_test.dart` (22 tests)
- [x] `test/src/cache/memory_metrics_test.dart` (11 tests)
- [x] `test/src/cache/size_estimator_test.dart` (11 tests)
- [x] `test/src/cache/lru_tracker_test.dart` (18 tests)
- [x] `test/src/cache/memory_pressure_handler_test.dart` (14 tests)
- [x] `test/src/cache/memory_manager_test.dart` (20 tests)
- [x] `test/src/core/nexus_store_memory_management_test.dart` (32 tests)
- [x] `flutter/test/src/cache/flutter_memory_pressure_handler_test.dart` (8 tests)

**Total: 170 tests**

## Files

**Source Files (Created):**
```
packages/nexus_store/lib/src/cache/
├── eviction_strategy.dart          # EvictionStrategy enum
├── lru_tracker.dart                # LruTracker class
├── memory_config.dart              # MemoryConfig (freezed)
├── memory_config.freezed.dart      # Generated
├── memory_manager.dart             # MemoryManager class
├── memory_metrics.dart             # MemoryMetrics (freezed)
├── memory_metrics.freezed.dart     # Generated
├── memory_pressure_handler.dart    # Interface + implementations
├── memory_pressure_level.dart      # MemoryPressureLevel enum
└── size_estimator.dart             # SizeEstimator interface + implementations

packages/nexus_store_flutter_widgets/lib/src/cache/
└── flutter_memory_pressure_handler.dart
```

**Modified Files:**
```
packages/nexus_store/lib/src/config/store_config.dart  # Added memory field
packages/nexus_store/lib/src/core/nexus_store.dart     # Full integration
packages/nexus_store/lib/nexus_store.dart              # Exports
packages/nexus_store_flutter_widgets/lib/nexus_store_flutter_widgets.dart  # Export
packages/nexus_store_flutter_widgets/pubspec.yaml              # Added rxdart
```

**Test Files (Created):**
```
packages/nexus_store/test/src/cache/
├── eviction_strategy_test.dart
├── lru_tracker_test.dart
├── memory_config_test.dart
├── memory_manager_test.dart
├── memory_metrics_test.dart
├── memory_pressure_handler_test.dart
├── memory_pressure_level_test.dart
└── size_estimator_test.dart

packages/nexus_store/test/src/core/
└── nexus_store_memory_management_test.dart

packages/nexus_store_flutter_widgets/test/src/cache/
└── flutter_memory_pressure_handler_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22) - for metrics
- Flutter extension (Task 14) - for Flutter handler
- RxDart - for BehaviorSubject streams
- Freezed - for immutable config/metrics classes

## API Usage

```dart
// Configure memory management
final store = NexusStore<User, String>(
  backend: backend,
  sizeEstimator: JsonSizeEstimator(toJson: (u) => u.toJson()),
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
store.pin('current-user');
store.pin('settings');

// Unpin when no longer needed
store.unpin('current-user');

// Check pinned items
final pinned = store.pinnedIds; // {'settings'}
final isPinned = store.isPinned('settings'); // true

// Monitor memory
store.memoryPressureStream.listen((level) {
  if (level.shouldEvict) {
    print('Memory pressure: $level');
  }
  if (level.isEmergency) {
    print('Emergency! Cache being cleared');
  }
});

// Get current metrics
final metrics = store.memoryMetrics;
if (metrics != null) {
  print('Cache size: ${metrics.currentBytes / 1024 / 1024} MB');
  print('Items: ${metrics.itemCount}');
  print('Pinned: ${metrics.pinnedCount}');
  print('Evictions: ${metrics.evictionCount}');
  print('Pressure: ${metrics.pressureLevel}');
}

// Manual eviction
final evicted = store.evictCache(count: 10);
print('Evicted ${evicted.length} items');

// Clear all non-pinned
store.evictUnpinnedCache();

// Flutter integration
final handler = FlutterMemoryPressureHandler();
handler.pressureStream.listen((level) {
  // React to system memory pressure
});
```

## Notes

- Memory pressure APIs vary by platform; Flutter handler uses WidgetsBindingObserver
- Size estimation is approximate; actual memory usage may differ
- Pinned items count against cache limit but are never evicted
- LRU tracking has small overhead per access (O(1) with LinkedHashMap)
- Evicted items will be re-fetched when accessed
- MemoryManager is only initialized when memory config is provided
- All memory methods are no-ops when memory management is not configured
- Test on actual low-memory devices for production
