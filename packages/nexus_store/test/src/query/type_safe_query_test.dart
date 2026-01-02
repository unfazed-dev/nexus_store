import 'package:test/test.dart';
import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/field.dart';
import 'package:nexus_store/src/query/fields.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/query/query_expression_extension.dart';

// Test entity
class User {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final List<String> tags;
  final String status;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    required this.tags,
    required this.status,
  });
}

// Test fields definition
class UserFields extends Fields<User> {
  const UserFields._();
  static const instance = UserFields._();

  static final id = StringField<User>('id');
  static final name = StringField<User>('name');
  static final age = ComparableField<User, int>('age');
  static final createdAt = ComparableField<User, DateTime>('createdAt');
  static final tags = ListField<User, String>('tags');
  static final status = Field<User, String>('status');
}

void main() {
  group('QueryExpressionExtension', () {
    group('whereExpression', () {
      test('adds single expression filter to empty query', () {
        final query =
            const Query<User>().whereExpression(UserFields.age.greaterThan(18));

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, equals('age'));
        expect(
            query.filters.first.operator, equals(FilterOperator.greaterThan));
        expect(query.filters.first.value, equals(18));
      });

      test('adds expression filter to query with existing string filter', () {
        final query = const Query<User>()
            .where('status', isEqualTo: 'active')
            .whereExpression(UserFields.age.greaterThan(18));

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, equals('status'));
        expect(query.filters[1].field, equals('age'));
      });

      test('adds multiple expression filters', () {
        final query = const Query<User>()
            .whereExpression(UserFields.age.greaterThan(18))
            .whereExpression(UserFields.name.isNotNull())
            .whereExpression(UserFields.status.equals('active'));

        expect(query.filters, hasLength(3));
        expect(query.filters[0].field, equals('age'));
        expect(query.filters[1].field, equals('name'));
        expect(query.filters[2].field, equals('status'));
      });

      test('handles AND expression by flattening to multiple filters', () {
        final query = const Query<User>().whereExpression(
          UserFields.age
              .greaterThan(18)
              .and(UserFields.status.equals('active')),
        );

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, equals('age'));
        expect(query.filters[1].field, equals('status'));
      });

      test('handles nested AND expressions', () {
        final query = const Query<User>().whereExpression(
          UserFields.age
              .greaterThan(18)
              .and(UserFields.age.lessThan(65))
              .and(UserFields.status.equals('active')),
        );

        expect(query.filters, hasLength(3));
      });

      test('throws for OR expression (not supported via toFilters)', () {
        expect(
          () => const Query<User>().whereExpression(
            UserFields.status
                .equals('active')
                .or(UserFields.status.equals('pending')),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('preserves existing query state', () {
        final query = const Query<User>()
            .orderByField('createdAt', descending: true)
            .limitTo(10)
            .offsetBy(5)
            .whereExpression(UserFields.age.greaterThan(18));

        expect(query.filters, hasLength(1));
        expect(query.orderBy, hasLength(1));
        expect(query.orderBy.first.field, equals('createdAt'));
        expect(query.limit, equals(10));
        expect(query.offset, equals(5));
      });
    });

    group('orderByTyped', () {
      test('adds typed ordering to query', () {
        final query = const Query<User>().orderByTyped(UserFields.createdAt);

        expect(query.orderBy, hasLength(1));
        expect(query.orderBy.first.field, equals('createdAt'));
        expect(query.orderBy.first.descending, isFalse);
      });

      test('supports descending order', () {
        final query = const Query<User>()
            .orderByTyped(UserFields.createdAt, descending: true);

        expect(query.orderBy.first.descending, isTrue);
      });

      test('can chain multiple typed orderings', () {
        final query = const Query<User>()
            .orderByTyped(UserFields.createdAt, descending: true)
            .orderByTyped(UserFields.name);

        expect(query.orderBy, hasLength(2));
        expect(query.orderBy[0].field, equals('createdAt'));
        expect(query.orderBy[1].field, equals('name'));
      });

      test('works with StringField', () {
        final query = const Query<User>().orderByTyped(UserFields.name);

        expect(query.orderBy.first.field, equals('name'));
      });

      test('works with ComparableField', () {
        final query = const Query<User>().orderByTyped(UserFields.age);

        expect(query.orderBy.first.field, equals('age'));
      });
    });

    group('mixed usage', () {
      test('combines string-based and type-safe filters', () {
        final query = const Query<User>()
            .where('legacyField', isEqualTo: 'value')
            .whereExpression(UserFields.age.greaterThan(18))
            .where('anotherField', isNotEqualTo: 'other');

        expect(query.filters, hasLength(3));
        expect(query.filters[0].field, equals('legacyField'));
        expect(query.filters[1].field, equals('age'));
        expect(query.filters[2].field, equals('anotherField'));
      });

      test('combines string-based and type-safe ordering', () {
        final query = const Query<User>()
            .orderByField('legacyField')
            .orderByTyped(UserFields.createdAt, descending: true);

        expect(query.orderBy, hasLength(2));
        expect(query.orderBy[0].field, equals('legacyField'));
        expect(query.orderBy[1].field, equals('createdAt'));
      });

      test('full query with expressions, ordering, and pagination', () {
        final now = DateTime.now();

        final query = const Query<User>()
            .whereExpression(UserFields.age.greaterThan(18))
            .whereExpression(UserFields.status.equals('active'))
            .whereExpression(UserFields.createdAt.lessThan(now))
            .orderByTyped(UserFields.createdAt, descending: true)
            .limitTo(20)
            .offsetBy(0);

        expect(query.filters, hasLength(3));
        expect(query.orderBy, hasLength(1));
        expect(query.limit, equals(20));
        expect(query.offset, equals(0));
      });
    });

    group('type safety', () {
      test('StringField provides string-specific methods', () {
        // These should compile and work
        final containsExpr = UserFields.name.contains('John');
        final startsWithExpr = UserFields.name.startsWith('Dr.');
        final endsWithExpr = UserFields.name.endsWith('Jr.');

        expect(containsExpr, isA<ComparisonExpression<User>>());
        expect(startsWithExpr, isA<ComparisonExpression<User>>());
        expect(endsWithExpr, isA<ComparisonExpression<User>>());
      });

      test('ComparableField provides comparison methods', () {
        // These should compile and work
        final gtExpr = UserFields.age.greaterThan(18);
        final ltExpr = UserFields.age.lessThan(65);
        final gteExpr = UserFields.age.greaterThanOrEqualTo(21);
        final lteExpr = UserFields.age.lessThanOrEqualTo(100);

        expect(gtExpr, isA<ComparisonExpression<User>>());
        expect(ltExpr, isA<ComparisonExpression<User>>());
        expect(gteExpr, isA<ComparisonExpression<User>>());
        expect(lteExpr, isA<ComparisonExpression<User>>());
      });

      test('ListField provides array methods', () {
        // These should compile and work
        final containsExpr = UserFields.tags.arrayContains('admin');
        final containsAnyExpr =
            UserFields.tags.arrayContainsAny(['admin', 'moderator']);

        expect(containsExpr, isA<ComparisonExpression<User>>());
        expect(containsAnyExpr, isA<ComparisonExpression<User>>());
      });

      test('all fields have base methods', () {
        // All field types should have equals, notEquals, isNull, isNotNull, isIn
        final nameEquals = UserFields.name.equals('John');
        final ageIsNull = UserFields.age.isNull();
        final statusIsIn = UserFields.status.isIn(['active', 'pending']);
        final tagsNotNull = UserFields.tags.isNotNull();

        expect(nameEquals, isA<ComparisonExpression<User>>());
        expect(ageIsNull, isA<ComparisonExpression<User>>());
        expect(statusIsIn, isA<ComparisonExpression<User>>());
        expect(tagsNotNull, isA<ComparisonExpression<User>>());
      });
    });

    group('immutability', () {
      test('whereExpression returns new query, does not mutate original', () {
        final original = const Query<User>().where('x', isEqualTo: 1);
        final modified =
            original.whereExpression(UserFields.age.greaterThan(18));

        expect(original.filters, hasLength(1));
        expect(modified.filters, hasLength(2));
        expect(identical(original, modified), isFalse);
      });

      test('orderByTyped returns new query, does not mutate original', () {
        final original = const Query<User>().orderByField('x');
        final modified = original.orderByTyped(UserFields.createdAt);

        expect(original.orderBy, hasLength(1));
        expect(modified.orderBy, hasLength(2));
        expect(identical(original, modified), isFalse);
      });
    });
  });
}
