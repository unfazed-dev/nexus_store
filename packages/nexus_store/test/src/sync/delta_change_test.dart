import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/field_change.dart';
import 'package:test/test.dart';

void main() {
  group('DeltaChange', () {
    late DateTime timestamp;

    setUp(() {
      timestamp = DateTime(2024, 1, 15, 10, 30);
    });

    group('creation', () {
      test('should create with required fields', () {
        final changes = [
          FieldChange(
            fieldName: 'name',
            oldValue: 'John',
            newValue: 'Jane',
            timestamp: timestamp,
          ),
        ];

        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: changes,
          timestamp: timestamp,
        );

        expect(delta.entityId, equals('user-123'));
        expect(delta.changes, equals(changes));
        expect(delta.timestamp, equals(timestamp));
        expect(delta.baseVersion, isNull);
      });

      test('should create with baseVersion for optimistic concurrency', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
          baseVersion: 5,
        );

        expect(delta.baseVersion, equals(5));
      });

      test('should support integer entity IDs', () {
        final delta = DeltaChange<int>(
          entityId: 42,
          changes: [],
          timestamp: timestamp,
        );

        expect(delta.entityId, equals(42));
      });

      test('should create with multiple changes', () {
        final changes = [
          FieldChange(
            fieldName: 'name',
            oldValue: 'John',
            newValue: 'Jane',
            timestamp: timestamp,
          ),
          FieldChange(
            fieldName: 'email',
            oldValue: 'john@example.com',
            newValue: 'jane@example.com',
            timestamp: timestamp,
          ),
          FieldChange(
            fieldName: 'age',
            oldValue: 30,
            newValue: 31,
            timestamp: timestamp,
          ),
        ];

        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: changes,
          timestamp: timestamp,
        );

        expect(delta.changes, hasLength(3));
      });
    });

    group('isEmpty', () {
      test('should return true when no changes', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
        );

        expect(delta.isEmpty, isTrue);
      });

      test('should return false when changes exist', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('should return false when no changes', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
        );

        expect(delta.isNotEmpty, isFalse);
      });

      test('should return true when changes exist', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.isNotEmpty, isTrue);
      });
    });

    group('fieldCount', () {
      test('should return 0 for empty changes', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
        );

        expect(delta.fieldCount, equals(0));
      });

      test('should return correct count for multiple changes', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
            FieldChange(
              fieldName: 'email',
              oldValue: 'john@example.com',
              newValue: 'jane@example.com',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.fieldCount, equals(2));
      });
    });

    group('changedFields', () {
      test('should return empty set for no changes', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
        );

        expect(delta.changedFields, isEmpty);
      });

      test('should return set of changed field names', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
            FieldChange(
              fieldName: 'email',
              oldValue: 'john@example.com',
              newValue: 'jane@example.com',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.changedFields, equals({'name', 'email'}));
      });
    });

    group('getChange', () {
      test('should return change for existing field', () {
        final nameChange = FieldChange(
          fieldName: 'name',
          oldValue: 'John',
          newValue: 'Jane',
          timestamp: timestamp,
        );

        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [nameChange],
          timestamp: timestamp,
        );

        expect(delta.getChange('name'), equals(nameChange));
      });

      test('should return null for non-existent field', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.getChange('email'), isNull);
      });
    });

    group('hasField', () {
      test('should return true for existing field', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.hasField('name'), isTrue);
      });

      test('should return false for non-existent field', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(delta.hasField('email'), isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final changes = [
          FieldChange(
            fieldName: 'name',
            oldValue: 'John',
            newValue: 'Jane',
            timestamp: timestamp,
          ),
        ];

        final delta1 = DeltaChange<String>(
          entityId: 'user-123',
          changes: changes,
          timestamp: timestamp,
        );

        final delta2 = DeltaChange<String>(
          entityId: 'user-123',
          changes: changes,
          timestamp: timestamp,
        );

        expect(delta1, equals(delta2));
        expect(delta1.hashCode, equals(delta2.hashCode));
      });

      test('should not be equal when entityId differs', () {
        final changes = [
          FieldChange(
            fieldName: 'name',
            oldValue: 'John',
            newValue: 'Jane',
            timestamp: timestamp,
          ),
        ];

        final delta1 = DeltaChange<String>(
          entityId: 'user-123',
          changes: changes,
          timestamp: timestamp,
        );

        final delta2 = DeltaChange<String>(
          entityId: 'user-456',
          changes: changes,
          timestamp: timestamp,
        );

        expect(delta1, isNot(equals(delta2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated entityId', () {
        final original = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
        );

        final copied = original.copyWith(entityId: 'user-456');

        expect(copied.entityId, equals('user-456'));
        expect(copied.timestamp, equals(timestamp));
      });

      test('should create copy with updated baseVersion', () {
        final original = DeltaChange<String>(
          entityId: 'user-123',
          changes: [],
          timestamp: timestamp,
          baseVersion: 1,
        );

        final copied = original.copyWith(baseVersion: 2);

        expect(copied.baseVersion, equals(2));
      });
    });

    group('toString', () {
      test('should include entity ID and field count', () {
        final delta = DeltaChange<String>(
          entityId: 'user-123',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final str = delta.toString();

        expect(str, contains('user-123'));
      });
    });
  });
}
