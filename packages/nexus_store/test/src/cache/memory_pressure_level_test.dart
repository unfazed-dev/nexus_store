import 'package:test/test.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';

void main() {
  group('MemoryPressureLevel', () {
    test('has four pressure levels', () {
      expect(MemoryPressureLevel.values, hasLength(4));
    });

    test('includes none level for normal operation', () {
      expect(MemoryPressureLevel.values, contains(MemoryPressureLevel.none));
    });

    test('includes moderate level for starting eviction', () {
      expect(
          MemoryPressureLevel.values, contains(MemoryPressureLevel.moderate));
    });

    test('includes critical level for aggressive eviction', () {
      expect(
          MemoryPressureLevel.values, contains(MemoryPressureLevel.critical));
    });

    test('includes emergency level for clearing all non-pinned', () {
      expect(
          MemoryPressureLevel.values, contains(MemoryPressureLevel.emergency));
    });

    group('severity ordering', () {
      test('none is least severe', () {
        expect(MemoryPressureLevel.none.index, equals(0));
      });

      test('moderate is more severe than none', () {
        expect(MemoryPressureLevel.moderate.index,
            greaterThan(MemoryPressureLevel.none.index));
      });

      test('critical is more severe than moderate', () {
        expect(MemoryPressureLevel.critical.index,
            greaterThan(MemoryPressureLevel.moderate.index));
      });

      test('emergency is most severe', () {
        expect(MemoryPressureLevel.emergency.index,
            greaterThan(MemoryPressureLevel.critical.index));
      });
    });

    group('isAtLeast', () {
      test('none is at least none', () {
        expect(MemoryPressureLevel.none.isAtLeast(MemoryPressureLevel.none),
            isTrue);
      });

      test('moderate is at least none', () {
        expect(MemoryPressureLevel.moderate.isAtLeast(MemoryPressureLevel.none),
            isTrue);
      });

      test('moderate is at least moderate', () {
        expect(
            MemoryPressureLevel.moderate
                .isAtLeast(MemoryPressureLevel.moderate),
            isTrue);
      });

      test('none is not at least moderate', () {
        expect(MemoryPressureLevel.none.isAtLeast(MemoryPressureLevel.moderate),
            isFalse);
      });

      test('critical is at least moderate', () {
        expect(
            MemoryPressureLevel.critical
                .isAtLeast(MemoryPressureLevel.moderate),
            isTrue);
      });

      test('emergency is at least critical', () {
        expect(
            MemoryPressureLevel.emergency
                .isAtLeast(MemoryPressureLevel.critical),
            isTrue);
      });

      test('moderate is not at least critical', () {
        expect(
            MemoryPressureLevel.moderate
                .isAtLeast(MemoryPressureLevel.critical),
            isFalse);
      });
    });

    group('shouldEvict', () {
      test('none should not evict', () {
        expect(MemoryPressureLevel.none.shouldEvict, isFalse);
      });

      test('moderate should evict', () {
        expect(MemoryPressureLevel.moderate.shouldEvict, isTrue);
      });

      test('critical should evict', () {
        expect(MemoryPressureLevel.critical.shouldEvict, isTrue);
      });

      test('emergency should evict', () {
        expect(MemoryPressureLevel.emergency.shouldEvict, isTrue);
      });
    });

    group('isEmergency', () {
      test('only emergency returns true', () {
        expect(MemoryPressureLevel.none.isEmergency, isFalse);
        expect(MemoryPressureLevel.moderate.isEmergency, isFalse);
        expect(MemoryPressureLevel.critical.isEmergency, isFalse);
        expect(MemoryPressureLevel.emergency.isEmergency, isTrue);
      });
    });
  });
}
