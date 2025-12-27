import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/store_interceptor.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

/// Test interceptor that extends StoreInterceptor with default behavior.
class DefaultTestInterceptor extends StoreInterceptor {
  const DefaultTestInterceptor();
}

/// Test interceptor that tracks all method calls.
class TrackingInterceptor extends StoreInterceptor {
  TrackingInterceptor({Set<StoreOperation>? operations})
      : _operations = operations;

  final Set<StoreOperation>? _operations;

  final List<String> calls = [];
  final List<InterceptorContext<dynamic, dynamic>> contexts = [];

  @override
  Set<StoreOperation> get operations => _operations ?? super.operations;

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    calls.add('onRequest');
    contexts.add(ctx);
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    calls.add('onResponse');
    contexts.add(ctx);
  }

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    calls.add('onError');
    contexts.add(ctx);
  }
}

/// Test interceptor that returns a custom result.
class CustomResultInterceptor extends StoreInterceptor {
  CustomResultInterceptor(this.resultFactory);

  final InterceptorResult<dynamic> Function() resultFactory;

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return resultFactory() as InterceptorResult<R>;
  }
}

void main() {
  group('StoreInterceptor', () {
    group('abstract class', () {
      test('should be extendable', () {
        const interceptor = DefaultTestInterceptor();
        expect(interceptor, isA<StoreInterceptor>());
      });

      test('should be const constructible', () {
        const interceptor1 = DefaultTestInterceptor();
        const interceptor2 = DefaultTestInterceptor();
        expect(identical(interceptor1, interceptor2), isTrue);
      });
    });

    group('operations getter', () {
      test('should return all operations by default', () {
        const interceptor = DefaultTestInterceptor();
        final operations = interceptor.operations;

        expect(operations, hasLength(StoreOperation.values.length));
        for (final op in StoreOperation.values) {
          expect(operations, contains(op));
        }
      });

      test('should be overridable', () {
        final interceptor = TrackingInterceptor(
          operations: {StoreOperation.save, StoreOperation.delete},
        );

        expect(interceptor.operations, hasLength(2));
        expect(interceptor.operations, contains(StoreOperation.save));
        expect(interceptor.operations, contains(StoreOperation.delete));
        expect(
          interceptor.operations,
          isNot(contains(StoreOperation.get)),
        );
      });
    });

    group('onRequest', () {
      test('should return Continue by default', () async {
        const interceptor = DefaultTestInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );

        final result = await interceptor.onRequest(ctx);

        expect(result, isA<Continue<int>>());
        expect((result as Continue<int>).modifiedResponse, isNull);
      });

      test('should receive context', () async {
        final interceptor = TrackingInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test-123',
        );

        await interceptor.onRequest(ctx);

        expect(interceptor.calls, contains('onRequest'));
        expect(interceptor.contexts.first.request, equals('test-123'));
      });

      test('should be overridable to return custom result', () async {
        final interceptor = CustomResultInterceptor(
          () => const InterceptorResult<int>.shortCircuit(42),
        );
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );

        final result = await interceptor.onRequest(ctx);

        expect(result, isA<ShortCircuit<int>>());
        expect((result as ShortCircuit<int>).response, equals(42));
      });
    });

    group('onResponse', () {
      test('should do nothing by default', () async {
        const interceptor = DefaultTestInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
          response: 42,
        );

        // Should complete without error
        await expectLater(
          interceptor.onResponse(ctx),
          completes,
        );
      });

      test('should receive context with response', () async {
        final interceptor = TrackingInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
          response: 100,
        );

        await interceptor.onResponse(ctx);

        expect(interceptor.calls, contains('onResponse'));
        expect(interceptor.contexts.first.response, equals(100));
      });

      test('should be overridable', () async {
        var called = false;
        final interceptor = _ResponseOverrideInterceptor(
          onResponseCallback: (ctx) {
            called = true;
          },
        );
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );

        await interceptor.onResponse(ctx);

        expect(called, isTrue);
      });
    });

    group('onError', () {
      test('should do nothing by default', () async {
        const interceptor = DefaultTestInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );

        // Should complete without error
        await expectLater(
          interceptor.onError(ctx, 'test error', StackTrace.current),
          completes,
        );
      });

      test('should receive context and error', () async {
        final interceptor = TrackingInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );
        final testError = Exception('test error');

        await interceptor.onError(ctx, testError, StackTrace.current);

        expect(interceptor.calls, contains('onError'));
      });

      test('should receive stack trace', () async {
        StackTrace? receivedStack;
        final interceptor = _ErrorOverrideInterceptor(
          onErrorCallback: (ctx, error, stack) {
            receivedStack = stack;
          },
        );
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );
        final testStack = StackTrace.current;

        await interceptor.onError(ctx, 'error', testStack);

        expect(receivedStack, equals(testStack));
      });
    });

    group('type parameters', () {
      test('should work with different request/response types', () async {
        final interceptor = TrackingInterceptor();

        // String request, int response
        final ctx1 = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );
        await interceptor.onRequest(ctx1);

        // Map request, List response
        final ctx2 = InterceptorContext<Map<String, dynamic>, List<String>>(
          operation: StoreOperation.save,
          request: {'id': 1, 'name': 'Test'},
        );
        await interceptor.onRequest(ctx2);

        expect(interceptor.calls, hasLength(2));
      });
    });

    group('multiple interceptors', () {
      test('different interceptor instances should be independent', () async {
        final interceptor1 = TrackingInterceptor();
        final interceptor2 = TrackingInterceptor();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'test',
        );

        await interceptor1.onRequest(ctx);

        expect(interceptor1.calls, hasLength(1));
        expect(interceptor2.calls, isEmpty);
      });
    });
  });
}

/// Helper interceptor that overrides onResponse.
class _ResponseOverrideInterceptor extends StoreInterceptor {
  _ResponseOverrideInterceptor({required this.onResponseCallback});

  final void Function(InterceptorContext<dynamic, dynamic>) onResponseCallback;

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    onResponseCallback(ctx);
  }
}

/// Helper interceptor that overrides onError.
class _ErrorOverrideInterceptor extends StoreInterceptor {
  _ErrorOverrideInterceptor({required this.onErrorCallback});

  final void Function(
    InterceptorContext<dynamic, dynamic>,
    Object,
    StackTrace,
  ) onErrorCallback;

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    onErrorCallback(ctx, error, stackTrace);
  }
}
