import 'package:nexus_store/src/cache/cache_stats.dart';
import 'package:nexus_store/src/cache/memory_metrics.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/reliability/health_status.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/store_stats.dart';

/// A slow operation record that exceeded the configured threshold.
class SlowOperation {
  /// Creates a slow operation record.
  const SlowOperation({
    required this.operation,
    required this.duration,
    required this.threshold,
    required this.timestamp,
  });

  /// The type of operation that was slow.
  final OperationType operation;

  /// How long the operation took.
  final Duration duration;

  /// The threshold it exceeded.
  final Duration threshold;

  /// When the operation occurred.
  final DateTime timestamp;

  /// How much slower than the threshold (e.g., 2.0 means 2x the threshold).
  double get ratio => duration.inMicroseconds / threshold.inMicroseconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlowOperation &&
          operation == other.operation &&
          duration == other.duration &&
          threshold == other.threshold &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(operation, duration, threshold, timestamp);

  @override
  String toString() => 'SlowOperation('
      '${operation.name}: ${duration.inMilliseconds}ms, '
      'threshold: ${threshold.inMilliseconds}ms, '
      'ratio: ${ratio.toStringAsFixed(1)}x)';
}

/// Comprehensive health snapshot of a NexusStore instance.
///
/// Combines operation stats, cache stats, memory metrics, and slow operation
/// tracking into a single diagnostic view.
///
/// ## Example
///
/// ```dart
/// final diagnostics = store.getDiagnostics();
/// print('Health: ${diagnostics.healthStatus}');
/// print('Cache hit rate: ${diagnostics.cacheHitPercentage}%');
/// print('Slow operations: ${diagnostics.slowOperations.length}');
/// print('Pending changes: ${diagnostics.pendingChangesCount}');
/// ```
class StoreDiagnostics {
  /// Creates a store diagnostics snapshot.
  const StoreDiagnostics({
    required this.storeStats,
    required this.cacheStats,
    required this.slowOperations,
    required this.pendingChangesCount,
    required this.isInitialized,
    required this.entityCount,
    required this.slowOperationThreshold,
    required this.timestamp,
    this.memoryMetrics,
    this.memoryPressure,
  });

  /// Aggregated operation statistics.
  final StoreStats storeStats;

  /// Cache state statistics.
  final CacheStats cacheStats;

  /// List of operations that exceeded the slow threshold.
  final List<SlowOperation> slowOperations;

  /// Number of pending changes awaiting sync.
  final int pendingChangesCount;

  /// Whether the store is initialized.
  final bool isInitialized;

  /// Total number of entities in the backend.
  final int entityCount;

  /// The threshold used to detect slow operations.
  final Duration slowOperationThreshold;

  /// When this snapshot was taken.
  final DateTime timestamp;

  /// Memory metrics (null if memory management is not configured).
  final MemoryMetrics? memoryMetrics;

  /// Current memory pressure level (null if not configured).
  final MemoryPressureLevel? memoryPressure;

  /// Cache hit rate as a percentage (0-100).
  double get cacheHitPercentage => storeStats.cacheHitPercentage;

  /// Average latency across all operation types.
  Duration get averageLatency {
    final durations = storeStats.totalDurations;
    final counts = storeStats.operationCounts;
    if (durations.isEmpty || counts.isEmpty) return Duration.zero;

    var totalMicros = 0;
    var totalOps = 0;
    for (final type in durations.keys) {
      totalMicros += durations[type]!.inMicroseconds;
      totalOps += counts[type] ?? 0;
    }
    if (totalOps == 0) return Duration.zero;
    return Duration(microseconds: totalMicros ~/ totalOps);
  }

  /// Whether there are any slow operations.
  bool get hasSlowOperations => slowOperations.isNotEmpty;

  /// Overall health status based on diagnostics.
  ///
  /// - `healthy`: No issues detected
  /// - `degraded`: Slow operations or high stale cache percentage
  /// - `unhealthy`: High error rate or extreme memory pressure
  HealthStatus get healthStatus {
    // Unhealthy: high error rate (>10% of operations)
    if (storeStats.totalOperations > 0 &&
        storeStats.errorCount / storeStats.totalOperations > 0.1) {
      return HealthStatus.unhealthy;
    }

    // Unhealthy: critical memory pressure
    if (memoryPressure == MemoryPressureLevel.critical) {
      return HealthStatus.unhealthy;
    }

    // Degraded: has slow operations
    if (hasSlowOperations) {
      return HealthStatus.degraded;
    }

    // Degraded: high stale percentage (>50%)
    if (cacheStats.stalePercentage > 50) {
      return HealthStatus.degraded;
    }

    // Degraded: moderate memory pressure
    if (memoryPressure == MemoryPressureLevel.moderate) {
      return HealthStatus.degraded;
    }

    return HealthStatus.healthy;
  }

  @override
  String toString() => 'StoreDiagnostics('
      'health: ${healthStatus.name}, '
      'entities: $entityCount, '
      'cacheHitRate: ${cacheHitPercentage.toStringAsFixed(1)}%, '
      'slowOps: ${slowOperations.length}, '
      'pending: $pendingChangesCount, '
      'errors: ${storeStats.errorCount})';
}
