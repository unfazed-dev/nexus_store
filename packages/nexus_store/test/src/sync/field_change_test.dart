import 'package:nexus_store/src/sync/field_change.dart';
import 'package:test/test.dart';

void main() {
  group('FieldChange', () {
    group('creation', () {
      test('should create with required fields', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );

        expect(change.fieldName, equals('name'));
        expect(change.oldValue, equals('John'));
        expect(change.newValue, equals('Jane'));
        expect(change.timestamp, equals(timestamp));
      });

      test('should allow null oldValue for new fields', () {
        final change = FieldChange(
          fieldName: 'email',
          oldValue: null,
          newValue: 'test@example.com',
          timestamp: DateTime.now(),
        );

        expect(change.oldValue, isNull);
        expect(change.newValue, equals('test@example.com'));
      });

      test('should allow null newValue for removed fields', () {
        final change = FieldChange(
          fieldName: 'nickname',
          oldValue: 'Johnny',
          newValue: null,
          timestamp: DateTime.now(),
        );

        expect(change.oldValue, equals('Johnny'));
        expect(change.newValue, isNull);
      });

      test('should handle complex types as values', () {
        final oldMap = {'key': 'value'};
        final newMap = {'key': 'updated'};
        final change = FieldChange(
          fieldName: 'metadata',
          oldValue: oldMap,
          newValue: newMap,
          timestamp: DateTime.now(),
        );

        expect(change.oldValue, equals(oldMap));
        expect(change.newValue, equals(newMap));
      });

      test('should handle list values', () {
        final change = FieldChange(
          fieldName: 'tags',
          oldValue: ['a', 'b'],
          newValue: ['a', 'b', 'c'],
          timestamp: DateTime.now(),
        );

        expect(change.oldValue, equals(['a', 'b']));
        expect(change.newValue, equals(['a', 'b', 'c']));
      });
    });

    group('hasChanged', () {
      test('should return true when values differ', () {
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: DateTime.now(),
        );

        expect(change.hasChanged, isTrue);
      });

      test('should return true when oldValue is null and newValue is not', () {
        final change = FieldChange(
          fieldName: 'email',
          oldValue: null,
          newValue: 'test@example.com',
          timestamp: DateTime.now(),
        );

        expect(change.hasChanged, isTrue);
      });

      test('should return true when oldValue exists and newValue is null', () {
        final change = FieldChange(
          fieldName: 'nickname',
          oldValue: 'Johnny',
          newValue: null,
          timestamp: DateTime.now(),
        );

        expect(change.hasChanged, isTrue);
      });

      test('should return false when both values are null', () {
        final change = FieldChange(
          fieldName: 'optional',
          oldValue: null,
          newValue: null,
          timestamp: DateTime.now(),
        );

        expect(change.hasChanged, isFalse);
      });

      test('should return false when values are equal', () {
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'John',
          timestamp: DateTime.now(),
        );

        expect(change.hasChanged, isFalse);
      });
    });

    group('isAddition', () {
      test('should return true when oldValue is null and newValue is not', () {
        final change = FieldChange(
          fieldName: 'email',
          oldValue: null,
          newValue: 'test@example.com',
          timestamp: DateTime.now(),
        );

        expect(change.isAddition, isTrue);
      });

      test('should return false when oldValue exists', () {
        final change = FieldChange(
          fieldName: 'email',
          oldValue: 'old@example.com',
          newValue: 'new@example.com',
          timestamp: DateTime.now(),
        );

        expect(change.isAddition, isFalse);
      });
    });

    group('isRemoval', () {
      test('should return true when newValue is null and oldValue is not', () {
        final change = FieldChange(
          fieldName: 'nickname',
          oldValue: 'Johnny',
          newValue: null,
          timestamp: DateTime.now(),
        );

        expect(change.isRemoval, isTrue);
      });

      test('should return false when newValue exists', () {
        final change = FieldChange(
          fieldName: 'nickname',
          oldValue: 'Johnny',
          newValue: 'Jon',
          timestamp: DateTime.now(),
        );

        expect(change.isRemoval, isFalse);
      });
    });

    group('isModification', () {
      test('should return true when both values exist and differ', () {
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: DateTime.now(),
        );

        expect(change.isModification, isTrue);
      });

      test('should return false when oldValue is null', () {
        final change = FieldChange(
          fieldName: 'email',
          oldValue: null,
          newValue: 'test@example.com',
          timestamp: DateTime.now(),
        );

        expect(change.isModification, isFalse);
      });

      test('should return false when newValue is null', () {
        final change = FieldChange(
          fieldName: 'nickname',
          oldValue: 'Johnny',
          newValue: null,
          timestamp: DateTime.now(),
        );

        expect(change.isModification, isFalse);
      });

      test('should return false when values are equal', () {
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'John',
          timestamp: DateTime.now(),
        );

        expect(change.isModification, isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final timestamp = DateTime(2024, 1, 15);
        final change1 = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );
        final change2 = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );

        expect(change1, equals(change2));
        expect(change1.hashCode, equals(change2.hashCode));
      });

      test('should not be equal when fieldName differs', () {
        final timestamp = DateTime(2024, 1, 15);
        final change1 = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );
        final change2 = FieldChange(
          fieldName: 'email',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );

        expect(change1, isNot(equals(change2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated field', () {
        final original = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(newValue: 'Janet');

        expect(copied.fieldName, equals('name'));
        expect(copied.oldValue, equals('John'));
        expect(copied.newValue, equals('Janet'));
        expect(copied.timestamp, equals(DateTime(2024, 1, 15)));
      });
    });

    group('toString', () {
      test('should include all fields', () {
        final change = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: DateTime(2024, 1, 15),
        );

        final str = change.toString();

        expect(str, contains('name'));
        expect(str, contains('John'));
        expect(str, contains('Jane'));
      });
    });
  });
}
