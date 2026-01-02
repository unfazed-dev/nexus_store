import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/query.dart';

void main() {
  group('Expression', () {
    group('ComparisonExpression', () {
      test('creates expression with field, operator, and value', () {
        final expression = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );

        expect(expression.fieldName, equals('age'));
        expect(expression.operator, equals(FilterOperator.greaterThan));
        expect(expression.value, equals(18));
      });

      test('toFilters returns single QueryFilter', () {
        final expression = ComparisonExpression<String>(
          fieldName: 'name',
          operator: FilterOperator.equals,
          value: 'John',
        );

        final filters = expression.toFilters();

        expect(filters, hasLength(1));
        expect(filters.first.field, equals('name'));
        expect(filters.first.operator, equals(FilterOperator.equals));
        expect(filters.first.value, equals('John'));
      });

      test('supports null value for isNull operator', () {
        final expression = ComparisonExpression<String>(
          fieldName: 'deletedAt',
          operator: FilterOperator.isNull,
          value: null,
        );

        final filters = expression.toFilters();

        expect(filters.first.operator, equals(FilterOperator.isNull));
        expect(filters.first.value, isNull);
      });

      test('supports list value for whereIn operator', () {
        final expression = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.whereIn,
          value: ['active', 'pending'],
        );

        final filters = expression.toFilters();

        expect(filters.first.operator, equals(FilterOperator.whereIn));
        expect(filters.first.value, equals(['active', 'pending']));
      });
    });

    group('AndExpression', () {
      test('combines two expressions with AND', () {
        final left = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );
        final right = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'active',
        );

        final andExpr = AndExpression<String>(left, right);

        expect(andExpr.left, equals(left));
        expect(andExpr.right, equals(right));
      });

      test('toFilters flattens to list of QueryFilters', () {
        final left = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );
        final right = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'active',
        );

        final andExpr = AndExpression<String>(left, right);
        final filters = andExpr.toFilters();

        expect(filters, hasLength(2));
        expect(filters[0].field, equals('age'));
        expect(filters[1].field, equals('status'));
      });

      test('toFilters handles nested AND expressions', () {
        final expr1 = ComparisonExpression<String>(
          fieldName: 'a',
          operator: FilterOperator.equals,
          value: 1,
        );
        final expr2 = ComparisonExpression<String>(
          fieldName: 'b',
          operator: FilterOperator.equals,
          value: 2,
        );
        final expr3 = ComparisonExpression<String>(
          fieldName: 'c',
          operator: FilterOperator.equals,
          value: 3,
        );

        final nested = AndExpression<String>(
          expr1,
          AndExpression<String>(expr2, expr3),
        );

        final filters = nested.toFilters();

        expect(filters, hasLength(3));
        expect(filters[0].field, equals('a'));
        expect(filters[1].field, equals('b'));
        expect(filters[2].field, equals('c'));
      });
    });

    group('OrExpression', () {
      test('combines two expressions with OR', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );

        final orExpr = OrExpression<String>(left, right);

        expect(orExpr.left, equals(left));
        expect(orExpr.right, equals(right));
      });

      test('toFilters throws UnsupportedError for OR expressions', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );

        final orExpr = OrExpression<String>(left, right);

        expect(
          () => orExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('NotExpression', () {
      test('wraps an expression for negation', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'deleted',
          operator: FilterOperator.equals,
          value: true,
        );

        final notExpr = NotExpression<String>(inner);

        expect(notExpr.expression, equals(inner));
      });

      test('toFilters inverts equals to notEquals', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'deleted',
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(filters, hasLength(1));
        expect(filters.first.operator, equals(FilterOperator.notEquals));
        expect(filters.first.value, equals('deleted'));
      });

      test('toFilters inverts notEquals to equals', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.notEquals,
          value: 'active',
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(filters.first.operator, equals(FilterOperator.equals));
      });

      test('toFilters inverts isNull to isNotNull', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'deletedAt',
          operator: FilterOperator.isNull,
          value: null,
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(filters.first.operator, equals(FilterOperator.isNotNull));
      });

      test('toFilters inverts greaterThan to lessThanOrEquals', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(filters.first.operator, equals(FilterOperator.lessThanOrEquals));
      });

      test('toFilters inverts lessThan to greaterThanOrEquals', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.lessThan,
          value: 18,
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(
          filters.first.operator,
          equals(FilterOperator.greaterThanOrEquals),
        );
      });

      test('toFilters inverts whereIn to whereNotIn', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.whereIn,
          value: ['a', 'b'],
        );

        final notExpr = NotExpression<String>(inner);
        final filters = notExpr.toFilters();

        expect(filters.first.operator, equals(FilterOperator.whereNotIn));
      });

      test('toFilters throws for NOT on OR expression', () {
        final orExpr = OrExpression<String>(
          ComparisonExpression<String>(
            fieldName: 'a',
            operator: FilterOperator.equals,
            value: 1,
          ),
          ComparisonExpression<String>(
            fieldName: 'b',
            operator: FilterOperator.equals,
            value: 2,
          ),
        );

        final notExpr = NotExpression<String>(orExpr);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('Expression chaining', () {
      test('and() method creates AndExpression', () {
        final left = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );
        final right = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'active',
        );

        final result = left.and(right);

        expect(result, isA<AndExpression<String>>());
        final andExpr = result as AndExpression<String>;
        expect(andExpr.left, equals(left));
        expect(andExpr.right, equals(right));
      });

      test('or() method creates OrExpression', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );

        final result = left.or(right);

        expect(result, isA<OrExpression<String>>());
      });

      test('not() method creates NotExpression', () {
        final expr = ComparisonExpression<String>(
          fieldName: 'deleted',
          operator: FilterOperator.equals,
          value: true,
        );

        final result = expr.not();

        expect(result, isA<NotExpression<String>>());
      });

      test('complex chaining works correctly', () {
        final age = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );
        final statusA = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'active',
        );
        final statusP = ComparisonExpression<String>(
          fieldName: 'status',
          operator: FilterOperator.equals,
          value: 'pending',
        );

        // age > 18 AND (status = 'active' OR status = 'pending')
        final result = age.and(statusA.or(statusP));

        expect(result, isA<AndExpression<String>>());
        final andExpr = result as AndExpression<String>;
        expect(andExpr.left, equals(age));
        expect(andExpr.right, isA<OrExpression<String>>());
      });
    });

    group('Expression equality', () {
      test('ComparisonExpression equals with same values', () {
        final expr1 = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.equals,
          value: 18,
        );
        final expr2 = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.equals,
          value: 18,
        );

        expect(expr1, equals(expr2));
        expect(expr1.hashCode, equals(expr2.hashCode));
      });

      test('ComparisonExpression not equals with different values', () {
        final expr1 = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.equals,
          value: 18,
        );
        final expr2 = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.equals,
          value: 21,
        );

        expect(expr1, isNot(equals(expr2)));
      });

      test('AndExpression equals with same children', () {
        final left = ComparisonExpression<String>(
          fieldName: 'a',
          operator: FilterOperator.equals,
          value: 1,
        );
        final right = ComparisonExpression<String>(
          fieldName: 'b',
          operator: FilterOperator.equals,
          value: 2,
        );

        final and1 = AndExpression<String>(left, right);
        final and2 = AndExpression<String>(left, right);

        expect(and1, equals(and2));
        expect(and1.hashCode, equals(and2.hashCode));
      });
    });

    group('Expression immutability', () {
      test('expressions are immutable', () {
        final expr = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.equals,
          value: 18,
        );

        // Can't modify - these should be compile-time errors
        // expr.fieldName = 'name';  // Not allowed
        // expr.value = 21;           // Not allowed

        expect(expr.fieldName, equals('age'));
        expect(expr.value, equals(18));
      });
    });

    group('Expression toString', () {
      test('ComparisonExpression toString includes type, field, operator and value', () {
        final expr = ComparisonExpression<String>(
          fieldName: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        );

        final str = expr.toString();

        expect(str, contains('ComparisonExpression<String>'));
        expect(str, contains('age'));
        expect(str, contains('greaterThan'));
        expect(str, contains('18'));
      });

      test('AndExpression toString includes left AND right', () {
        final left = ComparisonExpression<String>(
          fieldName: 'a',
          operator: FilterOperator.equals,
          value: 1,
        );
        final right = ComparisonExpression<String>(
          fieldName: 'b',
          operator: FilterOperator.equals,
          value: 2,
        );

        final andExpr = AndExpression<String>(left, right);
        final str = andExpr.toString();

        expect(str, contains('AndExpression<String>'));
        expect(str, contains('AND'));
      });

      test('OrExpression toString includes left OR right', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );

        final orExpr = OrExpression<String>(left, right);
        final str = orExpr.toString();

        expect(str, contains('OrExpression<String>'));
        expect(str, contains('OR'));
      });

      test('NotExpression toString includes NOT and inner expression', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'deleted',
          operator: FilterOperator.equals,
          value: true,
        );

        final notExpr = NotExpression<String>(inner);
        final str = notExpr.toString();

        expect(str, contains('NotExpression<String>'));
        expect(str, contains('NOT'));
      });
    });

    group('OrExpression equality', () {
      test('OrExpression equals with same children', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );

        final or1 = OrExpression<String>(left, right);
        final or2 = OrExpression<String>(left, right);

        expect(or1, equals(or2));
        expect(or1.hashCode, equals(or2.hashCode));
      });

      test('OrExpression not equals with different children', () {
        final left = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'admin',
        );
        final right1 = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'moderator',
        );
        final right2 = ComparisonExpression<String>(
          fieldName: 'role',
          operator: FilterOperator.equals,
          value: 'user',
        );

        final or1 = OrExpression<String>(left, right1);
        final or2 = OrExpression<String>(left, right2);

        expect(or1, isNot(equals(or2)));
      });
    });

    group('NotExpression equality', () {
      test('NotExpression equals with same inner expression', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'deleted',
          operator: FilterOperator.equals,
          value: true,
        );

        final not1 = NotExpression<String>(inner);
        final not2 = NotExpression<String>(inner);

        expect(not1, equals(not2));
        expect(not1.hashCode, equals(not2.hashCode));
      });

      test('NotExpression not equals with different inner expression', () {
        final inner1 = ComparisonExpression<String>(
          fieldName: 'deleted',
          operator: FilterOperator.equals,
          value: true,
        );
        final inner2 = ComparisonExpression<String>(
          fieldName: 'active',
          operator: FilterOperator.equals,
          value: false,
        );

        final not1 = NotExpression<String>(inner1);
        final not2 = NotExpression<String>(inner2);

        expect(not1, isNot(equals(not2)));
      });
    });

    group('NotExpression _invertOperator UnsupportedError', () {
      test('toFilters throws UnsupportedError for contains operator', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'name',
          operator: FilterOperator.contains,
          value: 'test',
        );

        final notExpr = NotExpression<String>(inner);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('toFilters throws UnsupportedError for startsWith operator', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'name',
          operator: FilterOperator.startsWith,
          value: 'test',
        );

        final notExpr = NotExpression<String>(inner);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('toFilters throws UnsupportedError for endsWith operator', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'name',
          operator: FilterOperator.endsWith,
          value: 'test',
        );

        final notExpr = NotExpression<String>(inner);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('toFilters throws UnsupportedError for arrayContains operator', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'tags',
          operator: FilterOperator.arrayContains,
          value: 'important',
        );

        final notExpr = NotExpression<String>(inner);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('toFilters throws UnsupportedError for arrayContainsAny operator', () {
        final inner = ComparisonExpression<String>(
          fieldName: 'tags',
          operator: FilterOperator.arrayContainsAny,
          value: ['a', 'b'],
        );

        final notExpr = NotExpression<String>(inner);

        expect(
          () => notExpr.toFilters(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });
}
