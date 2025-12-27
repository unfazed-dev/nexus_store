import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_interceptor.dart';
import 'store_operation.dart';
import '../telemetry/metrics_reporter.dart';
import '../telemetry/operation_metric.dart';

/// An interceptor that reports operation timing to a metrics reporter.
///
/// Measures the duration of each operation and reports it via the configured
/// [MetricsReporter]. Useful for performance monitoring and alerting.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore(
///   backend: backend,
///   config: StoreConfig(
///     interceptors: [
///       TimingInterceptor(
///         reporter: myMetricsReporter,
///         operations: {StoreOperation.get, StoreOperation.save},
///       ),
///     ],
///   ),
/// );
/// ```
class TimingInterceptor extends StoreInterceptor {
  /// Creates a timing interceptor.
  ///
  /// - [reporter]: The metrics reporter to send timing data to.
  /// - [operations]: Operations to measure. Defaults to all operations.
  TimingInterceptor({
    required this.reporter,
    Set<StoreOperation>? operations,
  }) : _operations = operations;

  /// The metrics reporter to send timing data to.
  final MetricsReporter reporter;
  final Set<StoreOperation>? _operations;

  @override
  Set<StoreOperation> get operations =>
      _operations ?? StoreOperation.values.toSet();

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    final stopwatch = Stopwatch()..start();
    ctx.metadata['_timing_start'] = stopwatch;
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    final stopwatch = ctx.metadata['_timing_start'] as Stopwatch?;
    final duration = _stopAndGetDuration(stopwatch);

    reporter.reportOperation(OperationMetric(
      operation: _mapOperation(ctx.operation),
      duration: duration,
      success: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    final stopwatch = ctx.metadata['_timing_start'] as Stopwatch?;
    final duration = _stopAndGetDuration(stopwatch);

    reporter.reportOperation(OperationMetric(
      operation: _mapOperation(ctx.operation),
      duration: duration,
      success: false,
      errorMessage: error.toString(),
      timestamp: DateTime.now(),
    ));
  }

  Duration _stopAndGetDuration(Stopwatch? stopwatch) {
    if (stopwatch == null) return Duration.zero;
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  OperationType _mapOperation(StoreOperation operation) {
    return switch (operation) {
      StoreOperation.get => OperationType.get,
      StoreOperation.getAll => OperationType.getAll,
      StoreOperation.save => OperationType.save,
      StoreOperation.saveAll => OperationType.saveAll,
      StoreOperation.delete => OperationType.delete,
      StoreOperation.deleteAll => OperationType.deleteAll,
      StoreOperation.watch => OperationType.watch,
      StoreOperation.watchAll => OperationType.watchAll,
      StoreOperation.sync => OperationType.sync,
    };
  }
}
