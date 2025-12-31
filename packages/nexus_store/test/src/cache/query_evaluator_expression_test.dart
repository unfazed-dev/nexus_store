import 'package:test/test.dart';
import 'package:nexus_store/src/cache/query_evaluator.dart';
import 'package:nexus_store/src/query/field.dart';
import 'package:nexus_store/src/query/fields.dart';

// Test entity
class User {
  final String id;
  final String name;
  final int age;
  final String? status;
  final List<String> tags;

  User({
    required this.id,
    required this.name,
    required this.age,
    this.status,
    required this.tags,
  });
}

// Test fields
class UserFields extends Fields<User> {
  static final id = StringField<User>('id');
  static final name = StringField<User>('name');
  static final age = ComparableField<User, int>('age');
  static final status = Field<User, String?>('status');
  static final tags = ListField<User, String>('tags');
}

void main() {
  late InMemoryQueryEvaluator<User> evaluator;

  // Field accessor for User
  Object? fieldAccessor(User user, String field) {
    return switch (field) {
      'id' => user.id,
      'name' => user.name,
      'age' => user.age,
      'status' => user.status,
      'tags' => user.tags,
      _ => throw ArgumentError('Unknown field: $field'),
    };
  }

  setUp(() {
    evaluator = InMemoryQueryEvaluator<User>(fieldAccessor: fieldAccessor);
  });

  group('InMemoryQueryEvaluator.matchesExpression', () {
    group('ComparisonExpression', () {
      test('matches equals expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );
        final expr = UserFields.name.equals('John');

        expect(evaluator.matchesExpression(user, expr), isTrue);
        expect(
          evaluator.matchesExpression(user, UserFields.name.equals('Jane')),
          isFalse,
        );
      });

      test('matches notEquals expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.name.notEquals('Jane')),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.name.notEquals('John')),
          isFalse,
        );
      });

      test('matches greaterThan expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.age.greaterThan(20)),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.age.greaterThan(25)),
          isFalse,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.age.greaterThan(30)),
          isFalse,
        );
      });

      test('matches lessThan expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.age.lessThan(30)),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.age.lessThan(25)),
          isFalse,
        );
      });

      test('matches greaterThanOrEqualTo expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(
            user,
            UserFields.age.greaterThanOrEqualTo(25),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            user,
            UserFields.age.greaterThanOrEqualTo(20),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            user,
            UserFields.age.greaterThanOrEqualTo(30),
          ),
          isFalse,
        );
      });

      test('matches isNull expression', () {
        final userWithStatus = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );
        final userWithoutStatus = User(
          id: '2',
          name: 'Jane',
          age: 30,
          status: null,
          tags: [],
        );

        expect(
          evaluator.matchesExpression(
              userWithStatus, UserFields.status.isNull()),
          isFalse,
        );
        expect(
          evaluator.matchesExpression(
            userWithoutStatus,
            UserFields.status.isNull(),
          ),
          isTrue,
        );
      });

      test('matches isNotNull expression', () {
        final userWithStatus = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );
        final userWithoutStatus = User(
          id: '2',
          name: 'Jane',
          age: 30,
          status: null,
          tags: [],
        );

        expect(
          evaluator.matchesExpression(
            userWithStatus,
            UserFields.status.isNotNull(),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            userWithoutStatus,
            UserFields.status.isNotNull(),
          ),
          isFalse,
        );
      });

      test('matches isIn expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(
            user,
            UserFields.name.isIn(['John', 'Jane', 'Bob']),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            user,
            UserFields.name.isIn(['Alice', 'Bob']),
          ),
          isFalse,
        );
      });

      test('matches contains expression (string)', () {
        final user = User(
          id: '1',
          name: 'John Smith',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.name.contains('Smith')),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.name.contains('Jones')),
          isFalse,
        );
      });

      test('matches startsWith expression', () {
        final user = User(
          id: '1',
          name: 'John Smith',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.name.startsWith('John')),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
              user, UserFields.name.startsWith('Smith')),
          isFalse,
        );
      });

      test('matches endsWith expression', () {
        final user = User(
          id: '1',
          name: 'John Smith',
          age: 25,
          status: 'active',
          tags: [],
        );

        expect(
          evaluator.matchesExpression(user, UserFields.name.endsWith('Smith')),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(user, UserFields.name.endsWith('John')),
          isFalse,
        );
      });

      test('matches arrayContains expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: ['admin', 'user'],
        );

        expect(
          evaluator.matchesExpression(
            user,
            UserFields.tags.arrayContains('admin'),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            user,
            UserFields.tags.arrayContains('moderator'),
          ),
          isFalse,
        );
      });

      test('matches arrayContainsAny expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: ['admin', 'user'],
        );

        expect(
          evaluator.matchesExpression(
            user,
            UserFields.tags.arrayContainsAny(['admin', 'moderator']),
          ),
          isTrue,
        );
        expect(
          evaluator.matchesExpression(
            user,
            UserFields.tags.arrayContainsAny(['moderator', 'guest']),
          ),
          isFalse,
        );
      });
    });

    group('AndExpression', () {
      test('matches when both sides are true', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.age.greaterThan(18).and(
              UserFields.name.equals('John'),
            );

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });

      test('does not match when left side is false', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 15,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.age.greaterThan(18).and(
              UserFields.name.equals('John'),
            );

        expect(evaluator.matchesExpression(user, expr), isFalse);
      });

      test('does not match when right side is false', () {
        final user = User(
          id: '1',
          name: 'Jane',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.age.greaterThan(18).and(
              UserFields.name.equals('John'),
            );

        expect(evaluator.matchesExpression(user, expr), isFalse);
      });

      test('handles nested AND expressions', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: ['admin'],
        );

        final expr = UserFields.age
            .greaterThan(18)
            .and(UserFields.age.lessThan(30))
            .and(UserFields.tags.arrayContains('admin'));

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });
    });

    group('OrExpression', () {
      test('matches when left side is true', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('John').or(
              UserFields.name.equals('Jane'),
            );

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });

      test('matches when right side is true', () {
        final user = User(
          id: '1',
          name: 'Jane',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('John').or(
              UserFields.name.equals('Jane'),
            );

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });

      test('matches when both sides are true', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('John').or(
              UserFields.age.greaterThan(18),
            );

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });

      test('does not match when both sides are false', () {
        final user = User(
          id: '1',
          name: 'Bob',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('John').or(
              UserFields.name.equals('Jane'),
            );

        expect(evaluator.matchesExpression(user, expr), isFalse);
      });
    });

    group('NotExpression', () {
      test('inverts true to false', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('John').not();

        expect(evaluator.matchesExpression(user, expr), isFalse);
      });

      test('inverts false to true', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        final expr = UserFields.name.equals('Jane').not();

        expect(evaluator.matchesExpression(user, expr), isTrue);
      });

      test('NOT on AND expression', () {
        final user = User(
          id: '1',
          name: 'John',
          age: 25,
          status: 'active',
          tags: [],
        );

        // NOT (age > 18 AND name = 'John') = age <= 18 OR name != 'John'
        final expr = UserFields.age.greaterThan(18).and(
              UserFields.name.equals('John'),
            );

        expect(evaluator.matchesExpression(user, expr), isTrue);
        expect(evaluator.matchesExpression(user, expr.not()), isFalse);
      });

      test('NOT on OR expression', () {
        final user = User(
          id: '1',
          name: 'Bob',
          age: 25,
          status: 'active',
          tags: [],
        );

        // NOT (name = 'John' OR name = 'Jane')
        final expr = UserFields.name.equals('John').or(
              UserFields.name.equals('Jane'),
            );

        expect(evaluator.matchesExpression(user, expr), isFalse);
        expect(evaluator.matchesExpression(user, expr.not()), isTrue);
      });
    });

    group('complex expressions', () {
      test('(age > 18 AND status = active) OR tags contains admin', () {
        final users = [
          User(
              id: '1',
              name: 'Adult Active',
              age: 25,
              status: 'active',
              tags: []),
          User(
              id: '2',
              name: 'Adult Inactive',
              age: 25,
              status: 'inactive',
              tags: []),
          User(
              id: '3',
              name: 'Minor Admin',
              age: 15,
              status: 'inactive',
              tags: ['admin']),
          User(
              id: '4',
              name: 'Minor NonAdmin',
              age: 15,
              status: 'inactive',
              tags: []),
        ];

        // Creating a typed expression that can be cast
        final ageGt18 = UserFields.age.greaterThan(18);
        final statusActive = UserFields.status.equals('active');
        final hasAdmin = UserFields.tags.arrayContains('admin');
        final expr = ageGt18.and(statusActive).or(hasAdmin);

        final matches =
            users.where((u) => evaluator.matchesExpression(u, expr)).toList();

        expect(matches, hasLength(2));
        expect(matches.map((u) => u.name),
            containsAll(['Adult Active', 'Minor Admin']));
      });

      test('deeply nested expressions', () {
        final user = User(
          id: '1',
          name: 'John Smith',
          age: 25,
          status: 'active',
          tags: ['admin', 'user'],
        );

        // (age >= 18 AND age < 65) AND (status = 'active' OR tags contains 'admin')
        // AND name starts with 'John'
        final ageExpr = UserFields.age.greaterThanOrEqualTo(18).and(
              UserFields.age.lessThan(65),
            );
        final statusOrAdmin = UserFields.status.equals('active').or(
              UserFields.tags.arrayContains('admin'),
            );
        final nameExpr = UserFields.name.startsWith('John');

        final fullExpr = ageExpr.and(statusOrAdmin).and(nameExpr);

        expect(evaluator.matchesExpression(user, fullExpr), isTrue);
      });
    });

    group('evaluateWithExpression', () {
      test('filters list using expression', () {
        final users = [
          User(id: '1', name: 'John', age: 25, status: 'active', tags: []),
          User(id: '2', name: 'Jane', age: 30, status: 'active', tags: []),
          User(id: '3', name: 'Bob', age: 15, status: 'inactive', tags: []),
          User(id: '4', name: 'Alice', age: 40, status: 'active', tags: []),
        ];

        final expr = UserFields.age.greaterThan(20).and(
              UserFields.status.equals('active'),
            );

        final results = evaluator.evaluateWithExpression(users, expr);

        expect(results, hasLength(3));
        expect(
            results.map((u) => u.name), containsAll(['John', 'Jane', 'Alice']));
      });

      test('returns all items for empty/always-true expression', () {
        final users = [
          User(id: '1', name: 'John', age: 25, status: 'active', tags: []),
          User(id: '2', name: 'Jane', age: 30, status: 'active', tags: []),
        ];

        // Always true: name is not null (assuming all users have names)
        final expr = UserFields.name.isNotNull();

        final results = evaluator.evaluateWithExpression(users, expr);

        expect(results, hasLength(2));
      });

      test('returns empty list when no items match', () {
        final users = [
          User(id: '1', name: 'John', age: 25, status: 'active', tags: []),
          User(id: '2', name: 'Jane', age: 30, status: 'active', tags: []),
        ];

        final expr = UserFields.age.greaterThan(100);

        final results = evaluator.evaluateWithExpression(users, expr);

        expect(results, isEmpty);
      });
    });
  });
}
