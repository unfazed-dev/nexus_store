import 'package:freezed_annotation/freezed_annotation.dart';

part 'circuit_breaker_config.freezed.dart';

/// Configuration for circuit breaker behavior.
///
/// Controls when the circuit breaker opens (blocks requests), how long it
/// stays open, and when it attempts recovery.
///
/// ## Example
///
/// ```dart
/// final config = CircuitBreakerConfig(
///   failureThreshold: 5,     // Open after 5 failures
///   successThreshold: 3,     // Close after 3 successes in half-open
///   openDuration: Duration(seconds: 30), // Stay open for 30 seconds
///   halfOpenMaxRequests: 3,  // Allow 3 test requests in half-open
/// );
/// ```
@freezed
abstract class CircuitBreakerConfig with _$CircuitBreakerConfig {
  /// Creates a circuit breaker configuration.
  const factory CircuitBreakerConfig({
    /// Number of consecutive failures before opening the circuit.
    ///
    /// When this many failures occur, the circuit breaker transitions from
    /// closed to open, blocking all subsequent requests. Defaults to 5.
    @Default(5) int failureThreshold,

    /// Number of consecutive successes needed to close the circuit.
    ///
    /// When in half-open state, this many successful requests must occur
    /// before transitioning back to closed. Defaults to 3.
    @Default(3) int successThreshold,

    /// Duration the circuit stays open before transitioning to half-open.
    ///
    /// After this cooldown period, the circuit breaker allows a limited
    /// number of test requests. Defaults to 30 seconds.
    @Default(Duration(seconds: 30)) Duration openDuration,

    /// Maximum concurrent requests allowed in half-open state.
    ///
    /// Limits the number of test requests during recovery to prevent
    /// overwhelming a recovering service. Defaults to 3.
    @Default(3) int halfOpenMaxRequests,

    /// Whether the circuit breaker is enabled.
    ///
    /// When false, all requests pass through without circuit breaker
    /// protection. Defaults to true.
    @Default(true) bool enabled,
  }) = _CircuitBreakerConfig;

  const CircuitBreakerConfig._();

  /// Default configuration with balanced thresholds.
  static const CircuitBreakerConfig defaults = CircuitBreakerConfig();

  /// Aggressive configuration for sensitive operations.
  ///
  /// Opens faster (3 failures) and stays open longer (60 seconds).
  /// Use for operations where failures are costly.
  static const CircuitBreakerConfig aggressive = CircuitBreakerConfig(
    failureThreshold: 3,
    openDuration: Duration(seconds: 60),
  );

  /// Lenient configuration for tolerant operations.
  ///
  /// Opens slower (10 failures) and recovers faster (15 seconds).
  /// Use for operations where occasional failures are acceptable.
  static const CircuitBreakerConfig lenient = CircuitBreakerConfig(
    failureThreshold: 10,
    openDuration: Duration(seconds: 15),
  );

  /// Disabled configuration that passes all requests through.
  static const CircuitBreakerConfig disabled = CircuitBreakerConfig(
    enabled: false,
  );

  /// Returns `true` if this configuration is valid.
  ///
  /// Configuration is valid when all thresholds are positive and
  /// the open duration is greater than zero.
  bool get isValid =>
      failureThreshold > 0 &&
      successThreshold > 0 &&
      halfOpenMaxRequests > 0 &&
      openDuration > Duration.zero;
}
