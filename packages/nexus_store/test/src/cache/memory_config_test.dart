import 'package:test/test.dart';
import 'package:nexus_store/src/cache/eviction_strategy.dart';
import 'package:nexus_store/src/cache/memory_config.dart';

void main() {
  group('MemoryConfig', () {
    group('defaults', () {
      test('maxCacheBytes is null (unlimited) by default', () {
        const config = MemoryConfig();
        expect(config.maxCacheBytes, isNull);
      });

      test('moderateThreshold defaults to 0.7', () {
        const config = MemoryConfig();
        expect(config.moderateThreshold, equals(0.7));
      });

      test('criticalThreshold defaults to 0.9', () {
        const config = MemoryConfig();
        expect(config.criticalThreshold, equals(0.9));
      });

      test('evictionBatchSize defaults to 10', () {
        const config = MemoryConfig();
        expect(config.evictionBatchSize, equals(10));
      });

      test('strategy defaults to lru', () {
        const config = MemoryConfig();
        expect(config.strategy, equals(EvictionStrategy.lru));
      });
    });

    group('custom values', () {
      test('can set maxCacheBytes', () {
        const config = MemoryConfig(maxCacheBytes: 50 * 1024 * 1024);
        expect(config.maxCacheBytes, equals(50 * 1024 * 1024));
      });

      test('can set moderateThreshold', () {
        const config = MemoryConfig(moderateThreshold: 0.6);
        expect(config.moderateThreshold, equals(0.6));
      });

      test('can set criticalThreshold', () {
        const config = MemoryConfig(criticalThreshold: 0.85);
        expect(config.criticalThreshold, equals(0.85));
      });

      test('can set evictionBatchSize', () {
        const config = MemoryConfig(evictionBatchSize: 20);
        expect(config.evictionBatchSize, equals(20));
      });

      test('can set strategy', () {
        const config = MemoryConfig(strategy: EvictionStrategy.lfu);
        expect(config.strategy, equals(EvictionStrategy.lfu));
      });
    });

    group('presets', () {
      test('defaults preset has sensible values', () {
        const config = MemoryConfig.defaults;
        expect(config.maxCacheBytes, isNull);
        expect(config.strategy, equals(EvictionStrategy.lru));
      });

      test('aggressive preset has lower thresholds', () {
        const config = MemoryConfig.aggressive;
        expect(config.moderateThreshold, lessThan(0.7));
        expect(config.criticalThreshold, lessThan(0.9));
        expect(config.evictionBatchSize, greaterThan(10));
      });

      test('conservative preset has higher thresholds', () {
        const config = MemoryConfig.conservative;
        expect(config.moderateThreshold, greaterThanOrEqualTo(0.7));
        expect(config.criticalThreshold, greaterThanOrEqualTo(0.9));
      });
    });

    group('validation helpers', () {
      test('isUnlimited returns true when maxCacheBytes is null', () {
        const config = MemoryConfig();
        expect(config.isUnlimited, isTrue);
      });

      test('isUnlimited returns false when maxCacheBytes is set', () {
        const config = MemoryConfig(maxCacheBytes: 1024);
        expect(config.isUnlimited, isFalse);
      });

      test('hasValidThresholds returns true for valid configuration', () {
        const config = MemoryConfig(
          moderateThreshold: 0.5,
          criticalThreshold: 0.8,
        );
        expect(config.hasValidThresholds, isTrue);
      });

      test('hasValidThresholds returns false when moderate >= critical', () {
        const config = MemoryConfig(
          moderateThreshold: 0.9,
          criticalThreshold: 0.8,
        );
        expect(config.hasValidThresholds, isFalse);
      });

      test('hasValidThresholds returns false when thresholds out of range', () {
        const configNegative = MemoryConfig(moderateThreshold: -0.1);
        expect(configNegative.hasValidThresholds, isFalse);

        const configOver = MemoryConfig(criticalThreshold: 1.1);
        expect(configOver.hasValidThresholds, isFalse);
      });
    });

    group('copyWith', () {
      test('can copy with new maxCacheBytes', () {
        const original = MemoryConfig(maxCacheBytes: 1024);
        final copied = original.copyWith(maxCacheBytes: 2048);
        expect(copied.maxCacheBytes, equals(2048));
        expect(copied.strategy, equals(original.strategy));
      });

      test('can copy with new strategy', () {
        const original = MemoryConfig();
        final copied = original.copyWith(strategy: EvictionStrategy.size);
        expect(copied.strategy, equals(EvictionStrategy.size));
        expect(copied.maxCacheBytes, equals(original.maxCacheBytes));
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = MemoryConfig(maxCacheBytes: 1024);
        const config2 = MemoryConfig(maxCacheBytes: 1024);
        expect(config1, equals(config2));
      });

      test('different configs are not equal', () {
        const config1 = MemoryConfig(maxCacheBytes: 1024);
        const config2 = MemoryConfig(maxCacheBytes: 2048);
        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
