import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEvent', () {
    test('should have all required event types', () {
      expect(CacheEvent.values, hasLength(6));
      expect(CacheEvent.values, contains(CacheEvent.hit));
      expect(CacheEvent.values, contains(CacheEvent.miss));
      expect(CacheEvent.values, contains(CacheEvent.write));
      expect(CacheEvent.values, contains(CacheEvent.eviction));
      expect(CacheEvent.values, contains(CacheEvent.invalidation));
      expect(CacheEvent.values, contains(CacheEvent.expiration));
    });

    test('should have correct names', () {
      expect(CacheEvent.hit.name, equals('hit'));
      expect(CacheEvent.miss.name, equals('miss'));
      expect(CacheEvent.write.name, equals('write'));
      expect(CacheEvent.eviction.name, equals('eviction'));
      expect(CacheEvent.invalidation.name, equals('invalidation'));
      expect(CacheEvent.expiration.name, equals('expiration'));
    });
  });

  group('CacheMetric', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);

    group('construction', () {
      test('should create with required fields', () {
        final metric = CacheMetric(
          event: CacheEvent.hit,
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.hit));
        expect(metric.timestamp, equals(testTimestamp));
      });

      test('should have correct default for itemCount', () {
        final metric = CacheMetric(
          event: CacheEvent.miss,
          timestamp: testTimestamp,
        );

        expect(metric.itemCount, equals(1));
      });

      test('should have empty default for tags', () {
        final metric = CacheMetric(
          event: CacheEvent.write,
          timestamp: testTimestamp,
        );

        expect(metric.tags, isEmpty);
      });

      test('should have null default for itemId', () {
        final metric = CacheMetric(
          event: CacheEvent.eviction,
          timestamp: testTimestamp,
        );

        expect(metric.itemId, isNull);
      });

      test('should accept all fields', () {
        final metric = CacheMetric(
          event: CacheEvent.invalidation,
          itemId: 'user-123',
          tags: {'premium', 'active'},
          timestamp: testTimestamp,
          itemCount: 5,
        );

        expect(metric.event, equals(CacheEvent.invalidation));
        expect(metric.itemId, equals('user-123'));
        expect(metric.tags, containsAll(['premium', 'active']));
        expect(metric.itemCount, equals(5));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final metric1 = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-1',
          timestamp: testTimestamp,
        );

        final metric2 = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-1',
          timestamp: testTimestamp,
        );

        expect(metric1, equals(metric2));
        expect(metric1.hashCode, equals(metric2.hashCode));
      });

      test('should not be equal with different event', () {
        final metric1 = CacheMetric(
          event: CacheEvent.hit,
          timestamp: testTimestamp,
        );

        final metric2 = CacheMetric(
          event: CacheEvent.miss,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different itemId', () {
        final metric1 = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-1',
          timestamp: testTimestamp,
        );

        final metric2 = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-2',
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different tags', () {
        final metric1 = CacheMetric(
          event: CacheEvent.write,
          tags: {'premium'},
          timestamp: testTimestamp,
        );

        final metric2 = CacheMetric(
          event: CacheEvent.write,
          tags: {'basic'},
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified event', () {
        final original = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'user-1',
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(event: CacheEvent.miss);

        expect(copy.event, equals(CacheEvent.miss));
        expect(copy.itemId, equals(original.itemId));
        expect(copy.timestamp, equals(original.timestamp));
      });

      test('should create copy with modified tags', () {
        final original = CacheMetric(
          event: CacheEvent.write,
          tags: {'tag1'},
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(tags: {'tag2', 'tag3'});

        expect(copy.tags, containsAll(['tag2', 'tag3']));
        expect(copy.tags, isNot(contains('tag1')));
      });

      test('should preserve original when copying', () {
        final original = CacheMetric(
          event: CacheEvent.hit,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(event: CacheEvent.eviction);

        expect(original.event, equals(CacheEvent.hit));
        expect(copy.event, equals(CacheEvent.eviction));
      });
    });

    group('cache hit/miss scenarios', () {
      test('should track cache hit with item id', () {
        final metric = CacheMetric(
          event: CacheEvent.hit,
          itemId: 'product-456',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.hit));
        expect(metric.itemId, equals('product-456'));
      });

      test('should track cache miss', () {
        final metric = CacheMetric(
          event: CacheEvent.miss,
          itemId: 'product-789',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.miss));
        expect(metric.itemId, equals('product-789'));
      });
    });

    group('cache write scenarios', () {
      test('should track single item write', () {
        final metric = CacheMetric(
          event: CacheEvent.write,
          itemId: 'user-1',
          tags: {'users', 'active'},
          timestamp: testTimestamp,
          itemCount: 1,
        );

        expect(metric.event, equals(CacheEvent.write));
        expect(metric.itemCount, equals(1));
        expect(metric.tags, hasLength(2));
      });

      test('should track batch write', () {
        final metric = CacheMetric(
          event: CacheEvent.write,
          tags: {'products'},
          timestamp: testTimestamp,
          itemCount: 100,
        );

        expect(metric.event, equals(CacheEvent.write));
        expect(metric.itemCount, equals(100));
      });
    });

    group('cache invalidation scenarios', () {
      test('should track single item invalidation', () {
        final metric = CacheMetric(
          event: CacheEvent.invalidation,
          itemId: 'order-123',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.invalidation));
        expect(metric.itemId, equals('order-123'));
      });

      test('should track tag-based invalidation', () {
        final metric = CacheMetric(
          event: CacheEvent.invalidation,
          tags: {'orders', 'pending'},
          timestamp: testTimestamp,
          itemCount: 50,
        );

        expect(metric.event, equals(CacheEvent.invalidation));
        expect(metric.tags, containsAll(['orders', 'pending']));
        expect(metric.itemCount, equals(50));
      });
    });

    group('cache eviction scenarios', () {
      test('should track eviction due to size limit', () {
        final metric = CacheMetric(
          event: CacheEvent.eviction,
          itemId: 'old-item-1',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.eviction));
      });

      test('should track batch eviction', () {
        final metric = CacheMetric(
          event: CacheEvent.eviction,
          timestamp: testTimestamp,
          itemCount: 25,
        );

        expect(metric.event, equals(CacheEvent.eviction));
        expect(metric.itemCount, equals(25));
      });
    });

    group('cache expiration scenarios', () {
      test('should track expired item', () {
        final metric = CacheMetric(
          event: CacheEvent.expiration,
          itemId: 'session-xyz',
          timestamp: testTimestamp,
        );

        expect(metric.event, equals(CacheEvent.expiration));
        expect(metric.itemId, equals('session-xyz'));
      });
    });

    group('toString', () {
      test('should include event type', () {
        final metric = CacheMetric(
          event: CacheEvent.hit,
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('hit'));
      });

      test('should include item id when present', () {
        final metric = CacheMetric(
          event: CacheEvent.miss,
          itemId: 'test-id',
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('test-id'));
      });
    });
  });
}
