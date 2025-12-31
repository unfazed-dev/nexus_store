import 'dart:async';

import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_interceptor.dart';
import 'store_operation.dart';

/// Type definition for custom cache key generator.
typedef CacheKeyGenerator = String Function(
    StoreOperation operation, Object? request);

/// An interceptor that deduplicates concurrent identical requests.
///
/// When multiple identical requests are made concurrently, only the first one
/// executes the actual operation. Subsequent requests wait for and share the
/// result of the first request.
///
/// This is useful for:
/// - Reducing redundant network calls
/// - Preventing duplicate database queries
/// - Optimizing high-frequency UI updates
///
/// ## Example
///
/// ```dart
/// final store = NexusStore(
///   backend: backend,
///   config: StoreConfig(
///     interceptors: [
///       CachingInterceptor(),
///     ],
///   ),
/// );
///
/// // These concurrent calls will only result in one actual operation
/// await Future.wait([
///   store.get('user-123'),
///   store.get('user-123'),
///   store.get('user-123'),
/// ]);
/// ```
class CachingInterceptor extends StoreInterceptor {
  /// Creates a caching interceptor.
  ///
  /// - [operations]: Operations to deduplicate. Defaults to get and getAll.
  /// - [keyGenerator]: Custom function to generate cache keys.
  CachingInterceptor({
    Set<StoreOperation>? operations,
    CacheKeyGenerator? keyGenerator,
  })  : _operations = operations ?? {StoreOperation.get, StoreOperation.getAll},
        _keyGenerator = keyGenerator ?? _defaultKeyGenerator;

  final Set<StoreOperation> _operations;
  final CacheKeyGenerator _keyGenerator;

  /// In-flight requests mapped by cache key.
  final Map<String, Completer<dynamic>> _inFlight = {};

  @override
  Set<StoreOperation> get operations => _operations;

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    final key = _keyGenerator(ctx.operation, ctx.request);

    // Check if there's already an in-flight request for this key
    final existing = _inFlight[key];
    if (existing != null) {
      // Wait for the existing request and return its result
      try {
        final result = await existing.future as R;
        return InterceptorResult.shortCircuit(result);
      } catch (e, st) {
        return InterceptorResult.error(e, st);
      }
    }

    // This is the first request - create a completer for others to wait on
    final completer = Completer<R>();
    _inFlight[key] = completer;

    // Add an error handler to prevent unhandled async errors
    // when no one is waiting on the completer. The error will be
    // propagated to actual callers via InterceptorResult.error().
    unawaited(completer.future.then((_) {}, onError: (_) {}));

    // Store the key in metadata for cleanup
    ctx.metadata['_caching_key'] = key;

    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    final key = ctx.metadata['_caching_key'] as String?;
    if (key == null) return;

    final completer = _inFlight.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.complete(ctx.response);
    }
  }

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    final key = ctx.metadata['_caching_key'] as String?;
    if (key == null) return;

    final completer = _inFlight.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }

  /// Default key generator that combines operation and request.
  static String _defaultKeyGenerator(
      StoreOperation operation, Object? request) {
    return '${operation.name}:${request?.hashCode ?? 'null'}';
  }
}
