import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/delta_merge_strategy.dart';
import 'package:nexus_store/src/sync/delta_merger.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/delta_tracker.dart';
import 'package:nexus_store/src/sync/field_change.dart';
import 'package:nexus_store/src/sync/tracked_entity.dart';
import 'package:test/test.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('Delta Sync Integration', () {
    group('complete workflow: track → delta → apply', () {
      test('should track changes and apply delta to base', () {
        // 1. Create original entity
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
          age: 30,
        );

        // 2. Track with TrackedEntity
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        // 3. Modify the entity
        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'john@example.com',
          age: 31,
        );

        // 4. Get the delta
        final delta = tracked.getDelta();

        // 5. Verify delta contents
        expect(delta.entityId, equals('user-1'));
        expect(delta.fieldCount, equals(2));
        expect(delta.changedFields, containsAll(['name', 'age']));

        // 6. Apply delta using merger
        final merger = DeltaMerger();
        final baseJson = original.toJson();
        final merged = merger.applyDelta(baseJson, delta);

        // 7. Verify merged result
        expect(merged['name'], equals('Jane'));
        expect(merged['age'], equals(31));
        expect(merged['email'], equals('john@example.com'));
      });

      test('should handle multiple sequential changes', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
        );

        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        // First modification
        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'john@example.com',
        );

        // Second modification
        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Janet',
          email: 'janet@example.com',
        );

        final delta = tracked.getDelta();

        // Should track all changes from original
        expect(delta.changedFields, containsAll(['name', 'email']));

        final nameChange = delta.getChange('name');
        expect(nameChange?.oldValue, equals('John'));
        expect(nameChange?.newValue, equals('Janet'));
      });

      test('should commit changes and reset tracking', () {
        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
        );

        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        // Make first batch of changes
        tracked.current = TestFixtures.createUser(id: 'user-1', name: 'Jane');
        final delta1 = tracked.commit();

        expect(delta1.hasField('name'), isTrue);
        expect(tracked.hasChanges, isFalse);

        // Make second batch of changes
        tracked.current = TestFixtures.createUser(id: 'user-1', name: 'Janet');
        final delta2 = tracked.getDelta();

        // Second delta should be from Jane → Janet, not John → Janet
        final nameChange = delta2.getChange('name');
        expect(nameChange?.oldValue, equals('Jane'));
        expect(nameChange?.newValue, equals('Janet'));
      });
    });

    group('conflict detection and resolution', () {
      late DeltaTracker tracker;

      setUp(() {
        tracker = DeltaTracker();
      });

      test('should detect conflicts when same field modified locally and remotely', () async {
        final base = {'id': '1', 'name': 'John', 'email': 'john@example.com'};

        // Local changes name
        final localDelta = tracker.trackChangesFromJson(
          original: base,
          modified: {'id': '1', 'name': 'Jane', 'email': 'john@example.com'},
          entityId: '1',
        );

        // Remote also changes name
        final remoteDelta = tracker.trackChangesFromJson(
          original: base,
          modified: {'id': '1', 'name': 'Janet', 'email': 'john@example.com'},
          entityId: '1',
        );

        final merger = DeltaMerger();
        final conflicts = merger.detectConflicts(localDelta, remoteDelta);

        expect(conflicts, hasLength(1));
        expect(conflicts.first.fieldName, equals('name'));
        expect(conflicts.first.localValue, equals('Jane'));
        expect(conflicts.first.remoteValue, equals('Janet'));
      });

      test('should resolve conflicts using lastWriteWins strategy', () async {
        final base = {'id': '1', 'name': 'John'};

        final now = DateTime.now();
        final earlier = now.subtract(const Duration(seconds: 10));
        final later = now.add(const Duration(seconds: 10));

        // Local change (earlier)
        final localDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: earlier,
            ),
          ],
          timestamp: earlier,
        );

        // Remote change (later)
        final remoteDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: later,
            ),
          ],
          timestamp: later,
        );

        final merger = DeltaMerger(
          config: const DeltaSyncConfig(
            mergeStrategy: DeltaMergeStrategy.lastWriteWins,
          ),
        );

        final result = await merger.mergeDeltas(
          base: base,
          local: localDelta,
          remote: remoteDelta,
        );

        // Remote wins because it's later
        expect(result.merged['name'], equals('Janet'));
        expect(result.hasConflicts, isTrue);
        expect(result.resolvedConflicts['name'], equals('Janet'));
      });

      test('should use custom strategy when provided', () async {
        final base = {'id': '1', 'name': 'John', 'priority': 1};

        final now = DateTime.now();

        final localDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: now,
            ),
          ],
          timestamp: now,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: now,
            ),
          ],
          timestamp: now,
        );

        // Custom strategy: always prefer local
        final merger = DeltaMerger(
          config: DeltaSyncConfig(
            mergeStrategy: DeltaMergeStrategy.custom,
            onMergeConflict: (field, local, remote) async => local,
          ),
        );

        final result = await merger.mergeDeltas(
          base: base,
          local: localDelta,
          remote: remoteDelta,
        );

        expect(result.merged['name'], equals('Jane'));
      });

      test('should merge non-conflicting changes from both sides', () async {
        final base = {
          'id': '1',
          'name': 'John',
          'email': 'john@example.com',
          'age': 30,
        };

        final now = DateTime.now();

        // Local changes name
        final localDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: now,
            ),
          ],
          timestamp: now,
        );

        // Remote changes email
        final remoteDelta = DeltaChange<String>(
          entityId: '1',
          changes: [
            FieldChange(
              fieldName: 'email',
              oldValue: 'john@example.com',
              newValue: 'jane@example.com',
              timestamp: now,
            ),
          ],
          timestamp: now,
        );

        final merger = DeltaMerger();
        final result = await merger.mergeDeltas(
          base: base,
          local: localDelta,
          remote: remoteDelta,
        );

        // Both changes should be applied
        expect(result.merged['name'], equals('Jane'));
        expect(result.merged['email'], equals('jane@example.com'));
        expect(result.merged['age'], equals(30));
        expect(result.hasConflicts, isFalse);
      });
    });

    group('field exclusion', () {
      test('should exclude configured fields from tracking', () {
        final config = DeltaSyncConfig(
          excludeFields: {'updatedAt', 'version'},
        );

        final tracker = DeltaTracker(config: config);

        final original = {
          'id': '1',
          'name': 'John',
          'updatedAt': '2024-01-01',
          'version': 1,
        };

        final modified = {
          'id': '1',
          'name': 'Jane',
          'updatedAt': '2024-12-27',
          'version': 2,
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: '1',
        );

        expect(delta.hasField('name'), isTrue);
        expect(delta.hasField('updatedAt'), isFalse);
        expect(delta.hasField('version'), isFalse);
        expect(delta.fieldCount, equals(1));
      });

      test('should pass exclusions through TrackedEntity', () {
        final config = DeltaSyncConfig(
          excludeFields: {'email'},
        );

        final original = TestFixtures.createUser(
          id: 'user-1',
          name: 'John',
          email: 'john@example.com',
        );

        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
          config: config,
        );

        tracked.current = TestFixtures.createUser(
          id: 'user-1',
          name: 'Jane',
          email: 'jane@example.com',
        );

        final changedFields = tracked.getChangedFields();

        expect(changedFields, contains('name'));
        expect(changedFields, isNot(contains('email')));
      });
    });

    group('with different ID types', () {
      test('should work with string IDs', () {
        final tracked = TrackedEntity<TestUser, String>(
          TestFixtures.createUser(id: 'abc-123', name: 'John'),
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(id: 'abc-123', name: 'Jane');
        final delta = tracked.getDelta();

        expect(delta.entityId, equals('abc-123'));
        expect(delta.entityId, isA<String>());
      });

      test('should work with integer IDs', () {
        final tracked = TrackedEntity<TestProduct, int>(
          TestFixtures.createProduct(id: 42, name: 'Widget'),
          idExtractor: (p) => p.id,
        );

        tracked.current = TestFixtures.createProduct(id: 42, name: 'Gadget');
        final delta = tracked.getDelta();

        expect(delta.entityId, equals(42));
        expect(delta.entityId, isA<int>());
      });
    });

    group('edge cases', () {
      test('should handle empty changes', () {
        final original = TestFixtures.createUser(id: 'user-1', name: 'John');
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        final delta = tracked.getDelta();

        expect(delta.isEmpty, isTrue);
        expect(delta.fieldCount, equals(0));
      });

      test('should handle null values in changes', () {
        final tracker = DeltaTracker();

        final original = {'id': '1', 'name': 'John', 'nickname': null};
        final modified = {'id': '1', 'name': 'John', 'nickname': 'Johnny'};

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: '1',
        );

        expect(delta.hasField('nickname'), isTrue);
        final change = delta.getChange('nickname');
        expect(change?.oldValue, isNull);
        expect(change?.newValue, equals('Johnny'));
      });

      test('should handle nested object changes', () {
        final tracker = DeltaTracker();

        final original = {
          'id': '1',
          'address': {'city': 'NYC', 'zip': '10001'},
        };
        final modified = {
          'id': '1',
          'address': {'city': 'LA', 'zip': '90001'},
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: '1',
        );

        expect(delta.hasField('address'), isTrue);
      });

      test('should handle list changes', () {
        final tracker = DeltaTracker();

        final original = {
          'id': '1',
          'tags': ['a', 'b'],
        };
        final modified = {
          'id': '1',
          'tags': ['a', 'b', 'c'],
        };

        final delta = tracker.trackChangesFromJson(
          original: original,
          modified: modified,
          entityId: '1',
        );

        expect(delta.hasField('tags'), isTrue);
      });

      test('should reset to original state', () {
        final original = TestFixtures.createUser(id: 'user-1', name: 'John');
        final tracked = TrackedEntity(
          original,
          idExtractor: (u) => u.id,
        );

        tracked.current = TestFixtures.createUser(id: 'user-1', name: 'Jane');
        expect(tracked.hasChanges, isTrue);

        tracked.reset();
        expect(tracked.hasChanges, isFalse);
        expect(tracked.current.name, equals('John'));
      });
    });

    group('StoreConfig integration', () {
      test('DeltaSyncConfig presets should be usable', () {
        // Verify presets work correctly
        expect(DeltaSyncConfig.off.enabled, isFalse);
        expect(DeltaSyncConfig.defaults.enabled, isTrue);
        expect(
          DeltaSyncConfig.fieldLevelMerge.mergeStrategy,
          equals(DeltaMergeStrategy.fieldLevel),
        );
      });

      test('DeltaSyncConfig should support copyWith', () {
        const config = DeltaSyncConfig.defaults;
        final modified = config.copyWith(
          excludeFields: {'timestamp'},
        );

        expect(modified.enabled, isTrue);
        expect(modified.excludeFields, contains('timestamp'));
      });
    });
  });
}
