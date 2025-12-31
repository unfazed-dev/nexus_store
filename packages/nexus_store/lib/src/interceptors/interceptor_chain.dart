import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_interceptor.dart';
import 'store_operation.dart';

/// Orchestrates the execution of interceptors around store operations.
///
/// The chain executes interceptors in a specific order:
/// - Request phase: Interceptors are called in forward order (first to last)
/// - Response phase: Interceptors are called in reverse order (last to first)
/// - Error phase: Interceptors are called in reverse order (last to first)
///
/// ## Execution Flow
///
/// For a chain with interceptors [A, B, C]:
///
/// ```
/// A.onRequest → B.onRequest → C.onRequest → operation
///                                               ↓
/// A.onResponse ← B.onResponse ← C.onResponse ← result
/// ```
///
/// If an error occurs:
///
/// ```
/// A.onRequest → B.onRequest → C.onRequest → operation
///                                               ↓ error
/// A.onError ← B.onError ← C.onError ← ← ← ← error
/// ```
///
/// ## Short-Circuiting
///
/// Interceptors can short-circuit the chain by returning:
/// - [InterceptorResult.shortCircuit]: Stops the chain immediately
/// - [InterceptorResult.continue_] with a response: Skips the operation
/// - [InterceptorResult.error]: Propagates an error
///
/// ## Example
///
/// ```dart
/// final chain = InterceptorChain([
///   LoggingInterceptor(),
///   AuthInterceptor(authService),
///   CachingInterceptor(cache),
/// ]);
///
/// final result = await chain.execute<String, User>(
///   operation: StoreOperation.get,
///   request: 'user-123',
///   execute: () => backend.get('user-123'),
/// );
/// ```
class InterceptorChain {
  /// Creates an interceptor chain with the given interceptors.
  ///
  /// The interceptors list is copied to ensure immutability.
  InterceptorChain(List<StoreInterceptor> interceptors)
      : _interceptors = List.unmodifiable(interceptors);

  final List<StoreInterceptor> _interceptors;

  /// The interceptors in this chain.
  List<StoreInterceptor> get interceptors => _interceptors;

  /// Executes an operation wrapped with interceptor hooks.
  ///
  /// The [operation] identifies what type of store operation is being performed.
  /// The [request] is the input to the operation (e.g., an ID or entity).
  /// The [execute] callback performs the actual operation.
  ///
  /// Returns the result of the operation, possibly modified by interceptors.
  ///
  /// Throws if an interceptor returns an error or if the operation throws.
  Future<R> execute<T, R>({
    required StoreOperation operation,
    required T request,
    required Future<R> Function() execute,
  }) async {
    // Filter interceptors that apply to this operation
    final applicableInterceptors =
        _interceptors.where((i) => i.operations.contains(operation)).toList();

    if (applicableInterceptors.isEmpty) {
      return execute();
    }

    // Create context
    final context = InterceptorContext<T, R>(
      operation: operation,
      request: request,
    );

    // Track which interceptors have processed the request
    final processedInterceptors = <StoreInterceptor>[];
    R? response;
    var shouldExecuteOperation = true;
    var errorHandlersCalled = false;

    try {
      // Request phase: forward order
      for (final interceptor in applicableInterceptors) {
        final result = await interceptor.onRequest<T, R>(context);

        switch (result) {
          case Continue<R>(:final modifiedResponse):
            processedInterceptors.add(interceptor);
            if (modifiedResponse != null) {
              response = modifiedResponse;
              shouldExecuteOperation = false;
            }

          case ShortCircuit<R>(:final response):
            // Don't add to processed - short circuit stops immediately
            // But we need response handlers for already processed
            await _callResponseHandlers(
              processedInterceptors,
              context.withResponse(response),
            );
            return response;

          case InterceptorError<R>(:final error, :final stackTrace):
            // Call error handlers for processed interceptors
            await _callErrorHandlers(
              processedInterceptors,
              context,
              error,
              stackTrace ?? StackTrace.current,
            );
            errorHandlersCalled = true;
            Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
        }
      }

      // Execute operation if not short-circuited
      if (shouldExecuteOperation) {
        response = await execute();
      }

      // Response phase: reverse order
      final contextWithResponse = context.withResponse(response as R);
      await _callResponseHandlers(processedInterceptors, contextWithResponse);

      return response;
    } catch (error, stackTrace) {
      // Error phase: reverse order for processed interceptors
      // Only call if not already called (e.g., from InterceptorError result)
      if (!errorHandlersCalled) {
        await _callErrorHandlers(
          processedInterceptors,
          context,
          error,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  /// Calls onResponse for interceptors in reverse order.
  Future<void> _callResponseHandlers<T, R>(
    List<StoreInterceptor> interceptors,
    InterceptorContext<T, R> context,
  ) async {
    for (final interceptor in interceptors.reversed) {
      await interceptor.onResponse<T, R>(context);
    }
  }

  /// Calls onError for interceptors in reverse order.
  Future<void> _callErrorHandlers<T, R>(
    List<StoreInterceptor> interceptors,
    InterceptorContext<T, R> context,
    Object error,
    StackTrace stackTrace,
  ) async {
    for (final interceptor in interceptors.reversed) {
      await interceptor.onError<T, R>(context, error, stackTrace);
    }
  }
}
