import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_check_config.freezed.dart';

/// Configuration for health check behavior.
///
/// Controls how often health checks are performed, timeouts, and
/// thresholds for determining system health status.
///
/// ## Example
///
/// ```dart
/// final config = HealthCheckConfig(
///   checkInterval: Duration(seconds: 30),
///   timeout: Duration(seconds: 10),
///   failureThreshold: 3,
/// );
/// ```
@freezed
abstract class HealthCheckConfig with _$HealthCheckConfig {
  /// Creates a health check configuration.
  const factory HealthCheckConfig({
    /// Interval between health checks.
    ///
    /// How often the health check service should check component health.
    /// Defaults to 30 seconds.
    @Default(Duration(seconds: 30)) Duration checkInterval,

    /// Timeout for individual health checks.
    ///
    /// Maximum time to wait for a health check to complete before
    /// considering it failed. Defaults to 10 seconds.
    @Default(Duration(seconds: 10)) Duration timeout,

    /// Number of consecutive failures before marking unhealthy.
    ///
    /// A component must fail this many consecutive checks before
    /// transitioning to unhealthy status. Defaults to 3.
    @Default(3) int failureThreshold,

    /// Number of consecutive successes before marking healthy.
    ///
    /// A component must pass this many consecutive checks after
    /// being unhealthy before transitioning back to healthy. Defaults to 2.
    @Default(2) int recoveryThreshold,

    /// Whether health checks are enabled.
    ///
    /// When false, no health checks are performed. Defaults to true.
    @Default(true) bool enabled,

    /// Whether to start health checks automatically.
    ///
    /// When true, health checks begin when the service is initialized.
    /// Defaults to true.
    @Default(true) bool autoStart,
  }) = _HealthCheckConfig;

  const HealthCheckConfig._();

  /// Default configuration with balanced settings.
  static const HealthCheckConfig defaults = HealthCheckConfig();

  /// Frequent check configuration for critical systems.
  ///
  /// Checks every 10 seconds with a 5 second timeout.
  /// Use for systems where early failure detection is critical.
  static const HealthCheckConfig frequent = HealthCheckConfig(
    checkInterval: Duration(seconds: 10),
    timeout: Duration(seconds: 5),
  );

  /// Infrequent check configuration for stable systems.
  ///
  /// Checks every 5 minutes with a 30 second timeout.
  /// Use for stable systems where frequent checks are unnecessary.
  static const HealthCheckConfig infrequent = HealthCheckConfig(
    checkInterval: Duration(minutes: 5),
    timeout: Duration(seconds: 30),
  );

  /// Disabled configuration that skips all health checks.
  static const HealthCheckConfig disabled = HealthCheckConfig(
    enabled: false,
  );

  /// Returns `true` if this configuration is valid.
  ///
  /// Configuration is valid when:
  /// - Check interval is greater than zero
  /// - Timeout is greater than zero
  /// - Timeout does not exceed check interval
  /// - Thresholds are positive
  bool get isValid =>
      checkInterval > Duration.zero &&
      timeout > Duration.zero &&
      timeout <= checkInterval &&
      failureThreshold > 0 &&
      recoveryThreshold > 0;
}
