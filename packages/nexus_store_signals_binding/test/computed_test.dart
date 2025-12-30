import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_signals_binding/src/computed/computed_utils.dart';
import 'package:signals/signals.dart';

import 'fixtures/test_entities.dart';

void main() {
  group('SignalListExtensions', () {
    group('filtered', () {
      test('returns computed signal with filtered items', () {
        final source = signal(testUsers);

        final activeUsers = source.filtered((u) => u.isActive);

        expect(activeUsers.value, hasLength(2));
        expect(activeUsers.value, contains(testUser1));
        expect(activeUsers.value, contains(testUser3));
        expect(activeUsers.value, isNot(contains(testUser2)));
      });

      test('updates when source changes', () {
        final source = signal(<TestUser>[testUser1]);

        final activeUsers = source.filtered((u) => u.isActive);

        expect(activeUsers.value, hasLength(1));

        source.value = testUsers;

        expect(activeUsers.value, hasLength(2));
      });

      test('returns empty when no items match', () {
        final source = signal(testUsers);

        final olderThan100 = source.filtered((u) => u.age > 100);

        expect(olderThan100.value, isEmpty);
      });
    });

    group('sorted', () {
      test('returns computed signal with sorted items', () {
        final source = signal(testUsers);

        final byAge = source.sorted((a, b) => a.age.compareTo(b.age));

        expect(byAge.value[0], equals(testUser3)); // age 22
        expect(byAge.value[1], equals(testUser1)); // age 25
        expect(byAge.value[2], equals(testUser2)); // age 30
      });

      test('updates when source changes', () {
        final source = signal(<TestUser>[testUser2, testUser1]);

        final byName = source.sorted((a, b) => a.name.compareTo(b.name));

        expect(byName.value[0].name, equals('Alice'));
        expect(byName.value[1].name, equals('Bob'));

        source.value = [testUser3, testUser1];

        expect(byName.value[0].name, equals('Alice'));
        expect(byName.value[1].name, equals('Charlie'));
      });
    });

    group('count', () {
      test('returns computed signal with item count', () {
        final source = signal(testUsers);

        final count = source.count();

        expect(count.value, equals(3));
      });

      test('updates when source changes', () {
        final source = signal(<TestUser>[testUser1]);

        final count = source.count();

        expect(count.value, equals(1));

        source.value = testUsers;

        expect(count.value, equals(3));
      });

      test('returns 0 for empty list', () {
        final source = signal(<TestUser>[]);

        final count = source.count();

        expect(count.value, equals(0));
      });
    });

    group('firstWhereOrNull', () {
      test('returns computed signal with first matching item', () {
        final source = signal(testUsers);

        final bob = source.firstWhereOrNull((u) => u.name == 'Bob');

        expect(bob.value, equals(testUser2));
      });

      test('returns null when no item matches', () {
        final source = signal(testUsers);

        final notFound = source.firstWhereOrNull((u) => u.name == 'Nobody');

        expect(notFound.value, isNull);
      });

      test('updates when source changes', () {
        final source = signal(<TestUser>[testUser1]);

        final bob = source.firstWhereOrNull((u) => u.name == 'Bob');

        expect(bob.value, isNull);

        source.value = testUsers;

        expect(bob.value, equals(testUser2));
      });
    });

    group('mapped', () {
      test('returns computed signal with mapped items', () {
        final source = signal(testUsers);

        final names = source.mapped((u) => u.name);

        expect(names.value, equals(['Alice', 'Bob', 'Charlie']));
      });

      test('updates when source changes', () {
        final source = signal(<TestUser>[testUser1]);

        final names = source.mapped((u) => u.name);

        expect(names.value, equals(['Alice']));

        source.value = [testUser2, testUser3];

        expect(names.value, equals(['Bob', 'Charlie']));
      });
    });

    group('any', () {
      test('returns true if any item matches predicate', () {
        final source = signal(testUsers);

        final hasInactive = source.any((u) => !u.isActive);

        expect(hasInactive.value, isTrue);
      });

      test('returns false if no item matches', () {
        final source = signal([testUser1, testUser3]); // both active

        final hasInactive = source.any((u) => !u.isActive);

        expect(hasInactive.value, isFalse);
      });
    });

    group('every', () {
      test('returns true if all items match predicate', () {
        final source = signal([testUser1, testUser3]); // both active

        final allActive = source.every((u) => u.isActive);

        expect(allActive.value, isTrue);
      });

      test('returns false if any item does not match', () {
        final source = signal(testUsers);

        final allActive = source.every((u) => u.isActive);

        expect(allActive.value, isFalse);
      });
    });
  });
}
