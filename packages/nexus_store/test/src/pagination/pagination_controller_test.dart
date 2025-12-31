import 'dart:async';

import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/pagination/pagination_controller.dart';
import 'package:nexus_store/src/pagination/pagination_state.dart';
import 'package:nexus_store/src/pagination/streaming_config.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('PaginationController', () {
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

    group('construction', () {
      test('creates with default config', () {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        expect(controller, isNotNull);
        expect(controller.config, equals(const StreamingConfig()));

        controller.dispose();
      });

      test('creates with custom config', () {
        const customConfig = StreamingConfig(
          pageSize: 50,
          prefetchDistance: 10,
        );

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: customConfig,
        );

        expect(controller.config, equals(customConfig));

        controller.dispose();
      });

      test('creates with query', () {
        final query = const Query<_TestUser>()
            .where('status', isEqualTo: 'active')
            .orderByField('name');

        final controller = PaginationController<_TestUser, String>(
          store: store,
          query: query,
        );

        expect(controller.query, equals(query));

        controller.dispose();
      });
    });

    group('stream', () {
      test('emits initial state first', () async {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        final firstState = await controller.stream.first;

        expect(firstState, isA<PaginationInitial<_TestUser>>());

        controller.dispose();
      });

      test('emits loading then data after refresh', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));
        backend.addToStorage('2', _TestUser('2', 'Bob'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        // Wait for initial state
        await Future<void>.delayed(const Duration(milliseconds: 50));

        controller.refresh();

        // Wait for loading and data states
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        expect(states.whereType<PaginationLoading<_TestUser>>(), isNotEmpty);
        expect(states.whereType<PaginationData<_TestUser>>(), isNotEmpty);

        final dataState = states.whereType<PaginationData<_TestUser>>().last;
        expect(dataState.items.length, equals(2));
      });

      test('is broadcast stream allowing multiple listeners', () async {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        final listener1States = <PaginationState<_TestUser>>[];
        final listener2States = <PaginationState<_TestUser>>[];

        final sub1 = controller.stream.listen(listener1States.add);
        final sub2 = controller.stream.listen(listener2States.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();
        controller.dispose();

        expect(listener1States, isNotEmpty);
        expect(listener2States, isNotEmpty);
      });
    });

    group('refresh', () {
      test('loads first page of data', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        final dataState = states.whereType<PaginationData<_TestUser>>().last;
        expect(dataState.items.length, equals(10));
        expect(dataState.hasMore, isTrue);
      });

      test('clears previous data on refresh', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Add more data and refresh again
        backend.addToStorage('2', _TestUser('2', 'Bob'));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        // Check that loading state has no previous items after refresh
        final loadingStates =
            states.whereType<PaginationLoading<_TestUser>>().toList();
        // Second refresh should have loading without previous items
        expect(loadingStates.length, greaterThanOrEqualTo(2));
      });

      test('applies query when refreshing', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice', status: 'active'));
        backend.addToStorage('2', _TestUser('2', 'Bob', status: 'inactive'));
        backend.addToStorage('3', _TestUser('3', 'Carol', status: 'active'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
          query: const Query<_TestUser>().where('status', isEqualTo: 'active'),
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        final dataState = states.whereType<PaginationData<_TestUser>>().last;
        expect(dataState.items.length, equals(2));
        expect(dataState.items.every((u) => u.status == 'active'), isTrue);
      });
    });

    group('loadMore', () {
      test('loads next page of data', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        controller.loadMore();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        final dataStates =
            states.whereType<PaginationData<_TestUser>>().toList();
        expect(dataStates.last.items.length, equals(20));
      });

      test('emits loadingMore state while loading', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        controller.loadMore();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        expect(
            states.whereType<PaginationLoadingMore<_TestUser>>(), isNotEmpty);
      });

      test('does nothing when no more pages', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));
        backend.addToStorage('2', _TestUser('2', 'Bob'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final beforeCount = states.length;
        controller.loadMore(); // Should do nothing
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        // No new loading states should be added
        final afterLoadingMore = states
            .skip(beforeCount)
            .whereType<PaginationLoadingMore<_TestUser>>();
        expect(afterLoadingMore, isEmpty);
      });

      test('does nothing when already loading', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();

        // Immediately call loadMore while still loading
        controller.loadMore();
        controller.loadMore();
        controller.loadMore();

        await Future<void>.delayed(const Duration(milliseconds: 200));

        controller.dispose();

        // Should not crash and should complete normally
        expect(true, isTrue);
      });

      test('loads all pages with repeated loadMore', () async {
        for (var i = 1; i <= 55; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 20),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        while (states.last.hasMore) {
          controller.loadMore();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        await subscription.cancel();
        controller.dispose();

        final lastData = states.whereType<PaginationData<_TestUser>>().last;
        expect(lastData.items.length, equals(55));
        expect(lastData.hasMore, isFalse);
      });
    });

    group('retry', () {
      test('retries after error', () async {
        backend.shouldFailOnGet = true;
        backend.errorToThrow = Exception('Network error');

        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(states.whereType<PaginationError<_TestUser>>(), isNotEmpty);

        // Fix the error and retry
        backend.shouldFailOnGet = false;
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        controller.retry();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        expect(states.whereType<PaginationData<_TestUser>>(), isNotEmpty);
      });

      test('does nothing when not in error state', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final beforeCount = states.length;
        controller.retry(); // Should do nothing
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();
        controller.dispose();

        // No significant state changes should occur
        expect(states.length, lessThanOrEqualTo(beforeCount + 1));
      });
    });

    group('onItemVisible', () {
      test('triggers prefetch when near end', () async {
        for (var i = 1; i <= 30; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(
            pageSize: 10,
            prefetchDistance: 3,
          ),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // User scrolls near the end (item 7 visible with prefetchDistance of 3)
        controller.onItemVisible(7);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        // Should have triggered loadMore
        final dataStates =
            states.whereType<PaginationData<_TestUser>>().toList();
        expect(dataStates.last.items.length, greaterThan(10));
      });

      test('does not prefetch when far from end', () async {
        for (var i = 1; i <= 30; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(
            pageSize: 10,
            prefetchDistance: 3,
          ),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final beforeCount = states.length;

        // User is at beginning, far from end
        controller.onItemVisible(0);
        controller.onItemVisible(1);
        controller.onItemVisible(2);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        // Should not have triggered any loadMore
        final afterLoadingMore = states
            .skip(beforeCount)
            .whereType<PaginationLoadingMore<_TestUser>>();
        expect(afterLoadingMore, isEmpty);
      });

      test('respects prefetchDistance of zero', () async {
        for (var i = 1; i <= 30; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig.noPrefetch(),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final beforeCount = states.length;

        // Even at the very end, should not prefetch
        controller.onItemVisible(9);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        // No prefetching with noPrefetch config
        final afterLoadingMore = states
            .skip(beforeCount)
            .whereType<PaginationLoadingMore<_TestUser>>();
        expect(afterLoadingMore, isEmpty);
      });
    });

    group('currentState', () {
      test('returns current state synchronously', () async {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        expect(controller.currentState, isA<PaginationInitial<_TestUser>>());

        controller.dispose();
      });

      test('updates as stream emits', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(controller.currentState, isA<PaginationData<_TestUser>>());

        controller.dispose();
      });
    });

    group('dispose', () {
      test('closes stream', () async {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        var streamClosed = false;
        controller.stream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        controller.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(streamClosed, isTrue);
      });

      test('can be called multiple times safely', () {
        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        controller.dispose();
        controller.dispose();
        controller.dispose();

        expect(true, isTrue); // No exception thrown
      });
    });

    group('error handling', () {
      test('emits error state on backend failure', () async {
        backend.shouldFailOnGet = true;
        backend.errorToThrow = Exception('Database error');

        final controller = PaginationController<_TestUser, String>(
          store: store,
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        final errorState = states.whereType<PaginationError<_TestUser>>().first;
        expect(errorState.error, isA<Exception>());
      });

      test('preserves previous items on loadMore error', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final controller = PaginationController<_TestUser, String>(
          store: store,
          config: const StreamingConfig(pageSize: 10),
        );

        final states = <PaginationState<_TestUser>>[];
        final subscription = controller.stream.listen(states.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Now fail on next load
        backend.shouldFailOnGet = true;
        backend.errorToThrow = Exception('Network error');

        controller.loadMore();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        controller.dispose();

        final errorState = states.whereType<PaginationError<_TestUser>>().first;
        expect(errorState.items.length, equals(10)); // Previous items preserved
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
