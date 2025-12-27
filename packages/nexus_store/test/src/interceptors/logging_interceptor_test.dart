import 'package:logging/logging.dart';
import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/logging_interceptor.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

void main() {
  group('LoggingInterceptor', () {
    late List<LogRecord> logs;
    late Logger logger;

    setUp(() {
      logs = [];
      logger = Logger('TestLogger');
      Logger.root.level = Level.ALL;
      logger.onRecord.listen(logs.add);
    });

    tearDown(() {
      logs.clear();
    });

    group('construction', () {
      test('should create with default settings', () {
        final interceptor = LoggingInterceptor();

        expect(interceptor, isNotNull);
        expect(interceptor.operations, equals(StoreOperation.values.toSet()));
      });

      test('should create with custom logger', () {
        final interceptor = LoggingInterceptor(logger: logger);

        expect(interceptor, isNotNull);
      });

      test('should create with custom log level', () {
        final interceptor = LoggingInterceptor(level: Level.FINE);

        expect(interceptor, isNotNull);
      });

      test('should create with limited operations', () {
        final interceptor = LoggingInterceptor(
          operations: {StoreOperation.save, StoreOperation.delete},
        );

        expect(
          interceptor.operations,
          equals({StoreOperation.save, StoreOperation.delete}),
        );
      });

      test('should allow disabling request logging', () {
        final interceptor = LoggingInterceptor(logRequests: false);

        expect(interceptor, isNotNull);
      });

      test('should allow disabling response logging', () {
        final interceptor = LoggingInterceptor(logResponses: false);

        expect(interceptor, isNotNull);
      });

      test('should allow disabling error logging', () {
        final interceptor = LoggingInterceptor(logErrors: false);

        expect(interceptor, isNotNull);
      });
    });

    group('onRequest', () {
      test('should log operation start', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        await interceptor.onRequest(context);

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('get'));
        expect(logs.first.message, contains('user-123'));
      });

      test('should return Continue result', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<String>>());
      });

      test('should use configured log level', () async {
        final interceptor =
            LoggingInterceptor(logger: logger, level: Level.FINE);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);

        expect(logs.first.level, equals(Level.FINE));
      });

      test('should not log if logRequests is false', () async {
        final interceptor =
            LoggingInterceptor(logger: logger, logRequests: false);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);

        expect(logs, isEmpty);
      });

      test('should store start time in metadata', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);

        expect(context.metadata['_logging_start_time'], isA<DateTime>());
      });
    });

    group('onResponse', () {
      test('should log operation completion', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        ).withResponse('result');
        context.metadata['_logging_start_time'] = DateTime.now();

        await interceptor.onResponse(context);

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('get'));
        expect(logs.first.message, contains('completed'));
      });

      test('should include duration in log message', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        ).withResponse('result');
        context.metadata['_logging_start_time'] =
            DateTime.now().subtract(const Duration(milliseconds: 50));

        await interceptor.onResponse(context);

        expect(logs.first.message, contains('ms'));
      });

      test('should not log if logResponses is false', () async {
        final interceptor =
            LoggingInterceptor(logger: logger, logResponses: false);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        ).withResponse('result');

        await interceptor.onResponse(context);

        expect(logs, isEmpty);
      });
    });

    group('onError', () {
      test('should log error with details', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        await interceptor.onError(context, error, stackTrace);

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('save'));
        expect(logs.first.message, contains('failed'));
        expect(logs.first.message, contains('Test error'));
      });

      test('should log at severe level by default', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        await interceptor.onError(context, 'error', StackTrace.current);

        expect(logs.first.level, equals(Level.SEVERE));
      });

      test('should include stack trace', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );
        final stackTrace = StackTrace.current;

        await interceptor.onError(context, 'error', stackTrace);

        expect(logs.first.stackTrace, equals(stackTrace));
      });

      test('should not log if logErrors is false', () async {
        final interceptor =
            LoggingInterceptor(logger: logger, logErrors: false);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        await interceptor.onError(context, 'error', StackTrace.current);

        expect(logs, isEmpty);
      });
    });

    group('integration', () {
      test('should log full request-response cycle', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'user-123',
        );

        // Request
        await interceptor.onRequest(context);

        // Simulate operation completion
        final responseContext = context.withResponse('User data');

        // Response
        await interceptor.onResponse(responseContext);

        expect(logs, hasLength(2));
        expect(logs[0].message, contains('get'));
        expect(logs[1].message, contains('completed'));
      });

      test('should log full request-error cycle', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        // Request
        await interceptor.onRequest(context);

        // Error
        await interceptor.onError(
            context, Exception('Failed to save'), StackTrace.current);

        expect(logs, hasLength(2));
        expect(logs[0].message, contains('save'));
        expect(logs[1].message, contains('failed'));
      });
    });

    group('request formatting', () {
      test('should handle null request', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<void, List<String>>(
          operation: StoreOperation.getAll,
          request: null,
        );

        await interceptor.onRequest(context);

        expect(logs, hasLength(1));
        // Should not throw
      });

      test('should handle complex request types', () async {
        final interceptor = LoggingInterceptor(logger: logger);
        final context = InterceptorContext<Map<String, dynamic>, String>(
          operation: StoreOperation.save,
          request: {'id': 1, 'name': 'test'},
        );

        await interceptor.onRequest(context);

        expect(logs, hasLength(1));
      });
    });
  });
}
