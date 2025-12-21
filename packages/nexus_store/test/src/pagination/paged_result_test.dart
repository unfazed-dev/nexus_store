import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:test/test.dart';

void main() {
  group('PagedResult', () {
    group('construction', () {
      test('creates PagedResult with items and pageInfo', () {
        final items = ['a', 'b', 'c'];
        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );

        final result = PagedResult<String>(
          items: items,
          pageInfo: pageInfo,
        );

        expect(result.items, equals(['a', 'b', 'c']));
        expect(result.pageInfo, equals(pageInfo));
      });

      test('creates PagedResult with empty items', () {
        final result = PagedResult<String>(
          items: [],
          pageInfo: PageInfo(
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );

        expect(result.items, isEmpty);
      });

      test('items list is unmodifiable', () {
        final mutableList = ['a', 'b', 'c'];
        final result = PagedResult<String>(
          items: mutableList,
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        // Original list modification doesn't affect result
        mutableList.add('d');
        expect(result.items.length, equals(3));

        // Result items can't be modified
        expect(() => result.items.add('e'), throwsA(anything));
      });
    });

    group('empty factory', () {
      test('creates empty PagedResult', () {
        final result = PagedResult<String>.empty();

        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
        expect(result.nextCursor, isNull);
        expect(result.previousCursor, isNull);
      });
    });

    group('convenience getters', () {
      test('hasMore delegates to pageInfo.hasNextPage', () {
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        expect(result.hasMore, isTrue);
      });

      test('hasMore returns false when no more pages', () {
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.hasMore, isFalse);
      });

      test('nextCursor delegates to pageInfo.endCursor', () {
        final cursor = Cursor.fromValues({'id': 'last'});
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(
            hasNextPage: true,
            hasPreviousPage: false,
            endCursor: cursor,
          ),
        );

        expect(result.nextCursor, equals(cursor));
      });

      test('previousCursor delegates to pageInfo.startCursor', () {
        final cursor = Cursor.fromValues({'id': 'first'});
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(
            hasNextPage: false,
            hasPreviousPage: true,
            startCursor: cursor,
          ),
        );

        expect(result.previousCursor, equals(cursor));
      });

      test('totalCount delegates to pageInfo.totalCount', () {
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(
            hasNextPage: false,
            hasPreviousPage: false,
            totalCount: 100,
          ),
        );

        expect(result.totalCount, equals(100));
      });
    });

    group('isEmpty', () {
      test('returns true when items is empty', () {
        final result = PagedResult<String>(
          items: [],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.isEmpty, isTrue);
      });

      test('returns false when items is not empty', () {
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('returns false when items is empty', () {
        final result = PagedResult<String>(
          items: [],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.isNotEmpty, isFalse);
      });

      test('returns true when items is not empty', () {
        final result = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.isNotEmpty, isTrue);
      });
    });

    group('length', () {
      test('returns number of items', () {
        final result = PagedResult<String>(
          items: ['a', 'b', 'c'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.length, equals(3));
      });

      test('returns 0 for empty result', () {
        final result = PagedResult<String>.empty();
        expect(result.length, equals(0));
      });
    });

    group('map', () {
      test('transforms items preserving pageInfo', () {
        final original = PagedResult<int>(
          items: [1, 2, 3],
          pageInfo: PageInfo(
            hasNextPage: true,
            hasPreviousPage: false,
            totalCount: 100,
          ),
        );

        final mapped = original.map((n) => n * 2);

        expect(mapped.items, equals([2, 4, 6]));
        expect(mapped.pageInfo, equals(original.pageInfo));
      });

      test('mapped result has correct type', () {
        final original = PagedResult<int>(
          items: [1, 2, 3],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        final mapped = original.map((n) => n.toString());

        expect(mapped, isA<PagedResult<String>>());
        expect(mapped.items, equals(['1', '2', '3']));
      });
    });

    group('copyWith', () {
      test('creates copy with new items', () {
        final original = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final copy = original.copyWith(items: ['c', 'd', 'e']);

        expect(copy.items, equals(['c', 'd', 'e']));
        expect(copy.pageInfo, equals(original.pageInfo));
      });

      test('creates copy with new pageInfo', () {
        final original = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final newPageInfo = PageInfo(hasNextPage: false, hasPreviousPage: true);
        final copy = original.copyWith(pageInfo: newPageInfo);

        expect(copy.items, equals(original.items));
        expect(copy.pageInfo, equals(newPageInfo));
      });

      test('original is unchanged', () {
        final original = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        original.copyWith(items: ['x', 'y', 'z']);

        expect(original.items, equals(['a', 'b']));
      });
    });

    group('equality', () {
      test('equal when items and pageInfo match', () {
        final result1 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        expect(result1, equals(result2));
      });

      test('not equal when items differ', () {
        final result1 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a', 'c'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        expect(result1, isNot(equals(result2)));
      });

      test('not equal when pageInfo differs', () {
        final result1 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result1, isNot(equals(result2)));
      });

      test('not equal when item count differs', () {
        final result1 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a', 'b', 'c'],
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result1, isNot(equals(result2)));
      });
    });

    group('hashCode', () {
      test('equal PagedResults have equal hashCode', () {
        final result1 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('can be used in sets', () {
        final result1 = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result2 = PagedResult<String>(
          items: ['a'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        final result3 = PagedResult<String>(
          items: ['b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final set = {result1, result2, result3};
        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final result = PagedResult<String>(
          items: ['a', 'b'],
          pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final str = result.toString();

        expect(str, contains('PagedResult'));
        expect(str, contains('2 items'));
      });
    });

    group('type safety', () {
      test('works with custom types', () {
        final users = [
          _TestUser('1', 'Alice'),
          _TestUser('2', 'Bob'),
        ];

        final result = PagedResult<_TestUser>(
          items: users,
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        expect(result.items.first.name, equals('Alice'));
        expect(result.items.last.name, equals('Bob'));
      });

      test('map converts between types', () {
        final users = [
          _TestUser('1', 'Alice'),
          _TestUser('2', 'Bob'),
        ];

        final result = PagedResult<_TestUser>(
          items: users,
          pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false),
        );

        final names = result.map((u) => u.name);

        expect(names, isA<PagedResult<String>>());
        expect(names.items, equals(['Alice', 'Bob']));
      });
    });
  });
}

class _TestUser {
  _TestUser(this.id, this.name);
  final String id;
  final String name;
}
