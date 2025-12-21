import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:test/test.dart';

void main() {
  group('PageInfo', () {
    group('construction', () {
      test('creates PageInfo with all fields', () {
        final startCursor = Cursor.fromValues({'id': 'first'});
        final endCursor = Cursor.fromValues({'id': 'last'});

        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: startCursor,
          endCursor: endCursor,
          totalCount: 100,
        );

        expect(pageInfo.hasNextPage, isTrue);
        expect(pageInfo.hasPreviousPage, isFalse);
        expect(pageInfo.startCursor, equals(startCursor));
        expect(pageInfo.endCursor, equals(endCursor));
        expect(pageInfo.totalCount, equals(100));
      });

      test('creates PageInfo with required fields only', () {
        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );

        expect(pageInfo.hasNextPage, isTrue);
        expect(pageInfo.hasPreviousPage, isFalse);
        expect(pageInfo.startCursor, isNull);
        expect(pageInfo.endCursor, isNull);
        expect(pageInfo.totalCount, isNull);
      });

      test('creates PageInfo with no more pages', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
        );

        expect(pageInfo.hasNextPage, isFalse);
        expect(pageInfo.hasPreviousPage, isFalse);
      });

      test('creates PageInfo with cursors but no total', () {
        final startCursor = Cursor.fromValues({'id': 'first'});
        final endCursor = Cursor.fromValues({'id': 'last'});

        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: startCursor,
          endCursor: endCursor,
        );

        expect(pageInfo.startCursor, equals(startCursor));
        expect(pageInfo.endCursor, equals(endCursor));
        expect(pageInfo.totalCount, isNull);
      });
    });

    group('empty factory', () {
      test('creates empty PageInfo with no pages', () {
        final pageInfo = PageInfo.empty();

        expect(pageInfo.hasNextPage, isFalse);
        expect(pageInfo.hasPreviousPage, isFalse);
        expect(pageInfo.startCursor, isNull);
        expect(pageInfo.endCursor, isNull);
        expect(pageInfo.totalCount, isNull);
      });
    });

    group('isEmpty', () {
      test('returns true when no cursors present', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
        );

        expect(pageInfo.isEmpty, isTrue);
      });

      test('returns false when startCursor present', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: Cursor.fromValues({'id': 'first'}),
        );

        expect(pageInfo.isEmpty, isFalse);
      });

      test('returns false when endCursor present', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: Cursor.fromValues({'id': 'last'}),
        );

        expect(pageInfo.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('returns false when no cursors present', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
        );

        expect(pageInfo.isNotEmpty, isFalse);
      });

      test('returns true when cursors present', () {
        final pageInfo = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: Cursor.fromValues({'id': 'first'}),
          endCursor: Cursor.fromValues({'id': 'last'}),
        );

        expect(pageInfo.isNotEmpty, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated hasNextPage', () {
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );
        final copy = original.copyWith(hasNextPage: false);

        expect(copy.hasNextPage, isFalse);
        expect(copy.hasPreviousPage, isFalse);
      });

      test('creates copy with updated hasPreviousPage', () {
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );
        final copy = original.copyWith(hasPreviousPage: true);

        expect(copy.hasNextPage, isTrue);
        expect(copy.hasPreviousPage, isTrue);
      });

      test('creates copy with updated cursors', () {
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );
        final newStart = Cursor.fromValues({'id': 'new-start'});
        final newEnd = Cursor.fromValues({'id': 'new-end'});
        final copy = original.copyWith(
          startCursor: newStart,
          endCursor: newEnd,
        );

        expect(copy.startCursor, equals(newStart));
        expect(copy.endCursor, equals(newEnd));
      });

      test('creates copy with updated totalCount', () {
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );
        final copy = original.copyWith(totalCount: 200);

        expect(copy.totalCount, equals(200));
      });

      test('original is unchanged', () {
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );
        original.copyWith(totalCount: 200);

        expect(original.totalCount, equals(100));
      });

      test('preserves fields not specified in copyWith', () {
        final startCursor = Cursor.fromValues({'id': 'first'});
        final endCursor = Cursor.fromValues({'id': 'last'});
        final original = PageInfo(
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: startCursor,
          endCursor: endCursor,
          totalCount: 100,
        );
        final copy = original.copyWith(hasNextPage: false);

        expect(copy.hasNextPage, isFalse);
        expect(copy.hasPreviousPage, isTrue);
        expect(copy.startCursor, equals(startCursor));
        expect(copy.endCursor, equals(endCursor));
        expect(copy.totalCount, equals(100));
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final startCursor = Cursor.fromValues({'id': 'first'});
        final endCursor = Cursor.fromValues({'id': 'last'});

        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: startCursor,
          endCursor: endCursor,
          totalCount: 100,
        );

        final pageInfo2 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: Cursor.fromValues({'id': 'first'}),
          endCursor: Cursor.fromValues({'id': 'last'}),
          totalCount: 100,
        );

        expect(pageInfo1, equals(pageInfo2));
      });

      test('not equal when hasNextPage differs', () {
        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );
        final pageInfo2 = PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
        );

        expect(pageInfo1, isNot(equals(pageInfo2)));
      });

      test('not equal when hasPreviousPage differs', () {
        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: true,
        );
        final pageInfo2 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );

        expect(pageInfo1, isNot(equals(pageInfo2)));
      });

      test('not equal when totalCount differs', () {
        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );
        final pageInfo2 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 200,
        );

        expect(pageInfo1, isNot(equals(pageInfo2)));
      });

      test('not equal when cursors differ', () {
        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: Cursor.fromValues({'id': 'first'}),
        );
        final pageInfo2 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: Cursor.fromValues({'id': 'second'}),
        );

        expect(pageInfo1, isNot(equals(pageInfo2)));
      });
    });

    group('hashCode', () {
      test('equal PageInfos have equal hashCode', () {
        final pageInfo1 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );
        final pageInfo2 = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );

        expect(pageInfo1.hashCode, equals(pageInfo2.hashCode));
      });

      test('can be used in sets', () {
        final pageInfo1 = PageInfo(hasNextPage: true, hasPreviousPage: false);
        final pageInfo2 = PageInfo(hasNextPage: true, hasPreviousPage: false);
        final pageInfo3 = PageInfo(hasNextPage: false, hasPreviousPage: false);

        final set = {pageInfo1, pageInfo2, pageInfo3};
        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          totalCount: 100,
        );
        final str = pageInfo.toString();

        expect(str, contains('PageInfo'));
        expect(str, contains('hasNextPage: true'));
        expect(str, contains('hasPreviousPage: false'));
      });
    });
  });
}
