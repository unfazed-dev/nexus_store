import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:nexus_store/src/interceptors/timing_interceptor.dart';
import 'package:nexus_store/src/pool/pool_metric.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';
import 'package:test/test.dart';

/// Test metrics reporter that captures reported metrics.
class TestMetricsReporter implements MetricsReporter {
  final List<OperationMetric> reportedMetrics = [];

  @override
  void reportOperation(OperationMetric metric) {
    reportedMetrics.add(metric);
  }

  @override
  void reportCacheEvent(CacheMetric metric) {}

  @override
  void reportSyncEvent(SyncMetric metric) {}

  @override
  void reportError(ErrorMetric metric) {}

  @override
  void reportPoolEvent(PoolMetric metric) {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}

  void clear() => reportedMetrics.clear();
}

void main() {
  group('TimingInterceptor', () {
    late TestMetricsReporter reporter;

    setUp(() {
      reporter = TestMetricsReporter();
    });

    tearDown(() {
      reporter.clear();
    });

    group('construction', () {
      test('should create with metrics reporter', () {
        final interceptor = TimingInterceptor(reporter: reporter);

        expect(interceptor, isNotNull);
        expect(interceptor.operations, equals(StoreOperation.values.toSet()));
      });

      test('should create with limited operations', () {
        final interceptor = TimingInterceptor(
          reporter: reporter,
          operations: {StoreOperation.get, StoreOperation.save},
        );

        expect(
          interceptor.operations,
          equals({StoreOperation.get, StoreOperation.save}),
        );
      });
    });

    group('onRequest', () {
      test('should store start time in metadata', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);

        expect(context.metadata['_timing_start'], isA<Stopwatch>());
      });

      test('should return Continue result', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<String>>());
      });

      test('should start the stopwatch', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);

        final stopwatch = context.metadata['_timing_start'] as Stopwatch;
        expect(stopwatch.isRunning, isTrue);
      });
    });

    group('onResponse', () {
      test('should report successful operation metric', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        // Simulate request phase
        await interceptor.onRequest(context);

        // Wait a bit to have measurable duration
        await Future.delayed(const Duration(milliseconds: 10));

        // Simulate response
        final responseContext = context.withResponse('result');
        await interceptor.onResponse(responseContext);

        expect(reporter.reportedMetrics, hasLength(1));
        final metric = reporter.reportedMetrics.first;
        expect(metric.operation, equals(OperationType.get));
        expect(metric.success, isTrue);
        expect(metric.duration.inMilliseconds, greaterThanOrEqualTo(10));
      });

      test('should stop the stopwatch', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse('result'));

        final stopwatch = context.metadata['_timing_start'] as Stopwatch;
        expect(stopwatch.isRunning, isFalse);
      });

      test('should handle missing stopwatch gracefully', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        ).withResponse('result');

        // No request phase, so no stopwatch
        await interceptor.onResponse(context);

        // Should not throw, metrics with zero duration
        expect(reporter.reportedMetrics, hasLength(1));
        expect(reporter.reportedMetrics.first.duration, equals(Duration.zero));
      });
    });

    group('onError', () {
      test('should report failed operation metric', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        await interceptor.onRequest(context);
        await Future.delayed(const Duration(milliseconds: 5));
        await interceptor.onError(
            context, Exception('Test error'), StackTrace.current);

        expect(reporter.reportedMetrics, hasLength(1));
        final metric = reporter.reportedMetrics.first;
        expect(metric.operation, equals(OperationType.save));
        expect(metric.success, isFalse);
        expect(metric.errorMessage, contains('Test error'));
      });

      test('should stop the stopwatch', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        await interceptor.onRequest(context);
        await interceptor.onError(context, 'error', StackTrace.current);

        final stopwatch = context.metadata['_timing_start'] as Stopwatch;
        expect(stopwatch.isRunning, isFalse);
      });

      test('should handle missing stopwatch gracefully', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        // No request phase
        await interceptor.onError(context, 'error', StackTrace.current);

        expect(reporter.reportedMetrics, hasLength(1));
        expect(reporter.reportedMetrics.first.duration, equals(Duration.zero));
      });
    });

    group('operation mapping', () {
      test('should map get operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse('result'));

        expect(
            reporter.reportedMetrics.first.operation, equals(OperationType.get));
      });

      test('should map getAll operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<void, List<String>>(
          operation: StoreOperation.getAll,
          request: null,
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse(['a', 'b']));

        expect(reporter.reportedMetrics.first.operation,
            equals(OperationType.getAll));
      });

      test('should map save operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.save,
          request: 'data',
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse('saved'));

        expect(reporter.reportedMetrics.first.operation,
            equals(OperationType.save));
      });

      test('should map saveAll operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<List<String>, List<String>>(
          operation: StoreOperation.saveAll,
          request: ['a', 'b'],
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse(['a', 'b']));

        expect(reporter.reportedMetrics.first.operation,
            equals(OperationType.saveAll));
      });

      test('should map delete operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, bool>(
          operation: StoreOperation.delete,
          request: 'id',
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse(true));

        expect(reporter.reportedMetrics.first.operation,
            equals(OperationType.delete));
      });

      test('should map deleteAll operation', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<List<String>, int>(
          operation: StoreOperation.deleteAll,
          request: ['a', 'b'],
        );

        await interceptor.onRequest(context);
        await interceptor.onResponse(context.withResponse(2));

        expect(reporter.reportedMetrics.first.operation,
            equals(OperationType.deleteAll));
      });
    });

    group('integration', () {
      test('should accurately measure operation duration', () async {
        final interceptor = TimingInterceptor(reporter: reporter);
        final context = InterceptorContext<String, String>(
          operation: StoreOperation.get,
          request: 'id',
        );

        await interceptor.onRequest(context);
        await Future.delayed(const Duration(milliseconds: 50));
        await interceptor.onResponse(context.withResponse('result'));

        final metric = reporter.reportedMetrics.first;
        // Allow some margin for test execution variance
        expect(metric.duration.inMilliseconds, greaterThanOrEqualTo(45));
        expect(metric.duration.inMilliseconds, lessThan(200));
      });
    });
  });
}
