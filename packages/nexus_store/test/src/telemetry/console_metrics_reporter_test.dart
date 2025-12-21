import 'dart:async';

import 'package:logging/logging.dart';
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
