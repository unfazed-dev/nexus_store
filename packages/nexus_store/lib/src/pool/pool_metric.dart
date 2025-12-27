import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_metric.freezed.dart';

/// Types of pool events that can be tracked.
enum PoolEvent {
  /// Connection was acquired from the pool.
  acquired,

  /// Connection was released back to the pool.
  released,

  /// Connection acquisition timed out.
  timeout,

  /// Pool is exhausted (all connections in use).
  exhausted,

  /// Health check failed for a connection.
  healthCheckFailed,

  /// Connection was created.
  connectionCreated,

  /// Connection was destroyed.
  connectionDestroyed,
}

/// Metric for tracking connection pool operations.
///
/// Records pool events for monitoring pool health and performance.
///
/// ## Example
///
/// ```dart
/// final metric = PoolMetric(
///   event: PoolEvent.acquired,
///   poolName: 'database',
///   duration: Duration(milliseconds: 5),
///   timestamp: DateTime.now(),
/// );
/// ```
@freezed
abstract class PoolMetric with _$PoolMetric {
  /// Creates a pool metric.
  const factory PoolMetric({
    /// The type of pool event.
    required PoolEvent event,

    /// Optional name to identify the pool.
    String? poolName,

    /// Duration of the operation (for acquired events).
    Duration? duration,

    /// Number of active connections at the time of the event.
    int? activeConnections,

    /// Number of idle connections at the time of the event.
    int? idleConnections,

    /// Number of waiting requests at the time of the event.
    int? waitingRequests,

    /// When the event occurred.
    required DateTime timestamp,
  }) = _PoolMetric;

  const PoolMetric._();
}
