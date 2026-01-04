import 'package:nexus_store/src/sync/tracked_entity.dart';
import 'package:test/test.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('TrackedEntity', () {
    group('creation', () {
      test('should store original value', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(user);

        expect(tracked.original, equals(user));
      });

      test('should have current equal to original initially', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(user);

        expect(tracked.current, equals(user));
      });

      test('should support generic ID extraction', () {
        final user = TestFixtures.createUser(id: 'user-123', name: 'John');
        final tracked = TrackedEntity(
          user,
          idExtractor: (u) => u.id,
        );

        expect(tracked.entityId, equals('user-123'));
      });
    });

    group('current', () {
      test('should allow setting new current value', () {
        final original = TestFixtures.createUser(name: 'John');
        final modified = TestFixtures.createUser(name: 'Jane');
        final tracked = TrackedEntity(original);

        tracked.current = modified;

        expect(tracked.current, equals(modified));
        expect(tracked.original, equals(original));
      });

      test('should preserve original when current is modified', () {
        final original = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(name: 'Jane');
        tracked.current = TestFixtures.createUser(name: 'Janet');

        expect(tracked.original.name, equals('John'));
        expect(tracked.current.name, equals('Janet'));
      });
    });

    group('hasChanges', () {
      test('should return false when current equals original', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(user);

        expect(tracked.hasChanges, isFalse);
      });

      test('should return true when current differs from original', () {
        final original = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(name: 'Jane');

        expect(tracked.hasChanges, isTrue);
      });

      test('should return false after reset', () {
        final original = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(name: 'Jane');
        tracked.reset();

        expect(tracked.hasChanges, isFalse);
      });
    });

    group('reset', () {
      test('should reset current to original', () {
        final original = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(name: 'Jane');
        tracked.reset();

        expect(tracked.current, equals(original));
      });

      test('should not affect original', () {
        final original = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(name: 'Jane');
        tracked.reset();

        expect(tracked.original.name, equals('John'));
      });
    });

    group('getDelta', () {
      test('throws StateError when no entityId and no idExtractor (line 101)',
          () {
        // Line 101: throw StateError(...)
        // When getDelta is called without entityId parameter and no idExtractor
        final user = TestFixtures.createUser(name: 'John');
        // Create TrackedEntity without idExtractor
        final tracked = TrackedEntity(user);

        tracked.current = TestFixtures.createUser(name: 'Jane');

        // Should throw because no entityId provided and no idExtractor
        expect(
          () => tracked.getDelta(),
          throwsStateError,
        );
      });

      test('should return empty delta when no changes', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(
          user,
          idExtractor: (u) => u.id,
        );

        final delta = tracked.getDelta();

        expect(delta.isEmpty, isTrue);
      });

      test('should return delta with changed fields', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
        );
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'john@example.com',
        );

        final delta = tracked.getDelta();

        expect(delta.entityId, equals('user-1'));
        expect(delta.hasField('name'), isTrue);
        expect(delta.hasField('email'), isFalse);
      });

      test('should track multiple changes', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
          age: 30,
        );
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'jane@example.com',
          age: 31,
        );

        final delta = tracked.getDelta();

        expect(delta.fieldCount, equals(3));
        expect(delta.changedFields, containsAll(['name', 'email', 'age']));
      });

      test('should use provided entityId', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(user);

        tracked.current = TestFixtures.createUser(name: 'Jane');
        final delta = tracked.getDelta(entityId: 'custom-id');

        expect(delta.entityId, equals('custom-id'));
      });
    });

    group('getChangedFields', () {
      test('should return empty list when no changes', () {
        final user = TestFixtures.createUser(name: 'John');
        final tracked = TrackedEntity(user);

        expect(tracked.getChangedFields(), isEmpty);
      });

      test('should return list of changed field names', () {
        final original = TestFixtures.createUser(
          name: 'John',
          email: 'john@example.com',
        );
        final tracked = TrackedEntity(original);

        tracked.current = TestFixtures.createUser(
          name: 'Jane',
          email: 'jane@example.com',
        );

        final fields = tracked.getChangedFields();

        expect(fields, containsAll(['name', 'email']));
      });
    });

    group('commit', () {
      test('should update original to current', () {
        final original = TestFixtures.createUser(id: 'user-1', name: 'John');
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(id: 'user-1', name: 'Jane');
        tracked.commit();

        expect(tracked.original.name, equals('Jane'));
        expect(tracked.hasChanges, isFalse);
      });

      test('should return the committed changes as delta', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
        );
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
        );

        final delta = tracked.commit();

        expect(delta.hasField('name'), isTrue);
        expect(tracked.hasChanges, isFalse);
      });
    });

    group('with integer IDs', () {
      test('should work with products (int ID)', () {
        final original = TestFixtures.createProduct(id: 42, name: 'Widget');
        final tracked = TrackedEntity(
          original,
          idExtractor: (p) => p.id,
        );

        tracked.current = TestFixtures.createProduct(id: 42, name: 'Gadget');

        final delta = tracked.getDelta();

        expect(delta.entityId, equals(42));
        expect(delta.hasField('name'), isTrue);
      });
    });
  });
}
