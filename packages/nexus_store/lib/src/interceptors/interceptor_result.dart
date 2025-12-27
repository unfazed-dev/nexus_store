/// Result of interceptor execution determining chain behavior.
///
/// Interceptors return this from [StoreInterceptor.onRequest] to control
/// how the interceptor chain should proceed.
///
/// ## Variants
///
/// - [Continue]: Proceed to the next interceptor, optionally with a modified response
/// - [ShortCircuit]: Stop the chain and return immediately with the given response
/// - [InterceptorError]: Propagate an error through the chain
///
/// ## Example
///
/// ```dart
/// Future<InterceptorResult<R>> onRequest<T, R>(
///   InterceptorContext<T, R> ctx,
/// ) async {
///   // Check authorization
///   if (!await isAuthorized()) {
///     return InterceptorResult.error(UnauthorizedException());
///   }
///
///   // Return cached value if available
///   final cached = cache.get(ctx.request);
///   if (cached != null) {
///     return InterceptorResult.shortCircuit(cached as R);
///   }
///
///   // Continue normally
///   return const InterceptorResult.continue_();
/// }
/// ```
sealed class InterceptorResult<R> {
  const InterceptorResult._();

  /// Continue to the next interceptor.
  ///
  /// Optionally provide a [modifiedResponse] to use instead of executing
  /// the actual operation. If null, the chain continues normally.
  const factory InterceptorResult.continue_([R? modifiedResponse]) =
      Continue<R>;

  /// Stop the chain and return immediately with [response].
  ///
  /// The actual operation will not be executed. Response interceptors
  /// will still be called in reverse order.
  const factory InterceptorResult.shortCircuit(R response) = ShortCircuit<R>;

  /// Propagate an error through the chain.
  ///
  /// Error interceptors will be called in reverse order.
  /// The [stackTrace] is optional but recommended for debugging.
  const factory InterceptorResult.error(Object error, [StackTrace? stackTrace]) =
      InterceptorError<R>;
}

/// Continue execution with optional response modification.
///
/// If [modifiedResponse] is provided, it will be used as the response
/// instead of executing the actual operation.
final class Continue<R> extends InterceptorResult<R> {
  /// Creates a continue result.
  ///
  /// The [modifiedResponse] is optional. If provided, the chain will
  /// use this value instead of executing the actual operation.
  const Continue([this.modifiedResponse]) : super._();

  /// The modified response to use instead of executing the operation.
  ///
  /// If null, the operation will execute normally.
  final R? modifiedResponse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Continue<R> &&
          runtimeType == other.runtimeType &&
          modifiedResponse == other.modifiedResponse;

  @override
  int get hashCode => modifiedResponse.hashCode;

  @override
  String toString() => 'InterceptorResult.continue_($modifiedResponse)';
}

/// Stop the chain and return immediately with the given response.
///
/// The actual store operation will not be executed. Response interceptors
/// will still be called for all interceptors that have already processed
/// the request.
final class ShortCircuit<R> extends InterceptorResult<R> {
  /// Creates a short-circuit result.
  ///
  /// The [response] will be returned as the final result of the operation.
  const ShortCircuit(this.response) : super._();

  /// The response to return immediately.
  final R response;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortCircuit<R> &&
          runtimeType == other.runtimeType &&
          response == other.response;

  @override
  int get hashCode => response.hashCode;

  @override
  String toString() => 'InterceptorResult.shortCircuit($response)';
}

/// Propagate an error through the interceptor chain.
///
/// Error interceptors will be called in reverse order for all interceptors
/// that have already processed the request.
final class InterceptorError<R> extends InterceptorResult<R> {
  /// Creates an error result.
  ///
  /// The [error] will be thrown after error interceptors have been called.
  /// The [stackTrace] is optional but helpful for debugging.
  const InterceptorError(this.error, [this.stackTrace]) : super._();

  /// The error to propagate.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterceptorError<R> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(error, stackTrace);

  @override
  String toString() => 'InterceptorResult.error($error)';
}
