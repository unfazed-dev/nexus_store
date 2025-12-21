import 'dart:async';

import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';

/// Buffered metrics reporter that batches metrics before forwarding.
///
/// Useful for reducing overhead by batching metrics before sending
/// to external services.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore<User, String>(
///   backend: backend,
///   config: StoreConfig(
///     metricsReporter: BufferedMetricsReporter(
///       delegate: MyAnalyticsReporter(),
///       bufferSize: 100,
///       flushInterval: Duration(seconds: 30),
///     ),
///   ),
/// );
/// ```
class BufferedMetricsReporter implements MetricsReporter {
  /// Creates a buffered metrics reporter.
  ///
  /// [delegate] is the underlying reporter to forward metrics to.
  /// [bufferSize] is the maximum buffer size before auto-flush (default: 100).
  /// [flushInterval] is the interval for periodic flush (default: 30 seconds).
  /// [onFlush] is an optional callback when flush occurs.
  BufferedMetricsReporter({
    required this.delegate,
    this.bufferSize = 100,
    this.flushInterval = const Duration(seconds: 30),
    this.onFlush,
  }) {
    _startFlushTimer();
  }

  /// The underlying reporter to forward metrics to.
  final MetricsReporter delegate;

  /// Maximum buffer size before auto-flush.
  final int bufferSize;

  /// Interval for periodic flush.
  final Duration flushInterval;

  /// Optional callback when flush occurs.
  final Future<void> Function(List<Object> metrics)? onFlush;

  final List<Object> _buffer = [];
  Timer? _flushTimer;
  bool _disposed = false;

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(flushInterval, (_) => flush());
  }

  void _addToBuffer(Object metric) {
    if (_disposed) return;

    _buffer.add(metric);

    if (_buffer.length >= bufferSize) {
      unawaited(flush());
    }
  }

  @override
  void reportOperation(OperationMetric metric) {
    _addToBuffer(metric);
  }

  @override
  void reportCacheEvent(CacheMetric metric) {
    _addToBuffer(metric);
  }

  @override
  void reportSyncEvent(SyncMetric metric) {
    _addToBuffer(metric);
  }

  @override
  void reportError(ErrorMetric metric) {
    _addToBuffer(metric);
  }

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    final metrics = List<Object>.from(_buffer);
    _buffer.clear();

    // Notify callback if provided
    await onFlush?.call(metrics);

    // Forward to delegate
    for (final metric in metrics) {
      switch (metric) {
        case final OperationMetric m:
          delegate.reportOperation(m);
        case final CacheMetric m:
          delegate.reportCacheEvent(m);
        case final SyncMetric m:
          delegate.reportSyncEvent(m);
        case final ErrorMetric m:
          delegate.reportError(m);
      }
    }

    await delegate.flush();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _flushTimer?.cancel();
    await flush();
    await delegate.dispose();
  }

  /// Current buffer size.
  int get currentBufferSize => _buffer.length;
}
