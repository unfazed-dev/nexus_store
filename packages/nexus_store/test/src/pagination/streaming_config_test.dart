import 'package:nexus_store/src/pagination/streaming_config.dart';
import 'package:test/test.dart';

void main() {
  group('StreamingConfig', () {
    group('construction', () {
      test('creates with default values', () {
        const config = StreamingConfig();

        expect(config.pageSize, equals(20));
        expect(config.prefetchDistance, equals(5));
        expect(config.maxPagesInMemory, equals(5));
        expect(config.debounce, equals(const Duration(milliseconds: 300)));
      });

      test('creates with custom pageSize', () {
        const config = StreamingConfig(pageSize: 50);

        expect(config.pageSize, equals(50));
        expect(config.prefetchDistance, equals(5));
      });

      test('creates with custom prefetchDistance', () {
        const config = StreamingConfig(prefetchDistance: 10);

        expect(config.prefetchDistance, equals(10));
      });

      test('creates with custom maxPagesInMemory', () {
        const config = StreamingConfig(maxPagesInMemory: 10);

        expect(config.maxPagesInMemory, equals(10));
      });

      test('creates with custom debounce duration', () {
        const config = StreamingConfig(
          debounce: Duration(milliseconds: 500),
        );

        expect(config.debounce, equals(const Duration(milliseconds: 500)));
      });

      test('creates with all custom values', () {
        const config = StreamingConfig(
          pageSize: 100,
          prefetchDistance: 20,
          maxPagesInMemory: 3,
          debounce: Duration(milliseconds: 200),
        );

        expect(config.pageSize, equals(100));
        expect(config.prefetchDistance, equals(20));
        expect(config.maxPagesInMemory, equals(3));
        expect(config.debounce, equals(const Duration(milliseconds: 200)));
      });
    });

    group('assertions', () {
      test('pageSize must be positive', () {
        expect(
          () => StreamingConfig(pageSize: 0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => StreamingConfig(pageSize: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('prefetchDistance must be non-negative', () {
        // Zero is valid (no prefetch)
        expect(
          () => const StreamingConfig(prefetchDistance: 0),
          returnsNormally,
        );
        expect(
          () => StreamingConfig(prefetchDistance: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('maxPagesInMemory must be positive', () {
        expect(
          () => StreamingConfig(maxPagesInMemory: 0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => StreamingConfig(maxPagesInMemory: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('debounce zero is valid', () {
        // Zero is valid (no debounce)
        expect(
          () => const StreamingConfig(debounce: Duration.zero),
          returnsNormally,
        );
        // Note: Negative Duration values with const are not possible in Dart
      });
    });

    group('copyWith', () {
      test('creates copy with updated pageSize', () {
        const original = StreamingConfig(pageSize: 20);
        final copy = original.copyWith(pageSize: 50);

        expect(copy.pageSize, equals(50));
        expect(copy.prefetchDistance, equals(original.prefetchDistance));
        expect(copy.maxPagesInMemory, equals(original.maxPagesInMemory));
        expect(copy.debounce, equals(original.debounce));
      });

      test('creates copy with updated prefetchDistance', () {
        const original = StreamingConfig();
        final copy = original.copyWith(prefetchDistance: 15);

        expect(copy.prefetchDistance, equals(15));
        expect(copy.pageSize, equals(original.pageSize));
      });

      test('creates copy with all values updated', () {
        const original = StreamingConfig();
        final copy = original.copyWith(
          pageSize: 100,
          prefetchDistance: 10,
          maxPagesInMemory: 8,
          debounce: const Duration(milliseconds: 500),
        );

        expect(copy.pageSize, equals(100));
        expect(copy.prefetchDistance, equals(10));
        expect(copy.maxPagesInMemory, equals(8));
        expect(copy.debounce, equals(const Duration(milliseconds: 500)));
      });

      test('copyWith with no args returns equivalent config', () {
        const original = StreamingConfig(
          pageSize: 30,
          prefetchDistance: 7,
          maxPagesInMemory: 4,
          debounce: Duration(milliseconds: 400),
        );
        final copy = original.copyWith();

        expect(copy.pageSize, equals(original.pageSize));
        expect(copy.prefetchDistance, equals(original.prefetchDistance));
        expect(copy.maxPagesInMemory, equals(original.maxPagesInMemory));
        expect(copy.debounce, equals(original.debounce));
      });
    });

    group('equality', () {
      test('configs with same values are equal', () {
        const config1 = StreamingConfig(
          pageSize: 20,
          prefetchDistance: 5,
        );
        const config2 = StreamingConfig(
          pageSize: 20,
          prefetchDistance: 5,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('non-identical configs with same values are equal', () {
        // Create non-const instances to cover the non-identical path
        // ignore: prefer_const_constructors
        final config1 = StreamingConfig(
          pageSize: 20,
          prefetchDistance: 5,
        );
        // ignore: prefer_const_constructors
        final config2 = StreamingConfig(
          pageSize: 20,
          prefetchDistance: 5,
        );

        expect(config1, equals(config2));
        expect(identical(config1, config2), isFalse);
      });

      test('configs with different values are not equal', () {
        const config1 = StreamingConfig(pageSize: 20);
        const config2 = StreamingConfig(pageSize: 50);

        expect(config1, isNot(equals(config2)));
      });

      test('default configs are equal', () {
        const config1 = StreamingConfig();
        const config2 = StreamingConfig();

        expect(config1, equals(config2));
      });

      test('configs with different debounce are not equal', () {
        const config1 = StreamingConfig(debounce: Duration(milliseconds: 100));
        const config2 = StreamingConfig(debounce: Duration(milliseconds: 200));

        expect(config1, isNot(equals(config2)));
      });

      test('configs with different maxPagesInMemory are not equal', () {
        const config1 = StreamingConfig(maxPagesInMemory: 5);
        const config2 = StreamingConfig(maxPagesInMemory: 10);

        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        const config = StreamingConfig(pageSize: 25);
        final str = config.toString();

        expect(str, contains('StreamingConfig'));
        expect(str, contains('pageSize: 25'));
      });
    });

    group('named constructors', () {
      test('StreamingConfig.small creates small page config', () {
        const config = StreamingConfig.small();

        expect(config.pageSize, equals(10));
        expect(config.maxPagesInMemory, equals(3));
      });

      test('StreamingConfig.large creates large page config', () {
        const config = StreamingConfig.large();

        expect(config.pageSize, equals(50));
        expect(config.maxPagesInMemory, equals(10));
      });

      test('StreamingConfig.noPrefetch disables prefetching', () {
        const config = StreamingConfig.noPrefetch();

        expect(config.prefetchDistance, equals(0));
      });
    });

    group('helper getters', () {
      test('totalItemsInMemory calculates correctly', () {
        const config = StreamingConfig(
          pageSize: 20,
          maxPagesInMemory: 5,
        );

        expect(config.totalItemsInMemory, equals(100));
      });

      test('shouldPrefetch returns true when prefetchDistance > 0', () {
        const config = StreamingConfig(prefetchDistance: 5);

        expect(config.shouldPrefetch, isTrue);
      });

      test('shouldPrefetch returns false when prefetchDistance is 0', () {
        const config = StreamingConfig(prefetchDistance: 0);

        expect(config.shouldPrefetch, isFalse);
      });

      test('shouldDebounce returns true when debounce > 0', () {
        const config = StreamingConfig(
          debounce: Duration(milliseconds: 100),
        );

        expect(config.shouldDebounce, isTrue);
      });

      test('shouldDebounce returns false when debounce is zero', () {
        const config = StreamingConfig(debounce: Duration.zero);

        expect(config.shouldDebounce, isFalse);
      });
    });
  });
}
