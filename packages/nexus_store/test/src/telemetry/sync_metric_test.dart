import 'package:nexus_store/src/telemetry/sync_metric.dart';
import 'package:test/test.dart';

void main() {
  group('SyncEvent', () {
    test('should have all required event types', () {
      expect(SyncEvent.values, hasLength(5));
      expect(SyncEvent.values, contains(SyncEvent.started));
      expect(SyncEvent.values, contains(SyncEvent.completed));
      expect(SyncEvent.values, contains(SyncEvent.failed));
      expect(SyncEvent.values, contains(SyncEvent.retried));
      expect(SyncEvent.values, contains(SyncEvent.conflictResolved));
    });

    test('should have correct names', () {
      expect(SyncEvent.started.name, equals('started'));
      expect(SyncEvent.completed.name, equals('completed'));
      expect(SyncEvent.failed.name, equals('failed'));
      expect(SyncEvent.retried.name, equals('retried'));
      expect(SyncEvent.conflictResolved.name, equals('conflictResolved'));
    });
  });

  group('SyncMetric', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);

    group('construction', () {
      test('should create with required fields', () {
        final metric = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.started));
        expect(metric.timestamp, equals(testTimestamp));
      });

      test('should have correct default for itemsSynced', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          timestamp: testTimestamp,
        );

        expect(metric.itemsSynced, equals(0));
      });

      test('should have null default for duration', () {
        final metric = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        expect(metric.duration, isNull);
      });

      test('should have null default for error', () {
        final metric = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        expect(metric.error, isNull);
      });

      test('should accept all fields', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          itemsSynced: 100,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.completed));
        expect(metric.duration, equals(const Duration(seconds: 5)));
        expect(metric.itemsSynced, equals(100));
      });

      test('should accept error for failed sync', () {
        final metric = SyncMetric(
          event: SyncEvent.failed,
          duration: const Duration(seconds: 2),
          error: 'Network timeout',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.failed));
        expect(metric.error, equals('Network timeout'));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final metric1 = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          itemsSynced: 10,
          timestamp: testTimestamp,
        );

        final metric2 = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          itemsSynced: 10,
          timestamp: testTimestamp,
        );

        expect(metric1, equals(metric2));
        expect(metric1.hashCode, equals(metric2.hashCode));
      });

      test('should not be equal with different event', () {
        final metric1 = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        final metric2 = SyncMetric(
          event: SyncEvent.completed,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different duration', () {
        final metric1 = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          timestamp: testTimestamp,
        );

        final metric2 = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 10),
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different itemsSynced', () {
        final metric1 = SyncMetric(
          event: SyncEvent.completed,
          itemsSynced: 10,
          timestamp: testTimestamp,
        );

        final metric2 = SyncMetric(
          event: SyncEvent.completed,
          itemsSynced: 20,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified event', () {
        final original = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(event: SyncEvent.completed);

        expect(copy.event, equals(SyncEvent.completed));
        expect(copy.timestamp, equals(original.timestamp));
      });

      test('should create copy with modified duration', () {
        final original = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(duration: const Duration(seconds: 10));

        expect(copy.duration, equals(const Duration(seconds: 10)));
      });

      test('should create copy with modified itemsSynced', () {
        final original = SyncMetric(
          event: SyncEvent.completed,
          itemsSynced: 10,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(itemsSynced: 50);

        expect(copy.itemsSynced, equals(50));
      });

      test('should preserve original when copying', () {
        final original = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        original.copyWith(event: SyncEvent.failed);

        expect(original.event, equals(SyncEvent.started));
      });
    });

    group('sync lifecycle scenarios', () {
      test('should track sync start', () {
        final metric = SyncMetric(
          event: SyncEvent.started,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.started));
        expect(metric.duration, isNull);
        expect(metric.itemsSynced, equals(0));
      });

      test('should track successful sync completion', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 30),
          itemsSynced: 250,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.completed));
        expect(metric.duration!.inSeconds, equals(30));
        expect(metric.itemsSynced, equals(250));
        expect(metric.error, isNull);
      });

      test('should track sync failure', () {
        final metric = SyncMetric(
          event: SyncEvent.failed,
          duration: const Duration(seconds: 5),
          error: 'Connection refused',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.failed));
        expect(metric.error, equals('Connection refused'));
      });

      test('should track sync retry', () {
        final metric = SyncMetric(
          event: SyncEvent.retried,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.retried));
      });

      test('should track conflict resolution', () {
        final metric = SyncMetric(
          event: SyncEvent.conflictResolved,
          itemsSynced: 1,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(SyncEvent.conflictResolved));
        expect(metric.itemsSynced, equals(1));
      });
    });

    group('duration values', () {
      test('should handle zero duration', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          duration: Duration.zero,
          timestamp: testTimestamp,
        );

        expect(metric.duration, equals(Duration.zero));
      });

      test('should handle long sync durations', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(hours: 1),
          itemsSynced: 10000,
          timestamp: testTimestamp,
        );

        expect(metric.duration!.inMinutes, equals(60));
      });
    });

    group('toString', () {
      test('should include event type', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('completed'));
      });

      test('should include duration when present', () {
        final metric = SyncMetric(
          event: SyncEvent.completed,
          duration: const Duration(seconds: 5),
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('5'));
      });
    });
  });
}
