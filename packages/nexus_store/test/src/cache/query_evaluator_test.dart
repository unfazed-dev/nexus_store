import 'package:nexus_store/src/cache/query_evaluator.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('InMemoryQueryEvaluator', () {
    late InMemoryQueryEvaluator<TestUser> evaluator;

    setUp(() {
      evaluator = InMemoryQueryEvaluator<TestUser>(
        fieldAccessor: (user, field) => switch (field) {
          'id' => user.id,
          'name' => user.name,
          'email' => user.email,
          'age' => user.age,
          'isActive' => user.isActive,
          _ => null,
        },
      );
    });

    group('equals filter', () {
      test('should evaluate equals filter', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', name: 'Alice'),
          TestFixtures.createUser(id: 'user-2', name: 'Bob'),
        ];

        final query = Query<TestUser>().where('name', isEqualTo: 'Alice');
        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(1));
        expect(matches.first.name, equals('Alice'));
      });

      test('should evaluate equals filter for booleans', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', isActive: true),
          TestFixtures.createUser(id: 'user-2', isActive: false),
        ];

        final query = Query<TestUser>().where('isActive', isEqualTo: true);
        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(1));
        expect(matches.first.id, equals('user-1'));
      });
    });

    group('notEquals filter', () {
      test('should evaluate notEquals filter', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', name: 'Alice'),
          TestFixtures.createUser(id: 'user-2', name: 'Bob'),
          TestFixtures.createUser(id: 'user-3', name: 'Charlie'),
        ];

        final query = Query<TestUser>().where('name', isNotEqualTo: 'Bob');
        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2));
        expect(matches.map((u) => u.name), containsAll(['Alice', 'Charlie']));
      });
    });

    group('comparison filters', () {
      test('should evaluate greaterThan filter', () {
        final users = TestFixtures.createUsers(5); // ages 20-24
        final query = Query<TestUser>().where('age', isGreaterThan: 22);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2)); // ages 23 and 24
        expect(matches.every((u) => u.age! > 22), isTrue);
      });

      test('should evaluate greaterThanOrEqualTo filter', () {
        final users = TestFixtures.createUsers(5); // ages 20-24
        final query =
            Query<TestUser>().where('age', isGreaterThanOrEqualTo: 22);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(3)); // ages 22, 23, 24
        expect(matches.every((u) => u.age! >= 22), isTrue);
      });

      test('should evaluate lessThan filter', () {
        final users = TestFixtures.createUsers(5); // ages 20-24
        final query = Query<TestUser>().where('age', isLessThan: 22);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2)); // ages 20 and 21
        expect(matches.every((u) => u.age! < 22), isTrue);
      });

      test('should evaluate lessThanOrEqualTo filter', () {
        final users = TestFixtures.createUsers(5); // ages 20-24
        final query = Query<TestUser>().where('age', isLessThanOrEqualTo: 22);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(3)); // ages 20, 21, 22
        expect(matches.every((u) => u.age! <= 22), isTrue);
      });
    });

    group('whereIn filter', () {
      test('should evaluate whereIn filter', () {
        final users = TestFixtures.createUsers(5);
        final query =
            Query<TestUser>().where('id', whereIn: ['user-0', 'user-2']);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2));
        expect(matches.map((u) => u.id), containsAll(['user-0', 'user-2']));
      });

      test('should return empty for empty whereIn list', () {
        final users = TestFixtures.createUsers(5);
        final query = Query<TestUser>().where('id', whereIn: []);

        final matches = evaluator.evaluate(users, query);

        expect(matches, isEmpty);
      });
    });

    group('whereNotIn filter', () {
      test('should evaluate whereNotIn filter', () {
        final users = TestFixtures.createUsers(3);
        final query = Query<TestUser>().where('id', whereNotIn: ['user-1']);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2));
        expect(matches.map((u) => u.id), containsAll(['user-0', 'user-2']));
      });
    });

    group('null filters', () {
      test('should evaluate isNull filter', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', age: 25),
          TestFixtures.createUser(id: 'user-2', age: null),
        ];

        final query = Query<TestUser>().where('age', isNull: true);
        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(1));
        expect(matches.first.id, equals('user-2'));
      });

      test('should evaluate isNotNull filter', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', age: 25),
          TestFixtures.createUser(id: 'user-2', age: null),
        ];

        final query = Query<TestUser>().where('age', isNull: false);
        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(1));
        expect(matches.first.id, equals('user-1'));
      });
    });

    group('multiple filters (AND)', () {
      test('should evaluate multiple filters as AND', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', age: 25, isActive: true),
          TestFixtures.createUser(id: 'user-2', age: 30, isActive: true),
          TestFixtures.createUser(id: 'user-3', age: 25, isActive: false),
        ];

        final query = Query<TestUser>()
            .where('age', isGreaterThan: 22)
            .where('isActive', isEqualTo: true);

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(2)); // user-1 and user-2
        expect(
          matches.map((u) => u.id),
          containsAll(['user-1', 'user-2']),
        );
      });

      test('should return empty when no items match all filters', () {
        final users = [
          TestFixtures.createUser(id: 'user-1', age: 25, isActive: true),
          TestFixtures.createUser(id: 'user-2', age: 30, isActive: false),
        ];

        final query = Query<TestUser>()
            .where('age', isGreaterThan: 28)
            .where('isActive', isEqualTo: true);

        final matches = evaluator.evaluate(users, query);

        expect(matches, isEmpty);
      });
    });

    group('matches method', () {
      test('should return true when item matches query', () {
        final user = TestFixtures.createUser(name: 'Alice', age: 25);
        final query = Query<TestUser>().where('name', isEqualTo: 'Alice');

        expect(evaluator.matches(user, query), isTrue);
      });

      test('should return false when item does not match query', () {
        final user = TestFixtures.createUser(name: 'Bob', age: 25);
        final query = Query<TestUser>().where('name', isEqualTo: 'Alice');

        expect(evaluator.matches(user, query), isFalse);
      });

      test('should return true for empty query', () {
        final user = TestFixtures.createUser();
        final query = Query<TestUser>();

        expect(evaluator.matches(user, query), isTrue);
      });
    });

    group('empty query', () {
      test('should return all items for empty query', () {
        final users = TestFixtures.createUsers(5);
        final query = Query<TestUser>();

        final matches = evaluator.evaluate(users, query);

        expect(matches, hasLength(5));
      });
    });

    group('unknown field', () {
      test('should handle unknown field gracefully', () {
        final users = [TestFixtures.createUser()];
        final query =
            Query<TestUser>().where('unknownField', isEqualTo: 'value');

        final matches = evaluator.evaluate(users, query);

        // Unknown field returns null, which doesn't equal 'value'
        expect(matches, isEmpty);
      });
    });

    group('_compareValues edge cases (lines 99, 106)', () {
      test('compares null field value in lessThan filter (line 99)', () {
        // Create users with null and non-null age values
        final users = [
          TestFixtures.createUser(id: 'user-1', name: 'Alice', age: 25),
          TestFixtures.createUser(id: 'user-2', name: 'Bob', age: null),
          TestFixtures.createUser(id: 'user-3', name: 'Charlie', age: 30),
        ];

        // lessThan comparison: _compareValues(value, filterValue) < 0
        // For null age: _compareValues(null, 30) returns -1 (line 99)
        // -1 < 0 is true, so null matches lessThan filter
        final query = Query<TestUser>().where('age', isLessThan: 30);
        final matches = evaluator.evaluate(users, query);

        // Should include: user with null age (null < 30 due to line 99 returning -1)
        // and user with age 25 (25 < 30)
        expect(matches.length, equals(2));
        expect(matches.any((u) => u.age == null), isTrue);
        expect(matches.any((u) => u.age == 25), isTrue);
      });

      test('compares non-Comparable values using toString (line 106)', () {
        // Create an evaluator that returns non-Comparable objects
        final evaluatorWithObjects = InMemoryQueryEvaluator<TestUser>(
          fieldAccessor: (user, field) => switch (field) {
            'id' => user.id,
            'name' => user.name,
            // Return a non-Comparable object for testing toString comparison
            'custom' => _NonComparableObject(user.name),
            _ => null,
          },
        );

        final users = [
          TestFixtures.createUser(id: 'user-1', name: 'Zoe'),
          TestFixtures.createUser(id: 'user-2', name: 'Alice'),
          TestFixtures.createUser(id: 'user-3', name: 'Bob'),
        ];

        // Use greaterThan filter with non-Comparable objects
        // This will fall through to toString comparison (line 106)
        // Comparing: _NonComparableObject.toString() > filterValue.toString()
        final filterValue = _NonComparableObject('B');
        final query =
            Query<TestUser>().where('custom', isGreaterThan: filterValue);
        final matches = evaluatorWithObjects.evaluate(users, query);

        // String comparison: 'Bob' > 'B' is true, 'Zoe' > 'B' is true, 'Alice' > 'B' is false
        expect(matches.length, equals(2));
        expect(matches.any((u) => u.name == 'Bob'), isTrue);
        expect(matches.any((u) => u.name == 'Zoe'), isTrue);
        expect(matches.any((u) => u.name == 'Alice'), isFalse);
      });
    });
  });
}

/// A non-Comparable class for testing toString fallback in comparisons.
class _NonComparableObject {
  _NonComparableObject(this.value);
  final String value;

  @override
  String toString() => value;
}
