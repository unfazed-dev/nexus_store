import 'package:freezed_annotation/freezed_annotation.dart';

import 'degradation_mode.dart';

part 'degradation_config.freezed.dart';

/// Configuration for graceful degradation behavior.
///
/// Controls how the system responds when components become unavailable,
/// including automatic degradation and recovery settings.
///
/// ## Example
///
/// ```dart
/// final config = DegradationConfig(
///   autoDegradation: true,
///   fallbackMode: DegradationMode.cacheOnly,
///   cooldown: Duration(seconds: 60),
/// );
/// ```
@freezed
abstract class DegradationConfig with _$DegradationConfig {
  /// Creates a degradation configuration.
  const factory DegradationConfig({
    /// Whether degradation handling is enabled.
    ///
    /// When false, no automatic degradation occurs. Defaults to true.
    @Default(true) bool enabled,

    /// Whether automatic degradation is enabled.
    ///
    /// When true, the system automatically degrades based on
    /// component health and circuit breaker state. Defaults to true.
    @Default(true) bool autoDegradation,

    /// Default operational mode.
    ///
    /// The mode to use when the system is functioning normally.
    /// Defaults to [DegradationMode.normal].
    @Default(DegradationMode.normal) DegradationMode defaultMode,

    /// Fallback mode when degradation occurs.
    ///
    /// The mode to switch to when automatic degradation triggers.
    /// Defaults to [DegradationMode.cacheOnly].
    @Default(DegradationMode.cacheOnly) DegradationMode fallbackMode,

    /// Cooldown period before attempting recovery.
    ///
    /// After degrading, the system waits this long before attempting
    /// to return to normal operation. Defaults to 60 seconds.
    @Default(Duration(seconds: 60)) Duration cooldown,
  }) = _DegradationConfig;

  const DegradationConfig._();

  /// Default configuration with balanced settings.
  static const DegradationConfig defaults = DegradationConfig();

  /// Aggressive configuration for sensitive systems.
  ///
  /// Uses shorter cooldown and more restrictive fallback mode.
  static const DegradationConfig aggressive = DegradationConfig(
    fallbackMode: DegradationMode.readOnly,
    cooldown: Duration(seconds: 30),
  );

  /// Conservative configuration for resilient systems.
  ///
  /// Uses longer cooldown and less restrictive fallback mode.
  static const DegradationConfig conservative = DegradationConfig(
    fallbackMode: DegradationMode.cacheOnly,
    cooldown: Duration(minutes: 5),
  );

  /// Disabled configuration that skips degradation handling.
  static const DegradationConfig disabled = DegradationConfig(
    enabled: false,
    autoDegradation: false,
  );
}

/// Metrics snapshot of the degradation state.
///
/// Provides point-in-time information about the current degradation
/// mode and related statistics.
///
/// ## Example
///
/// ```dart
/// final metrics = degradationManager.metrics;
/// print('Mode: ${metrics.mode}');
/// print('Degradation count: ${metrics.degradationCount}');
/// ```
@freezed
abstract class DegradationMetrics with _$DegradationMetrics {
  /// Creates a degradation metrics snapshot.
  const factory DegradationMetrics({
    /// Current degradation mode.
    required DegradationMode mode,

    /// Timestamp when this snapshot was taken.
    required DateTime timestamp,

    /// Number of times the system has degraded.
    @Default(0) int degradationCount,

    /// Number of times the system has recovered.
    @Default(0) int recoveryCount,

    /// Timestamp of the last mode change.
    DateTime? lastModeChange,
  }) = _DegradationMetrics;

  const DegradationMetrics._();

  /// Creates initial metrics with normal mode.
  factory DegradationMetrics.initial() => DegradationMetrics(
        mode: DegradationMode.normal,
        timestamp: DateTime.now(),
      );

  /// Returns `true` if currently in a degraded mode.
  bool get isDegraded => mode.isDegraded;

  /// Returns the time since the last mode change.
  ///
  /// Returns `null` if no mode change has occurred.
  Duration? get timeSinceLastChange {
    if (lastModeChange == null) return null;
    return DateTime.now().difference(lastModeChange!);
  }
}
