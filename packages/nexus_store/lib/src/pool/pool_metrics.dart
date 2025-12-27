import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_metrics.freezed.dart';

/// Metrics about the current state of a connection pool.
///
/// Provides observability into pool health, utilization, and performance.
///
/// ## Example
///
/// ```dart
/// final metrics = pool.currentMetrics;
/// print('Active: ${metrics.activeConnections}/${metrics.totalConnections}');
/// print('Waiting: ${metrics.waitingRequests}');
/// print('Utilization: ${(metrics.utilizationRate * 100).toStringAsFixed(1)}%');
/// ```
@freezed
abstract class PoolMetrics with _$PoolMetrics {
  /// Creates pool metrics.
  const factory PoolMetrics({
    /// Total connections in the pool (idle + active).
    required int totalConnections,

    /// Number of idle connections available for borrowing.
    required int idleConnections,

    /// Number of connections currently in use.
    required int activeConnections,

    /// Number of requests waiting for a connection.
    required int waitingRequests,

    /// Average time to acquire a connection.
    required Duration averageAcquireTime,

    /// Peak number of active connections since pool started.
    required int peakActiveConnections,

    /// Total connections created since pool started.
    required int totalConnectionsCreated,

    /// Total connections destroyed since pool started.
    required int totalConnectionsDestroyed,

    /// When these metrics were captured.
    required DateTime timestamp,
  }) = _PoolMetrics;

  const PoolMetrics._();

  /// Empty metrics with all zero values.
  ///
  /// Useful as an initial state before the pool is used.
  static PoolMetrics get empty => PoolMetrics(
        totalConnections: 0,
        idleConnections: 0,
        activeConnections: 0,
        waitingRequests: 0,
        averageAcquireTime: Duration.zero,
        peakActiveConnections: 0,
        totalConnectionsCreated: 0,
        totalConnectionsDestroyed: 0,
        timestamp: DateTime.now(),
      );

  /// The pool utilization rate (0.0 to 1.0).
  ///
  /// Calculated as activeConnections / totalConnections.
  /// Returns 0.0 if the pool has no connections.
  double get utilizationRate {
    if (totalConnections == 0) return 0.0;
    return activeConnections / totalConnections;
  }
}
