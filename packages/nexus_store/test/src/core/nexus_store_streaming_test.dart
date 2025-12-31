import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/pagination/pagination_state.dart';
import 'package:nexus_store/src/pagination/streaming_config.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('NexusStore.watchAllPaginated', () {
    late FakeStoreBackend<_TestUser, String> backend;
    late NexusStore<_TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<_TestUser, String>(
        idExtractor: (u) => u.id,
      );
      backend.fieldAccessor = (item, field) {
        switch (field) {
          case 'id':
            return item.id;
          case 'name':
            return item.name;
          case 'status':
            return item.status;
          default:
            return null;
        }
      };

      store = NexusStore<_TestUser, String>(
        backend: backend,
        config: StoreConfig.defaults,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    test('returns stream of PaginationState', () async {
      final stream = store.watchAllPaginated();

      expect(stream, isA<Stream<PaginationState<_TestUser>>>());
    });

    test('emits initial state first', () async {
      final stream = store.watchAllPaginated();

      final firstState = await stream.first;

      expect(firstState, isA<PaginationInitial<_TestUser>>());
    });

    test('uses provided config', () async {
      const customConfig = StreamingConfig(
        pageSize: 50,
        prefetchDistance: 10,
      );

      final stream = store.watchAllPaginated(config: customConfig);

      // Stream should be created without error
      expect(stream, isNotNull);
    });

    test('uses provided query', () async {
      backend.addToStorage('1', _TestUser('1', 'Alice', status: 'active'));
      backend.addToStorage('2', _TestUser('2', 'Bob', status: 'inactive'));

      final states = <PaginationState<_TestUser>>[];
      final subscription = store
          .watchAllPaginated(
            query:
                const Query<_TestUser>().where('status', isEqualTo: 'active'),
          )
          .listen(states.add);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Should emit at least initial state
      expect(states, isNotEmpty);
      expect(states.first, isA<PaginationInitial<_TestUser>>());
    });

    test('allows refresh via controller callback', () async {
      backend.addToStorage('1', _TestUser('1', 'Alice'));

      final states = <PaginationState<_TestUser>>[];
      final subscription = store
          .watchAllPaginated(
            config: const StreamingConfig(pageSize: 10),
            onController: (controller) {
              controller.refresh();
            },
          )
          .listen(states.add);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await subscription.cancel();

      expect(states.whereType<PaginationLoading<_TestUser>>(), isNotEmpty);
      expect(states.whereType<PaginationData<_TestUser>>(), isNotEmpty);
    });

    test('allows loadMore via controller callback', () async {
      for (var i = 1; i <= 25; i++) {
        backend.addToStorage('$i', _TestUser('$i', 'User $i'));
      }

      late void Function() loadMoreCallback;
      final states = <PaginationState<_TestUser>>[];

      final subscription = store
          .watchAllPaginated(
            config: const StreamingConfig(pageSize: 10),
            onController: (controller) {
              controller.refresh();
              loadMoreCallback = controller.loadMore;
            },
          )
          .listen(states.add);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      loadMoreCallback();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      final dataStates = states.whereType<PaginationData<_TestUser>>().toList();
      expect(dataStates.last.items.length, equals(20));
    });

    test('throws StateError when not initialized', () {
      final uninitializedStore = NexusStore<_TestUser, String>(
        backend: backend,
      );

      expect(
        () => uninitializedStore.watchAllPaginated(),
        throwsStateError,
      );
    });

    test('throws StateError when disposed', () async {
      await store.dispose();

      expect(
        () => store.watchAllPaginated(),
        throwsStateError,
      );
    });

    group('integration with PaginationController', () {
      test('loads paginated data correctly', () async {
        for (var i = 1; i <= 35; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final states = <PaginationState<_TestUser>>[];
        late void Function() loadMore;

        final subscription = store
            .watchAllPaginated(
              config: const StreamingConfig(pageSize: 15),
              onController: (controller) {
                controller.refresh();
                loadMore = controller.loadMore;
              },
            )
            .listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Load second page
        loadMore();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Load third page
        loadMore();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        final lastData = states.whereType<PaginationData<_TestUser>>().last;
        expect(lastData.items.length, equals(35));
        expect(lastData.hasMore, isFalse);
      });

      test('applies filters and ordering', () async {
        backend.addToStorage('1', _TestUser('1', 'Charlie', status: 'active'));
        backend.addToStorage('2', _TestUser('2', 'Alice', status: 'active'));
        backend.addToStorage('3', _TestUser('3', 'Bob', status: 'inactive'));

        final states = <PaginationState<_TestUser>>[];
        final subscription = store
            .watchAllPaginated(
              query: const Query<_TestUser>()
                  .where('status', isEqualTo: 'active')
                  .orderByField('name'),
              onController: (controller) {
                controller.refresh();
              },
            )
            .listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        final dataState = states.whereType<PaginationData<_TestUser>>().last;
        expect(dataState.items.length, equals(2));
        expect(dataState.items[0].name, equals('Alice'));
        expect(dataState.items[1].name, equals('Charlie'));
      });

      test('handles errors gracefully', () async {
        backend.shouldFailOnGet = true;
        backend.errorToThrow = Exception('Database error');

        final states = <PaginationState<_TestUser>>[];
        final subscription = store.watchAllPaginated(
          onController: (controller) {
            controller.refresh();
          },
        ).listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(states.whereType<PaginationError<_TestUser>>(), isNotEmpty);
      });

      test('retry works after error', () async {
        backend.shouldFailOnGet = true;
        backend.errorToThrow = Exception('Network error');

        late void Function() retry;
        final states = <PaginationState<_TestUser>>[];

        final subscription = store.watchAllPaginated(
          onController: (controller) {
            controller.refresh();
            retry = controller.retry;
          },
        ).listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Fix the error and retry
        backend.shouldFailOnGet = false;
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        retry();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(states.whereType<PaginationData<_TestUser>>(), isNotEmpty);
      });
    });
  });
}

class _TestUser {
  const _TestUser(this.id, this.name, {this.status = 'active'});

  final String id;
  final String name;
  final String status;

  @override
  String toString() => '_TestUser($id, $name, $status)';
}
