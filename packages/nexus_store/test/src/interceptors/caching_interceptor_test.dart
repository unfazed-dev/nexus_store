import 'dart:async';

import 'package:nexus_store/src/interceptors/caching_interceptor.dart';
import 'package:nexus_store/src/interceptors/interceptor_chain.dart';
import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

void main() {
  group('CachingInterceptor', () {
    group('construction', () {
      test('should create with defaults', () {
        final interceptor = CachingInterceptor();

        expect(interceptor, isNotNull);
      });

      test('should apply to read operations by default', () {
        final interceptor = CachingInterceptor();

        expect(
          interceptor.operations,
          equals({StoreOperation.get, StoreOperation.getAll}),
        );
      });

      test('should allow custom operations', () {
        final interceptor = CachingInterceptor(
          operations: {StoreOperation.get},
        );

        expect(interceptor.operations, equals({StoreOperation.get}));
      });

      test('should allow custom key generator', () {
        final interceptor = CachingInterceptor(
          keyGenerator: (op, req) => 'custom-$op-$req',
        );

        expect(interceptor, isNotNull);
      });
    });

    group('request deduplication', () {
      test('should allow first request through', () async {
        final interceptor = CachingInterceptor();
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<String>>());
      });

      test('should deduplicate concurrent identical requests', () async {
        final interceptor = CachingInterceptor();
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        // Start two concurrent requests for the same key
        final futures = <Future<String>>[];
        for (var i = 0; i < 3; i++) {
          futures.add(chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'user-123',
            execute: () async {
              operationCount++;
              await Future.delayed(const Duration(milliseconds: 50));
              return 'result';
            },
          ));
        }

        final results = await Future.wait(futures);

        // All should return the same result
        expect(results, everyElement('result'));
        // But operation should only run once
        expect(operationCount, equals(1));
      });

      test('should not deduplicate different requests', () async {
        final interceptor = CachingInterceptor();
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        // Start two concurrent requests for different keys
        final future1 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'user-1',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result-1';
          },
        );

        final future2 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'user-2',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result-2';
          },
        );

        final results = await Future.wait([future1, future2]);

        expect(results, equals(['result-1', 'result-2']));
        expect(operationCount, equals(2));
      });

      test('should not deduplicate different operations', () async {
        final interceptor = CachingInterceptor(
          operations: {StoreOperation.get, StoreOperation.getAll},
        );
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        final future1 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'query',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'single';
          },
        );

        final future2 = chain.execute<String, List<String>>(
          operation: StoreOperation.getAll,
          request: 'query',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return ['list'];
          },
        );

        await Future.wait([future1, future2]);

        expect(operationCount, equals(2));
      });

      test('should allow new request after previous completes', () async {
        final interceptor = CachingInterceptor();
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        // First request
        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
          execute: () async {
            operationCount++;
            return 'result-1';
          },
        );

        // Second request (after first completed)
        await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
          execute: () async {
            operationCount++;
            return 'result-2';
          },
        );

        // Both should execute since they are sequential
        expect(operationCount, equals(2));
      });
    });

    group('error handling', () {
      test('should propagate error to all waiting requests', () async {
        final interceptor = CachingInterceptor();
        final chain = InterceptorChain([interceptor]);

        // Start multiple concurrent requests
        final futures = <Future<String>>[];
        for (var i = 0; i < 3; i++) {
          futures.add(chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'user-123',
            execute: () async {
              await Future.delayed(const Duration(milliseconds: 20));
              throw Exception('Network error');
            },
          ));
        }

        // All should receive the error
        for (final future in futures) {
          await expectLater(future, throwsA(isA<Exception>()));
        }
      });

      test('should clean up after error', () async {
        final interceptor = CachingInterceptor();
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        // First request fails
        await expectLater(
          chain.execute<String, String>(
            operation: StoreOperation.get,
            request: 'user-123',
            execute: () async {
              operationCount++;
              throw Exception('Error');
            },
          ),
          throwsA(isA<Exception>()),
        );

        // Second request should run (not deduplicated with failed one)
        final result = await chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
          execute: () async {
            operationCount++;
            return 'success';
          },
        );

        expect(result, equals('success'));
        expect(operationCount, equals(2));
      });
    });

    group('key generation', () {
      test('should use default key generator', () async {
        final interceptor = CachingInterceptor();
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        final future1 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'same-key',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result';
          },
        );

        final future2 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'same-key',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result';
          },
        );

        await Future.wait([future1, future2]);

        expect(operationCount, equals(1));
      });

      test('should use custom key generator', () async {
        // Custom key generator that ignores request differences
        final interceptor = CachingInterceptor(
          keyGenerator: (op, req) => 'always-same',
        );
        var operationCount = 0;

        final chain = InterceptorChain([interceptor]);

        final future1 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'different-1',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result';
          },
        );

        final future2 = chain.execute<String, String>(
          operation: StoreOperation.get,
          request: 'different-2',
          execute: () async {
            operationCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return 'result';
          },
        );

        await Future.wait([future1, future2]);

        // Should deduplicate despite different requests
        expect(operationCount, equals(1));
      });
    });

    group('onResponse and onError cleanup', () {
      test('onResponse should clean up in-flight tracking', () async {
        final interceptor = CachingInterceptor();
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
        ).withResponse('result');

        // Should not throw
        await interceptor.onResponse(context);
      });

      test('onError should clean up in-flight tracking', () async {
        final interceptor = CachingInterceptor();
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        // Should not throw
        await interceptor.onError(context, 'error', StackTrace.current);
      });
    });
  });
}
