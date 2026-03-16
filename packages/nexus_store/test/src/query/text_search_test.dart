import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

class _TestSqlTranslator with SqlQueryTranslatorMixin<dynamic> {}

void main() {
  group('TextSearchType', () {
    test('has three values', () {
      expect(TextSearchType.values, hasLength(3));
    });

    test('contains plain, phrase, and websearch', () {
      expect(
          TextSearchType.values,
          containsAll([
            TextSearchType.plain,
            TextSearchType.phrase,
            TextSearchType.websearch,
          ]));
    });
  });

  group('TextSearchConfig', () {
    test('creates with required query parameter', () {
      final config = TextSearchConfig(query: 'hello world');

      expect(config.query, 'hello world');
      expect(config.config, isNull);
      expect(config.type, TextSearchType.plain);
    });

    test('creates with all parameters', () {
      final config = TextSearchConfig(
        query: 'fat cats',
        config: 'english',
        type: TextSearchType.websearch,
      );

      expect(config.query, 'fat cats');
      expect(config.config, 'english');
      expect(config.type, TextSearchType.websearch);
    });

    test('equality works correctly', () {
      final a = TextSearchConfig(query: 'hello', config: 'english');
      final b = TextSearchConfig(query: 'hello', config: 'english');
      final c = TextSearchConfig(query: 'world', config: 'english');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = TextSearchConfig(query: 'hello', config: 'english');
      final b = TextSearchConfig(query: 'hello', config: 'english');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes all fields', () {
      final config = TextSearchConfig(
        query: 'test',
        config: 'english',
        type: TextSearchType.websearch,
      );

      final str = config.toString();
      expect(str, contains('test'));
      expect(str, contains('english'));
      expect(str, contains('websearch'));
    });

    test('inequality with different type', () {
      final a = TextSearchConfig(query: 'hello', type: TextSearchType.plain);
      final b = TextSearchConfig(query: 'hello', type: TextSearchType.phrase);

      expect(a, isNot(equals(b)));
    });

    test('is not equal to non-TextSearchConfig object', () {
      final config = TextSearchConfig(query: 'hello');

      // ignore: unrelated_type_equality_checks
      expect(config == 'not a config', isFalse);
    });
  });

  group('FilterOperator.textSearch', () {
    test('exists in FilterOperator enum', () {
      expect(FilterOperator.values, contains(FilterOperator.textSearch));
    });

    test('enum has 19 values', () {
      expect(FilterOperator.values, hasLength(19));
    });
  });

  group('InMemoryQueryEvaluator textSearch', () {
    late InMemoryQueryEvaluator<Map<String, dynamic>> evaluator;

    setUp(() {
      evaluator = InMemoryQueryEvaluator<Map<String, dynamic>>(
        fieldAccessor: (item, field) => item[field],
      );
    });

    test('matches substring case-insensitively', () {
      final query = const Query<Map<String, dynamic>>().where(
        'body',
        textSearch: TextSearchConfig(query: 'hello'),
      );

      expect(evaluator.matches({'body': 'Hello World'}, query), isTrue);
      expect(evaluator.matches({'body': 'HELLO'}, query), isTrue);
      expect(evaluator.matches({'body': 'goodbye'}, query), isFalse);
    });

    test('matches with null field value', () {
      final query = const Query<Map<String, dynamic>>().where(
        'body',
        textSearch: TextSearchConfig(query: 'hello'),
      );

      expect(evaluator.matches({'body': null}, query), isFalse);
    });
  });

  group('SqlQueryTranslatorMixin textSearch', () {
    test('operatorToSql throws UnsupportedError for textSearch', () {
      final translator = _TestSqlTranslator();

      expect(
        () => translator.operatorToSql(FilterOperator.textSearch),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('Query.where with textSearch', () {
    test('adds textSearch filter to query', () {
      final query = const Query<dynamic>().where(
        'description',
        textSearch: TextSearchConfig(query: 'hello world'),
      );

      expect(query.filters, hasLength(1));
      expect(query.filters.first.field, 'description');
      expect(query.filters.first.operator, FilterOperator.textSearch);
      expect(query.filters.first.value, isA<TextSearchConfig>());
    });

    test('textSearch config is stored as filter value', () {
      final config = TextSearchConfig(
        query: 'fat cats',
        config: 'english',
        type: TextSearchType.phrase,
      );
      final query = const Query<dynamic>().where(
        'body',
        textSearch: config,
      );

      final filterValue = query.filters.first.value! as TextSearchConfig;
      expect(filterValue.query, 'fat cats');
      expect(filterValue.config, 'english');
      expect(filterValue.type, TextSearchType.phrase);
    });

    test('textSearch can be combined with other filters', () {
      final query =
          const Query<dynamic>().where('status', isEqualTo: 'published').where(
                'content',
                textSearch: TextSearchConfig(query: 'dart flutter'),
              );

      expect(query.filters, hasLength(2));
      expect(query.filters[0].operator, FilterOperator.equals);
      expect(query.filters[1].operator, FilterOperator.textSearch);
    });
  });
}
