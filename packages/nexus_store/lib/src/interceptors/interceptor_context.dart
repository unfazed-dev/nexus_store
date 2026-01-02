import 'package:meta/meta.dart';

import 'store_operation.dart';

/// Context passed through the interceptor chain during store operations.
///
/// Contains operation details, request/response data, and metadata
/// that can be modified by interceptors as the request flows through the chain.
///
/// ## Type Parameters
///
/// - [T]: The type of the request data (e.g., ID for get, entity for save)
/// - [R]: The type of the response data (e.g., entity for get, void for delete)
///
/// ## Example
///
/// ```dart
/// // In an interceptor
/// Future<InterceptorResult<R>> onRequest<T, R>(
///   InterceptorContext<T, R> ctx,
/// ) async {
///   // Access operation info
///   print('Operation: ${ctx.operation.name}');
///   print('Request: ${ctx.request}');
///
///   // Store data for later interceptors or onResponse
///   ctx.metadata['startTime'] = DateTime.now();
///
///   // Stop further interceptors if needed
///   if (someCondition) {
///     ctx.stopPropagation();
///   }
///
///   return const InterceptorResult.continue_();
/// }
/// ```
@sealed
class InterceptorContext<T, R> {
  /// Creates an interceptor context.
  ///
  /// The [operation] and [request] are required.
  /// The [timestamp] defaults to the current time if not provided.
  /// The [metadata] defaults to an empty map if not provided.
  InterceptorContext({
    required this.operation,
    required this.request,
    this.response,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  })  : metadata = metadata ?? <String, dynamic>{},
        timestamp = timestamp ?? DateTime.now();

  /// The store operation being performed.
  final StoreOperation operation;

  /// The input data for the operation.
  ///
  /// For different operations:
  /// - `get`: The entity ID
  /// - `getAll`: The query object or null
  /// - `save`: The entity to save
  /// - `saveAll`: The list of entities to save
  /// - `delete`: The entity ID
  /// - `deleteAll`: The list of entity IDs
  /// - `watch`/`watchAll`: The ID or query
  /// - `sync`: null or sync options
  final T request;

  /// The output data after the operation completes.
  ///
  /// This is set by the store after the operation executes,
  /// or can be set by an interceptor to provide a custom response.
  ///
  /// For different operations:
  /// - `get`: The entity or null
  /// - `getAll`: The list of entities
  /// - `save`: The saved entity
  /// - `saveAll`: The list of saved entities
  /// - `delete`: Whether deletion succeeded
  /// - `deleteAll`: The count of deleted entities
  /// - `watch`/`watchAll`: The stream
  /// - `sync`: void
  R? response;

  /// Additional metadata that can be modified by interceptors.
  ///
  /// Use this to pass data between interceptors or from
  /// `onRequest` to `onResponse`/`onError` within the same interceptor.
  ///
  /// Common uses:
  /// - Storing timing information
  /// - Passing authentication data
  /// - Storing correlation IDs for tracing
  final Map<String, dynamic> metadata;

  /// When the operation started.
  ///
  /// Useful for timing and audit purposes.
  final DateTime timestamp;

  bool _stopped = false;

  /// Whether propagation has been stopped.
  ///
  /// When true, remaining interceptors in the chain will be skipped
  /// for the request phase. Response and error phases still execute
  /// in reverse order.
  bool get isStopped => _stopped;

  /// Stops further interceptor propagation for the request phase.
  ///
  /// Call this to prevent remaining interceptors from processing
  /// the request. The response phase will still execute for all
  /// interceptors that have already processed the request.
  ///
  /// This is useful when an interceptor needs to short-circuit
  /// the chain without throwing an error.
  void stopPropagation() {
    _stopped = true;
  }

  /// Creates a copy of this context with an updated response.
  ///
  /// Preserves all other properties including the stopped state
  /// and metadata. The original context is not modified.
  ///
  /// This is useful when an interceptor needs to transform
  /// the response while maintaining context immutability.
  InterceptorContext<T, R> withResponse(R newResponse) {
    return InterceptorContext<T, R>(
      operation: operation,
      request: request,
      response: newResponse,
      metadata: metadata,
      timestamp: timestamp,
    ).._stopped = _stopped;
  }

  // coverage:ignore-start
  @override
  String toString() {
    return 'InterceptorContext('
        'operation: ${operation.name}, '
        'request: $request, '
        'response: $response, '
        'metadata: $metadata, '
        'isStopped: $isStopped'
        ')';
  }
  // coverage:ignore-end
}
