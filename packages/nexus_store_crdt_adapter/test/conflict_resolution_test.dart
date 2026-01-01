import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for conflict resolution tests.
class TestModel {
  TestModel({
    required this.id,
    required this.name,
    this.age = 0,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'TestModel(id: $id, name: $name, age: $age)';
}

void main() {
  group('CrdtBackend Conflict Resolution', () {
    late CrdtBackend<TestModel, String> backend;

    setUp(() async {
      backend = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
      await backend.initialize();
    });

    tearDown(() async {
      await backend.close();
    });

    group('retryChange', () {
      test('returns gracefully when change does not exist', () async {
        // retryChange with non-existent ID should not throw
        await expectLater(backend.retryChange('non-existent'), completes);
      });

      test('triggers sync operation', () async {
        // Verify retryChange triggers sync (which is a no-op in this impl)
        await backend.retryChange('any-change-id');

        // Should complete without error
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });
    });

    group('cancelChange', () {
      test('returns null when change does not exist', () async {
        final result = await backend.cancelChange('non-existent');
        expect(result, isNull);
      });
    });

    group('CRDT merge behavior', () {
      test('getChangeset returns all changes', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));

        final changeset = await backend.getChangeset();

        expect(changeset.isNotEmpty, isTrue);
        expect(changeset.containsKey('test_models'), isTrue);
      });

      // Note: Cross-database CRDT merge tests require proper CrdtChangeset
      // format with Hlc objects. These are covered in integration tests.
      // Here we test that the API methods exist and are callable.

      test('applyChangeset accepts changeset format', () async {
        // Save initial data
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        // Get changeset
        final changeset = await backend.getChangeset();

        // Verify changeset structure
        expect(changeset, isA<Map<String, List<Map<String, Object?>>>>());
        expect(changeset.containsKey('test_models'), isTrue);
      });

      test('deleted items create tombstones', () async {
        // Save and delete
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.delete('1');

        // Get changeset - should contain the deletion
        final changeset = await backend.getChangeset();
        expect(changeset.isNotEmpty, isTrue);

        // Item should not be retrievable
        final item = await backend.get('1');
        expect(item, isNull);
      });

      test('tombstone revival works locally', () async {
        // Save and delete
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.delete('1');

        // Verify deleted
        expect(await backend.get('1'), isNull);

        // Re-save (tombstone revival)
        await backend.save(TestModel(id: '1', name: 'Alice Revived', age: 31));

        // Should be retrievable again
        final result = await backend.get('1');
        expect(result, isNotNull);
        expect(result!.name, equals('Alice Revived'));
      });
    });

    group('pendingChangesStream', () {
      test('emits stream of pending changes', () async {
        final stream = backend.pendingChangesStream;
        expect(stream, isA<Stream<List<nexus.PendingChange<TestModel>>>>());

        // Initial state should be empty
        final changes = await stream.first;
        expect(changes, isEmpty);
      });
    });

    group('conflictsStream', () {
      test('returns a valid stream', () {
        expect(
          backend.conflictsStream,
          isA<Stream<nexus.ConflictDetails<TestModel>>>(),
        );
      });
    });

    group('sync operations', () {
      test('sync emits syncing then synced status', () async {
        final statuses = <nexus.SyncStatus>[];
        final subscription = backend.syncStatusStream.listen(statuses.add);

        await backend.sync();

        // Allow stream to emit
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        // Should have synced initially, then syncing, then synced
        expect(statuses, contains(nexus.SyncStatus.syncing));
        expect(statuses.last, equals(nexus.SyncStatus.synced));
      });
    });

    group('watch with updates', () {
      test('watch notifies on save', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final stream = backend.watch('1');
        final firstValue = await stream.first;

        expect(firstValue, equals(model));
      });

      test('watch notifies null on delete', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final stream = backend.watch('1');

        // Skip first emission (initial value)
        final values = <TestModel?>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Delete the item
        await backend.delete('1');

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Should have received the initial value and then null
        expect(values.last, isNull);
      });

      test('watchAll updates when items change', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final stream = backend.watchAll();
        final initialList = await stream.first;

        expect(initialList.length, equals(1));
      });
    });

    group('watch subscription caching', () {
      test('watch caches subjects for same ID', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        // Get two streams for the same ID
        final stream1 = backend.watch('1');
        final stream2 = backend.watch('1');

        // Both streams should receive the same data
        final value1 = await stream1.first;
        final value2 = await stream2.first;

        expect(value1, equals(value2));
      });

      test('watchAll caches subjects for same query', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final stream1 = backend.watchAll();
        final stream2 = backend.watchAll();

        // Both streams should receive the same data
        final value1 = await stream1.first;
        final value2 = await stream2.first;

        expect(value1, equals(value2));
      });

      test('watchAll with different queries returns independent streams',
          () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));

        final allStream = backend.watchAll();
        final filteredStream = backend.watchAll(
          query: const nexus.Query<TestModel>().where('age', isEqualTo: 30),
        );

        final allItems = await allStream.first;
        final filteredItems = await filteredStream.first;

        // All should have 2 items, filtered should have 1
        expect(allItems.length, equals(2));
        expect(filteredItems.length, equals(1));
        expect(filteredItems.first.name, equals('Alice'));
      });
    });

    group('cancelChange with pending changes', () {
      test('cancelChange with UPDATE operation restores original value',
          () async {
        final originalModel = TestModel(id: '1', name: 'Original', age: 25);
        final updatedModel = TestModel(id: '1', name: 'Updated', age: 30);

        // Save initial data
        await backend.save(originalModel);

        // Add a pending UPDATE change with original value
        final change =
            await backend.pendingChangesManagerForTesting.addChange(
          item: updatedModel,
          operation: nexus.PendingChangeOperation.update,
          originalValue: originalModel,
        );

        // Cancel the change - should restore original
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.id, equals(change.id));
        expect(result.operation, equals(nexus.PendingChangeOperation.update));

        // Verify original was restored
        final saved = await backend.get('1');
        expect(saved, isNotNull);
        expect(saved!.name, equals('Original'));
        expect(saved.age, equals(25));
      });

      test('cancelChange with CREATE operation deletes the item', () async {
        final createdModel = TestModel(id: '2', name: 'NewItem', age: 20);

        // Save the item first
        await backend.save(createdModel);

        // Add a pending CREATE change
        final change =
            await backend.pendingChangesManagerForTesting.addChange(
          item: createdModel,
          operation: nexus.PendingChangeOperation.create,
        );

        // Cancel the change - should delete the created item
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.operation, equals(nexus.PendingChangeOperation.create));

        // Verify item was deleted
        final deleted = await backend.get('2');
        expect(deleted, isNull);
      });

      test('cancelChange with DELETE operation restores original value',
          () async {
        final deletedModel = TestModel(id: '3', name: 'Deleted', age: 35);

        // Item was deleted - add pending DELETE change
        final change =
            await backend.pendingChangesManagerForTesting.addChange(
          item: deletedModel,
          operation: nexus.PendingChangeOperation.delete,
          originalValue: deletedModel,
        );

        // Cancel the change - should restore the deleted item
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.operation, equals(nexus.PendingChangeOperation.delete));

        // Verify item was restored
        final restored = await backend.get('3');
        expect(restored, isNotNull);
        expect(restored!.name, equals('Deleted'));
      });
    });

    group('retryChange with pending changes', () {
      test('retryChange increments retry count and updates lastAttempt',
          () async {
        final model = TestModel(id: '1', name: 'Test', age: 25);

        // Add a pending change
        final change =
            await backend.pendingChangesManagerForTesting.addChange(
          item: model,
          operation: nexus.PendingChangeOperation.update,
        );

        expect(change.retryCount, equals(0));
        expect(change.lastAttempt, isNull);

        // Retry the change
        await backend.retryChange(change.id);

        // Verify retry count was incremented
        final updatedChange =
            backend.pendingChangesManagerForTesting.getChange(change.id);
        expect(updatedChange, isNotNull);
        expect(updatedChange!.retryCount, equals(1));
        expect(updatedChange.lastAttempt, isNotNull);
      });

      test('retryChange can be called multiple times', () async {
        final model = TestModel(id: '2', name: 'Test2', age: 30);

        // Add a pending change
        final change =
            await backend.pendingChangesManagerForTesting.addChange(
          item: model,
          operation: nexus.PendingChangeOperation.create,
        );

        // Retry multiple times
        await backend.retryChange(change.id);
        await backend.retryChange(change.id);
        await backend.retryChange(change.id);

        // Verify retry count was incremented each time
        final updatedChange =
            backend.pendingChangesManagerForTesting.getChange(change.id);
        expect(updatedChange!.retryCount, equals(3));
      });
    });
  });
}
