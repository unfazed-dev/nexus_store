import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/delta_tracker.dart';
import 'package:test/test.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('DeltaTracker', () {
    late DeltaTracker tracker;

    setUp(() {
      tracker = DeltaTracker();
    });

    group('trackChanges', () {
      test('should detect no changes when entities are identical', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
        );

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.isEmpty, isTrue);
        expect(delta.changes, isEmpty);
      });

      test('should detect single field change', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
        );

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.isNotEmpty, isTrue);
        expect(delta.fieldCount, equals(1));
        expect(delta.hasField('name'), isTrue);

        final nameChange = delta.getChange('name');
        expect(nameChange!.oldValue, equals('John'));
        expect(nameChange.newValue, equals('Jane'));
      });

      test('should detect multiple field changes', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
          age: 30,
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'jane@example.com',
          age: 31,
        );

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.fieldCount, equals(3));
        expect(delta.changedFields, containsAll(['name', 'email', 'age']));
      });

      test('should handle null to value change', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          age: null,
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          age: 30,
        );

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.hasField('age'), isTrue);
        final ageChange = delta.getChange('age');
        expect(ageChange!.oldValue, isNull);
        expect(ageChange.newValue, equals(30));
        expect(ageChange.isAddition, isTrue);
      });

      test('should handle value to null change', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          age: 30,
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          age: null,
        );

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.hasField('age'), isTrue);
        final ageChange = delta.getChange('age');
        expect(ageChange!.oldValue, equals(30));
        expect(ageChange.newValue, isNull);
        expect(ageChange.isRemoval, isTrue);
      });

      test('should preserve entity ID in delta', () {
        final original = TestFixtures.createUser(id: 'user-123', name: 'John');
        final modified = TestFixtures.createUser(id: 'user-123', name: 'Jane');

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-123',
        );

        expect(delta.entityId, equals('user-123'));
      });

      test('should work with integer entity IDs', () {
        final original = TestFixtures.createProduct(id: 42, name: 'Widget');
        final modified = TestFixtures.createProduct(id: 42, name: 'Gadget');

        final delta = tracker.trackChanges<int>(
          original: original,
          modified: modified,
          entityId: 42,
        );

        expect(delta.entityId, equals(42));
        expect(delta.hasField('name'), isTrue);
      });

      test('should set timestamp on delta', () {
        final before = DateTime.now();
        final original = TestFixtures.createUser(name: 'John');
        final modified = TestFixtures.createUser(name: 'Jane');

        final delta = tracker.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        final after = DateTime.now();

        expect(delta.timestamp.isAfter(before) || delta.timestamp == before,
            isTrue);
        expect(delta.timestamp.isBefore(after) || delta.timestamp == after,
            isTrue);
      });
    });

    group('trackChanges with config', () {
      test('should exclude configured fields', () {
        final config = DeltaSyncConfig(
          excludeFields: {'email'},
        );
        final trackerWithConfig = DeltaTracker(config: config);

        final original = TestFixtures.createUser(
          name: 'John',
          email: 'john@example.com',
        );
        final modified = TestFixtures.createUser(
          name: 'Jane',
          email: 'jane@example.com',
        );

        final delta = trackerWithConfig.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.hasField('name'), isTrue);
        expect(delta.hasField('email'), isFalse);
      });

      test('should exclude multiple fields', () {
        final config = DeltaSyncConfig(
          excludeFields: {'email', 'age'},
        );
        final trackerWithConfig = DeltaTracker(config: config);

        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
          age: 30,
        );
        final modified = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'jane@example.com',
          age: 31,
        );

        final delta = trackerWithConfig.trackChanges(
          original: original,
          modified: modified,
          entityId: 'user-1',
        );

        expect(delta.hasField('name'), isTrue);
        expect(delta.hasField('email'), isFalse);
        expect(delta.hasField('age'), isFalse);
        expect(delta.fieldCount, equals(1));
      });
    });

    group('getChangedFields', () {
      test('should return empty list for identical entities', () {
        final original = TestFixtures.createUser(name: 'John');
        final modified = TestFixtures.createUser(name: 'John');

        final fields = tracker.getChangedFields(
          original: original,
          modified: modified,
        );

        expect(fields, isEmpty);
      });

      test('should return list of changed field names', () {
        final original = TestFixtures.createUser(
          name: 'John',
          email: 'john@example.com',
        );
        final modified = TestFixtures.createUser(
          name: 'Jane',
          email: 'jane@example.com',
        );

        final fields = tracker.getChangedFields(
          original: original,
          modified: modified,
        );

        expect(fields, containsAll(['name', 'email']));
        expect(fields, hasLength(2));
      });
    });

    group('hasChanges', () {
      test('should return false for identical entities', () {
        final original = TestFixtures.createUser(name: 'John');
        final modified = TestFixtures.createUser(name: 'John');

        expect(
          tracker.hasChanges(original: original, modified: modified),
          isFalse,
        );
      });

      test('should return true when entities differ', () {
        final original = TestFixtures.createUser(name: 'John');
        final modified = TestFixtures.createUser(name: 'Jane');

        expect(
          tracker.hasChanges(original: original, modified: modified),
          isTrue,
        );
      });
    });

    group('nested object comparison', () {
      test('should detect changes in nested map values', () {
        // Using raw maps to test nested comparison
        final original = {
          'metadata': {'key': 'value1'}
        };
        final modified = {
          'metadata': {'key': 'value2'}
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.hasField('metadata'), isTrue);
      });

      test('should not detect changes when nested maps are equal', () {
        final original = {
          'metadata': {'key': 'value'}
        };
        final modified = {
          'metadata': {'key': 'value'}
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.isEmpty, isTrue);
      });
    });

    group('collection comparison', () {
      test('should detect changes in list values', () {
        final original = {
          'tags': ['a', 'b']
        };
        final modified = {
          'tags': ['a', 'b', 'c']
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.hasField('tags'), isTrue);
        final tagsChange = delta.getChange('tags');
        expect(tagsChange!.oldValue, equals(['a', 'b']));
        expect(tagsChange.newValue, equals(['a', 'b', 'c']));
      });

      test('should not detect changes when lists are equal', () {
        final original = {
          'tags': ['a', 'b']
        };
        final modified = {
          'tags': ['a', 'b']
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.isEmpty, isTrue);
      });

      test('should detect list reordering as change', () {
        final original = {
          'tags': ['a', 'b']
        };
        final modified = {
          'tags': ['b', 'a']
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        // Reordering is a change since list equality is order-sensitive
        expect(delta.hasField('tags'), isTrue);
      });
    });

    group('edge cases', () {
      test('should handle empty entities', () {
        final original = <String, dynamic>{};
        final modified = <String, dynamic>{};

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.isEmpty, isTrue);
      });

      test('should detect new fields in modified', () {
        final original = {'name': 'John'};
        final modified = {'name': 'John', 'email': 'john@example.com'};

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.hasField('email'), isTrue);
        final emailChange = delta.getChange('email');
        expect(emailChange!.oldValue, isNull);
        expect(emailChange.newValue, equals('john@example.com'));
      });

      test('should detect removed fields in modified', () {
        final original = {'name': 'John', 'email': 'john@example.com'};
        final modified = {'name': 'John'};

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: 'entity-1',
        );

        expect(delta.hasField('email'), isTrue);
        final emailChange = delta.getChange('email');
        expect(emailChange!.oldValue, equals('john@example.com'));
        expect(emailChange.newValue, isNull);
      });
    });
  });
}
