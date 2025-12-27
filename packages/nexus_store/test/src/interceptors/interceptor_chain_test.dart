import 'package:nexus_store/src/interceptors/interceptor_chain.dart';
import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/store_interceptor.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

/// Tracking interceptor that records all method calls in order.
class TrackingInterceptor extends StoreInterceptor {
  final String name;
  final List<String> log;
  final Set<StoreOperation>? _operations;

  TrackingInterceptor(this.name, this.log, [this._operations]);

  @override
  Set<StoreOperation> get operations => _operations ?? super.operations;

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    log.add('$name.onRequest');
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    log.add('$name.onResponse');
  }

  @override
  Future<void> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
    StackTrace stackTrace,
  ) async {
    log.add('$name.onError');
  }
}

/// Interceptor that modifies the response.
class ModifyingInterceptor extends StoreInterceptor {
  final String prefix;

  ModifyingInterceptor(this.prefix);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    // Response modification would be done via metadata
    ctx.metadata['modified_by'] = prefix;
  }
}

/// Interceptor that short-circuits the chain.
class ShortCircuitInterceptor extends StoreInterceptor {
  final Object value;

  ShortCircuitInterceptor(this.value);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return InterceptorResult.shortCircuit(value as R);
  }
}

/// Interceptor that returns an error.
class ErrorInterceptor extends StoreInterceptor {
  final Object error;

  ErrorInterceptor(this.error);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return InterceptorResult.error(error, StackTrace.current);
  }
}

/// Interceptor that provides a modified response via Continue.
class ContinueWithResponseInterceptor extends StoreInterceptor {
  final Object response;

  ContinueWithResponseInterceptor(this.response);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    return InterceptorResult.continue_(response as R);
  }
}

void main() {
  group('InterceptorChain', () {
    group('construction', () {
      test('should create with empty interceptor list', () {
        final chain = InterceptorChain([]);

        expect(chain.interceptors, isEmpty);
      });

      test('should create with interceptor list', () {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log),
        ]);

        expect(chain.interceptors, hasLength(2));
      });

      test('should be immutable after creation', () {
        final log = <String>[];
        final interceptors = [TrackingInterceptor('A', log)];
        final chain = InterceptorChain(interceptors);

        // Modifying original list should not affect chain
        interceptors.add(TrackingInterceptor('B', log));

        expect(chain.interceptors, hasLength(1));
      });
    });

    group('execute', () {
      test('should execute operation when no interceptors', () async {
        final chain = InterceptorChain([]);
        var executed = false;

        final result = await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async {
            executed = true;
            return 'result';
          },
        );

        expect(executed, isTrue);
        expect(result, equals('result'));
      });

      test('should call onRequest in forward order', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log),
          TrackingInterceptor('C', log),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'result',
        );

        expect(log.where((e) => e.contains('onRequest')).toList(), [
          'A.onRequest',
          'B.onRequest',
          'C.onRequest',
        ]);
      });

      test('should call onResponse in reverse order', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log),
          TrackingInterceptor('C', log),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'result',
        );

        expect(log.where((e) => e.contains('onResponse')).toList(), [
          'C.onResponse',
          'B.onResponse',
          'A.onResponse',
        ]);
      });

      test('should call onError in reverse order', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log),
          TrackingInterceptor('C', log),
        ]);

        try {
          await chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'id-1',
            execute: () async => throw Exception('Test error'),
          );
        } catch (_) {}

        expect(log.where((e) => e.contains('onError')).toList(), [
          'C.onError',
          'B.onError',
          'A.onError',
        ]);
      });

      test('should rethrow error after calling error handlers', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
        ]);

        await expectLater(
          () => chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'id-1',
            execute: () async => throw Exception('Test error'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should skip interceptor if operation not in operations set',
          () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log, {StoreOperation.save}),
          TrackingInterceptor('C', log),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get, // B doesn't handle 'get'
          request: 'id-1',
          execute: () async => 'result',
        );

        // B should be skipped
        expect(log, isNot(contains('B.onRequest')));
        expect(log, isNot(contains('B.onResponse')));
        expect(log, contains('A.onRequest'));
        expect(log, contains('C.onRequest'));
      });
    });

    group('short-circuit', () {
      test('should short-circuit chain when interceptor returns ShortCircuit',
          () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          ShortCircuitInterceptor('short-circuit-value'),
          TrackingInterceptor('C', log),
        ]);

        var operationExecuted = false;
        final result = await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async {
            operationExecuted = true;
            return 'result';
          },
        );

        // Operation should not execute
        expect(operationExecuted, isFalse);
        // Result should be the short-circuited value
        expect(result, equals('short-circuit-value'));
        // C.onRequest should not be called
        expect(log, isNot(contains('C.onRequest')));
        // But response handlers should still be called in reverse for processed interceptors
        expect(log.where((e) => e.contains('onResponse')).toList(), [
          'A.onResponse',
        ]);
      });

      test('should return modified response from Continue with response',
          () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          ContinueWithResponseInterceptor('modified-value'),
          TrackingInterceptor('C', log),
        ]);

        var operationExecuted = false;
        final result = await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async {
            operationExecuted = true;
            return 'original';
          },
        );

        // With Continue(response), operation should NOT execute
        expect(operationExecuted, isFalse);
        // Result should be the modified value
        expect(result, equals('modified-value'));
        // C.onRequest should still be called
        expect(log, contains('C.onRequest'));
      });
    });

    group('error handling', () {
      test('should propagate error from interceptor', () async {
        final chain = InterceptorChain([
          ErrorInterceptor(Exception('Interceptor error')),
        ]);

        await expectLater(
          () => chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'id-1',
            execute: () async => 'result',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should call onError for preceding interceptors when error returned',
          () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
          TrackingInterceptor('B', log),
          ErrorInterceptor(Exception('Error from C')),
        ]);

        try {
          await chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'id-1',
            execute: () async => 'result',
          );
        } catch (_) {}

        // Error handlers called in reverse for processed interceptors
        expect(log.where((e) => e.contains('onError')).toList(), [
          'B.onError',
          'A.onError',
        ]);
      });

      test('should not call onResponse when error occurs', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
        ]);

        try {
          await chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'id-1',
            execute: () async => throw Exception('Operation error'),
          );
        } catch (_) {}

        expect(log, isNot(contains('A.onResponse')));
        expect(log, contains('A.onError'));
      });
    });

    group('context', () {
      test('should provide operation in context', () async {
        StoreOperation? capturedOperation;
        final chain = InterceptorChain([
          _CapturingInterceptor((ctx) {
            capturedOperation = ctx.operation;
          }),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.save,
          request: 'data',
          execute: () async => 'result',
        );

        expect(capturedOperation, equals(StoreOperation.save));
      });

      test('should provide request in context', () async {
        Object? capturedRequest;
        final chain = InterceptorChain([
          _CapturingInterceptor((ctx) {
            capturedRequest = ctx.request;
          }),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'my-request',
          execute: () async => 'result',
        );

        expect(capturedRequest, equals('my-request'));
      });

      test('should provide response in onResponse', () async {
        Object? capturedResponse;
        final chain = InterceptorChain([
          _ResponseCapturingInterceptor((ctx) {
            capturedResponse = ctx.response;
          }),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'the-result',
        );

        expect(capturedResponse, equals('the-result'));
      });

      test('should share metadata across interceptors', () async {
        final chain = InterceptorChain([
          _MetadataWritingInterceptor('key1', 'value1'),
          _MetadataWritingInterceptor('key2', 'value2'),
          _MetadataReadingInterceptor(),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'result',
        );

        // The reading interceptor checks that both keys exist
      });
    });

    group('type safety', () {
      test('should work with complex request types', () async {
        final chain = InterceptorChain([]);
        final request = {'id': 1, 'name': 'test'};

        final result = await chain.execute<Map<String, Object>, String>(
          operation: StoreOperation.get,
          request: request,
          execute: () async => 'found',
        );

        expect(result, equals('found'));
      });

      test('should work with complex response types', () async {
        final chain = InterceptorChain([]);

        final result = await chain.execute<String, List<Map<String, int>>>(
          operation: StoreOperation.getAll,
          request: 'query',
          execute: () async => [
            {'a': 1},
            {'b': 2}
          ],
        );

        expect(result, hasLength(2));
      });

      test('should work with void response', () async {
        final chain = InterceptorChain([]);

        await chain.execute<String, void>(
          operation: StoreOperation.delete,
          request: 'id-1',
          execute: () async {},
        );
      });
    });

    group('async behavior', () {
      test('should wait for async interceptor onRequest', () async {
        final order = <int>[];
        final chain = InterceptorChain([
          _AsyncInterceptor(order, 1, Duration(milliseconds: 50)),
          _AsyncInterceptor(order, 2, Duration(milliseconds: 10)),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async {
            order.add(0); // Operation
            return 'result';
          },
        );

        // Should be in order despite timing differences
        expect(order.take(3).toList(), [1, 2, 0]);
      });

      test('should wait for async interceptor onResponse', () async {
        final order = <int>[];
        final chain = InterceptorChain([
          _AsyncResponseInterceptor(order, 1, Duration(milliseconds: 50)),
          _AsyncResponseInterceptor(order, 2, Duration(milliseconds: 10)),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'result',
        );

        // Response handlers in reverse order (2, 1), waiting for each
        expect(order, [2, 1]);
      });
    });

    group('edge cases', () {
      test('should handle null request', () async {
        final chain = InterceptorChain([]);

        final result = await chain.execute<String?, String>(
          operation: StoreOperation.getAll,
          request: null,
          execute: () async => 'all-items',
        );

        expect(result, equals('all-items'));
      });

      test('should handle empty interceptor chain efficiently', () async {
        final chain = InterceptorChain([]);
        var callCount = 0;

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id',
          execute: () async {
            callCount++;
            return 'result';
          },
        );

        expect(callCount, equals(1));
      });

      test('should handle single interceptor', () async {
        final log = <String>[];
        final chain = InterceptorChain([
          TrackingInterceptor('A', log),
        ]);

        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'id-1',
          execute: () async => 'result',
        );

        expect(log, ['A.onRequest', 'A.onResponse']);
      });
    });
  });
}

/// Interceptor that captures context in onRequest.
class _CapturingInterceptor extends StoreInterceptor {
  final void Function(InterceptorContext) onCapture;

  _CapturingInterceptor(this.onCapture);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    onCapture(ctx);
    return const InterceptorResult.continue_();
  }
}

/// Interceptor that captures context in onResponse.
class _ResponseCapturingInterceptor extends StoreInterceptor {
  final void Function(InterceptorContext) onCapture;

  _ResponseCapturingInterceptor(this.onCapture);

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    onCapture(ctx);
  }
}

/// Interceptor that writes to metadata.
class _MetadataWritingInterceptor extends StoreInterceptor {
  final String key;
  final Object value;

  _MetadataWritingInterceptor(this.key, this.value);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    ctx.metadata[key] = value;
    return const InterceptorResult.continue_();
  }
}

/// Interceptor that reads and verifies metadata.
class _MetadataReadingInterceptor extends StoreInterceptor {
  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    expect(ctx.metadata['key1'], equals('value1'));
    expect(ctx.metadata['key2'], equals('value2'));
    return const InterceptorResult.continue_();
  }
}

/// Async interceptor with configurable delay.
class _AsyncInterceptor extends StoreInterceptor {
  final List<int> order;
  final int id;
  final Duration delay;

  _AsyncInterceptor(this.order, this.id, this.delay);

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    await Future.delayed(delay);
    order.add(id);
    return const InterceptorResult.continue_();
  }
}

/// Async response interceptor with configurable delay.
class _AsyncResponseInterceptor extends StoreInterceptor {
  final List<int> order;
  final int id;
  final Duration delay;

  _AsyncResponseInterceptor(this.order, this.id, this.delay);

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    await Future.delayed(delay);
    order.add(id);
  }
}
