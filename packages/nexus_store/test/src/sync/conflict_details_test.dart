import 'package:test/test.dart';
import 'package:nexus_store/src/sync/conflict_details.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('ConflictDetails', () {
    final localUser = TestFixtures.createUser(
      id: 'user-1',
      name: 'Local Name',
      email: 'local@example.com',
    );
    final remoteUser = TestFixtures.createUser(
      id: 'user-1',
      name: 'Remote Name',
      email: 'remote@example.com',
    );
    final localTimestamp = DateTime(2024, 1, 1, 10, 0);
    final remoteTimestamp = DateTime(2024, 1, 1, 11, 0);

    group('constructor', () {
      test('should create with required fields', () {
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );

        expect(details.localValue, equals(localUser));
        expect(details.remoteValue, equals(remoteUser));
        expect(details.localTimestamp, equals(localTimestamp));
        expect(details.remoteTimestamp, equals(remoteTimestamp));
        expect(details.conflictingFields, isNull);
      });

      test('should create with optional conflicting fields', () {
        final conflictingFields = {'name', 'email'};
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
          conflictingFields: conflictingFields,
        );

        expect(details.conflictingFields, equals(conflictingFields));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final details1 = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );
        final details2 = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );

        expect(details1, equals(details2));
        expect(details1.hashCode, equals(details2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final details1 = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );
        final details2 = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: DateTime(2024, 1, 2), // Different timestamp
        );

        expect(details1, isNot(equals(details2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated fields', () {
        final original = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );

        final newConflictingFields = {'age'};
        final copied = original.copyWith(
          conflictingFields: newConflictingFields,
        );

        expect(copied.localValue, equals(localUser));
        expect(copied.remoteValue, equals(remoteUser));
        expect(copied.conflictingFields, equals(newConflictingFields));
      });
    });

    group('isNewerLocal', () {
      test('should return true when local timestamp is newer', () {
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: DateTime(2024, 1, 2), // Newer
          remoteTimestamp: DateTime(2024, 1, 1),
        );

        expect(details.isNewerLocal, isTrue);
      });

      test('should return false when remote timestamp is newer', () {
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp, // Newer
        );

        expect(details.isNewerLocal, isFalse);
      });
    });

    group('isNewerRemote', () {
      test('should return true when remote timestamp is newer', () {
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp, // Newer
        );

        expect(details.isNewerRemote, isTrue);
      });

      test('should return false when local timestamp is newer', () {
        final details = ConflictDetails<TestUser>(
          localValue: localUser,
          remoteValue: remoteUser,
          localTimestamp: DateTime(2024, 1, 2), // Newer
          remoteTimestamp: DateTime(2024, 1, 1),
        );

        expect(details.isNewerRemote, isFalse);
      });
    });
  });
}
