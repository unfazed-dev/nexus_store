import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Query.where() text search parameters', () {
    group('contains', () {
      test('creates filter with FilterOperator.contains', () {
        final query =
            Query<Map<String, dynamic>>().where('name', contains: 'john');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'name');
        expect(query.filters.first.operator, FilterOperator.contains);
        expect(query.filters.first.value, 'john');
      });

      test('composes with other filters via AND', () {
        final query = Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .where('name', contains: 'john');

        expect(query.filters, hasLength(2));
        expect(query.filters[0].operator, FilterOperator.equals);
        expect(query.filters[1].operator, FilterOperator.contains);
      });
    });

    group('startsWith', () {
      test('creates filter with FilterOperator.startsWith', () {
        final query =
            Query<Map<String, dynamic>>().where('name', startsWith: 'Jo');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'name');
        expect(query.filters.first.operator, FilterOperator.startsWith);
        expect(query.filters.first.value, 'Jo');
      });
    });

    group('endsWith', () {
      test('creates filter with FilterOperator.endsWith', () {
        final query = Query<Map<String, dynamic>>()
            .where('email', endsWith: '@example.com');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'email');
        expect(query.filters.first.operator, FilterOperator.endsWith);
        expect(query.filters.first.value, '@example.com');
      });
    });

    group('combined text search', () {
      test('multiple text search params on same call', () {
        final query = Query<Map<String, dynamic>>()
            .where('name', contains: 'john', startsWith: 'J');

        expect(query.filters, hasLength(2));
        expect(query.filters[0].operator, FilterOperator.contains);
        expect(query.filters[1].operator, FilterOperator.startsWith);
      });

      test('all three text params together', () {
        final query = Query<Map<String, dynamic>>().where(
          'name',
          contains: 'oh',
          startsWith: 'J',
          endsWith: 'n',
        );

        expect(query.filters, hasLength(3));
        final operators = query.filters.map((f) => f.operator).toSet();
        expect(
            operators,
            containsAll([
              FilterOperator.contains,
              FilterOperator.startsWith,
              FilterOperator.endsWith,
            ]));
      });
    });
  });
}
