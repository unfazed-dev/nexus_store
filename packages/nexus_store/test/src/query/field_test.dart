import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/field.dart';
import 'package:nexus_store/src/query/query.dart';

// Test entity for type checking
class TestUser {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final List<String> tags;
  final double? rating;

  TestUser({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    required this.tags,
    this.rating,
  });
}

void main() {
  group('Field', () {
    group('basic Field<T, F>', () {
      test('creates field with name', () {
        final field = Field<TestUser, String>('id');

        expect(field.name, equals('id'));
      });

      test('equals creates ComparisonExpression with equals operator', () {
        final field = Field<TestUser, String>('status');

        final expr = field.equals('active');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.fieldName, equals('status'));
        expect(comparison.operator, equals(FilterOperator.equals));
        expect(comparison.value, equals('active'));
      });

      test('notEquals creates ComparisonExpression with notEquals operator',
          () {
        final field = Field<TestUser, String>('status');

        final expr = field.notEquals('deleted');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.notEquals));
        expect(comparison.value, equals('deleted'));
      });

      test('isNull creates ComparisonExpression with isNull operator', () {
        final field = Field<TestUser, String>('name');

        final expr = field.isNull();

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.isNull));
        expect(comparison.value, isNull);
      });

      test('isNotNull creates ComparisonExpression with isNotNull operator',
          () {
        final field = Field<TestUser, String>('name');

        final expr = field.isNotNull();

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.isNotNull));
      });

      test('isIn creates ComparisonExpression with whereIn operator', () {
        final field = Field<TestUser, String>('status');

        final expr = field.isIn(['active', 'pending']);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.whereIn));
        expect(comparison.value, equals(['active', 'pending']));
      });

      test('isNotIn creates ComparisonExpression with whereNotIn operator', () {
        final field = Field<TestUser, String>('status');

        final expr = field.isNotIn(['deleted', 'archived']);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.whereNotIn));
        expect(comparison.value, equals(['deleted', 'archived']));
      });
    });

    group('ComparableField<T, F>', () {
      test('inherits from Field', () {
        final field = ComparableField<TestUser, int>('age');

        expect(field, isA<Field<TestUser, int>>());
        expect(field.name, equals('age'));
      });

      test('greaterThan creates comparison expression', () {
        final field = ComparableField<TestUser, int>('age');

        final expr = field.greaterThan(18);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.fieldName, equals('age'));
        expect(comparison.operator, equals(FilterOperator.greaterThan));
        expect(comparison.value, equals(18));
      });

      test('greaterThanOrEqualTo creates comparison expression', () {
        final field = ComparableField<TestUser, int>('age');

        final expr = field.greaterThanOrEqualTo(18);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.greaterThanOrEquals));
        expect(comparison.value, equals(18));
      });

      test('lessThan creates comparison expression', () {
        final field = ComparableField<TestUser, int>('age');

        final expr = field.lessThan(65);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.lessThan));
        expect(comparison.value, equals(65));
      });

      test('lessThanOrEqualTo creates comparison expression', () {
        final field = ComparableField<TestUser, int>('age');

        final expr = field.lessThanOrEqualTo(65);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.lessThanOrEquals));
        expect(comparison.value, equals(65));
      });

      test('works with double values', () {
        final field = ComparableField<TestUser, double>('rating');

        final expr = field.greaterThan(4.5);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.value, equals(4.5));
      });

      test('works with DateTime values', () {
        final field = ComparableField<TestUser, DateTime>('createdAt');
        final now = DateTime.now();

        final expr = field.lessThan(now);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.value, equals(now));
      });

      test('still has basic Field methods', () {
        final field = ComparableField<TestUser, int>('age');

        final equalsExpr = field.equals(25);
        final isNullExpr = field.isNull();
        final isInExpr = field.isIn([18, 21, 25]);

        expect(equalsExpr, isA<ComparisonExpression<TestUser>>());
        expect(isNullExpr, isA<ComparisonExpression<TestUser>>());
        expect(isInExpr, isA<ComparisonExpression<TestUser>>());
      });
    });

    group('StringField<T>', () {
      test('inherits from ComparableField', () {
        final field = StringField<TestUser>('name');

        expect(field, isA<ComparableField<TestUser, String>>());
        expect(field.name, equals('name'));
      });

      test('contains creates comparison expression', () {
        final field = StringField<TestUser>('name');

        final expr = field.contains('John');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.fieldName, equals('name'));
        expect(comparison.operator, equals(FilterOperator.contains));
        expect(comparison.value, equals('John'));
      });

      test('startsWith creates comparison expression', () {
        final field = StringField<TestUser>('name');

        final expr = field.startsWith('Dr.');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.startsWith));
        expect(comparison.value, equals('Dr.'));
      });

      test('endsWith creates comparison expression', () {
        final field = StringField<TestUser>('email');

        final expr = field.endsWith('@example.com');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.endsWith));
        expect(comparison.value, equals('@example.com'));
      });

      test('still has ComparableField methods', () {
        final field = StringField<TestUser>('name');

        final gtExpr = field.greaterThan('A');
        final ltExpr = field.lessThan('Z');

        expect(gtExpr, isA<ComparisonExpression<TestUser>>());
        expect(ltExpr, isA<ComparisonExpression<TestUser>>());
      });
    });

    group('ListField<T, E>', () {
      test('creates field with name', () {
        final field = ListField<TestUser, String>('tags');

        expect(field.name, equals('tags'));
      });

      test('arrayContains creates comparison expression', () {
        final field = ListField<TestUser, String>('tags');

        final expr = field.arrayContains('admin');

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.fieldName, equals('tags'));
        expect(comparison.operator, equals(FilterOperator.arrayContains));
        expect(comparison.value, equals('admin'));
      });

      test('arrayContainsAny creates comparison expression', () {
        final field = ListField<TestUser, String>('tags');

        final expr = field.arrayContainsAny(['admin', 'moderator']);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.operator, equals(FilterOperator.arrayContainsAny));
        expect(comparison.value, equals(['admin', 'moderator']));
      });

      test('works with int list elements', () {
        final field = ListField<TestUser, int>('scores');

        final expr = field.arrayContains(100);

        expect(expr, isA<ComparisonExpression<TestUser>>());
        final comparison = expr as ComparisonExpression<TestUser>;
        expect(comparison.value, equals(100));
      });

      test('still has basic Field methods for list equality', () {
        final field = ListField<TestUser, String>('tags');

        final isNullExpr = field.isNull();
        final isNotNullExpr = field.isNotNull();

        expect(isNullExpr, isA<ComparisonExpression<TestUser>>());
        expect(isNotNullExpr, isA<ComparisonExpression<TestUser>>());
      });
    });

    group('field chaining', () {
      test('expressions can be chained with and', () {
        final ageField = ComparableField<TestUser, int>('age');
        final statusField = Field<TestUser, String>('status');

        final expr = ageField.greaterThan(18).and(statusField.equals('active'));

        expect(expr, isA<AndExpression<TestUser>>());
      });

      test('expressions can be chained with or', () {
        final roleField = Field<TestUser, String>('role');

        final expr =
            roleField.equals('admin').or(roleField.equals('moderator'));

        expect(expr, isA<OrExpression<TestUser>>());
      });

      test('complex expression chains work', () {
        final ageField = ComparableField<TestUser, int>('age');
        final nameField = StringField<TestUser>('name');
        final statusField = Field<TestUser, String>('status');

        // (age > 18) AND (name starts with 'A' OR name starts with 'B') AND (status = 'active')
        final expr = ageField
            .greaterThan(18)
            .and(nameField.startsWith('A').or(nameField.startsWith('B')))
            .and(statusField.equals('active'));

        expect(expr, isA<AndExpression<TestUser>>());
      });
    });

    group('field equality', () {
      test('fields with same name are equal', () {
        final field1 = Field<TestUser, String>('name');
        final field2 = Field<TestUser, String>('name');

        expect(field1, equals(field2));
        expect(field1.hashCode, equals(field2.hashCode));
      });

      test('fields with different names are not equal', () {
        final field1 = Field<TestUser, String>('name');
        final field2 = Field<TestUser, String>('status');

        expect(field1, isNot(equals(field2)));
      });

      test('different field types with same name are not equal', () {
        final stringField = StringField<TestUser>('age');
        final intField = ComparableField<TestUser, int>('age');

        // These are different types, so they shouldn't be equal
        expect(stringField.runtimeType, isNot(equals(intField.runtimeType)));
      });
    });

    group('toFilters integration', () {
      test('field expression converts to QueryFilter', () {
        final field = ComparableField<TestUser, int>('age');
        final expr = field.greaterThan(18);

        final filters = expr.toFilters();

        expect(filters, hasLength(1));
        expect(filters.first.field, equals('age'));
        expect(filters.first.operator, equals(FilterOperator.greaterThan));
        expect(filters.first.value, equals(18));
      });

      test('chained expressions convert to list of filters', () {
        final ageField = ComparableField<TestUser, int>('age');
        final statusField = Field<TestUser, String>('status');

        final expr =
            ageField.greaterThan(18).and(statusField.equals('active'));
        final filters = expr.toFilters();

        expect(filters, hasLength(2));
        expect(filters[0].field, equals('age'));
        expect(filters[1].field, equals('status'));
      });
    });
  });
}
