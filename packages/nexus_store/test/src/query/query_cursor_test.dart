import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

void main() {
  group('Query cursor extensions', () {
    group('after', () {
      test('sets afterCursor field', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().after(cursor);

        expect(query.afterCursor, equals(cursor));
      });

      test('preserves existing query properties', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .orderByField('name')
            .after(cursor);

        expect(query.afterCursor, equals(cursor));
        expect(query.filters, hasLength(1));
        expect(query.orderBy, hasLength(1));
      });

      test('original query is unchanged (immutability)', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final original = const Query<String>();
        original.after(cursor);

        expect(original.afterCursor, isNull);
      });

      test('can be chained with other methods', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query =
            const Query<String>().after(cursor).first(10).orderByField('name');

        expect(query.afterCursor, equals(cursor));
        expect(query.firstCount, equals(10));
        expect(query.orderBy, hasLength(1));
      });
    });

    group('before', () {
      test('sets beforeCursor field', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().before(cursor);

        expect(query.beforeCursor, equals(cursor));
      });

      test('preserves existing query properties', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .orderByField('name')
            .before(cursor);

        expect(query.beforeCursor, equals(cursor));
        expect(query.filters, hasLength(1));
        expect(query.orderBy, hasLength(1));
      });

      test('original query is unchanged (immutability)', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final original = const Query<String>();
        original.before(cursor);

        expect(original.beforeCursor, isNull);
      });
    });

    group('first', () {
      test('sets first count', () {
        final query = const Query<String>().first(20);

        expect(query.firstCount, equals(20));
      });

      test('can be combined with after cursor', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().after(cursor).first(10);

        expect(query.afterCursor, equals(cursor));
        expect(query.firstCount, equals(10));
      });

      test('throws assertion error for non-positive count', () {
        expect(
          () => const Query<String>().first(0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => const Query<String>().first(-1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('original query is unchanged (immutability)', () {
        final original = const Query<String>();
        original.first(10);

        expect(original.firstCount, isNull);
      });
    });

    group('last', () {
      test('sets last count', () {
        final query = const Query<String>().last(20);

        expect(query.lastCount, equals(20));
      });

      test('can be combined with before cursor', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().before(cursor).last(10);

        expect(query.beforeCursor, equals(cursor));
        expect(query.lastCount, equals(10));
      });

      test('throws assertion error for non-positive count', () {
        expect(
          () => const Query<String>().last(0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => const Query<String>().last(-1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('original query is unchanged (immutability)', () {
        final original = const Query<String>();
        original.last(10);

        expect(original.lastCount, isNull);
      });
    });

    group('cursor field accessors', () {
      test('afterCursor is null by default', () {
        expect(const Query<String>().afterCursor, isNull);
      });

      test('beforeCursor is null by default', () {
        expect(const Query<String>().beforeCursor, isNull);
      });

      test('firstCount is null by default', () {
        expect(const Query<String>().firstCount, isNull);
      });

      test('lastCount is null by default', () {
        expect(const Query<String>().lastCount, isNull);
      });
    });

    group('interaction with limit/offset', () {
      test('first is independent of limit', () {
        final query = const Query<String>().first(10).limitTo(20);

        expect(query.firstCount, equals(10));
        expect(query.limit, equals(20));
      });

      test('last is independent of limit', () {
        final query = const Query<String>().last(10).limitTo(20);

        expect(query.lastCount, equals(10));
        expect(query.limit, equals(20));
      });
    });

    group('copyWith', () {
      test('copies cursor fields', () {
        final cursor1 = Cursor.fromValues({'id': '1'});
        final cursor2 = Cursor.fromValues({'id': '2'});
        final query = const Query<String>()
            .after(cursor1)
            .before(cursor2)
            .first(10)
            .last(5);

        final copy = query.copyWith();

        expect(copy.afterCursor, equals(cursor1));
        expect(copy.beforeCursor, equals(cursor2));
        expect(copy.firstCount, equals(10));
        expect(copy.lastCount, equals(5));
      });

      test('can override cursor fields', () {
        final original = const Query<String>().first(10);
        final newCursor = Cursor.fromValues({'id': 'new'});

        final copy = original.copyWith(
          afterCursor: newCursor,
          first: 20,
        );

        expect(copy.afterCursor, equals(newCursor));
        expect(copy.firstCount, equals(20));
      });
    });

    group('equality', () {
      test('queries with same cursor fields are equal', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query1 = const Query<String>().after(cursor).first(10);
        final query2 = const Query<String>().after(cursor).first(10);

        expect(query1, equals(query2));
      });

      test('queries with different cursor fields are not equal', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-456'});
        final query1 = const Query<String>().after(cursor1);
        final query2 = const Query<String>().after(cursor2);

        expect(query1, isNot(equals(query2)));
      });

      test('queries with different first counts are not equal', () {
        final query1 = const Query<String>().first(10);
        final query2 = const Query<String>().first(20);

        expect(query1, isNot(equals(query2)));
      });
    });

    group('hashCode', () {
      test('equal queries have equal hashCode', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query1 = const Query<String>().after(cursor).first(10);
        final query2 = const Query<String>().after(cursor).first(10);

        expect(query1.hashCode, equals(query2.hashCode));
      });
    });

    group('toString', () {
      test('includes cursor fields in string representation', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().after(cursor).first(10);
        final str = query.toString();

        expect(str, contains('Query'));
        expect(str, contains('first: 10'));
      });
    });

    group('isEmpty', () {
      test('query with only cursor fields is not empty', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>().after(cursor);

        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('query with only first is not empty', () {
        final query = const Query<String>().first(10);

        expect(query.isEmpty, isFalse);
      });
    });

    group('complex scenarios', () {
      test('pagination pattern: first page', () {
        final query = const Query<String>()
            .orderByField('createdAt', descending: true)
            .first(20);

        expect(query.firstCount, equals(20));
        expect(query.afterCursor, isNull);
        expect(query.orderBy.first.field, equals('createdAt'));
      });

      test('pagination pattern: next page', () {
        final cursor = Cursor.fromValues({
          'createdAt': '2024-01-15T10:30:00Z',
          'id': 'user-123',
        });
        final query = const Query<String>()
            .orderByField('createdAt', descending: true)
            .after(cursor)
            .first(20);

        expect(query.firstCount, equals(20));
        expect(query.afterCursor, equals(cursor));
      });

      test('pagination pattern: previous page', () {
        final cursor = Cursor.fromValues({
          'createdAt': '2024-01-15T10:30:00Z',
          'id': 'user-123',
        });
        final query = const Query<String>()
            .orderByField('createdAt', descending: true)
            .before(cursor)
            .last(20);

        expect(query.lastCount, equals(20));
        expect(query.beforeCursor, equals(cursor));
      });

      test('full query with filters and pagination', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .where('role', whereIn: ['admin', 'moderator'])
            .orderByField('name')
            .after(cursor)
            .first(50);

        expect(query.filters, hasLength(2));
        expect(query.orderBy, hasLength(1));
        expect(query.afterCursor, equals(cursor));
        expect(query.firstCount, equals(50));
      });
    });
  });
}
