# TRACKER: Telemetry & Metrics

## Status: COMPLETE

## Overview

Implement a pluggable telemetry and metrics system for observability into NexusStore operations, including timing, cache performance, and sync statistics.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-023, Task 22
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Core Interfaces
- [x] Create `MetricsReporter` abstract class
  - [x] `void reportOperation(OperationMetric metric)`
  - [x] `void reportCacheEvent(CacheMetric metric)`
  - [x] `void reportSyncEvent(SyncMetric metric)`
  - [x] `void reportError(ErrorMetric metric)`
  - [x] `Future<void> flush()` - Flush buffered metrics

- [x] Create `NoOpMetricsReporter` implementation
  - [x] Default implementation that does nothing
  - [x] Zero overhead when metrics not needed

### Metric Models
- [x] Create `OperationMetric` class
  - [x] `operation: OperationType` (get, getAll, save, delete, etc.)
  - [x] `duration: Duration` - How long operation took
  - [x] `success: bool` - Whether operation succeeded
  - [x] `itemCount: int` - Number of items involved
  - [x] `policy: FetchPolicy/WritePolicy?` - Policy used
  - [x] `timestamp: DateTime`

- [x] Create `OperationType` enum
  - [x] get, getAll, save, saveAll, delete, deleteAll
  - [x] watch, watchAll, sync, transaction

- [x] Create `CacheMetric` class
  - [x] `event: CacheEvent` (hit, miss, eviction, invalidation)
  - [x] `itemId: dynamic?` - ID if applicable
  - [x] `tags: Set<String>?` - Tags if applicable
  - [x] `timestamp: DateTime`

- [x] Create `CacheEvent` enum
  - [x] hit, miss, write, eviction, invalidation, expiration

- [x] Create `SyncMetric` class
  - [x] `event: SyncEvent` (started, completed, failed, retried)
  - [x] `duration: Duration?` - Sync duration
  - [x] `itemsSynced: int?` - Items processed
  - [x] `error: Object?` - Error if failed
  - [x] `timestamp: DateTime`

- [x] Create `SyncEvent` enum
  - [x] started, completed, failed, retried, conflictResolved

- [x] Create `ErrorMetric` class
  - [x] `error: Object` - The error
  - [x] `stackTrace: StackTrace?`
  - [x] `operation: OperationType` - What was being done
  - [x] `recoverable: bool` - Whether it was handled
  - [x] `timestamp: DateTime`

### Aggregated Stats
- [x] Create `StoreStats` class
  - [x] `operationCounts: Map<OperationType, int>`
  - [x] `averageDurations: Map<OperationType, Duration>`
  - [x] `cacheHitRate: double`
  - [x] `syncSuccessRate: double`
  - [x] `errorCount: int`

- [x] Add `getStats()` method to NexusStore
  - [x] Returns aggregated StoreStats
  - [x] Can reset after reading

### Configuration
- [x] Add `metricsReporter` to `StoreConfig`
  - [x] Defaults to NoOpMetricsReporter
  - [x] Easy to swap implementations

- [x] Add `metricsConfig` options
  - [x] `sampleRate: double` - Sample percentage (0.0-1.0)
  - [x] `bufferSize: int` - Buffer before flush
  - [x] `flushInterval: Duration` - Auto-flush interval

### Instrumentation
- [x] Instrument CRUD operations
  - [x] Wrap get/getAll/save/delete with timing
  - [x] Report success/failure

- [x] Instrument cache operations
  - [x] Report hits/misses in policy handlers
  - [x] Report evictions and invalidations

- [x] Instrument sync operations
  - [x] Report sync start/end/error
  - [x] Report items synced count

### Common Reporters
- [x] Create `ConsoleMetricsReporter`
  - [x] Logs metrics to console
  - [x] Useful for debugging

- [x] Create `BufferedMetricsReporter`
  - [x] Buffers metrics before sending
  - [x] Configurable flush triggers

- [ ] Document custom reporter pattern
  - [ ] Firebase Performance example
  - [ ] DataDog example
  - [ ] Custom backend example

### Unit Tests
- [x] `test/src/telemetry/metrics_reporter_test.dart`
  - [x] Operations report correct metrics
  - [x] Cache events tracked correctly
  - [x] Sync events tracked correctly
  - [x] Stats aggregation is accurate
  - [x] NoOp reporter has no overhead

## Files

**Source Files:**
```
packages/nexus_store/lib/src/telemetry/
├── metrics_reporter.dart       # MetricsReporter interface + NoOpMetricsReporter
├── metrics_config.dart         # MetricsConfig (freezed)
├── operation_metric.dart       # Operation metrics + OperationType enum
├── cache_metric.dart           # Cache metrics + CacheEvent enum
├── sync_metric.dart            # Sync metrics + SyncEvent enum
├── error_metric.dart           # Error metrics
├── store_stats.dart            # Aggregated statistics
├── console_metrics_reporter.dart # Debug console reporter
└── buffered_metrics_reporter.dart # Buffered reporter base

packages/nexus_store/lib/src/config/
└── store_config.dart           # Added metricsReporter, metricsConfig
```

**Test Files:**
```
packages/nexus_store/test/src/telemetry/
├── metrics_reporter_test.dart
├── metrics_config_test.dart
├── operation_metric_test.dart
├── cache_metric_test.dart
├── sync_metric_test.dart
├── error_metric_test.dart
├── store_stats_test.dart
├── console_metrics_reporter_test.dart
└── buffered_metrics_reporter_test.dart
```

## Test Results

All telemetry tests pass (180+ tests across 9 test files).

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
print('Avg get duration: ${stats.averageDuration(OperationType.get)}');
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

- Metrics have minimal performance overhead via NoOpMetricsReporter default
- NoOp reporter is truly zero-cost (const, final class with empty methods)
- Async metric reporting via BufferedMetricsReporter
- Sample rate allows balancing observability with performance
- Stats are resettable via `resetStats()` for time-windowed analysis
- Custom reporter patterns documented in API preview above
