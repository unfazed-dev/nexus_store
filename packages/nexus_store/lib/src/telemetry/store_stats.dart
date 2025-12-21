import 'package:collection/collection.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';

/// Aggregated statistics about store operations.
///
/// Provides computed metrics for monitoring store health and performance.
///
/// ## Example
///
/// ```dart
/// final stats = store.getStats();
/// print('Cache hit rate: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%');
/// print('Avg get duration: ${stats.averageDurations[OperationType.get]}');
/// print('Total operations: ${stats.totalOperations}');
/// ```
class StoreStats {
  /// Creates store statistics.
  const StoreStats({
    required this.operationCounts,
    required this.totalDurations,
    required this.cacheHits,
    required this.cacheMisses,
    required this.syncSuccessCount,
    required this.syncFailureCount,
    required this.errorCount,
    this.lastUpdated,
  });

  /// Creates empty store statistics.
  factory StoreStats.empty() => const StoreStats(
        operationCounts: {},
        totalDurations: {},
        cacheHits: 0,
        cacheMisses: 0,
        syncSuccessCount: 0,
        syncFailureCount: 0,
        errorCount: 0,
      );

  /// Count of operations by type.
  final Map<OperationType, int> operationCounts;

  /// Total duration of operations by type (for average calculation).
  final Map<OperationType, Duration> totalDurations;

  /// Number of cache hits.
  final int cacheHits;

  /// Number of cache misses.
  final int cacheMisses;

  /// Number of successful syncs.
  final int syncSuccessCount;

  /// Number of failed syncs.
  final int syncFailureCount;

  /// Total error count.
  final int errorCount;

  /// When stats were last updated.
  final DateTime? lastUpdated;

  /// Average duration for an operation type.
  ///
  /// Returns null if no operations of that type have been recorded.
  Duration? averageDuration(OperationType type) {
    final count = operationCounts[type] ?? 0;
    final total = totalDurations[type];
    if (count == 0 || total == null) return null;
    return Duration(microseconds: total.inMicroseconds ~/ count);
  }

  /// Map of average durations by operation type.
  ///
  /// Only includes operation types that have been recorded.
  Map<OperationType, Duration> get averageDurations {
    final result = <OperationType, Duration>{};
    for (final type in OperationType.values) {
      final avg = averageDuration(type);
      if (avg != null) result[type] = avg;
    }
    return result;
  }

  /// Cache hit rate (0.0 to 1.0).
  ///
  /// Returns 0.0 if no cache operations have been recorded.
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    if (total == 0) return 0.0;
    return cacheHits / total;
  }

  /// Cache hit rate as percentage (0 to 100).
  double get cacheHitPercentage => cacheHitRate * 100;

  /// Sync success rate (0.0 to 1.0).
  ///
  /// Returns 1.0 if no syncs have been attempted (no failures).
  double get syncSuccessRate {
    final total = syncSuccessCount + syncFailureCount;
    if (total == 0) return 1.0; // No syncs = 100% success
    return syncSuccessCount / total;
  }

  /// Total operation count across all types.
  int get totalOperations =>
      operationCounts.values.fold(0, (sum, count) => sum + count);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StoreStats) return false;
    return cacheHits == other.cacheHits &&
        cacheMisses == other.cacheMisses &&
        syncSuccessCount == other.syncSuccessCount &&
        syncFailureCount == other.syncFailureCount &&
        errorCount == other.errorCount &&
        const MapEquality<OperationType, int>()
            .equals(operationCounts, other.operationCounts);
  }

  @override
  int get hashCode => Object.hash(
        cacheHits,
        cacheMisses,
        syncSuccessCount,
        syncFailureCount,
        errorCount,
        const MapEquality<OperationType, int>().hash(operationCounts),
      );

  @override
  String toString() => 'StoreStats('
      'operations: $totalOperations, '
      'cacheHitRate: ${cacheHitPercentage.toStringAsFixed(1)}%, '
      'syncSuccessRate: ${(syncSuccessRate * 100).toStringAsFixed(1)}%, '
      'errors: $errorCount)';
}
