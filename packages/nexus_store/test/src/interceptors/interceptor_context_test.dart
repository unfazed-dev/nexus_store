import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

void main() {
  group('InterceptorContext', () {
    group('constructor', () {
      test('should create with required fields', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        expect(ctx.operation, equals(StoreOperation.get));
        expect(ctx.request, equals('user-123'));
        expect(ctx.response, isNull);
        expect(ctx.metadata, isEmpty);
        expect(ctx.timestamp, isNotNull);
      });

      test('should create with optional response', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
          response: 42,
        );

        expect(ctx.response, equals(42));
      });

      test('should create with initial metadata', () {
        final metadata = {'key': 'value'};
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
          metadata: metadata,
        );

        expect(ctx.metadata, equals(metadata));
      });

      test('should create with custom timestamp', () {
        final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
          timestamp: timestamp,
        );

        expect(ctx.timestamp, equals(timestamp));
      });

      test('should use current time as default timestamp', () {
        final before = DateTime.now();
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );
        final after = DateTime.now();

        expect(
            ctx.timestamp.isAfter(before) || ctx.timestamp == before, isTrue);
        expect(
          ctx.timestamp.isBefore(after) || ctx.timestamp == after,
          isTrue,
        );
      });
    });

    group('stopPropagation', () {
      test('should initially not be stopped', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        expect(ctx.isStopped, isFalse);
      });

      test('should set isStopped to true', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        ctx.stopPropagation();

        expect(ctx.isStopped, isTrue);
      });

      test('should be idempotent', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        ctx.stopPropagation();
        ctx.stopPropagation();

        expect(ctx.isStopped, isTrue);
      });
    });

    group('metadata', () {
      test('should allow modification', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        ctx.metadata['userId'] = 'user-456';
        ctx.metadata['timestamp'] = DateTime.now();

        expect(ctx.metadata['userId'], equals('user-456'));
        expect(ctx.metadata['timestamp'], isA<DateTime>());
      });

      test('should persist changes', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        ctx.metadata['first'] = 1;
        ctx.metadata['second'] = 2;
        ctx.metadata['first'] = 10;

        expect(ctx.metadata['first'], equals(10));
        expect(ctx.metadata['second'], equals(2));
        expect(ctx.metadata.length, equals(2));
      });
    });

    group('response', () {
      test('should be settable', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        expect(ctx.response, isNull);
        ctx.response = 100;
        expect(ctx.response, equals(100));
      });

      test('should allow null to be set', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
          response: 42,
        );

        expect(ctx.response, equals(42));
        ctx.response = null;
        expect(ctx.response, isNull);
      });
    });

    group('withResponse', () {
      test('should create copy with new response', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        final newCtx = ctx.withResponse(100);

        expect(newCtx.response, equals(100));
        expect(newCtx.operation, equals(ctx.operation));
        expect(newCtx.request, equals(ctx.request));
        expect(newCtx.timestamp, equals(ctx.timestamp));
      });

      test('should preserve metadata', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
          metadata: {'key': 'value'},
        );

        final newCtx = ctx.withResponse(100);

        expect(newCtx.metadata, equals({'key': 'value'}));
      });

      test('should preserve stopped state', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );
        ctx.stopPropagation();

        final newCtx = ctx.withResponse(100);

        expect(newCtx.isStopped, isTrue);
      });

      test('should not modify original context', () {
        final ctx = InterceptorContext<String, int>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        ctx.withResponse(100);

        expect(ctx.response, isNull);
      });
    });

    group('type safety', () {
      test('should work with complex request types', () {
        final request = {'id': 1, 'name': 'Test'};
        final ctx = InterceptorContext<Map<String, dynamic>, List<String>>(
          operation: StoreOperation.save,
          request: request,
        );

        expect(ctx.request, equals(request));
      });

      test('should work with complex response types', () {
        final ctx = InterceptorContext<String, List<Map<String, dynamic>>>(
          operation: StoreOperation.getAll,
          request: 'query',
        );

        ctx.response = [
          {'id': 1},
          {'id': 2},
        ];

        expect(ctx.response, hasLength(2));
      });
    });

    group('all operations', () {
      for (final operation in StoreOperation.values) {
        test('should work with $operation', () {
          final ctx = InterceptorContext<String, String>(
            operation: operation,
            request: 'test',
          );

          expect(ctx.operation, equals(operation));
        });
      }
    });
  });
}
