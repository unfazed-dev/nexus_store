import 'package:test/test.dart';
import 'package:nexus_store/src/cache/lru_tracker.dart';

void main() {
  group('LruTracker', () {
    late LruTracker<String> tracker;

    setUp(() {
      tracker = LruTracker<String>();
    });

    group('recordAccess', () {
      test('adds new entry on first access', () {
        tracker.recordAccess('item1', size: 100);
        expect(tracker.contains('item1'), isTrue);
        expect(tracker.itemCount, equals(1));
      });

      test('updates access time on subsequent access', () async {
        tracker.recordAccess('item1', size: 100);
        final firstTime = tracker.getLastAccessTime('item1');

        await Future.delayed(Duration(milliseconds: 10));

        tracker.recordAccess('item1', size: 100);
        final secondTime = tracker.getLastAccessTime('item1');

        expect(secondTime!.isAfter(firstTime!), isTrue);
      });

      test('increments access count on each access', () {
        tracker.recordAccess('item1', size: 100);
        expect(tracker.getAccessCount('item1'), equals(1));

        tracker.recordAccess('item1', size: 100);
        expect(tracker.getAccessCount('item1'), equals(2));

        tracker.recordAccess('item1', size: 100);
        expect(tracker.getAccessCount('item1'), equals(3));
      });

      test('updates size on access', () {
        tracker.recordAccess('item1', size: 100);
        expect(tracker.getSize('item1'), equals(100));

        tracker.recordAccess('item1', size: 150);
        expect(tracker.getSize('item1'), equals(150));
      });
    });

    group('remove', () {
      test('removes existing entry', () {
        tracker.recordAccess('item1', size: 100);
        expect(tracker.contains('item1'), isTrue);

        tracker.remove('item1');
        expect(tracker.contains('item1'), isFalse);
        expect(tracker.itemCount, equals(0));
      });

      test('does nothing for non-existent entry', () {
        tracker.recordAccess('item1', size: 100);
        tracker.remove('nonexistent');
        expect(tracker.itemCount, equals(1));
      });
    });

    group('getEvictionCandidatesLru', () {
      test('returns items in LRU order', () async {
        tracker.recordAccess('item1', size: 100);
        await Future.delayed(Duration(milliseconds: 5));
        tracker.recordAccess('item2', size: 100);
        await Future.delayed(Duration(milliseconds: 5));
        tracker.recordAccess('item3', size: 100);

        final candidates = tracker.getEvictionCandidatesLru(2);

        expect(candidates, hasLength(2));
        expect(candidates[0], equals('item1'));
        expect(candidates[1], equals('item2'));
      });

      test('excludes pinned items', () async {
        tracker.recordAccess('item1', size: 100);
        await Future.delayed(Duration(milliseconds: 5));
        tracker.recordAccess('item2', size: 100);
        await Future.delayed(Duration(milliseconds: 5));
        tracker.recordAccess('item3', size: 100);

        final candidates = tracker.getEvictionCandidatesLru(
          2,
          excludeIds: {'item1'},
        );

        expect(candidates, hasLength(2));
        expect(candidates[0], equals('item2'));
        expect(candidates[1], equals('item3'));
      });

      test('returns fewer items if not enough available', () {
        tracker.recordAccess('item1', size: 100);

        final candidates = tracker.getEvictionCandidatesLru(5);

        expect(candidates, hasLength(1));
      });
    });

    group('getEvictionCandidatesLfu', () {
      test('returns items in LFU order (least frequently used first)', () {
        // Access item1 once
        tracker.recordAccess('item1', size: 100);
        // Access item2 twice
        tracker.recordAccess('item2', size: 100);
        tracker.recordAccess('item2', size: 100);
        // Access item3 three times
        tracker.recordAccess('item3', size: 100);
        tracker.recordAccess('item3', size: 100);
        tracker.recordAccess('item3', size: 100);

        final candidates = tracker.getEvictionCandidatesLfu(2);

        expect(candidates, hasLength(2));
        expect(candidates[0], equals('item1')); // 1 access
        expect(candidates[1], equals('item2')); // 2 accesses
      });

      test('excludes pinned items', () {
        tracker.recordAccess('item1', size: 100);
        tracker.recordAccess('item2', size: 100);
        tracker.recordAccess('item2', size: 100);
        tracker.recordAccess('item3', size: 100);

        final candidates = tracker.getEvictionCandidatesLfu(
          2,
          excludeIds: {'item1'},
        );

        expect(candidates, hasLength(2));
        expect(candidates.contains('item1'), isFalse);
      });
    });

    group('getEvictionCandidatesBySize', () {
      test('returns items in size order (largest first)', () {
        tracker.recordAccess('small', size: 100);
        tracker.recordAccess('medium', size: 500);
        tracker.recordAccess('large', size: 1000);

        final candidates = tracker.getEvictionCandidatesBySize(2);

        expect(candidates, hasLength(2));
        expect(candidates[0], equals('large'));
        expect(candidates[1], equals('medium'));
      });

      test('excludes pinned items', () {
        tracker.recordAccess('small', size: 100);
        tracker.recordAccess('medium', size: 500);
        tracker.recordAccess('large', size: 1000);

        final candidates = tracker.getEvictionCandidatesBySize(
          2,
          excludeIds: {'large'},
        );

        expect(candidates, hasLength(2));
        expect(candidates[0], equals('medium'));
        expect(candidates[1], equals('small'));
      });
    });

    group('totalSize', () {
      test('returns sum of all item sizes', () {
        tracker.recordAccess('item1', size: 100);
        tracker.recordAccess('item2', size: 200);
        tracker.recordAccess('item3', size: 300);

        expect(tracker.totalSize, equals(600));
      });

      test('returns 0 when empty', () {
        expect(tracker.totalSize, equals(0));
      });

      test('updates when items are removed', () {
        tracker.recordAccess('item1', size: 100);
        tracker.recordAccess('item2', size: 200);
        expect(tracker.totalSize, equals(300));

        tracker.remove('item1');
        expect(tracker.totalSize, equals(200));
      });
    });

    group('clear', () {
      test('removes all entries', () {
        tracker.recordAccess('item1', size: 100);
        tracker.recordAccess('item2', size: 200);
        expect(tracker.itemCount, equals(2));

        tracker.clear();
        expect(tracker.itemCount, equals(0));
        expect(tracker.totalSize, equals(0));
      });
    });

    group('allIds', () {
      test('returns all tracked IDs', () {
        tracker.recordAccess('item1', size: 100);
        tracker.recordAccess('item2', size: 200);
        tracker.recordAccess('item3', size: 300);

        final ids = tracker.allIds;
        expect(ids, containsAll(['item1', 'item2', 'item3']));
        expect(ids, hasLength(3));
      });
    });
  });
}
