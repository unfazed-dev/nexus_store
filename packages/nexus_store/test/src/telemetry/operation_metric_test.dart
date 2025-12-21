import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:test/test.dart';

void main() {
  group('OperationType', () {
    test('should have all required operation types', () {
      expect(OperationType.values, hasLength(10));
      expect(OperationType.values, contains(OperationType.get));
      expect(OperationType.values, contains(OperationType.getAll));
      expect(OperationType.values, contains(OperationType.save));
      expect(OperationType.values, contains(OperationType.saveAll));
      expect(OperationType.values, contains(OperationType.delete));
      expect(OperationType.values, contains(OperationType.deleteAll));
      expect(OperationType.values, contains(OperationType.watch));
      expect(OperationType.values, contains(OperationType.watchAll));
      expect(OperationType.values, contains(OperationType.sync));
      expect(OperationType.values, contains(OperationType.transaction));
    });

    test('should have correct names', () {
      expect(OperationType.get.name, equals('get'));
      expect(OperationType.getAll.name, equals('getAll'));
      expect(OperationType.save.name, equals('save'));
      expect(OperationType.saveAll.name, equals('saveAll'));
      expect(OperationType.delete.name, equals('delete'));
      expect(OperationType.deleteAll.name, equals('deleteAll'));
      expect(OperationType.watch.name, equals('watch'));
      expect(OperationType.watchAll.name, equals('watchAll'));
      expect(OperationType.sync.name, equals('sync'));
      expect(OperationType.transaction.name, equals('transaction'));
    });
  });

  group('OperationMetric', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);

    group('construction', () {
      test('should create with required fields', () {
        final metric = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals(OperationType.get));
        expect(metric.duration, equals(const Duration(milliseconds: 100)));
        expect(metric.success, isTrue);
        expect(metric.timestamp, equals(testTimestamp));
      });

      test('should have correct default for itemCount', () {
        final metric = OperationMetric(
          operation: OperationType.save,
          duration: Duration.zero,
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.itemCount, equals(1));
      });

      test('should have null defaults for optional fields', () {
        final metric = OperationMetric(
          operation: OperationType.delete,
          duration: const Duration(milliseconds: 50),
          success: false,
          timestamp: testTimestamp,
        );

        expect(metric.policy, isNull);
        expect(metric.errorMessage, isNull);
      });

      test('should accept all fields', () {
        final metric = OperationMetric(
          operation: OperationType.saveAll,
          duration: const Duration(milliseconds: 200),
          success: true,
          itemCount: 10,
          policy: 'cacheFirst',
          timestamp: testTimestamp,
          errorMessage: null,
        );

        expect(metric.operation, equals(OperationType.saveAll));
        expect(metric.duration.inMilliseconds, equals(200));
        expect(metric.success, isTrue);
        expect(metric.itemCount, equals(10));
        expect(metric.policy, equals('cacheFirst'));
      });

      test('should accept error message for failed operations', () {
        final metric = OperationMetric(
          operation: OperationType.sync,
          duration: const Duration(seconds: 5),
          success: false,
          timestamp: testTimestamp,
          errorMessage: 'Network timeout',
        );

        expect(metric.success, isFalse);
        expect(metric.errorMessage, equals('Network timeout'));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final metric1 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          itemCount: 1,
          timestamp: testTimestamp,
        );

        final metric2 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          itemCount: 1,
          timestamp: testTimestamp,
        );

        expect(metric1, equals(metric2));
        expect(metric1.hashCode, equals(metric2.hashCode));
      });

      test('should not be equal with different operation', () {
        final metric1 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        final metric2 = OperationMetric(
          operation: OperationType.save,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different duration', () {
        final metric1 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        final metric2 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 200),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different success', () {
        final metric1 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        final metric2 = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: false,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified operation', () {
        final original = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(operation: OperationType.save);

        expect(copy.operation, equals(OperationType.save));
        expect(copy.duration, equals(original.duration));
        expect(copy.success, equals(original.success));
        expect(copy.timestamp, equals(original.timestamp));
      });

      test('should create copy with modified duration', () {
        final original = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(
          duration: const Duration(milliseconds: 500),
        );

        expect(copy.duration, equals(const Duration(milliseconds: 500)));
        expect(copy.operation, equals(original.operation));
      });

      test('should create copy with modified itemCount', () {
        final original = OperationMetric(
          operation: OperationType.saveAll,
          duration: const Duration(milliseconds: 100),
          success: true,
          itemCount: 5,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(itemCount: 20);

        expect(copy.itemCount, equals(20));
      });

      test('should preserve original when copying', () {
        final original = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        original.copyWith(operation: OperationType.delete);

        expect(original.operation, equals(OperationType.get));
      });
    });

    group('toString', () {
      test('should include operation type', () {
        final metric = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(milliseconds: 100),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('get'));
      });

      test('should include duration', () {
        final metric = OperationMetric(
          operation: OperationType.save,
          duration: const Duration(milliseconds: 250),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('250'));
      });
    });

    group('duration values', () {
      test('should handle zero duration', () {
        final metric = OperationMetric(
          operation: OperationType.get,
          duration: Duration.zero,
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.duration, equals(Duration.zero));
        expect(metric.duration.inMilliseconds, equals(0));
      });

      test('should handle microsecond precision', () {
        final metric = OperationMetric(
          operation: OperationType.get,
          duration: const Duration(microseconds: 500),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.duration.inMicroseconds, equals(500));
      });

      test('should handle long durations', () {
        final metric = OperationMetric(
          operation: OperationType.sync,
          duration: const Duration(minutes: 5),
          success: true,
          timestamp: testTimestamp,
        );

        expect(metric.duration.inMinutes, equals(5));
      });
    });

    group('batch operations', () {
      test('should track item count for getAll', () {
        final metric = OperationMetric(
          operation: OperationType.getAll,
          duration: const Duration(milliseconds: 500),
          success: true,
          itemCount: 100,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals(OperationType.getAll));
        expect(metric.itemCount, equals(100));
      });

      test('should track item count for saveAll', () {
        final metric = OperationMetric(
          operation: OperationType.saveAll,
          duration: const Duration(seconds: 2),
          success: true,
          itemCount: 50,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals(OperationType.saveAll));
        expect(metric.itemCount, equals(50));
      });

      test('should track item count for deleteAll', () {
        final metric = OperationMetric(
          operation: OperationType.deleteAll,
          duration: const Duration(milliseconds: 300),
          success: true,
          itemCount: 25,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals(OperationType.deleteAll));
        expect(metric.itemCount, equals(25));
      });
    });
  });
}
