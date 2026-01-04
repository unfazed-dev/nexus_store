import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/query/query_translator.dart';
import 'package:test/test.dart';

/// Test implementation that uses the SqlQueryTranslatorMixin.
class TestSqlTranslator with SqlQueryTranslatorMixin<void> {}

void main() {
  late TestSqlTranslator translator;

  setUp(() {
    translator = TestSqlTranslator();
  });

  group('SqlQueryTranslatorMixin', () {
    group('operatorToSql', () {
      test('equals returns =', () {
        expect(translator.operatorToSql(FilterOperator.equals), equals('='));
      });

      test('notEquals returns !=', () {
        expect(
          translator.operatorToSql(FilterOperator.notEquals),
          equals('!='),
        );
      });

      test('lessThan returns <', () {
        expect(translator.operatorToSql(FilterOperator.lessThan), equals('<'));
      });

      test('lessThanOrEquals returns <=', () {
        expect(
          translator.operatorToSql(FilterOperator.lessThanOrEquals),
          equals('<='),
        );
      });

      test('greaterThan returns >', () {
        expect(
          translator.operatorToSql(FilterOperator.greaterThan),
          equals('>'),
        );
      });

      test('greaterThanOrEquals returns >=', () {
        expect(
          translator.operatorToSql(FilterOperator.greaterThanOrEquals),
          equals('>='),
        );
      });

      test('isNull returns IS NULL', () {
        expect(
          translator.operatorToSql(FilterOperator.isNull),
          equals('IS NULL'),
        );
      });

      test('isNotNull returns IS NOT NULL', () {
        expect(
          translator.operatorToSql(FilterOperator.isNotNull),
          equals('IS NOT NULL'),
        );
      });

      test('whereIn returns IN', () {
        expect(translator.operatorToSql(FilterOperator.whereIn), equals('IN'));
      });

      test('whereNotIn returns NOT IN', () {
        expect(
          translator.operatorToSql(FilterOperator.whereNotIn),
          equals('NOT IN'),
        );
      });

      test('contains returns LIKE', () {
        expect(
          translator.operatorToSql(FilterOperator.contains),
          equals('LIKE'),
        );
      });

      test('startsWith returns LIKE', () {
        expect(
          translator.operatorToSql(FilterOperator.startsWith),
          equals('LIKE'),
        );
      });

      test('endsWith returns LIKE', () {
        expect(
          translator.operatorToSql(FilterOperator.endsWith),
          equals('LIKE'),
        );
      });

      test('arrayContains returns LIKE', () {
        expect(
          translator.operatorToSql(FilterOperator.arrayContains),
          equals('LIKE'),
        );
      });

      test('arrayContainsAny returns LIKE', () {
        expect(
          translator.operatorToSql(FilterOperator.arrayContainsAny),
          equals('LIKE'),
        );
      });
    });

    group('escapeSqlString', () {
      test('escapes single quote', () {
        expect(translator.escapeSqlString("O'Brien"), equals("O''Brien"));
      });

      test('escapes multiple single quotes', () {
        expect(
          translator.escapeSqlString("It's a 'test'"),
          equals("It''s a ''test''"),
        );
      });

      test('returns string unchanged when no quotes', () {
        expect(
            translator.escapeSqlString('Hello World'), equals('Hello World'));
      });

      test('handles empty string', () {
        expect(translator.escapeSqlString(''), equals(''));
      });

      test('handles consecutive quotes', () {
        expect(translator.escapeSqlString("'''"), equals("''''''"));
      });
    });

    group('formatSqlValue', () {
      group('null values', () {
        test('returns NULL', () {
          expect(translator.formatSqlValue(null), equals('NULL'));
        });
      });

      group('String values', () {
        test('wraps in single quotes', () {
          expect(translator.formatSqlValue('hello'), equals("'hello'"));
        });

        test('escapes single quotes in string', () {
          expect(translator.formatSqlValue("O'Brien"), equals("'O''Brien'"));
        });

        test('handles empty string', () {
          expect(translator.formatSqlValue(''), equals("''"));
        });
      });

      group('bool values', () {
        test('true returns 1', () {
          expect(translator.formatSqlValue(true), equals('1'));
        });

        test('false returns 0', () {
          expect(translator.formatSqlValue(false), equals('0'));
        });
      });

      group('DateTime values', () {
        test('returns ISO8601 string in quotes', () {
          final date = DateTime.utc(2024, 1, 15, 10, 30, 0);
          expect(
            translator.formatSqlValue(date),
            equals("'2024-01-15T10:30:00.000Z'"),
          );
        });

        test('handles local DateTime', () {
          final date = DateTime(2024, 6, 15, 14, 45, 30);
          final result = translator.formatSqlValue(date);
          expect(result, startsWith("'2024-06-15T14:45:30"));
          expect(result, endsWith("'"));
        });
      });

      group('List values', () {
        test('formats list with parentheses', () {
          expect(translator.formatSqlValue([1, 2, 3]), equals('(1, 2, 3)'));
        });

        test('formats list of strings with quotes', () {
          expect(
            translator.formatSqlValue(['a', 'b', 'c']),
            equals("('a', 'b', 'c')"),
          );
        });

        test('formats empty list', () {
          expect(translator.formatSqlValue([]), equals('()'));
        });

        test('formats nested values correctly', () {
          expect(
            translator.formatSqlValue([true, 'test', 42]),
            equals("(1, 'test', 42)"),
          );
        });

        test('escapes strings in list', () {
          expect(
            translator.formatSqlValue(["O'Brien", "It's"]),
            equals("('O''Brien', 'It''s')"),
          );
        });
      });

      group('numeric values', () {
        test('int returns toString', () {
          expect(translator.formatSqlValue(42), equals('42'));
        });

        test('negative int returns toString', () {
          expect(translator.formatSqlValue(-17), equals('-17'));
        });

        test('double returns toString', () {
          expect(translator.formatSqlValue(3.14), equals('3.14'));
        });

        test('double with trailing zeros returns toString', () {
          expect(translator.formatSqlValue(2.0), equals('2.0'));
        });

        test('very large number returns toString', () {
          expect(
            translator.formatSqlValue(9223372036854775807),
            equals('9223372036854775807'),
          );
        });
      });
    });
  });
}
