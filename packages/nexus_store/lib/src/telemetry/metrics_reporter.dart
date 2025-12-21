import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';

/// Abstract interface for reporting metrics.
///
/// Implementations can send metrics to various backends:
/// - Console for debugging
/// - Analytics services (Firebase, DataDog, etc.)
/// - Monitoring systems
/// - Custom storage
///
/// ## Example
///
/// ```dart
/// // Custom Firebase reporter
/// class FirebaseMetricsReporter implements MetricsReporter {
///   @override
///   void reportOperation(OperationMetric metric) {
///     FirebasePerformance.instance.newTrace('nexus_${metric.operation.name}')
///       ..putAttribute('success', metric.success.toString())
///       ..setMetric('duration_ms', metric.duration.inMilliseconds)
///       ..stop();
///   }
///
///   // ... other methods
/// }
/// ```
abstract interface class MetricsReporter {
  /// Reports an operation metric.
  ///
  /// Called after each store operation (get, save, delete, etc.).
  void reportOperation(OperationMetric metric);

  /// Reports a cache event metric.
  ///
  /// Called for cache hits, misses, evictions, and invalidations.
  void reportCacheEvent(CacheMetric metric);

  /// Reports a sync event metric.
  ///
  /// Called when sync operations start, complete, or fail.
  void reportSyncEvent(SyncMetric metric);

  /// Reports an error metric.
  ///
  /// Called when errors occur during store operations.
  void reportError(ErrorMetric metric);

  /// Flushes any buffered metrics.
  ///
  /// For buffered reporters, this ensures all pending metrics are sent.
  /// For non-buffered reporters, this is a no-op.
  Future<void> flush();

  /// Disposes resources used by the reporter.
  ///
  /// Should flush any buffered metrics before disposing.
  Future<void> dispose();
}

/// No-operation metrics reporter with zero overhead.
///
/// All methods are empty and the class is `final` to allow maximum
/// inlining by the Dart compiler. This is the default reporter when
/// metrics are disabled.
///
/// ## Example
///
/// ```dart
/// // Use NoOpMetricsReporter when metrics are disabled
/// final store = NexusStore<User, String>(
///   backend: backend,
///   config: StoreConfig(
///     metricsReporter: const NoOpMetricsReporter(),
///   ),
/// );
/// ```
final class NoOpMetricsReporter implements MetricsReporter {
  /// Creates a no-op metrics reporter.
  ///
  /// Use `const NoOpMetricsReporter()` for zero allocation overhead.
  const NoOpMetricsReporter();

  @override
  void reportOperation(OperationMetric metric) {
    // Intentionally empty - zero overhead
  }

  @override
  void reportCacheEvent(CacheMetric metric) {
    // Intentionally empty - zero overhead
  }

  @override
  void reportSyncEvent(SyncMetric metric) {
    // Intentionally empty - zero overhead
  }

  @override
  void reportError(ErrorMetric metric) {
    // Intentionally empty - zero overhead
  }

  @override
  Future<void> flush() async {
    // Intentionally empty - zero overhead
  }

  @override
  Future<void> dispose() async {
    // Intentionally empty - zero overhead
  }
}
