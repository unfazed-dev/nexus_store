import 'package:nexus_store/src/pool/pool_metric.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';
import 'package:test/test.dart';

void main() {
  group('MetricsReporter', () {
    test('should be an abstract interface', () {
      // MetricsReporter is an interface that can be implemented
      expect(NoOpMetricsReporter(), isA<MetricsReporter>());
    });
  });

  group('NoOpMetricsReporter', () {
    late NoOpMetricsReporter reporter;

    setUp(() {
      reporter = const NoOpMetricsReporter();
    });

    group('construction', () {
      test('should be const constructible', () {
        const reporter1 = NoOpMetricsReporter();
        const reporter2 = NoOpMetricsReporter();

        expect(reporter1, isA<MetricsReporter>());
        expect(identical(reporter1, reporter2), isTrue);
      });

      test('should implement MetricsReporter', () {
        expect(reporter, isA<MetricsReporter>());
      });
    });

    group('reportOperation', () {
      test('should accept OperationMetric without error', () {
        final metric = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: DateTime.now(),
        );

        // Should not throw
        expect(() => reporter.reportOperation(metric), returnsNormally);
      });

      test('should accept multiple metrics', () {
        for (var i = 0; i < 100; i++) {
          reporter.reportOperation(OperationMetric(
            operation: OperationType.save,
            duration: Duration(milliseconds: i),
            success: true,
            timestamp: DateTime.now(),
          ));
        }

        // All calls should complete without issue
        expect(true, isTrue);
      });
    });

    group('reportCacheEvent', () {
      test('should accept CacheMetric without error', () {
        final metric = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'test-id',
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportCacheEvent(metric), returnsNormally);
      });

      test('should accept all cache event types', () {
        for (final event in CacheEvent.values) {
          reporter.reportCacheEvent(CacheMetric(
            event: event,
            timestamp: DateTime.now(),
          ));
        }

        expect(true, isTrue);
      });
    });

    group('reportSyncEvent', () {
      test('should accept SyncMetric without error', () {
        final metric = SyncMetric(
          event: SyncEvent.started,
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportSyncEvent(metric), returnsNormally);
      });

      test('should accept all sync event types', () {
        for (final event in SyncEvent.values) {
          reporter.reportSyncEvent(SyncMetric(
            event: event,
            timestamp: DateTime.now(),
          ));
        }

        expect(true, isTrue);
      });
    });

    group('reportError', () {
      test('should accept ErrorMetric without error', () {
        final metric = ErrorMetric(
          error: Exception('Test error'),
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportError(metric), returnsNormally);
      });

      test('should accept error with stack trace', () {
        final metric = ErrorMetric(
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
          operation: 'save',
          recoverable: true,
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportError(metric), returnsNormally);
      });
    });

    group('reportPoolEvent', () {
      test('should accept PoolMetric without error', () {
        final metric = PoolMetric(
          event: PoolEvent.acquired,
          poolName: 'test-pool',
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportPoolEvent(metric), returnsNormally);
      });

      test('should accept all pool event types', () {
        for (final event in PoolEvent.values) {
          reporter.reportPoolEvent(PoolMetric(
            event: event,
            timestamp: DateTime.now(),
          ));
        }

        expect(true, isTrue);
      });

      test('should handle pool metric with all fields', () {
        final metric = PoolMetric(
          event: PoolEvent.timeout,
          poolName: 'connection-pool',
          duration: const Duration(milliseconds: 500),
          activeConnections: 10,
          idleConnections: 5,
          waitingRequests: 3,
          timestamp: DateTime.now(),
        );

        expect(() => reporter.reportPoolEvent(metric), returnsNormally);
      });
    });

    group('flush', () {
      test('should complete immediately', () async {
        await expectLater(reporter.flush(), completes);
      });

      test('should be safe to call multiple times', () async {
        await reporter.flush();
        await reporter.flush();
        await reporter.flush();

        expect(true, isTrue);
      });
    });

    group('dispose', () {
      test('should complete immediately', () async {
        await expectLater(reporter.dispose(), completes);
      });

      test('should be safe to call after reporting', () async {
        reporter.reportOperation(OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 10),
          success: true,
          timestamp: DateTime.now(),
        ));

        await expectLater(reporter.dispose(), completes);
      });
    });

    group('zero overhead', () {
      test('should have no side effects', () {
        // Report many metrics - should have no memory or performance impact
        for (var i = 0; i < 1000; i++) {
          reporter.reportOperation(OperationMetric(
            operation: OperationType.values[i % OperationType.values.length],
            duration: Duration(milliseconds: i),
            success: i % 2 == 0,
            timestamp: DateTime.now(),
          ));
        }

        // NoOp means no state to check - just verify no errors
        expect(true, isTrue);
      });

      test('should be identical instances when const', () {
        const r1 = NoOpMetricsReporter();
        const r2 = NoOpMetricsReporter();
        const r3 = NoOpMetricsReporter();

        expect(identical(r1, r2), isTrue);
        expect(identical(r2, r3), isTrue);
      });
    });
  });
}
