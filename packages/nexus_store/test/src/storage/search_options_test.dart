import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('SearchOptions', () {
    test('constructs with defaults', () {
      const options = SearchOptions();

      expect(options.limit, 100);
      expect(options.offset, 0);
      expect(options.sortBy, isNull);
      expect(options.search, isNull);
    });

    test('constructs with all fields', () {
      const options = SearchOptions(
        limit: 50,
        offset: 10,
        sortBy: SortBy(column: 'name', order: SortOrder.asc),
        search: 'photo',
      );

      expect(options.limit, 50);
      expect(options.offset, 10);
      expect(options.sortBy!.column, 'name');
      expect(options.sortBy!.order, SortOrder.asc);
      expect(options.search, 'photo');
    });

    test('equality compares all fields', () {
      const a = SearchOptions(limit: 50, search: 'photo');
      const b = SearchOptions(limit: 50, search: 'photo');
      const c = SearchOptions(limit: 100, search: 'doc');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on later fields', () {
      const a = SearchOptions(
        limit: 50,
        offset: 10,
        sortBy: SortBy(column: 'name', order: SortOrder.asc),
        search: 'photo',
      );
      const diffOffset = SearchOptions(
        limit: 50,
        offset: 20,
        sortBy: SortBy(column: 'name', order: SortOrder.asc),
        search: 'photo',
      );
      const diffSortBy = SearchOptions(
        limit: 50,
        offset: 10,
        sortBy: SortBy(column: 'size', order: SortOrder.desc),
        search: 'photo',
      );
      const diffSearch = SearchOptions(
        limit: 50,
        offset: 10,
        sortBy: SortBy(column: 'name', order: SortOrder.asc),
        search: 'doc',
      );
      expect(a, isNot(equals(diffOffset)));
      expect(a, isNot(equals(diffSortBy)));
      expect(a, isNot(equals(diffSearch)));
    });

    test('toString includes all fields', () {
      const options = SearchOptions(limit: 50, search: 'photo');
      final str = options.toString();
      expect(str, contains('SearchOptions'));
      expect(str, contains('50'));
    });
  });

  group('SortBy', () {
    test('constructs with required fields', () {
      const sortBy = SortBy(column: 'created_at', order: SortOrder.desc);

      expect(sortBy.column, 'created_at');
      expect(sortBy.order, SortOrder.desc);
    });

    test('equality compares all fields', () {
      const a = SortBy(column: 'name', order: SortOrder.asc);
      const b = SortBy(column: 'name', order: SortOrder.asc);
      const c = SortBy(column: 'name', order: SortOrder.desc);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes fields', () {
      const sortBy = SortBy(column: 'name', order: SortOrder.asc);
      expect(sortBy.toString(), contains('SortBy'));
      expect(sortBy.toString(), contains('name'));
    });
  });

  group('SortOrder', () {
    test('has expected values', () {
      expect(SortOrder.values, containsAll([SortOrder.asc, SortOrder.desc]));
    });
  });
}
