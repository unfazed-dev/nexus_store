import 'package:nexus_store/src/cache/cache_stats.dart';
import 'package:test/test.dart';

void main() {
  group('CacheStats', () {
    group('construction', () {
      test('should create CacheStats with counts', () {
        final stats = CacheStats(
          totalCount: 100,
          staleCount: 10,
          tagCounts: {'premium': 25, 'active': 80},
        );

        expect(stats.totalCount, equals(100));
        expect(stats.staleCount, equals(10));
        expect(stats.tagCounts['premium'], equals(25));
        expect(stats.tagCounts['active'], equals(80));
      });

      test('should create with empty tag counts', () {
        final stats = CacheStats(
          totalCount: 50,
          staleCount: 5,
          tagCounts: {},
        );

        expect(stats.totalCount, equals(50));
        expect(stats.tagCounts, isEmpty);
      });
    });

    group('stalePercentage', () {
      test('should calculate stale percentage', () {
        final stats = CacheStats(
          totalCount: 100,
          staleCount: 25,
          tagCounts: {},
        );

        expect(stats.stalePercentage, equals(25.0));
      });

      test('should return 0 for empty cache', () {
        final stats = CacheStats(
          totalCount: 0,
          staleCount: 0,
          tagCounts: {},
        );

        expect(stats.stalePercentage, equals(0.0));
      });

      test('should calculate 100% when all stale', () {
        final stats = CacheStats(
          totalCount: 50,
          staleCount: 50,
          tagCounts: {},
        );

        expect(stats.stalePercentage, equals(100.0));
      });
    });

    group('freshCount', () {
      test('should calculate fresh count', () {
        final stats = CacheStats(
          totalCount: 100,
          staleCount: 30,
          tagCounts: {},
        );

        expect(stats.freshCount, equals(70));
      });
    });

    group('empty factory', () {
      test('should create empty cache stats', () {
        final stats = CacheStats.empty();

        expect(stats.totalCount, equals(0));
        expect(stats.staleCount, equals(0));
        expect(stats.tagCounts, isEmpty);
        expect(stats.stalePercentage, equals(0.0));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final stats1 = CacheStats(
          totalCount: 100,
          staleCount: 10,
          tagCounts: {'user': 50},
        );
        final stats2 = CacheStats(
          totalCount: 100,
          staleCount: 10,
          tagCounts: {'user': 50},
        );

        expect(stats1, equals(stats2));
        expect(stats1.hashCode, equals(stats2.hashCode));
      });

      test('should not be equal when counts differ', () {
        final stats1 = CacheStats(
          totalCount: 100,
          staleCount: 10,
          tagCounts: {},
        );
        final stats2 = CacheStats(
          totalCount: 100,
          staleCount: 20,
          tagCounts: {},
        );

        expect(stats1, isNot(equals(stats2)));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        final stats = CacheStats(
          totalCount: 100,
          staleCount: 10,
          tagCounts: {'user': 50},
        );

        final str = stats.toString();
        expect(str, contains('100'));
        expect(str, contains('10'));
      });
    });
  });
}
