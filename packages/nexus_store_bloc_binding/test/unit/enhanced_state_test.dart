import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/test_entities.dart';

void main() {
  group('NexusStoreStateX extension', () {
    group('mapData', () {
      test('should transform loaded data', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        final mapped = state.mapData((users) => users.length);

        expect(mapped, equals(3));
      });

      test('should return null for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        final mapped = state.mapData((users) => users.length);

        expect(mapped, isNull);
      });

      test('should use previous data for loading state if available', () {
        final state = NexusStoreLoading<TestUser>(
          previousData: TestFixtures.sampleUsers,
        );

        final mapped = state.mapData((users) => users.length);

        expect(mapped, equals(3));
      });

      test('should return null for loading state without previous data', () {
        const state = NexusStoreLoading<TestUser>();

        final mapped = state.mapData((users) => users.length);

        expect(mapped, isNull);
      });

      test('should use previous data for error state if available', () {
        final state = NexusStoreError<TestUser>(
          error: Exception('test'),
          previousData: TestFixtures.sampleUsers,
        );

        final mapped = state.mapData((users) => users.length);

        expect(mapped, equals(3));
      });
    });

    group('where', () {
      test('should filter loaded data', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        final filtered = state.where((user) => user.age != null && user.age! > 20);

        expect(filtered.length, equals(2));
      });

      test('should return empty list for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        final filtered = state.where((user) => true);

        expect(filtered, isEmpty);
      });

      test('should filter previous data in loading state', () {
        final state = NexusStoreLoading<TestUser>(
          previousData: TestFixtures.sampleUsers,
        );

        final filtered = state.where((user) => user.age != null && user.age! > 20);

        expect(filtered.length, equals(2));
      });
    });

    group('firstOrNull', () {
      test('should return first item from loaded data', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        final first = state.firstOrNull;

        expect(first, isNotNull);
        expect(first!.id, equals('user-0'));
      });

      test('should return null for empty loaded data', () {
        const state = NexusStoreLoaded<TestUser>(data: []);

        final first = state.firstOrNull;

        expect(first, isNull);
      });

      test('should return null for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        final first = state.firstOrNull;

        expect(first, isNull);
      });
    });

    group('findById', () {
      test('should find item by ID', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        final found = state.findById('user-1', (user) => user.id);

        expect(found, isNotNull);
        expect(found!.id, equals('user-1'));
      });

      test('should return null when ID not found', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        final found = state.findById('non-existent', (user) => user.id);

        expect(found, isNull);
      });

      test('should return null for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        final found = state.findById('user-1', (user) => user.id);

        expect(found, isNull);
      });
    });

    group('isEmpty', () {
      test('should return true for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        expect(state.isEmpty, isTrue);
      });

      test('should return true for empty loaded data', () {
        const state = NexusStoreLoaded<TestUser>(data: []);

        expect(state.isEmpty, isTrue);
      });

      test('should return false for non-empty loaded data', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        expect(state.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('should return false for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        expect(state.isNotEmpty, isFalse);
      });

      test('should return true for non-empty loaded data', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        expect(state.isNotEmpty, isTrue);
      });
    });

    group('length', () {
      test('should return 0 for initial state', () {
        const state = NexusStoreInitial<TestUser>();

        expect(state.length, equals(0));
      });

      test('should return data length for loaded state', () {
        final state = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );

        expect(state.length, equals(3));
      });
    });
  });

  group('CombinedState', () {
    test('should combine two loaded states', () {
      final usersState = NexusStoreLoaded<TestUser>(
        data: TestFixtures.sampleUsers,
      );
      const postsState = NexusStoreLoaded<String>(
        data: ['post1', 'post2'],
      );

      final combined = usersState.combineWith(postsState);

      expect(combined.isLoading, isFalse);
      expect(combined.hasError, isFalse);
      expect(combined.firstData, equals(TestFixtures.sampleUsers));
      expect(combined.secondData, equals(['post1', 'post2']));
    });

    test('should indicate loading if either state is loading', () {
      final usersState = NexusStoreLoaded<TestUser>(
        data: TestFixtures.sampleUsers,
      );
      const postsState = NexusStoreLoading<String>();

      final combined = usersState.combineWith(postsState);

      expect(combined.isLoading, isTrue);
    });

    test('should indicate error if either state has error', () {
      final usersState = NexusStoreLoaded<TestUser>(
        data: TestFixtures.sampleUsers,
      );
      final postsState = NexusStoreError<String>(
        error: Exception('test'),
      );

      final combined = usersState.combineWith(postsState);

      expect(combined.hasError, isTrue);
      expect(combined.firstError, isA<Exception>());
    });

    test('should provide null data for initial states', () {
      const usersState = NexusStoreInitial<TestUser>();
      const postsState = NexusStoreInitial<String>();

      final combined = usersState.combineWith(postsState);

      expect(combined.firstData, isNull);
      expect(combined.secondData, isNull);
    });

    group('hasBothData', () {
      test('should return true when both states have data', () {
        final usersState = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );
        const postsState = NexusStoreLoaded<String>(
          data: ['post1', 'post2'],
        );

        final combined = usersState.combineWith(postsState);

        expect(combined.hasBothData, isTrue);
      });

      test('should return false when first state has no data', () {
        const usersState = NexusStoreInitial<TestUser>();
        const postsState = NexusStoreLoaded<String>(
          data: ['post1', 'post2'],
        );

        final combined = usersState.combineWith(postsState);

        expect(combined.hasBothData, isFalse);
      });

      test('should return false when second state has no data', () {
        final usersState = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );
        const postsState = NexusStoreInitial<String>();

        final combined = usersState.combineWith(postsState);

        expect(combined.hasBothData, isFalse);
      });

      test('should return false when neither state has data', () {
        const usersState = NexusStoreInitial<TestUser>();
        const postsState = NexusStoreInitial<String>();

        final combined = usersState.combineWith(postsState);

        expect(combined.hasBothData, isFalse);
      });
    });

    group('mapBoth', () {
      test('should transform both data sources when available', () {
        final usersState = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );
        const postsState = NexusStoreLoaded<String>(
          data: ['post1', 'post2'],
        );

        final combined = usersState.combineWith(postsState);
        final result = combined.mapBoth(
          (users, posts) => '${users.length} users, ${posts.length} posts',
        );

        expect(result, equals('3 users, 2 posts'));
      });

      test('should return null when first data is missing', () {
        const usersState = NexusStoreInitial<TestUser>();
        const postsState = NexusStoreLoaded<String>(
          data: ['post1', 'post2'],
        );

        final combined = usersState.combineWith(postsState);
        final result = combined.mapBoth(
          (users, posts) => '${users.length} users, ${posts.length} posts',
        );

        expect(result, isNull);
      });

      test('should return null when second data is missing', () {
        final usersState = NexusStoreLoaded<TestUser>(
          data: TestFixtures.sampleUsers,
        );
        const postsState = NexusStoreInitial<String>();

        final combined = usersState.combineWith(postsState);
        final result = combined.mapBoth(
          (users, posts) => '${users.length} users, ${posts.length} posts',
        );

        expect(result, isNull);
      });

      test('should return null when both data sources are missing', () {
        const usersState = NexusStoreInitial<TestUser>();
        const postsState = NexusStoreInitial<String>();

        final combined = usersState.combineWith(postsState);
        final result = combined.mapBoth(
          (users, posts) => '${users.length} users, ${posts.length} posts',
        );

        expect(result, isNull);
      });
    });
  });
}
