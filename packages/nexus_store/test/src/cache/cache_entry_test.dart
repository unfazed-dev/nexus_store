import 'package:nexus_store/src/cache/cache_entry.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEntry', () {
    group('construction', () {
      test('should create CacheEntry with required fields', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
        );

        expect(entry.id, equals('user-1'));
        expect(entry.cachedAt, equals(DateTime(2024, 1, 1)));
        expect(entry.tags, isEmpty);
        expect(entry.staleAt, isNull);
      });

      test('should create CacheEntry with tags', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user', 'premium'},
        );

        expect(entry.tags, containsAll(['user', 'premium']));
      });

      test('should create CacheEntry with staleAt', () {
        final staleTime = DateTime(2024, 1, 2);
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          staleAt: staleTime,
        );

        expect(entry.staleAt, equals(staleTime));
      });
    });

    group('isStale', () {
      test('should report isStale when staleAt is in the past', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          staleAt: DateTime(2024, 1, 1, 0, 1), // 1 minute later
        );

        expect(entry.isStale(DateTime(2024, 1, 1, 0, 2)), isTrue);
      });

      test('should report not stale when staleAt is in the future', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          staleAt: DateTime(2024, 1, 2),
        );

        expect(entry.isStale(DateTime(2024, 1, 1, 12, 0)), isFalse);
      });

      test('should report not stale when staleAt is null', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
        );

        expect(entry.isStale(DateTime(2024, 1, 2)), isFalse);
      });

      test('should use current time when now is not provided', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          staleAt: DateTime(2020, 1, 1), // Past date
        );

        expect(entry.isStale(), isTrue);
      });
    });

    group('copyWith', () {
      test('should copy with modified tags', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user'},
        );

        final updated = entry.copyWith(tags: {'user', 'admin'});

        expect(updated.tags, containsAll(['user', 'admin']));
        expect(entry.tags, equals({'user'})); // Original unchanged
      });

      test('should copy with modified staleAt', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
        );

        final newStaleAt = DateTime(2024, 1, 2);
        final updated = entry.copyWith(staleAt: newStaleAt);

        expect(updated.staleAt, equals(newStaleAt));
        expect(entry.staleAt, isNull); // Original unchanged
      });

      test('should preserve other fields when not specified', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user'},
          staleAt: DateTime(2024, 1, 2),
        );

        final updated = entry.copyWith(tags: {'admin'});

        expect(updated.id, equals('user-1'));
        expect(updated.cachedAt, equals(DateTime(2024, 1, 1)));
        expect(updated.staleAt, equals(DateTime(2024, 1, 2)));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final entry1 = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user'},
        );
        final entry2 = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user'},
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('should not be equal when id differs', () {
        final entry1 = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
        );
        final entry2 = CacheEntry<String>(
          id: 'user-2',
          cachedAt: DateTime(2024, 1, 1),
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('should not be equal when tags differ', () {
        final entry1 = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'user'},
        );
        final entry2 = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
          tags: {'admin'},
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('markStale', () {
      test('should mark entry as immediately stale', () {
        final entry = CacheEntry<String>(
          id: 'user-1',
          cachedAt: DateTime(2024, 1, 1),
        );

        final stale = entry.markStale();

        expect(stale.isStale(), isTrue);
        expect(stale.staleAt, isNotNull);
      });
    });
  });
}
