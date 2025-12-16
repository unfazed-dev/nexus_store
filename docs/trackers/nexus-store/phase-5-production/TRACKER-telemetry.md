# TRACKER: Telemetry & Metrics

## Status: PENDING

## Overview

Implement a pluggable telemetry and metrics system for observability into NexusStore operations, including timing, cache performance, and sync statistics.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-023, Task 22
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Core Interfaces
- [ ] Create `MetricsReporter` abstract class
  - [ ] `void reportOperation(OperationMetric metric)`
  - [ ] `void reportCacheEvent(CacheMetric metric)`
  - [ ] `void reportSyncEvent(SyncMetric metric)`
  - [ ] `void reportError(ErrorMetric metric)`
  - [ ] `Future<void> flush()` - Flush buffered metrics

- [ ] Create `NoOpMetricsReporter` implementation
  - [ ] Default implementation that does nothing
  - [ ] Zero overhead when metrics not needed

### Metric Models
- [ ] Create `OperationMetric` class
  - [ ] `operation: OperationType` (get, getAll, save, delete, etc.)
  - [ ] `duration: Duration` - How long operation took
  - [ ] `success: bool` - Whether operation succeeded
  - [ ] `itemCount: int` - Number of items involved
  - [ ] `policy: FetchPolicy/WritePolicy?` - Policy used
  - [ ] `timestamp: DateTime`

- [ ] Create `OperationType` enum
  - [ ] get, getAll, save, saveAll, delete, deleteAll
  - [ ] watch, watchAll, sync, transaction

- [ ] Create `CacheMetric` class
  - [ ] `event: CacheEvent` (hit, miss, eviction, invalidation)
  - [ ] `itemId: dynamic?` - ID if applicable
  - [ ] `tags: Set<String>?` - Tags if applicable
  - [ ] `timestamp: DateTime`

- [ ] Create `CacheEvent` enum
  - [ ] hit, miss, write, eviction, invalidation, expiration

- [ ] Create `SyncMetric` class
  - [ ] `event: SyncEvent` (started, completed, failed, retried)
  - [ ] `duration: Duration?` - Sync duration
  - [ ] `itemsSynced: int?` - Items processed
  - [ ] `error: Object?` - Error if failed
  - [ ] `timestamp: DateTime`

- [ ] Create `SyncEvent` enum
  - [ ] started, completed, failed, retried, conflictResolved

- [ ] Create `ErrorMetric` class
  - [ ] `error: Object` - The error
  - [ ] `stackTrace: StackTrace?`
  - [ ] `operation: OperationType` - What was being done
  - [ ] `recoverable: bool` - Whether it was handled
  - [ ] `timestamp: DateTime`

### Aggregated Stats
- [ ] Create `StoreStats` class
  - [ ] `operationCounts: Map<OperationType, int>`
  - [ ] `averageDurations: Map<OperationType, Duration>`
  - [ ] `cacheHitRate: double`
  - [ ] `syncSuccessRate: double`
  - [ ] `errorCount: int`

- [ ] Add `getStats()` method to NexusStore
  - [ ] Returns aggregated StoreStats
  - [ ] Can reset after reading

### Configuration
- [ ] Add `metricsReporter` to `StoreConfig`
  - [ ] Defaults to NoOpMetricsReporter
  - [ ] Easy to swap implementations

- [ ] Add `metricsConfig` options
  - [ ] `sampleRate: double` - Sample percentage (0.0-1.0)
  - [ ] `bufferSize: int` - Buffer before flush
  - [ ] `flushInterval: Duration` - Auto-flush interval

### Instrumentation
- [ ] Instrument CRUD operations
  - [ ] Wrap get/getAll/save/delete with timing
  - [ ] Report success/failure

- [ ] Instrument cache operations
  - [ ] Report hits/misses in policy handlers
  - [ ] Report evictions and invalidations

- [ ] Instrument sync operations
  - [ ] Report sync start/end/error
  - [ ] Report items synced count

### Common Reporters
- [ ] Create `ConsoleMetricsReporter`
  - [ ] Logs metrics to console
  - [ ] Useful for debugging

- [ ] Create `BufferedMetricsReporter`
  - [ ] Buffers metrics before sending
  - [ ] Configurable flush triggers

- [ ] Document custom reporter pattern
  - [ ] Firebase Performance example
  - [ ] DataDog example
  - [ ] Custom backend example

### Unit Tests
- [ ] `test/src/telemetry/metrics_reporter_test.dart`
  - [ ] Operations report correct metrics
  - [ ] Cache events tracked correctly
  - [ ] Sync events tracked correctly
  - [ ] Stats aggregation is accurate
  - [ ] NoOp reporter has no overhead

## Files

**Source Files:**
```
packages/nexus_store/lib/src/telemetry/
├── metrics_reporter.dart       # MetricsReporter interface
├── operation_metric.dart       # Operation metrics
├── cache_metric.dart           # Cache metrics
├── sync_metric.dart            # Sync metrics
├── error_metric.dart           # Error metrics
├── store_stats.dart            # Aggregated statistics
├── noop_metrics_reporter.dart  # Default no-op implementation
├── console_metrics_reporter.dart # Debug console reporter
└── buffered_metrics_reporter.dart # Buffered reporter base

packages/nexus_store/lib/src/config/
└── store_config.dart           # Add metricsReporter, metricsConfig
```

**Test Files:**
```
packages/nexus_store/test/src/telemetry/
├── metrics_reporter_test.dart
└── store_stats_test.dart
```

## Dependencies

- Core package (Task 1, complete)

## API Preview

```dart
// Console reporter for debugging
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    metricsReporter: ConsoleMetricsReporter(),
  ),
);
// Logs: [NexusStore] get(user-123) completed in 15ms (cache hit)

// Custom Firebase reporter
class FirebaseMetricsReporter extends MetricsReporter {
  @override
  void reportOperation(OperationMetric metric) {
    FirebasePerformance.instance.newTrace('nexus_${metric.operation.name}')
      ..putAttribute('success', metric.success.toString())
      ..setMetric('duration_ms', metric.duration.inMilliseconds)
      ..stop();
  }
  // ... other methods
}

final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    metricsReporter: FirebaseMetricsReporter(),
    metricsConfig: MetricsConfig(
      sampleRate: 0.1, // Sample 10% of operations
    ),
  ),
);

// Get aggregated stats
final stats = store.getStats();
print('Cache hit rate: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%');
print('Avg get duration: ${stats.averageDurations[OperationType.get]}');
print('Sync success rate: ${(stats.syncSuccessRate * 100).toStringAsFixed(1)}%');

// Buffered reporter with auto-flush
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    metricsReporter: BufferedMetricsReporter(
      delegate: MyBackendReporter(),
      bufferSize: 100,
      flushInterval: Duration(seconds: 30),
    ),
  ),
);
```

## Notes

- Metrics should have minimal performance overhead
- NoOp reporter should be truly zero-cost (no object creation)
- Consider async metric reporting to not block operations
- Sample rate allows balancing observability with performance
- Integration with common platforms (Firebase, DataDog) should be documented
- Stats should be resettable for time-windowed analysis
- Consider adding custom metric dimensions for filtering
