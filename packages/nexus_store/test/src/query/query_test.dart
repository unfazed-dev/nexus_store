import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Query', () {
    group('constructor', () {
      test('should create empty query', () {
        const query = Query<String>();
        expect(query.isEmpty, isTrue);
        expect(query.filters, isEmpty);
        expect(query.orderBy, isEmpty);
        expect(query.limit, isNull);
        expect(query.offset, isNull);
      });
    });

    group('where', () {
      test('should add equality filter with isEqualTo', () {
        final query = const Query<String>().where(
          'status',
          isEqualTo: 'active',
        );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, equals('status'));
        expect(query.filters.first.operator, equals(FilterOperator.equals));
        expect(query.filters.first.value, equals('active'));
      });

      test('should add filter with isNotEqualTo', () {
        final query = const Query<String>().where(
          'status',
          isNotEqualTo: 'deleted',
        );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.notEquals));
        expect(query.filters.first.value, equals('deleted'));
      });

      test('should add filter with isLessThan', () {
        final query = const Query<String>().where(
          'age',
          isLessThan: 18,
        );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.lessThan));
        expect(query.filters.first.value, equals(18));
      });

      test('should add filter with isLessThanOrEqualTo', () {
        final query = const Query<String>().where(
          'age',
          isLessThanOrEqualTo: 65,
        );

        expect(query.filters, hasLength(1));
        expect(
          query.filters.first.operator,
          equals(FilterOperator.lessThanOrEquals),
        );
      });

      test('should add filter with isGreaterThan', () {
        final query = const Query<String>().where('price', isGreaterThan: 100);

        expect(query.filters, hasLength(1));
        expect(
          query.filters.first.operator,
          equals(FilterOperator.greaterThan),
        );
      });

      test('should add filter with isGreaterThanOrEqualTo', () {
        final query = const Query<String>().where(
          'price',
          isGreaterThanOrEqualTo: 0,
        );

        expect(query.filters, hasLength(1));
        expect(
          query.filters.first.operator,
          equals(FilterOperator.greaterThanOrEquals),
        );
      });

      test('should add filter with arrayContains', () {
        final query = const Query<String>().where(
          'tags',
          arrayContains: 'featured',
        );

        expect(query.filters, hasLength(1));
        expect(
          query.filters.first.operator,
          equals(FilterOperator.arrayContains),
        );
      });

      test('should add filter with arrayContainsAny', () {
        final query = const Query<String>().where(
          'tags',
          arrayContainsAny: ['featured', 'popular'],
        );

        expect(query.filters, hasLength(1));
        expect(
          query.filters.first.operator,
          equals(FilterOperator.arrayContainsAny),
        );
      });

      test('should add filter with whereIn', () {
        final query = const Query<String>().where(
          'status',
          whereIn: ['active', 'pending'],
        );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.whereIn));
      });

      test('should add filter with whereNotIn', () {
        final query = const Query<String>().where(
          'status',
          whereNotIn: ['deleted', 'archived'],
        );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.whereNotIn));
      });

      test('should add filter with isNull true', () {
        final query = const Query<String>().where('deletedAt', isNull: true);

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.isNull));
      });

      test('should add filter with isNull false (isNotNull)', () {
        final query = const Query<String>().where('email', isNull: false);

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, equals(FilterOperator.isNotNull));
      });

      test('should support multiple where conditions (AND)', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .where('age', isGreaterThan: 18);

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, equals('status'));
        expect(query.filters[1].field, equals('age'));
      });

      test('should return new instance (immutability)', () {
        const original = Query<String>();
        final modified = original.where('field', isEqualTo: 'value');

        expect(original.filters, isEmpty);
        expect(modified.filters, hasLength(1));
        expect(identical(original, modified), isFalse);
      });
    });

    group('orderByField', () {
      test('should add ascending order by default', () {
        final query = const Query<String>().orderByField('createdAt');

        expect(query.orderBy, hasLength(1));
        expect(query.orderBy.first.field, equals('createdAt'));
        expect(query.orderBy.first.descending, isFalse);
      });

      test('should add descending order when specified', () {
        final query = const Query<String>().orderByField(
          'createdAt',
          descending: true,
        );

        expect(query.orderBy, hasLength(1));
        expect(query.orderBy.first.descending, isTrue);
      });

      test('should support multiple orderBy conditions', () {
        final query = const Query<String>()
            .orderByField('status')
            .orderByField('createdAt', descending: true);

        expect(query.orderBy, hasLength(2));
        expect(query.orderBy[0].field, equals('status'));
        expect(query.orderBy[0].descending, isFalse);
        expect(query.orderBy[1].field, equals('createdAt'));
        expect(query.orderBy[1].descending, isTrue);
      });

      test('should return new instance (immutability)', () {
        const original = Query<String>();
        final modified = original.orderByField('field');

        expect(original.orderBy, isEmpty);
        expect(modified.orderBy, hasLength(1));
        expect(identical(original, modified), isFalse);
      });
    });

    group('limitTo', () {
      test('should set limit', () {
        final query = const Query<String>().limitTo(10);

        expect(query.limit, equals(10));
      });

      test('should throw assertion error when limit is zero', () {
        expect(
          () => const Query<String>().limitTo(0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw assertion error when limit is negative', () {
        expect(
          () => const Query<String>().limitTo(-1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should return new instance (immutability)', () {
        const original = Query<String>();
        final modified = original.limitTo(10);

        expect(original.limit, isNull);
        expect(modified.limit, equals(10));
        expect(identical(original, modified), isFalse);
      });
    });

    group('offsetBy', () {
      test('should set offset', () {
        final query = const Query<String>().offsetBy(20);

        expect(query.offset, equals(20));
      });

      test('should allow zero offset', () {
        final query = const Query<String>().offsetBy(0);

        expect(query.offset, equals(0));
      });

      test('should throw assertion error when offset is negative', () {
        expect(
          () => const Query<String>().offsetBy(-1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should return new instance (immutability)', () {
        const original = Query<String>();
        final modified = original.offsetBy(10);

        expect(original.offset, isNull);
        expect(modified.offset, equals(10));
        expect(identical(original, modified), isFalse);
      });
    });

    group('pagination', () {
      test('should combine limit and offset for pagination', () {
        final query = const Query<String>().limitTo(10).offsetBy(20);

        expect(query.limit, equals(10));
        expect(query.offset, equals(20));
      });
    });

    group('isEmpty/isNotEmpty', () {
      test('should return isEmpty true for empty query', () {
        const query = Query<String>();
        expect(query.isEmpty, isTrue);
        expect(query.isNotEmpty, isFalse);
      });

      test('should return isNotEmpty true when has filters', () {
        final query = const Query<String>().where('field', isEqualTo: 'value');
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('should return isNotEmpty true when has orderBy', () {
        final query = const Query<String>().orderByField('field');
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('should return isNotEmpty true when has limit', () {
        final query = const Query<String>().limitTo(10);
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('should return isNotEmpty true when has offset', () {
        final query = const Query<String>().offsetBy(10);
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with new filters', () {
        final original = const Query<String>().where('a', isEqualTo: 1);
        final modified = original.copyWith(
          filters: [
            const QueryFilter(
              field: 'b',
              operator: FilterOperator.equals,
              value: 2,
            ),
          ],
        );

        expect(original.filters.first.field, equals('a'));
        expect(modified.filters.first.field, equals('b'));
      });

      test('should preserve unchanged values', () {
        final original = const Query<String>()
            .where('field', isEqualTo: 'value')
            .orderByField('field')
            .limitTo(10);
        final modified = original.copyWith(offset: 5);

        expect(modified.filters, hasLength(1));
        expect(modified.orderBy, hasLength(1));
        expect(modified.limit, equals(10));
        expect(modified.offset, equals(5));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final query1 = const Query<String>()
            .where('field', isEqualTo: 'value')
            .orderByField('field')
            .limitTo(10);
        final query2 = const Query<String>()
            .where('field', isEqualTo: 'value')
            .orderByField('field')
            .limitTo(10);

        expect(query1, equals(query2));
      });

      test('should not be equal when filters differ', () {
        final query1 = const Query<String>().where('a', isEqualTo: 1);
        final query2 = const Query<String>().where('b', isEqualTo: 2);

        expect(query1, isNot(equals(query2)));
      });

      test('should not be equal when orderBy differs', () {
        final query1 = const Query<String>().orderByField('a');
        final query2 = const Query<String>().orderByField('b');

        expect(query1, isNot(equals(query2)));
      });

      test('should not be equal when limit differs', () {
        final query1 = const Query<String>().limitTo(10);
        final query2 = const Query<String>().limitTo(20);

        expect(query1, isNot(equals(query2)));
      });

      test('should have same hashCode for equal queries', () {
        final query1 = const Query<String>().where('field', isEqualTo: 'value');
        final query2 = const Query<String>().where('field', isEqualTo: 'value');

        expect(query1.hashCode, equals(query2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .limitTo(10);
        final str = query.toString();

        expect(str, contains('Query'));
        expect(str, contains('filters'));
        expect(str, contains('limit'));
      });
    });
  });

  group('FilterOperator', () {
    test('should have all expected operators', () {
      expect(FilterOperator.values, hasLength(15));
      expect(FilterOperator.values, contains(FilterOperator.equals));
      expect(FilterOperator.values, contains(FilterOperator.notEquals));
      expect(FilterOperator.values, contains(FilterOperator.lessThan));
      expect(FilterOperator.values, contains(FilterOperator.lessThanOrEquals));
      expect(FilterOperator.values, contains(FilterOperator.greaterThan));
      expect(
        FilterOperator.values,
        contains(FilterOperator.greaterThanOrEquals),
      );
      expect(FilterOperator.values, contains(FilterOperator.arrayContains));
      expect(FilterOperator.values, contains(FilterOperator.arrayContainsAny));
      expect(FilterOperator.values, contains(FilterOperator.whereIn));
      expect(FilterOperator.values, contains(FilterOperator.whereNotIn));
      expect(FilterOperator.values, contains(FilterOperator.isNull));
      expect(FilterOperator.values, contains(FilterOperator.isNotNull));
      expect(FilterOperator.values, contains(FilterOperator.contains));
      expect(FilterOperator.values, contains(FilterOperator.startsWith));
      expect(FilterOperator.values, contains(FilterOperator.endsWith));
    });
  });

  group('QueryFilter', () {
    test('should create filter with required properties', () {
      const filter = QueryFilter(
        field: 'name',
        operator: FilterOperator.equals,
        value: 'John',
      );

      expect(filter.field, equals('name'));
      expect(filter.operator, equals(FilterOperator.equals));
      expect(filter.value, equals('John'));
    });

    test('should be equal when all properties match', () {
      const filter1 = QueryFilter(
        field: 'name',
        operator: FilterOperator.equals,
        value: 'John',
      );
      const filter2 = QueryFilter(
        field: 'name',
        operator: FilterOperator.equals,
        value: 'John',
      );

      expect(filter1, equals(filter2));
    });

    test('should not be equal when field differs', () {
      const filter1 = QueryFilter(
        field: 'name',
        operator: FilterOperator.equals,
        value: 'John',
      );
      const filter2 = QueryFilter(
        field: 'email',
        operator: FilterOperator.equals,
        value: 'John',
      );

      expect(filter1, isNot(equals(filter2)));
    });

    test('should return readable string', () {
      const filter = QueryFilter(
        field: 'age',
        operator: FilterOperator.greaterThan,
        value: 18,
      );

      expect(filter.toString(), contains('age'));
      expect(filter.toString(), contains('greaterThan'));
      expect(filter.toString(), contains('18'));
    });
  });

  group('QueryOrderBy', () {
    test('should create order with required properties', () {
      const order = QueryOrderBy(field: 'createdAt');

      expect(order.field, equals('createdAt'));
      expect(order.descending, isFalse);
    });

    test('should create descending order', () {
      const order = QueryOrderBy(field: 'createdAt', descending: true);

      expect(order.descending, isTrue);
    });

    test('should be equal when all properties match', () {
      const order1 = QueryOrderBy(field: 'name');
      const order2 = QueryOrderBy(field: 'name');

      expect(order1, equals(order2));
    });

    test('should not be equal when field differs', () {
      const order1 = QueryOrderBy(field: 'name');
      const order2 = QueryOrderBy(field: 'email');

      expect(order1, isNot(equals(order2)));
    });

    test('should not be equal when descending differs', () {
      const order1 = QueryOrderBy(field: 'name');
      const order2 = QueryOrderBy(field: 'name', descending: true);

      expect(order1, isNot(equals(order2)));
    });

    test('should return readable string with ASC', () {
      const order = QueryOrderBy(field: 'name');

      expect(order.toString(), contains('name'));
      expect(order.toString(), contains('ASC'));
    });

    test('should return readable string with DESC', () {
      const order = QueryOrderBy(field: 'name', descending: true);

      expect(order.toString(), contains('name'));
      expect(order.toString(), contains('DESC'));
    });
  });
}
