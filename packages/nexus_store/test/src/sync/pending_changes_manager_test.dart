import 'package:test/test.dart';
import 'package:nexus_store/src/sync/pending_change.dart';
import 'package:nexus_store/src/sync/pending_changes_manager.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('PendingChangesManager', () {
    late PendingChangesManager<TestUser, String> manager;

    setUp(() {
      manager = PendingChangesManager<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    group('initial state', () {
      test('should start with empty pending changes', () {
        expect(manager.pendingChanges, isEmpty);
      });

      test('should emit empty list on stream initially', () async {
        final changes = await manager.pendingChangesStream.first;
        expect(changes, isEmpty);
      });
    });

    group('addChange', () {
      test('should add pending change for create operation', () async {
        final user = TestFixtures.createUser();

        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );

        expect(change.item, equals(user));
        expect(change.operation, equals(PendingChangeOperation.create));
        expect(change.originalValue, isNull);
        expect(manager.pendingChanges, hasLength(1));
      });

      test('should add pending change for update with original value', () async {
        final originalUser = TestFixtures.createUser(name: 'Original');
        final updatedUser = TestFixtures.createUser(name: 'Updated');

        final change = await manager.addChange(
          item: updatedUser,
          operation: PendingChangeOperation.update,
          originalValue: originalUser,
        );

        expect(change.item, equals(updatedUser));
        expect(change.operation, equals(PendingChangeOperation.update));
        expect(change.originalValue, equals(originalUser));
      });

      test('should add pending change for delete with original value', () async {
        final user = TestFixtures.createUser();

        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.delete,
          originalValue: user,
        );

        expect(change.operation, equals(PendingChangeOperation.delete));
        expect(change.originalValue, equals(user));
      });

      test('should generate unique change IDs', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        final change1 = await manager.addChange(
          item: user1,
          operation: PendingChangeOperation.create,
        );
        final change2 = await manager.addChange(
          item: user2,
          operation: PendingChangeOperation.create,
        );

        expect(change1.id, isNot(equals(change2.id)));
      });

      test('should emit on stream when change is added', () async {
        final user = TestFixtures.createUser();
        final emissions = <List<PendingChange<TestUser>>>[];

        manager.pendingChangesStream.listen(emissions.add);
        await Future<void>.delayed(Duration.zero);

        await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );
        await Future<void>.delayed(Duration.zero);

        expect(emissions.last, hasLength(1));
      });
    });

    group('removeChange', () {
      test('should remove change by ID', () async {
        final user = TestFixtures.createUser();
        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );

        final removed = manager.removeChange(change.id);

        expect(removed, equals(change));
        expect(manager.pendingChanges, isEmpty);
      });

      test('should return null when change not found', () {
        final removed = manager.removeChange('non-existent');
        expect(removed, isNull);
      });

      test('should emit on stream when change is removed', () async {
        final user = TestFixtures.createUser();
        final emissions = <List<PendingChange<TestUser>>>[];

        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );

        manager.pendingChangesStream.listen(emissions.add);
        await Future<void>.delayed(Duration.zero);

        manager.removeChange(change.id);
        await Future<void>.delayed(Duration.zero);

        expect(emissions.last, isEmpty);
      });
    });

    group('getChange', () {
      test('should return change by ID', () async {
        final user = TestFixtures.createUser();
        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );

        final retrieved = manager.getChange(change.id);

        expect(retrieved, equals(change));
      });

      test('should return null when change not found', () {
        final retrieved = manager.getChange('non-existent');
        expect(retrieved, isNull);
      });
    });

    group('updateChange', () {
      test('should update retry count and error', () async {
        final user = TestFixtures.createUser();
        final change = await manager.addChange(
          item: user,
          operation: PendingChangeOperation.create,
        );

        final error = Exception('Sync failed');
        final updated = manager.updateChange(
          change.id,
          retryCount: 1,
          lastError: error,
          lastAttempt: DateTime(2024, 1, 1),
        );

        expect(updated?.retryCount, equals(1));
        expect(updated?.lastError, equals(error));
        expect(updated?.lastAttempt, equals(DateTime(2024, 1, 1)));
      });

      test('should return null when change not found', () {
        final updated = manager.updateChange('non-existent', retryCount: 1);
        expect(updated, isNull);
      });
    });

    group('getChangesForEntity', () {
      test('should return changes for specific entity', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        await manager.addChange(
          item: user1,
          operation: PendingChangeOperation.create,
        );
        await manager.addChange(
          item: user1,
          operation: PendingChangeOperation.update,
        );
        await manager.addChange(
          item: user2,
          operation: PendingChangeOperation.create,
        );

        final user1Changes = manager.getChangesForEntity('user-1');

        expect(user1Changes, hasLength(2));
        expect(user1Changes.every((c) => c.item.id == 'user-1'), isTrue);
      });
    });

    group('clearAll', () {
      test('should remove all pending changes', () async {
        await manager.addChange(
          item: TestFixtures.createUser(id: 'user-1'),
          operation: PendingChangeOperation.create,
        );
        await manager.addChange(
          item: TestFixtures.createUser(id: 'user-2'),
          operation: PendingChangeOperation.create,
        );

        final removed = manager.clearAll();

        expect(removed, hasLength(2));
        expect(manager.pendingChanges, isEmpty);
      });
    });

    group('failedChanges', () {
      test('should return only changes with errors', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        final change1 = await manager.addChange(
          item: user1,
          operation: PendingChangeOperation.create,
        );
        await manager.addChange(
          item: user2,
          operation: PendingChangeOperation.create,
        );

        manager.updateChange(
          change1.id,
          lastError: Exception('Failed'),
        );

        expect(manager.failedChanges, hasLength(1));
        expect(manager.failedChanges.first.id, equals(change1.id));
      });
    });

    group('pendingCount and failedCount', () {
      test('should return correct counts', () async {
        final change1 = await manager.addChange(
          item: TestFixtures.createUser(id: 'user-1'),
          operation: PendingChangeOperation.create,
        );
        await manager.addChange(
          item: TestFixtures.createUser(id: 'user-2'),
          operation: PendingChangeOperation.create,
        );

        manager.updateChange(change1.id, lastError: Exception('Failed'));

        expect(manager.pendingCount, equals(2));
        expect(manager.failedCount, equals(1));
      });
    });
  });
}
