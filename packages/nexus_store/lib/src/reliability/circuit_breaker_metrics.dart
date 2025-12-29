import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';

part 'circuit_breaker_metrics.freezed.dart';

/// Metrics snapshot for a circuit breaker.
///
/// Provides insight into the circuit breaker's current state and
/// historical performance, useful for monitoring and alerting.
///
/// ## Example
///
/// ```dart
/// final metrics = circuitBreaker.currentMetrics;
/// print('State: ${metrics.state}');
/// print('Failure rate: ${(metrics.failureRate * 100).toStringAsFixed(1)}%');
/// if (metrics.failureRate > 0.5) {
///   alertOps('High failure rate detected');
/// }
/// ```
@freezed
abstract class CircuitBreakerMetrics with _$CircuitBreakerMetrics {
  /// Creates a circuit breaker metrics snapshot.
  const factory CircuitBreakerMetrics({
    /// Current state of the circuit breaker.
    required CircuitBreakerState state,

    /// Number of failures recorded in the current window.
    required int failureCount,

    /// Number of successes recorded in the current window.
    required int successCount,

    /// Total number of requests processed.
    required int totalRequests,

    /// Number of requests rejected due to open circuit.
    required int rejectedRequests,

    /// Timestamp when this snapshot was taken.
    required DateTime timestamp,

    /// Time of the last recorded failure, if any.
    DateTime? lastFailureTime,

    /// Time of the last state transition, if any.
    DateTime? lastStateChange,
  }) = _CircuitBreakerMetrics;

  const CircuitBreakerMetrics._();

  /// Creates an empty metrics snapshot with initial values.
  ///
  /// Used when the circuit breaker is first created.
  factory CircuitBreakerMetrics.empty() => CircuitBreakerMetrics(
        state: CircuitBreakerState.closed,
        failureCount: 0,
        successCount: 0,
        totalRequests: 0,
        rejectedRequests: 0,
        timestamp: DateTime.now(),
      );

  /// Failure rate as a ratio (0.0 to 1.0).
  ///
  /// Returns 0.0 if no requests have been processed.
  double get failureRate =>
      totalRequests > 0 ? failureCount / totalRequests : 0.0;

  /// Success rate as a ratio (0.0 to 1.0).
  ///
  /// Returns 0.0 if no requests have been processed.
  double get successRate =>
      totalRequests > 0 ? successCount / totalRequests : 0.0;
}
