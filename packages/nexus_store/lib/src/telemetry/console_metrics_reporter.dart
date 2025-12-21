import 'package:logging/logging.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';

/// Metrics reporter that logs to console for debugging.
///
/// Useful during development to see metrics in real-time.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore<User, String>(
///   backend: backend,
///   config: StoreConfig(
///     metricsReporter: ConsoleMetricsReporter(),
///   ),
/// );
/// // Logs: [Metrics] Operation: get took 15ms (success, items: 1)
/// ```
class ConsoleMetricsReporter implements MetricsReporter {
  /// Creates a console metrics reporter.
  ///
  /// [prefix] is prepended to all log messages. Defaults to `[Metrics]`.
  /// [logger] is the logger instance to use. Defaults to a logger named
  /// `ConsoleMetricsReporter`.
  ConsoleMetricsReporter({
    this.prefix = '[Metrics]',
    Logger? logger,
  }) : _logger = logger ?? Logger('ConsoleMetricsReporter');

  /// Prefix for log messages.
  final String prefix;
  final Logger _logger;

  @override
  void reportOperation(OperationMetric metric) {
    _logger.info(
      '$prefix Operation: ${metric.operation.name} '
      'took ${metric.duration.inMilliseconds}ms '
      '(${metric.success ? "success" : "failed"}, '
      'items: ${metric.itemCount})',
    );
  }

  @override
  void reportCacheEvent(CacheMetric metric) {
    final parts = <String>[
      '$prefix Cache: ${metric.event.name}',
      if (metric.itemId != null) 'id=${metric.itemId}',
      if (metric.tags.isNotEmpty) 'tags=${metric.tags}',
    ];
    _logger.fine(parts.join(' '));
  }

  @override
  void reportSyncEvent(SyncMetric metric) {
    final parts = <String>[
      '$prefix Sync: ${metric.event.name}',
      if (metric.duration != null)
        'took ${metric.duration!.inMilliseconds}ms',
      if (metric.itemsSynced > 0) 'items=${metric.itemsSynced}',
      if (metric.error != null) 'error=${metric.error}',
    ];
    _logger.info(parts.join(' '));
  }

  @override
  void reportError(ErrorMetric metric) {
    _logger.warning(
      '$prefix Error: ${metric.error} '
      'in ${metric.operation ?? "unknown"} '
      '(${metric.recoverable ? "recoverable" : "fatal"})',
    );
  }

  @override
  Future<void> flush() async {
    // Console reporter doesn't buffer
  }

  @override
  Future<void> dispose() async {
    // No resources to dispose
  }
}
