import 'package:brick_core/query.dart' as brick;
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('BrickQueryTranslator', () {
    late BrickQueryTranslator<TestModel> translator;

    setUp(() {
      translator = BrickQueryTranslator<TestModel>();
    });

    group('translate', () {
      test('translates empty query to empty Brick query', () {
        const query = Query<TestModel>();
        final result = translator.translate(query);

        expect(result.where, isNull);
        expect(result.orderBy, isEmpty);
        expect(result.limit, isNull);
        expect(result.offset, isNull);
      });

      test('translates query with limit and offset', () {
        final query = const Query<TestModel>().limitTo(10).offsetBy(5);
        final result = translator.translate(query);

        expect(result.limit, 10);
        expect(result.offset, 5);
      });
    });

    group('filter translation', () {
      test('translates equals filter', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.length, 1);
        expect(result.where!.first.evaluatedField, 'name');
        expect(result.where!.first.value, 'John');
        expect(result.where!.first.compare, brick.Compare.exact);
      });

      test('translates notEquals filter', () {
        final query =
            const Query<TestModel>().where('status', isNotEqualTo: 'deleted');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'status');
        expect(result.where!.first.value, 'deleted');
        expect(result.where!.first.compare, brick.Compare.notEqual);
      });

      test('translates lessThan filter', () {
        final query = const Query<TestModel>().where('age', isLessThan: 30);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'age');
        expect(result.where!.first.value, 30);
        expect(result.where!.first.compare, brick.Compare.lessThan);
      });

      test('translates lessThanOrEqualTo filter', () {
        final query =
            const Query<TestModel>().where('age', isLessThanOrEqualTo: 30);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.compare, brick.Compare.lessThanOrEqualTo);
      });

      test('translates greaterThan filter', () {
        final query = const Query<TestModel>().where('age', isGreaterThan: 18);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'age');
        expect(result.where!.first.value, 18);
        expect(result.where!.first.compare, brick.Compare.greaterThan);
      });

      test('translates greaterThanOrEqualTo filter', () {
        final query =
            const Query<TestModel>().where('age', isGreaterThanOrEqualTo: 18);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.compare, brick.Compare.greaterThanOrEqualTo);
      });

      test('translates whereIn filter', () {
        final query =
            const Query<TestModel>().where('role', whereIn: ['admin', 'user']);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'role');
        expect(result.where!.first.value, ['admin', 'user']);
        expect(result.where!.first.compare, brick.Compare.inIterable);
      });

      test('translates isNull filter', () {
        final query = const Query<TestModel>().where('deletedAt', isNull: true);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'deletedAt');
        expect(result.where!.first.compare, brick.Compare.exact);
      });

      test('translates isNotNull filter', () {
        final query =
            const Query<TestModel>().where('deletedAt', isNull: false);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'deletedAt');
        expect(result.where!.first.compare, brick.Compare.notEqual);
      });

      test('translates multiple filters', () {
        final query = const Query<TestModel>()
            .where('status', isEqualTo: 'active')
            .where('age', isGreaterThan: 18);
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.length, 2);
        expect(result.where![0].evaluatedField, 'status');
        expect(result.where![1].evaluatedField, 'age');
      });

      test('translates startsWith filter', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.startsWith,
            value: 'Jo',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'name');
        expect(result.where!.first.value, 'Jo');
        expect(result.where!.first.compare, brick.Compare.contains);
      });

      test('translates endsWith filter', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.endsWith,
            value: 'son',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'name');
        expect(result.where!.first.value, 'son');
        expect(result.where!.first.compare, brick.Compare.contains);
      });

      group('whereNotIn filter', () {
        test('handles empty list', () {
          final query = const Query<TestModel>()
              .where('role', whereNotIn: <String>[]);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'role');
          expect(result.where!.first.compare, brick.Compare.notEqual);
        });

        test('handles single value', () {
          final query =
              const Query<TestModel>().where('role', whereNotIn: ['admin']);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'role');
          expect(result.where!.first.value, 'admin');
          expect(result.where!.first.compare, brick.Compare.notEqual);
        });

        test('handles multiple values (uses first only)', () {
          final query = const Query<TestModel>()
              .where('role', whereNotIn: ['admin', 'superuser']);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'role');
          expect(result.where!.first.value, 'admin');
          expect(result.where!.first.compare, brick.Compare.notEqual);
        });
      });

      group('arrayContainsAny filter', () {
        test('handles empty list', () {
          final query = const Query<TestModel>()
              .where('tags', arrayContainsAny: <String>[]);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'tags');
          expect(result.where!.first.compare, brick.Compare.exact);
        });

        test('handles single value', () {
          final query = const Query<TestModel>()
              .where('tags', arrayContainsAny: ['flutter']);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'tags');
          expect(result.where!.first.value, 'flutter');
          expect(result.where!.first.compare, brick.Compare.contains);
        });

        test('handles multiple values (uses first only)', () {
          final query = const Query<TestModel>()
              .where('tags', arrayContainsAny: ['flutter', 'dart']);
          final result = translator.translate(query);

          expect(result.where, isNotNull);
          expect(result.where!.first.evaluatedField, 'tags');
          expect(result.where!.first.value, 'flutter');
          expect(result.where!.first.compare, brick.Compare.contains);
        });
      });

      test('translates arrayContains filter', () {
        final query =
            const Query<TestModel>().where('tags', arrayContains: 'flutter');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'tags');
        expect(result.where!.first.value, 'flutter');
        expect(result.where!.first.compare, brick.Compare.contains);
      });
    });

    group('orderBy translation', () {
      test('translates ascending orderBy', () {
        final query = const Query<TestModel>().orderByField('name');
        final result = translator.translate(query);

        expect(result.orderBy, isNotEmpty);
        expect(result.orderBy.length, 1);
        expect(result.orderBy.first.evaluatedField, 'name');
        expect(result.orderBy.first.ascending, isTrue);
      });

      test('translates descending orderBy', () {
        final query = const Query<TestModel>().orderByField(
          'createdAt',
          descending: true,
        );
        final result = translator.translate(query);

        expect(result.orderBy, isNotEmpty);
        expect(result.orderBy.first.evaluatedField, 'createdAt');
        expect(result.orderBy.first.ascending, isFalse);
      });

      test('translates multiple orderBy', () {
        final query = const Query<TestModel>()
            .orderByField('status')
            .orderByField('createdAt', descending: true);
        final result = translator.translate(query);

        expect(result.orderBy.length, 2);
        expect(result.orderBy[0].evaluatedField, 'status');
        expect(result.orderBy[0].ascending, isTrue);
        expect(result.orderBy[1].evaluatedField, 'createdAt');
        expect(result.orderBy[1].ascending, isFalse);
      });
    });

    group('field mapping', () {
      test('maps field names when fieldMapping provided', () {
        final translatorWithMapping = BrickQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );

        final query = const Query<TestModel>()
            .where('userName', isEqualTo: 'john')
            .orderByField('createdAt', descending: true);
        final result = translatorWithMapping.translate(query);

        expect(result.where!.first.evaluatedField, 'user_name');
        expect(result.orderBy.first.evaluatedField, 'created_at');
      });

      test('uses original field name when not in mapping', () {
        final translatorWithMapping = BrickQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );

        final query =
            const Query<TestModel>().where('status', isEqualTo: 'active');
        final result = translatorWithMapping.translate(query);

        expect(result.where!.first.evaluatedField, 'status');
      });
    });

    group('translateFilters', () {
      test('translates filter list to Brick query', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.equals,
            value: 'John',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where, isNotNull);
        expect(result.where!.length, 1);
        expect(result.orderBy, isEmpty);
        expect(result.limit, isNull);
      });
    });

    group('translateOrderBy', () {
      test('translates orderBy list to Brick query', () {
        final orderBy = [
          const QueryOrderBy(field: 'name'),
          const QueryOrderBy(field: 'createdAt', descending: true),
        ];
        final result = translator.translateOrderBy(orderBy);

        expect(result.where, isNull);
        expect(result.orderBy.length, 2);
        expect(result.limit, isNull);
      });
    });

    group('BrickQueryExtension', () {
      test('toBrickQuery converts Query to Brick Query', () {
        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .limitTo(10);
        final result = query.toBrickQuery();

        expect(result.where, isNotNull);
        expect(result.limit, 10);
      });

      test('toBrickQuery with fieldMapping', () {
        final query =
            const Query<TestModel>().where('userName', isEqualTo: 'john');
        final result = query.toBrickQuery(
          fieldMapping: {'userName': 'user_name'},
        );

        expect(result.where!.first.evaluatedField, 'user_name');
      });
    });
  });
}

/// Test model for type parameter.
class TestModel {}
