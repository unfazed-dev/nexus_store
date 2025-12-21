import 'package:freezed_annotation/freezed_annotation.dart';

part 'metrics_config.freezed.dart';

/// Configuration for metrics collection.
///
/// Controls how metrics are sampled, buffered, and reported.
///
/// ## Example
///
/// ```dart
/// // Full sampling for development
/// const config = MetricsConfig.defaults;
///
/// // Minimal overhead for production
/// const config = MetricsConfig.minimal;
///
/// // Custom configuration
/// const config = MetricsConfig(
///   sampleRate: 0.1,  // Sample 10% of operations
///   bufferSize: 200,
///   flushInterval: Duration(minutes: 1),
/// );
/// ```
@freezed
abstract class MetricsConfig with _$MetricsConfig {
  /// Creates a metrics configuration.
  const factory MetricsConfig({
    /// Sample rate for metrics (0.0 to 1.0).
    ///
    /// - 1.0 = sample all operations (100%)
    /// - 0.5 = sample half of operations (50%)
    /// - 0.0 = sample none (disabled)
    @Default(1.0) double sampleRate,

    /// Buffer size for buffered reporters.
    ///
    /// When the buffer reaches this size, it will auto-flush.
    @Default(100) int bufferSize,

    /// Flush interval for buffered reporters.
    ///
    /// Metrics will be flushed at least this often.
    @Default(Duration(seconds: 30)) Duration flushInterval,

    /// Whether to include stack traces in error metrics.
    ///
    /// Set to false in production to reduce overhead and payload size.
    @Default(true) bool includeStackTraces,

    /// Whether to track timing for operations.
    ///
    /// When false, duration will be Duration.zero.
    @Default(true) bool trackTiming,
  }) = _MetricsConfig;

  const MetricsConfig._();

  /// Default configuration with all metrics enabled.
  ///
  /// Suitable for development and debugging.
  static const MetricsConfig defaults = MetricsConfig();

  /// Minimal overhead configuration.
  ///
  /// Samples 10% of operations, no stack traces.
  /// Suitable for production with low overhead.
  static const MetricsConfig minimal = MetricsConfig(
    sampleRate: 0.1,
    includeStackTraces: false,
  );

  /// Disabled configuration.
  ///
  /// No sampling, no timing tracking.
  /// Use when you want metrics completely disabled.
  static const MetricsConfig disabled = MetricsConfig(
    sampleRate: 0.0,
    trackTiming: false,
  );

  /// Whether metrics collection is enabled.
  ///
  /// Returns true if sampleRate > 0.
  bool get isEnabled => sampleRate > 0;

  /// Whether all operations are being sampled.
  ///
  /// Returns true if sampleRate >= 1.0.
  bool get isFullSampling => sampleRate >= 1.0;
}
