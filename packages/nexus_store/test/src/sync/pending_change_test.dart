import 'package:test/test.dart';
import 'package:nexus_store/src/sync/pending_change.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('PendingChangeOperation', () {
    test('should have create, update, delete values', () {
      expect(PendingChangeOperation.values, hasLength(3));
      expect(PendingChangeOperation.values, contains(PendingChangeOperation.create));
      expect(PendingChangeOperation.values, contains(PendingChangeOperation.update));
      expect(PendingChangeOperation.values, contains(PendingChangeOperation.delete));
    });
  });

  group('PendingChange', () {
    final testUser = TestFixtures.createUser();
    final createdAt = DateTime(2024, 1, 1, 10, 0);
    final lastAttempt = DateTime(2024, 1, 1, 11, 0);

    group('constructor', () {
      test('should create with required fields', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        expect(change.id, equals('change-1'));
        expect(change.item, equals(testUser));
        expect(change.operation, equals(PendingChangeOperation.create));
        expect(change.createdAt, equals(createdAt));
        expect(change.retryCount, equals(0));
        expect(change.lastError, isNull);
        expect(change.lastAttempt, isNull);
      });

      test('should create with optional fields', () {
        final error = Exception('Sync failed');
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.update,
          createdAt: createdAt,
          retryCount: 3,
          lastError: error,
          lastAttempt: lastAttempt,
        );

        expect(change.retryCount, equals(3));
        expect(change.lastError, equals(error));
        expect(change.lastAttempt, equals(lastAttempt));
      });

      test('should create with originalValue for undo support', () {
        final originalUser = TestFixtures.createUser(name: 'Original Name');
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.update,
          createdAt: createdAt,
          originalValue: originalUser,
        );

        expect(change.originalValue, equals(originalUser));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final change1 = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );
        final change2 = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        expect(change1, equals(change2));
        expect(change1.hashCode, equals(change2.hashCode));
      });

      test('should not be equal when id differs', () {
        final change1 = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );
        final change2 = PendingChange<TestUser>(
          id: 'change-2',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        expect(change1, isNot(equals(change2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated retryCount', () {
        final original = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        final copied = original.copyWith(retryCount: 5);

        expect(copied.id, equals('change-1'));
        expect(copied.retryCount, equals(5));
      });

      test('should copy with updated error', () {
        final original = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        final error = Exception('Network error');
        final copied = original.copyWith(
          lastError: error,
          lastAttempt: lastAttempt,
          retryCount: 1,
        );

        expect(copied.lastError, equals(error));
        expect(copied.lastAttempt, equals(lastAttempt));
        expect(copied.retryCount, equals(1));
      });
    });

    group('hasFailed', () {
      test('should return true when lastError is not null', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
          lastError: Exception('Failed'),
        );

        expect(change.hasFailed, isTrue);
      });

      test('should return false when lastError is null', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        expect(change.hasFailed, isFalse);
      });
    });

    group('canRevert', () {
      test('should return true for update with originalValue', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.update,
          createdAt: createdAt,
          originalValue: TestFixtures.createUser(name: 'Original'),
        );

        expect(change.canRevert, isTrue);
      });

      test('should return true for create operation', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.create,
          createdAt: createdAt,
        );

        expect(change.canRevert, isTrue);
      });

      test('should return true for delete with originalValue', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.delete,
          createdAt: createdAt,
          originalValue: testUser,
        );

        expect(change.canRevert, isTrue);
      });

      test('should return false for update without originalValue', () {
        final change = PendingChange<TestUser>(
          id: 'change-1',
          item: testUser,
          operation: PendingChangeOperation.update,
          createdAt: createdAt,
        );

        expect(change.canRevert, isFalse);
      });
    });
  });
}
