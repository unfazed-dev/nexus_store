import 'package:test/test.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/cache/memory_metrics.dart';

void main() {
  group('MemoryMetrics', () {
    test('can create with all required fields', () {
      final metrics = MemoryMetrics(
        currentBytes: 1000,
        maxBytes: 2000,
        evictionCount: 5,
        pinnedCount: 2,
        pinnedBytes: 500,
        pressureLevel: MemoryPressureLevel.none,
        itemCount: 10,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(metrics.currentBytes, equals(1000));
      expect(metrics.maxBytes, equals(2000));
      expect(metrics.evictionCount, equals(5));
      expect(metrics.pinnedCount, equals(2));
      expect(metrics.pinnedBytes, equals(500));
      expect(metrics.pressureLevel, equals(MemoryPressureLevel.none));
      expect(metrics.itemCount, equals(10));
      expect(metrics.timestamp, equals(DateTime(2024, 1, 1)));
    });

    group('empty factory', () {
      test('creates metrics with zero values', () {
        final metrics = MemoryMetrics.empty();
        expect(metrics.currentBytes, equals(0));
        expect(metrics.maxBytes, equals(0));
        expect(metrics.evictionCount, equals(0));
        expect(metrics.pinnedCount, equals(0));
        expect(metrics.pinnedBytes, equals(0));
        expect(metrics.itemCount, equals(0));
        expect(metrics.pressureLevel, equals(MemoryPressureLevel.none));
      });
    });

    group('computed properties', () {
      test('usageRatio returns 0 when maxBytes is 0', () {
        final metrics = MemoryMetrics(
          currentBytes: 100,
          maxBytes: 0,
          evictionCount: 0,
          pinnedCount: 0,
          pinnedBytes: 0,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.usageRatio, equals(0.0));
      });

      test('usageRatio returns correct ratio', () {
        final metrics = MemoryMetrics(
          currentBytes: 500,
          maxBytes: 1000,
          evictionCount: 0,
          pinnedCount: 0,
          pinnedBytes: 0,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.usageRatio, equals(0.5));
      });

      test('unpinnedBytes returns difference between current and pinned', () {
        final metrics = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 0,
          pinnedCount: 5,
          pinnedBytes: 300,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime.now(),
        );
        expect(metrics.unpinnedBytes, equals(700));
      });

      test('unpinnedCount returns difference between item and pinned count',
          () {
        final metrics = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 0,
          pinnedCount: 3,
          pinnedBytes: 300,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime.now(),
        );
        expect(metrics.unpinnedCount, equals(7));
      });

      test('averageItemSize returns 0 when itemCount is 0', () {
        final metrics = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 0,
          pinnedCount: 0,
          pinnedBytes: 0,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.averageItemSize, equals(0));
      });

      test('averageItemSize returns correct average', () {
        final metrics = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 0,
          pinnedCount: 0,
          pinnedBytes: 0,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime.now(),
        );
        expect(metrics.averageItemSize, equals(100));
      });
    });

    group('copyWith', () {
      test('can copy with new values', () {
        final original = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 5,
          pinnedCount: 2,
          pinnedBytes: 500,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime(2024, 1, 1),
        );

        final copied = original.copyWith(
          currentBytes: 1500,
          pressureLevel: MemoryPressureLevel.moderate,
        );

        expect(copied.currentBytes, equals(1500));
        expect(copied.pressureLevel, equals(MemoryPressureLevel.moderate));
        expect(copied.maxBytes, equals(original.maxBytes));
        expect(copied.evictionCount, equals(original.evictionCount));
      });
    });

    group('equality', () {
      test('equal metrics are equal', () {
        final timestamp = DateTime(2024, 1, 1);
        final metrics1 = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 5,
          pinnedCount: 2,
          pinnedBytes: 500,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: timestamp,
        );
        final metrics2 = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 5,
          pinnedCount: 2,
          pinnedBytes: 500,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: timestamp,
        );
        expect(metrics1, equals(metrics2));
      });

      test('different metrics are not equal', () {
        final metrics1 = MemoryMetrics(
          currentBytes: 1000,
          maxBytes: 2000,
          evictionCount: 5,
          pinnedCount: 2,
          pinnedBytes: 500,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime.now(),
        );
        final metrics2 = MemoryMetrics(
          currentBytes: 2000,
          maxBytes: 2000,
          evictionCount: 5,
          pinnedCount: 2,
          pinnedBytes: 500,
          pressureLevel: MemoryPressureLevel.none,
          itemCount: 10,
          timestamp: DateTime.now(),
        );
        expect(metrics1, isNot(equals(metrics2)));
      });
    });
  });
}
