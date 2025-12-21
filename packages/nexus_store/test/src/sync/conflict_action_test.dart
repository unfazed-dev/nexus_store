import 'package:test/test.dart';
import 'package:nexus_store/src/sync/conflict_action.dart';

import '../../fixtures/test_entities.dart';

void main() {
  group('ConflictAction', () {
    final testUser = TestFixtures.createUser();
    final mergedUser = TestFixtures.createUser(name: 'Merged Name');

    group('keepLocal', () {
      test('should create keepLocal action', () {
        final action = ConflictAction<TestUser>.keepLocal();

        expect(action, isA<KeepLocal<TestUser>>());
      });

      test('should pattern match as keepLocal', () {
        final action = ConflictAction<TestUser>.keepLocal();

        final result = switch (action) {
          KeepLocal() => 'local',
          KeepRemote() => 'remote',
          Merge() => 'merge',
          SkipResolution() => 'skip',
        };

        expect(result, equals('local'));
      });
    });

    group('keepRemote', () {
      test('should create keepRemote action', () {
        final action = ConflictAction<TestUser>.keepRemote();

        expect(action, isA<KeepRemote<TestUser>>());
      });

      test('should pattern match as keepRemote', () {
        final action = ConflictAction<TestUser>.keepRemote();

        final result = switch (action) {
          KeepLocal() => 'local',
          KeepRemote() => 'remote',
          Merge() => 'merge',
          SkipResolution() => 'skip',
        };

        expect(result, equals('remote'));
      });
    });

    group('merge', () {
      test('should create merge action with merged value', () {
        final action = ConflictAction<TestUser>.merge(mergedUser);

        expect(action, isA<Merge<TestUser>>());
        expect((action as Merge<TestUser>).merged, equals(mergedUser));
      });

      test('should pattern match as merge and access merged value', () {
        final action = ConflictAction<TestUser>.merge(mergedUser);

        final result = switch (action) {
          KeepLocal() => null,
          KeepRemote() => null,
          Merge(:final merged) => merged,
          SkipResolution() => null,
        };

        expect(result, equals(mergedUser));
      });
    });

    group('skip', () {
      test('should create skip action', () {
        final action = ConflictAction<TestUser>.skip();

        expect(action, isA<SkipResolution<TestUser>>());
      });

      test('should pattern match as skip', () {
        final action = ConflictAction<TestUser>.skip();

        final result = switch (action) {
          KeepLocal() => 'local',
          KeepRemote() => 'remote',
          Merge() => 'merge',
          SkipResolution() => 'skip',
        };

        expect(result, equals('skip'));
      });
    });

    group('equality', () {
      test('keepLocal actions should be equal', () {
        final action1 = ConflictAction<TestUser>.keepLocal();
        final action2 = ConflictAction<TestUser>.keepLocal();

        expect(action1, equals(action2));
      });

      test('merge actions with same value should be equal', () {
        final action1 = ConflictAction<TestUser>.merge(mergedUser);
        final action2 = ConflictAction<TestUser>.merge(mergedUser);

        expect(action1, equals(action2));
      });

      test('merge actions with different values should not be equal', () {
        final action1 = ConflictAction<TestUser>.merge(mergedUser);
        final action2 = ConflictAction<TestUser>.merge(testUser);

        expect(action1, isNot(equals(action2)));
      });
    });
  });
}
