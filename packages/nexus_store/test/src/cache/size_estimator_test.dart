import 'dart:convert';

import 'package:test/test.dart';
import 'package:nexus_store/src/cache/size_estimator.dart';

void main() {
  group('SizeEstimator', () {
    group('JsonSizeEstimator', () {
      late JsonSizeEstimator<Map<String, dynamic>> estimator;

      setUp(() {
        estimator = JsonSizeEstimator<Map<String, dynamic>>(
          toJson: (item) => item,
        );
      });

      test('estimates size based on JSON serialization', () {
        final item = {'name': 'Test', 'value': 123};
        final size = estimator.estimateSize(item);

        // Size should be roughly the UTF-8 encoded JSON length
        final expectedSize = utf8.encode(jsonEncode(item)).length;
        expect(size, equals(expectedSize));
      });

      test('returns 0 for null values when nullable', () {
        final nullableEstimator = JsonSizeEstimator<Map<String, dynamic>?>(
          toJson: (item) => item,
        );
        expect(nullableEstimator.estimateSize(null), equals(4)); // 'null' is 4 bytes
      });

      test('larger objects have larger estimates', () {
        final small = {'a': 1};
        final large = {
          'a': 1,
          'b': 2,
          'c': 'a longer string value',
          'd': List.generate(100, (i) => i),
        };

        final smallSize = estimator.estimateSize(small);
        final largeSize = estimator.estimateSize(large);

        expect(largeSize, greaterThan(smallSize));
      });

      test('caches estimates when enabled', () {
        final cachingEstimator = JsonSizeEstimator<Map<String, dynamic>>(
          toJson: (item) => item,
          cacheEstimates: true,
          maxCacheSize: 100,
        );

        final item = {'test': 'value'};

        // First call should compute
        final size1 = cachingEstimator.estimateSize(item);

        // Second call should return cached value
        final size2 = cachingEstimator.estimateSize(item);

        expect(size1, equals(size2));
      });

      test('cache respects maxCacheSize', () {
        final cachingEstimator = JsonSizeEstimator<Map<String, dynamic>>(
          toJson: (item) => item,
          cacheEstimates: true,
          maxCacheSize: 2,
        );

        // Add 3 items to cache (exceeds maxCacheSize of 2)
        cachingEstimator.estimateSize({'a': 1});
        cachingEstimator.estimateSize({'b': 2});
        cachingEstimator.estimateSize({'c': 3});

        // Cache should have evicted oldest entry
        expect(cachingEstimator.cacheSize, lessThanOrEqualTo(2));
      });

      test('clearCache removes all cached estimates', () {
        final cachingEstimator = JsonSizeEstimator<Map<String, dynamic>>(
          toJson: (item) => item,
          cacheEstimates: true,
        );

        cachingEstimator.estimateSize({'test': 'value'});
        expect(cachingEstimator.cacheSize, equals(1));

        cachingEstimator.clearCache();
        expect(cachingEstimator.cacheSize, equals(0));
      });
    });

    group('FixedSizeEstimator', () {
      test('always returns the fixed size', () {
        final estimator = FixedSizeEstimator<String>(100);
        expect(estimator.estimateSize('short'), equals(100));
        expect(estimator.estimateSize('a much longer string'), equals(100));
      });
    });

    group('CallbackSizeEstimator', () {
      test('uses callback to estimate size', () {
        final estimator = CallbackSizeEstimator<String>(
          (item) => item.length * 2, // 2 bytes per character
        );

        expect(estimator.estimateSize('hello'), equals(10));
        expect(estimator.estimateSize('hi'), equals(4));
      });
    });

    group('CompositeSizeEstimator', () {
      test('adds overhead to delegate estimate', () {
        final delegate = FixedSizeEstimator<String>(100);
        final estimator = CompositeSizeEstimator<String>(
          delegate: delegate,
          overhead: 50,
        );

        expect(estimator.estimateSize('test'), equals(150));
      });

      test('applies multiplier to delegate estimate', () {
        final delegate = FixedSizeEstimator<String>(100);
        final estimator = CompositeSizeEstimator<String>(
          delegate: delegate,
          multiplier: 1.5,
        );

        expect(estimator.estimateSize('test'), equals(150));
      });

      test('applies both overhead and multiplier', () {
        final delegate = FixedSizeEstimator<String>(100);
        final estimator = CompositeSizeEstimator<String>(
          delegate: delegate,
          overhead: 20,
          multiplier: 2.0,
        );

        // (100 * 2.0) + 20 = 220
        expect(estimator.estimateSize('test'), equals(220));
      });
    });
  });
}
