import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_operation.dart';

/// Abstract base class for store interceptors.
///
/// Interceptors observe and optionally modify store operations at three points:
/// - [onRequest]: Before the operation executes
/// - [onResponse]: After successful operation completion
/// - [onError]: When an error occurs
///
/// ## Execution Order
///
/// For a chain of interceptors [A, B, C]:
/// - Request phase: A.onRequest → B.onRequest → C.onRequest → operation
/// - Response phase: C.onResponse → B.onResponse → A.onResponse
/// - Error phase: C.onError → B.onError → A.onError
///
/// ## Limiting Scope
///
/// Override [operations] to limit which operations this interceptor applies to:
///
/// ```dart
/// class WriteOnlyInterceptor extends StoreInterceptor {
///   @override
///   Set<StoreOperation> get operations => {
///     StoreOperation.save,
///     StoreOperation.saveAll,
///     StoreOperation.delete,
///     StoreOperation.deleteAll,
///   };
/// }
/// ```
///
/// ## Example
///
/// ```dart
/// class AuthInterceptor extends StoreInterceptor {
///   final AuthService _auth;
///
///   AuthInterceptor(this._auth);
///
///   @override
///   Set<StoreOperation> get operations => {
///     StoreOperation.save,
///     StoreOperation.delete,
///   };
///
///   @override
///   Future<InterceptorResult<R>> onRequest<T, R>(
///     InterceptorContext<T, R> ctx,
///   ) async {
///     final user = await _auth.currentUser;
///     if (user == null) {
///       return InterceptorResult.error(
///         UnauthorizedException('User not authenticated'),
///       );
///     }
///     ctx.metadata['userId'] = user.id;
///     return const InterceptorResult.continue_();
///   }
///
///   @override
///   Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
///     final userId = ctx.metadata['userId'];
///     await _auditLog.record('${ctx.operation} by $userId');
///   }
/// }
/// ```
abstract class StoreInterceptor {
  /// Creates a store interceptor.
  const StoreInterceptor();

  /// Operations this interceptor applies to.
  ///
  /// Defaults to all operations. Override to limit scope.
  ///
  /// The interceptor will only have its methods called for operations
  /// in this set. Operations not in this set will skip this interceptor.
  Set<StoreOperation> get operations => StoreOperation.values.toSet();

  /// Called before an operation executes.
  ///
  /// This is the primary hook for interceptors to:
  /// - Validate or authorize the request
  /// - Modify the request via [ctx.metadata]
  /// - Short-circuit the operation with a cached value
  /// - Block the operation with an error
  ///
  /// ## Return Values
  ///
  /// - [InterceptorResult.continue_]: Proceed to the next interceptor.
  ///   Optionally provide a response to skip the actual operation.
  /// - [InterceptorResult.shortCircuit]: Stop the chain and return
  ///   the given response immediately.
  /// - [InterceptorResult.error]: Propagate an error through the chain.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<InterceptorResult<R>> onRequest<T, R>(
  ///   InterceptorContext<T, R> ctx,
  /// ) async {
  ///   // Check cache
  ///   final cached = await cache.get(ctx.request);
  ///   if (cached != null) {
  ///     return InterceptorResult.shortCircuit(cached as R);
  ///   }
  ///
  ///   // Record timing
  ///   ctx.metadata['startTime'] = DateTime.now();
  ///
  ///   return const InterceptorResult.continue_();
  /// }
  /// ```
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return const InterceptorResult.continue_();
  }

  /// Called after successful operation completion.
  ///
  /// The [ctx.response] contains the final response value.
  /// This hook is called in reverse order (last added, first called).
  ///
  /// Use this for:
  /// - Logging successful operations
  /// - Caching responses
  /// - Collecting metrics
  /// - Post-processing (though modifying response is not recommended)
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
  ///   final startTime = ctx.metadata['startTime'] as DateTime?;
  ///   if (startTime != null) {
  ///     final duration = DateTime.now().difference(startTime);
  ///     logger.info('${ctx.operation} completed in ${duration.inMs}ms');
  ///   }
  /// }
  /// ```
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {}

  /// Called when an error occurs during the operation.
  ///
  /// This hook is called in reverse order (last added, first called).
  /// The original error will be rethrown after all error handlers complete.
  ///
  /// Use this for:
  /// - Error logging
  /// - Error metrics/reporting
  /// - Cleanup operations
  ///
  /// Note: This method cannot prevent the error from propagating.
  /// To handle errors differently, use [onRequest] to wrap the operation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<void> onError<T, R>(
  ///   InterceptorContext<T, R> ctx,
  ///   Object error,
  ///   StackTrace stackTrace,
  /// ) async {
  ///   errorReporter.report(
  ///     error,
  ///     stackTrace: stackTrace,
  ///     context: {
  ///       'operation': ctx.operation.name,
  ///       'request': ctx.request,
  ///     },
  ///   );
  /// }
  /// ```
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {}
}
