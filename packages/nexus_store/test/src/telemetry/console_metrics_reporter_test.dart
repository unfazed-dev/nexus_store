import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nexus_store/src/pool/pool_metric.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/telemetry/console_metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleMetricsReporter', () {
    late ConsoleMetricsReporter reporter;
    late List<LogRecord> logs;
    late StreamSubscription<LogRecord> subscription;

    setUp(() {
      logs = [];
      final logger = Logger('TestMetrics');
      // Enable all log levels for testing
      Logger.root.level = Level.ALL;
      subscription = logger.onRecord.listen((record) => logs.add(record));
      reporter = ConsoleMetricsReporter(logger: logger);
    });

    tearDown(() async {
      await subscription.cancel();
    });

    group('construction', () {
      test('should create with default prefix', () {
        final r = ConsoleMetricsReporter();
        expect(r.prefix, equals('[Metrics]'));
      });

      test('should accept custom prefix', () {
        final r = ConsoleMetricsReporter(prefix: '[MyApp]');
        expect(r.prefix, equals('[MyApp]'));
      });

      test('should implement MetricsReporter', () {
        expect(reporter, isA<MetricsReporter>());
      });
    });

    group('reportOperation', () {
      test('should log operation metric', () {
        reporter.reportOperation(OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 15),
          success: true,
          timestamp: DateTime.now(),
        ));

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('get'));
        expect(logs.first.message, contains('15'));
        expect(logs.first.message, contains('success'));
      });

      test('should log failed operation', () {
        reporter.reportOperation(OperationMetric(
          operation: OperationType.save,
          duration: const Duration(milliseconds: 100),
          success: false,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('failed'));
      });

      test('should include item count', () {
        reporter.reportOperation(OperationMetric(
          operation: OperationType.saveAll,
          duration: const Duration(milliseconds: 500),
          success: true,
          itemCount: 50,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('50'));
      });
    });

    group('reportCacheEvent', () {
      test('should log cache hit', () {
        reporter.reportCacheEvent(CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-123',
          timestamp: DateTime.now(),
        ));

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('hit'));
        expect(logs.first.message, contains('user-123'));
      });

      test('should log cache miss', () {
        reporter.reportCacheEvent(CacheMetric(
          event: CacheEvent.miss,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('miss'));
      });

      test('should include tags when present', () {
        reporter.reportCacheEvent(CacheMetric(
          event: CacheEvent.invalidation,
          tags: {'users', 'active'},
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('users'));
        expect(logs.first.message, contains('active'));
      });
    });

    group('reportSyncEvent', () {
      test('should log sync started', () {
        reporter.reportSyncEvent(SyncMetric(
          event: SyncEvent.started,
          timestamp: DateTime.now(),
        ));

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('started'));
      });

      test('should log sync completed with duration', () {
        reporter.reportSyncEvent(SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          itemsSynced: 100,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('completed'));
        expect(logs.first.message, contains('5000'));
        expect(logs.first.message, contains('100'));
      });

      test('should log sync failed with error', () {
        reporter.reportSyncEvent(SyncMetric(
          event: SyncEvent.failed,
          error: 'Network timeout',
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('failed'));
        expect(logs.first.message, contains('Network timeout'));
      });
    });

    group('reportError', () {
      test('should log error', () {
        reporter.reportError(ErrorMetric(
          error: Exception('Test error'),
          operation: 'save',
          timestamp: DateTime.now(),
        ));

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('Exception'));
        expect(logs.first.message, contains('save'));
      });

      test('should indicate recoverable error', () {
        reporter.reportError(ErrorMetric(
          error: Exception('Temporary failure'),
          recoverable: true,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('recoverable'));
      });

      test('should indicate fatal error', () {
        reporter.reportError(ErrorMetric(
          error: Exception('Critical failure'),
          recoverable: false,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('fatal'));
      });

      test('should show unknown when operation is null', () {
        reporter.reportError(ErrorMetric(
          error: Exception('Unknown operation error'),
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('unknown'));
      });
    });

    group('reportPoolEvent', () {
      test('should log pool acquired event', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          timestamp: DateTime.now(),
        ));

        expect(logs, hasLength(1));
        expect(logs.first.message, contains('acquired'));
      });

      test('should include pool name when present', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.released,
          poolName: 'MainPool',
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('released'));
        expect(logs.first.message, contains('MainPool'));
      });

      test('should include duration when present', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          duration: const Duration(milliseconds: 50),
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('50'));
      });

      test('should include connection counts when present', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          activeConnections: 5,
          idleConnections: 3,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('active=5'));
        expect(logs.first.message, contains('idle=3'));
      });

      test('should include waiting requests when greater than zero', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.timeout,
          waitingRequests: 10,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, contains('waiting=10'));
      });

      test('should not include waiting requests when zero', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          waitingRequests: 0,
          timestamp: DateTime.now(),
        ));

        expect(logs.first.message, isNot(contains('waiting')));
      });

      test('should log all optional fields together', () {
        reporter.reportPoolEvent(PoolMetric(
          event: PoolEvent.acquired,
          poolName: 'TestPool',
          duration: const Duration(milliseconds: 25),
          activeConnections: 2,
          idleConnections: 8,
          waitingRequests: 3,
          timestamp: DateTime.now(),
        ));

        final message = logs.first.message;
        expect(message, contains('acquired'));
        expect(message, contains('TestPool'));
        expect(message, contains('25'));
        expect(message, contains('active=2'));
        expect(message, contains('idle=8'));
        expect(message, contains('waiting=3'));
      });
    });

    group('flush', () {
      test('should complete immediately', () async {
        await expectLater(reporter.flush(), completes);
      });
    });

    group('dispose', () {
      test('should complete immediately', () async {
        await expectLater(reporter.dispose(), completes);
      });
    });
  });
}
