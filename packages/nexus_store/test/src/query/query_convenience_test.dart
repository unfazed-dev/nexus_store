import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Query convenience methods', () {
    group('whereBetween', () {
      test('should create >= and <= filters for the field', () {
        final query = const Query<String>().whereBetween('age', 18, 65);

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, equals('age'));
        expect(
          query.filters[0].operator,
          equals(FilterOperator.greaterThanOrEquals),
        );
        expect(query.filters[0].value, equals(18));
        expect(query.filters[1].field, equals('age'));
        expect(
          query.filters[1].operator,
          equals(FilterOperator.lessThanOrEquals),
        );
        expect(query.filters[1].value, equals(65));
      });

      test('should compose with existing filters', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .whereBetween('price', 10.0, 99.99);

        expect(query.filters, hasLength(3));
        expect(query.filters[0].field, equals('status'));
        expect(query.filters[1].field, equals('price'));
        expect(query.filters[2].field, equals('price'));
      });

      test('should preserve immutability', () {
        const original = Query<String>();
        final modified = original.whereBetween('age', 0, 100);

        expect(original.filters, isEmpty);
        expect(modified.filters, hasLength(2));
      });

      test('should work with DateTime values', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 12, 31);
        final query = const Query<String>().whereBetween(
          'createdAt',
          start,
          end,
        );

        expect(query.filters, hasLength(2));
        expect(query.filters[0].value, equals(start));
        expect(query.filters[1].value, equals(end));
      });
    });

    group('whereNull', () {
      test('should create isNull filter', () {
        final query = const Query<String>().whereNull('deletedAt');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, equals('deletedAt'));
        expect(query.filters.first.operator, equals(FilterOperator.isNull));
        expect(query.filters.first.value, isNull);
      });

      test('should compose with existing filters', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .whereNull('archivedAt');

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, equals('status'));
        expect(query.filters[1].field, equals('archivedAt'));
        expect(query.filters[1].operator, equals(FilterOperator.isNull));
      });

      test('should preserve immutability', () {
        const original = Query<String>();
        final modified = original.whereNull('field');

        expect(original.filters, isEmpty);
        expect(modified.filters, hasLength(1));
      });
    });

    group('whereNotNull', () {
      test('should create isNotNull filter', () {
        final query = const Query<String>().whereNotNull('email');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, equals('email'));
        expect(query.filters.first.operator, equals(FilterOperator.isNotNull));
        expect(query.filters.first.value, isNull);
      });

      test('should compose with existing filters', () {
        final query = const Query<String>()
            .where('role', isEqualTo: 'admin')
            .whereNotNull('verifiedAt');

        expect(query.filters, hasLength(2));
        expect(query.filters[1].operator, equals(FilterOperator.isNotNull));
      });

      test('should preserve immutability', () {
        const original = Query<String>();
        final modified = original.whereNotNull('field');

        expect(original.filters, isEmpty);
        expect(modified.filters, hasLength(1));
      });
    });

    group('select', () {
      test('should set select fields on query', () {
        final query = const Query<String>().select({'name', 'email'});

        expect(query.selectFields, equals({'name', 'email'}));
      });

      test('should return empty set by default', () {
        const query = Query<String>();

        expect(query.selectFields, isEmpty);
      });

      test('should compose with filters', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .select({'name', 'email', 'status'});

        expect(query.filters, hasLength(1));
        expect(query.selectFields, equals({'name', 'email', 'status'}));
      });

      test('should merge with previous select call', () {
        final query =
            const Query<String>().select({'name', 'email'}).select({'phone'});

        expect(query.selectFields, equals({'name', 'email', 'phone'}));
      });

      test('should preserve immutability', () {
        const original = Query<String>();
        final modified = original.select({'name'});

        expect(original.selectFields, isEmpty);
        expect(modified.selectFields, equals({'name'}));
      });

      test('should affect isEmpty', () {
        final query = const Query<String>().select({'name'});
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('should be included in equality check', () {
        final query1 = const Query<String>().select({'name', 'email'});
        final query2 = const Query<String>().select({'name', 'email'});
        final query3 = const Query<String>().select({'name'});

        expect(query1, equals(query2));
        expect(query1, isNot(equals(query3)));
      });

      test('should be included in hashCode', () {
        final query1 = const Query<String>().select({'name', 'email'});
        final query2 = const Query<String>().select({'name', 'email'});

        expect(query1.hashCode, equals(query2.hashCode));
      });

      test('should be included in toString', () {
        final query = const Query<String>().select({'name'});
        expect(query.toString(), contains('selectFields'));
      });

      test('should be copyable via copyWith', () {
        final original = const Query<String>().select({'name'});
        final copied = original.copyWith(selectFields: {'email'});

        expect(copied.selectFields, equals({'email'}));
      });
    });

    group('distinct', () {
      test('should set distinct flag on query', () {
        final query = const Query<String>().distinct();

        expect(query.isDistinct, isTrue);
      });

      test('should default to false', () {
        const query = Query<String>();

        expect(query.isDistinct, isFalse);
      });

      test('should compose with select', () {
        final query =
            const Query<String>().select({'name', 'email'}).distinct();

        expect(query.selectFields, equals({'name', 'email'}));
        expect(query.isDistinct, isTrue);
      });

      test('should compose with filters', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .distinct();

        expect(query.filters, hasLength(1));
        expect(query.isDistinct, isTrue);
      });

      test('should preserve immutability', () {
        const original = Query<String>();
        final modified = original.distinct();

        expect(original.isDistinct, isFalse);
        expect(modified.isDistinct, isTrue);
      });

      test('should affect isEmpty', () {
        final query = const Query<String>().distinct();
        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });

      test('should be included in equality check', () {
        final query1 = const Query<String>().distinct();
        final query2 = const Query<String>().distinct();
        final query3 = const Query<String>();

        expect(query1, equals(query2));
        expect(query1, isNot(equals(query3)));
      });

      test('should be included in hashCode', () {
        final query1 = const Query<String>().distinct();
        final query2 = const Query<String>().distinct();

        expect(query1.hashCode, equals(query2.hashCode));
      });

      test('should be included in toString', () {
        final query = const Query<String>().distinct();
        expect(query.toString(), contains('distinct'));
      });

      test('should be copyable via copyWith', () {
        final original = const Query<String>().distinct();
        final copied = original.copyWith(isDistinct: false);

        expect(copied.isDistinct, isFalse);
      });
    });
  });
}
