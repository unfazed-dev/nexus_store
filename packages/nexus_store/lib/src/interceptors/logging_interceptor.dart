import 'package:logging/logging.dart';

import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_interceptor.dart';
import 'store_operation.dart';

/// An interceptor that logs store operations.
///
/// Logs operation start, completion, and errors with configurable log levels
/// and optional timing information.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore(
///   backend: backend,
///   config: StoreConfig(
///     interceptors: [
///       LoggingInterceptor(
///         logger: Logger('MyStore'),
///         level: Level.INFO,
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ## Log Output
///
/// ```
/// [INFO] MyStore: get started - request: user-123
/// [INFO] MyStore: get completed in 15ms
/// [SEVERE] MyStore: save failed - Exception: Network error
/// ```
class LoggingInterceptor extends StoreInterceptor {
  /// Creates a logging interceptor.
  ///
  /// - [logger]: The logger to use. Defaults to a logger named 'NexusStore'.
  /// - [level]: Log level for normal operations. Defaults to [Level.INFO].
  /// - [operations]: Operations to log. Defaults to all operations.
  /// - [logRequests]: Whether to log request start. Defaults to true.
  /// - [logResponses]: Whether to log successful responses. Defaults to true.
  /// - [logErrors]: Whether to log errors. Defaults to true.
  LoggingInterceptor({
    Logger? logger,
    this.level = Level.INFO,
    Set<StoreOperation>? operations,
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
  })  : _logger = logger ?? Logger('NexusStore'),
        _operations = operations;

  final Logger _logger;
  final Set<StoreOperation>? _operations;

  /// Log level for normal operations (request/response).
  final Level level;

  /// Whether to log request start.
  final bool logRequests;

  /// Whether to log successful responses.
  final bool logResponses;

  /// Whether to log errors.
  final bool logErrors;

  @override
  Set<StoreOperation> get operations =>
      _operations ?? StoreOperation.values.toSet();

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    // Store start time for duration calculation
    ctx.metadata['_logging_start_time'] = DateTime.now();

    if (logRequests) {
      final request = ctx.request;
      final requestStr = request != null ? ' - request: $request' : '';
      _logger.log(level, '${ctx.operation.name} started$requestStr');
    }

    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    if (!logResponses) return;

    final startTime = ctx.metadata['_logging_start_time'] as DateTime?;
    final durationStr = _formatDuration(startTime);

    _logger.log(level, '${ctx.operation.name} completed$durationStr');
  }

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!logErrors) return;

    final startTime = ctx.metadata['_logging_start_time'] as DateTime?;
    final durationStr = _formatDuration(startTime);

    _logger.log(
      Level.SEVERE,
      '${ctx.operation.name} failed$durationStr - $error',
      error,
      stackTrace,
    );
  }

  String _formatDuration(DateTime? startTime) {
    if (startTime == null) return '';
    final duration = DateTime.now().difference(startTime);
    return ' in ${duration.inMilliseconds}ms';
  }
}
