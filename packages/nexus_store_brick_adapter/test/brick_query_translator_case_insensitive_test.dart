import 'package:brick_core/query.dart' as brick;
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('BrickQueryTranslator case-insensitive operators', () {
    late BrickQueryTranslator<TestModel> translator;

    setUp(() {
      translator = BrickQueryTranslator<TestModel>();
    });

    group('iContains', () {
      test('translates to contains comparison', () {
        final query =
            const Query<TestModel>().where('title', iContains: 'hello');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.length, 1);
        expect(result.where!.first.evaluatedField, 'title');
        expect(result.where!.first.value, 'hello');
        expect(result.where!.first.compare, brick.Compare.contains);
      });

      test('preserves value as-is (Brick handles case sensitivity)', () {
        final query =
            const Query<TestModel>().where('name', iContains: 'UPPER');
        final result = translator.translate(query);

        expect(result.where!.first.value, 'UPPER');
      });
    });

    group('iStartsWith', () {
      test('translates to contains comparison', () {
        final query = const Query<TestModel>().where('name', iStartsWith: 'Jo');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'name');
        expect(result.where!.first.value, 'Jo');
        expect(result.where!.first.compare, brick.Compare.contains);
      });
    });

    group('iEndsWith', () {
      test('translates to contains comparison', () {
        final query =
            const Query<TestModel>().where('email', iEndsWith: '.com');
        final result = translator.translate(query);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'email');
        expect(result.where!.first.value, '.com');
        expect(result.where!.first.compare, brick.Compare.contains);
      });
    });

    group('combined with other filters', () {
      test('iContains combined with equals filter', () {
        final query = const Query<TestModel>()
            .where('status', isEqualTo: 'active')
            .where('title', iContains: 'search');
        final result = translator.translate(query);

        expect(result.where!.length, 2);
        expect(result.where![0].evaluatedField, 'status');
        expect(result.where![0].compare, brick.Compare.exact);
        expect(result.where![1].evaluatedField, 'title');
        expect(result.where![1].compare, brick.Compare.contains);
      });

      test('iContains with ordering and limit', () {
        final query = const Query<TestModel>()
            .where('title', iContains: 'test')
            .orderByField('created_at', descending: true)
            .limitTo(10);
        final result = translator.translate(query);

        expect(result.where!.length, 1);
        expect(result.where!.first.compare, brick.Compare.contains);
        expect(result.orderBy.length, 1);
        expect(result.orderBy.first.evaluatedField, 'created_at');
        expect(result.limit, 10);
      });
    });

    group('field mapping with case-insensitive ops', () {
      test('maps field names for iContains', () {
        final translatorWithMapping = BrickQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );

        final query =
            const Query<TestModel>().where('userName', iContains: 'john');
        final result = translatorWithMapping.translate(query);

        expect(result.where!.first.evaluatedField, 'user_name');
        expect(result.where!.first.value, 'john');
        expect(result.where!.first.compare, brick.Compare.contains);
      });
    });

    group('translateFilters with case-insensitive operators', () {
      test('translates iContains filter directly', () {
        final filters = [
          const QueryFilter(
            field: 'title',
            operator: FilterOperator.iContains,
            value: 'search',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where, isNotNull);
        expect(result.where!.first.evaluatedField, 'title');
        expect(result.where!.first.value, 'search');
        expect(result.where!.first.compare, brick.Compare.contains);
      });

      test('translates iStartsWith filter directly', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.iStartsWith,
            value: 'Jo',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where!.first.compare, brick.Compare.contains);
      });

      test('translates iEndsWith filter directly', () {
        final filters = [
          const QueryFilter(
            field: 'email',
            operator: FilterOperator.iEndsWith,
            value: '.org',
          ),
        ];
        final result = translator.translateFilters(filters);

        expect(result.where!.first.compare, brick.Compare.contains);
      });
    });
  });
}

/// Test model for type parameter.
class TestModel {}
