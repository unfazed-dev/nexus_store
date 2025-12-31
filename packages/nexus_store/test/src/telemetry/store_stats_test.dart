import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/store_stats.dart';
import 'package:test/test.dart';

void main() {
  group('StoreStats', () {
    group('construction', () {
      test('should create with required fields', () {
        final stats = StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {
            OperationType.get: const Duration(milliseconds: 500)
          },
          cacheHits: 80,
          cacheMisses: 20,
          syncSuccessCount: 5,
          syncFailureCount: 1,
          errorCount: 2,
        );

        expect(stats.operationCounts[OperationType.get], equals(10));
        expect(stats.cacheHits, equals(80));
        expect(stats.cacheMisses, equals(20));
        expect(stats.syncSuccessCount, equals(5));
        expect(stats.syncFailureCount, equals(1));
        expect(stats.errorCount, equals(2));
      });

      test('should accept optional lastUpdated', () {
        final now = DateTime.now();
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
          lastUpdated: now,
        );

        expect(stats.lastUpdated, equals(now));
      });
    });

    group('factory empty', () {
      test('should create empty stats', () {
        final stats = StoreStats.empty();

        expect(stats.operationCounts, isEmpty);
        expect(stats.totalDurations, isEmpty);
        expect(stats.cacheHits, equals(0));
        expect(stats.cacheMisses, equals(0));
        expect(stats.syncSuccessCount, equals(0));
        expect(stats.syncFailureCount, equals(0));
        expect(stats.errorCount, equals(0));
        expect(stats.lastUpdated, isNull);
      });
    });

    group('cacheHitRate', () {
      test('should calculate hit rate correctly', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 80,
          cacheMisses: 20,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.cacheHitRate, equals(0.8));
      });

      test('should return 0 when no cache operations', () {
        final stats = StoreStats.empty();

        expect(stats.cacheHitRate, equals(0.0));
      });

      test('should return 1.0 when all hits', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 100,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.cacheHitRate, equals(1.0));
      });

      test('should return 0.0 when all misses', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 100,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.cacheHitRate, equals(0.0));
      });
    });

    group('cacheHitPercentage', () {
      test('should return percentage', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 75,
          cacheMisses: 25,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.cacheHitPercentage, equals(75.0));
      });
    });

    group('syncSuccessRate', () {
      test('should calculate success rate correctly', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 9,
          syncFailureCount: 1,
          errorCount: 0,
        );

        expect(stats.syncSuccessRate, equals(0.9));
      });

      test('should return 1.0 when no syncs', () {
        final stats = StoreStats.empty();

        expect(stats.syncSuccessRate, equals(1.0));
      });

      test('should return 1.0 when all successful', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 100,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.syncSuccessRate, equals(1.0));
      });

      test('should return 0.0 when all failed', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 10,
          errorCount: 0,
        );

        expect(stats.syncSuccessRate, equals(0.0));
      });
    });

    group('averageDuration', () {
      test('should calculate average for operation type', () {
        final stats = StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {
            OperationType.get: const Duration(milliseconds: 500),
          },
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(
          stats.averageDuration(OperationType.get),
          equals(const Duration(milliseconds: 50)),
        );
      });

      test('should return null for unknown operation', () {
        final stats = StoreStats.empty();

        expect(stats.averageDuration(OperationType.get), isNull);
      });

      test('should return null when count is zero', () {
        final stats = StoreStats(
          operationCounts: {OperationType.get: 0},
          totalDurations: {
            OperationType.get: const Duration(milliseconds: 500),
          },
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.averageDuration(OperationType.get), isNull);
      });
    });

    group('averageDurations', () {
      test('should return map of all averages', () {
        final stats = StoreStats(
          operationCounts: {
            OperationType.get: 10,
            OperationType.save: 5,
          },
          totalDurations: {
            OperationType.get: const Duration(milliseconds: 1000),
            OperationType.save: const Duration(milliseconds: 500),
          },
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        final averages = stats.averageDurations;

        expect(averages[OperationType.get],
            equals(const Duration(milliseconds: 100)));
        expect(averages[OperationType.save],
            equals(const Duration(milliseconds: 100)));
      });

      test('should return empty map when no operations', () {
        final stats = StoreStats.empty();

        expect(stats.averageDurations, isEmpty);
      });
    });

    group('totalOperations', () {
      test('should sum all operation counts', () {
        final stats = StoreStats(
          operationCounts: {
            OperationType.get: 10,
            OperationType.save: 5,
            OperationType.delete: 3,
          },
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.totalOperations, equals(18));
      });

      test('should return 0 when no operations', () {
        final stats = StoreStats.empty();

        expect(stats.totalOperations, equals(0));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final stats1 = StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {},
          cacheHits: 80,
          cacheMisses: 20,
          syncSuccessCount: 5,
          syncFailureCount: 1,
          errorCount: 2,
        );

        final stats2 = StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {},
          cacheHits: 80,
          cacheMisses: 20,
          syncSuccessCount: 5,
          syncFailureCount: 1,
          errorCount: 2,
        );

        expect(stats1, equals(stats2));
        expect(stats1.hashCode, equals(stats2.hashCode));
      });

      test('should not be equal with different cache hits', () {
        final stats1 = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 80,
          cacheMisses: 20,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        final stats2 = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 90,
          cacheMisses: 20,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats1, isNot(equals(stats2)));
      });

      test('should not be equal with different operation counts', () {
        final stats1 = StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        final stats2 = StoreStats(
          operationCounts: {OperationType.get: 20},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats1, isNot(equals(stats2)));
      });
    });

    group('toString', () {
      test('should include total operations', () {
        final stats = StoreStats(
          operationCounts: {OperationType.get: 100},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.toString(), contains('100'));
      });

      test('should include cache hit rate', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 75,
          cacheMisses: 25,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        );

        expect(stats.toString(), contains('75'));
      });

      test('should include error count', () {
        final stats = StoreStats(
          operationCounts: {},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 5,
        );

        expect(stats.toString(), contains('5'));
      });
    });
  });
}
