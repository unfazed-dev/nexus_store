import 'package:nexus_store/src/pool/pool_metric.dart';
import 'package:nexus_store/src/telemetry/buffered_metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';
import 'package:test/test.dart';

/// Mock reporter for testing
class MockMetricsReporter implements MetricsReporter {
  final List<OperationMetric> operations = [];
  final List<CacheMetric> cacheEvents = [];
  final List<SyncMetric> syncEvents = [];
  final List<ErrorMetric> errors = [];
  final List<PoolMetric> poolEvents = [];
  int flushCount = 0;
  int disposeCount = 0;

  @override
  void reportOperation(OperationMetric metric) => operations.add(metric);

  @override
  void reportCacheEvent(CacheMetric metric) => cacheEvents.add(metric);

  @override
  void reportSyncEvent(SyncMetric metric) => syncEvents.add(metric);

  @override
  void reportError(ErrorMetric metric) => errors.add(metric);

  @override
  void reportPoolEvent(PoolMetric metric) => poolEvents.add(metric);

  @override
  Future<void> flush() async => flushCount++;

  @override
  Future<void> dispose() async => disposeCount++;
}

void main() {
  group('BufferedMetricsReporter', () {
    late MockMetricsReporter mockDelegate;
    late BufferedMetricsReporter reporter;

    setUp(() {
      mockDelegate = MockMetricsReporter();
      reporter = BufferedMetricsReporter(
        delegate: mockDelegate,
        bufferSize: 5,
        flushInterval: const Duration(minutes: 10), // Long interval for tests
      );
    });

    tearDown(() async {
      await reporter.dispose();
    });

    group('construction', () {
      test('should create with required delegate', () {
        final r = BufferedMetricsReporter(delegate: mockDelegate);
        expect(r.delegate, equals(mockDelegate));
        expect(r.bufferSize, equals(100)); // default
        expect(r.flushInterval, equals(const Duration(seconds: 30))); // default
      });

      test('should accept custom buffer size', () {
        final r = BufferedMetricsReporter(
          delegate: mockDelegate,
          bufferSize: 50,
        );
        expect(r.bufferSize, equals(50));
      });

      test('should accept custom flush interval', () {
        final r = BufferedMetricsReporter(
          delegate: mockDelegate,
          flushInterval: const Duration(minutes: 1),
        );
        expect(r.flushInterval, equals(const Duration(minutes: 1)));
      });

      test('should implement MetricsReporter', () {
        expect(reporter, isA<MetricsReporter>());
      });
    });

    group('buffering', () {
      test('should buffer metrics until buffer size reached', () {
        for (var i = 0; i < 4; i++) {
          reporter.reportOperation(_createOperationMetric());
        }

        expect(mockDelegate.operations, isEmpty);
        expect(reporter.currentBufferSize, equals(4));
      });

      test('should auto-flush when buffer is full', () async {
        for (var i = 0; i < 5; i++) {
          reporter.reportOperation(_createOperationMetric());
        }

        // Wait for async flush
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(mockDelegate.operations, hasLength(5));
        expect(reporter.currentBufferSize, equals(0));
      });

      test('should buffer different metric types', () {
        reporter.reportOperation(_createOperationMetric());
        reporter.reportCacheEvent(_createCacheMetric());
        reporter.reportSyncEvent(_createSyncMetric());
        reporter.reportError(_createErrorMetric());

        expect(reporter.currentBufferSize, equals(4));
        expect(mockDelegate.operations, isEmpty);
        expect(mockDelegate.cacheEvents, isEmpty);
        expect(mockDelegate.syncEvents, isEmpty);
        expect(mockDelegate.errors, isEmpty);
      });
    });

    group('flush', () {
      test('should forward all buffered metrics to delegate', () async {
        reporter.reportOperation(_createOperationMetric());
        reporter.reportCacheEvent(_createCacheMetric());
        reporter.reportSyncEvent(_createSyncMetric());
        reporter.reportError(_createErrorMetric());

        await reporter.flush();

        expect(mockDelegate.operations, hasLength(1));
        expect(mockDelegate.cacheEvents, hasLength(1));
        expect(mockDelegate.syncEvents, hasLength(1));
        expect(mockDelegate.errors, hasLength(1));
        expect(mockDelegate.flushCount, equals(1));
      });

      test('should clear buffer after flush', () async {
        reporter.reportOperation(_createOperationMetric());
        reporter.reportOperation(_createOperationMetric());

        await reporter.flush();

        expect(reporter.currentBufferSize, equals(0));
      });

      test('should do nothing when buffer is empty', () async {
        await reporter.flush();

        expect(mockDelegate.operations, isEmpty);
        expect(mockDelegate.flushCount, equals(0));
      });

      test('should call onFlush callback', () async {
        final flushedMetrics = <Object>[];
        final r = BufferedMetricsReporter(
          delegate: mockDelegate,
          onFlush: (metrics) async => flushedMetrics.addAll(metrics),
        );

        r.reportOperation(_createOperationMetric());
        r.reportCacheEvent(_createCacheMetric());

        await r.flush();

        expect(flushedMetrics, hasLength(2));
      });
    });

    group('dispose', () {
      test('should flush remaining metrics', () async {
        reporter.reportOperation(_createOperationMetric());
        reporter.reportOperation(_createOperationMetric());

        await reporter.dispose();

        expect(mockDelegate.operations, hasLength(2));
      });

      test('should dispose delegate', () async {
        await reporter.dispose();

        expect(mockDelegate.disposeCount, equals(1));
      });

      test('should not accept new metrics after dispose', () async {
        await reporter.dispose();

        reporter.reportOperation(_createOperationMetric());

        expect(reporter.currentBufferSize, equals(0));
      });
    });

    group('currentBufferSize', () {
      test('should track buffer size', () {
        expect(reporter.currentBufferSize, equals(0));

        reporter.reportOperation(_createOperationMetric());
        expect(reporter.currentBufferSize, equals(1));

        reporter.reportOperation(_createOperationMetric());
        expect(reporter.currentBufferSize, equals(2));
      });

      test('should reset after flush', () async {
        reporter.reportOperation(_createOperationMetric());
        reporter.reportOperation(_createOperationMetric());

        await reporter.flush();

        expect(reporter.currentBufferSize, equals(0));
      });
    });

    group('timer', () {
      test('should trigger flush at flushInterval', () async {
        final timerMock = MockMetricsReporter();
        final timerReporter = BufferedMetricsReporter(
          delegate: timerMock,
          bufferSize: 100, // High to prevent auto-flush
          flushInterval: const Duration(milliseconds: 50),
        );

        timerReporter.reportOperation(_createOperationMetric());
        expect(timerMock.operations, isEmpty);

        // Wait for timer to fire
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(timerMock.operations, hasLength(1));
        expect(timerMock.flushCount, equals(1));

        await timerReporter.dispose();
      });

      test('should cancel timer on dispose', () async {
        final timerMock = MockMetricsReporter();
        final timerReporter = BufferedMetricsReporter(
          delegate: timerMock,
          bufferSize: 100,
          flushInterval: const Duration(milliseconds: 50),
        );

        timerReporter.reportOperation(_createOperationMetric());

        // Dispose before timer fires
        await timerReporter.dispose();

        // Metrics should be flushed during dispose
        expect(timerMock.operations, hasLength(1));

        // Wait past the timer interval
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should not have flushed again (only once during dispose)
        expect(timerMock.flushCount, equals(1));
      });
    });

    group('PoolMetric forwarding', () {
      test('should forward PoolMetric to delegate on flush', () async {
        final poolMetric = PoolMetric(
          event: PoolEvent.acquired,
          timestamp: DateTime.now(),
        );

        reporter.reportPoolEvent(poolMetric);
        expect(reporter.currentBufferSize, equals(1));
        expect(mockDelegate.poolEvents, isEmpty);

        await reporter.flush();

        expect(mockDelegate.poolEvents, hasLength(1));
        expect(mockDelegate.poolEvents.first.event, equals(PoolEvent.acquired));
      });

      test('should buffer multiple PoolMetrics', () async {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          timestamp: DateTime.now(),
        ));
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.released,
          timestamp: DateTime.now(),
        ));
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.timeout,
          timestamp: DateTime.now(),
        ));

        expect(reporter.currentBufferSize, equals(3));

        await reporter.flush();

        expect(mockDelegate.poolEvents, hasLength(3));
      });
    });
  });
}

OperationMetric _createOperationMetric() => OperationMetric(
      operation: OperationType.get,
      duration: const Duration(milliseconds: 10),
      success: true,
      timestamp: DateTime.now(),
    );

CacheMetric _createCacheMetric() => CacheMetric(
      event: CacheEvent.hit,
      timestamp: DateTime.now(),
    );

SyncMetric _createSyncMetric() => SyncMetric(
      event: SyncEvent.completed,
      timestamp: DateTime.now(),
    );

ErrorMetric _createErrorMetric() => ErrorMetric(
      error: Exception('Test'),
      timestamp: DateTime.now(),
    );
