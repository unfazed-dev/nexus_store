import 'package:test/test.dart';
import 'package:nexus_store/src/cache/eviction_strategy.dart';

void main() {
  group('EvictionStrategy', () {
    test('has three strategies', () {
      expect(EvictionStrategy.values, hasLength(3));
    });

    test('includes lru (least recently used)', () {
      expect(EvictionStrategy.values, contains(EvictionStrategy.lru));
    });

    test('includes lfu (least frequently used)', () {
      expect(EvictionStrategy.values, contains(EvictionStrategy.lfu));
    });

    test('includes size (largest items first)', () {
      expect(EvictionStrategy.values, contains(EvictionStrategy.size));
    });

    group('isAccessBased', () {
      test('lru is access-based', () {
        expect(EvictionStrategy.lru.isAccessBased, isTrue);
      });

      test('lfu is access-based', () {
        expect(EvictionStrategy.lfu.isAccessBased, isTrue);
      });

      test('size is not access-based', () {
        expect(EvictionStrategy.size.isAccessBased, isFalse);
      });
    });

    group('requiresAccessTracking', () {
      test('lru requires access tracking', () {
        expect(EvictionStrategy.lru.requiresAccessTracking, isTrue);
      });

      test('lfu requires access tracking', () {
        expect(EvictionStrategy.lfu.requiresAccessTracking, isTrue);
      });

      test('size does not require access tracking', () {
        expect(EvictionStrategy.size.requiresAccessTracking, isFalse);
      });
    });

    group('requiresFrequencyTracking', () {
      test('lru does not require frequency tracking', () {
        expect(EvictionStrategy.lru.requiresFrequencyTracking, isFalse);
      });

      test('lfu requires frequency tracking', () {
        expect(EvictionStrategy.lfu.requiresFrequencyTracking, isTrue);
      });

      test('size does not require frequency tracking', () {
        expect(EvictionStrategy.size.requiresFrequencyTracking, isFalse);
      });
    });
  });
}
