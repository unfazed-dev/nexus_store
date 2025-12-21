import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('NexusStore pagination', () {
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

    group('getAllPaged', () {
      test('returns empty result when no data', () async {
        final result = await store.getAllPaged();

        expect(result.isEmpty, isTrue);
        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
      });

      test('returns all items when count is less than first', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));
        backend.addToStorage('2', _TestUser('2', 'Bob'));

        final result = await store.getAllPaged(
          query: const Query<_TestUser>().first(10),
        );

        expect(result.length, equals(2));
        expect(result.hasMore, isFalse);
      });

      test('returns first N items with pagination info', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final result = await store.getAllPaged(
          query: const Query<_TestUser>().first(10),
        );

        expect(result.length, equals(10));
        expect(result.hasMore, isTrue);
        expect(result.nextCursor, isNotNull);
        expect(result.totalCount, equals(25));
      });

      test('supports cursor-based forward pagination', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        // Get first page
        final firstPage = await store.getAllPaged(
          query: const Query<_TestUser>().first(10),
        );

        expect(firstPage.length, equals(10));
        expect(firstPage.hasMore, isTrue);

        // Get second page
        final secondPage = await store.getAllPaged(
          query: const Query<_TestUser>()
              .after(firstPage.nextCursor!)
              .first(10),
        );

        expect(secondPage.length, equals(10));
        expect(secondPage.hasMore, isTrue);
        expect(secondPage.pageInfo.hasPreviousPage, isTrue);

        // Ensure no overlap between pages
        final firstIds = firstPage.items.map((u) => u.id).toSet();
        final secondIds = secondPage.items.map((u) => u.id).toSet();
        expect(firstIds.intersection(secondIds), isEmpty);
      });

      test('handles query with filters', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice', status: 'active'));
        backend.addToStorage('2', _TestUser('2', 'Bob', status: 'inactive'));
        backend.addToStorage('3', _TestUser('3', 'Carol', status: 'active'));

        final result = await store.getAllPaged(
          query: const Query<_TestUser>()
              .where('status', isEqualTo: 'active')
              .first(10),
        );

        expect(result.length, equals(2));
        expect(result.items.every((u) => u.status == 'active'), isTrue);
      });

      test('handles query with ordering', () async {
        backend.addToStorage('1', _TestUser('1', 'Charlie'));
        backend.addToStorage('2', _TestUser('2', 'Alice'));
        backend.addToStorage('3', _TestUser('3', 'Bob'));

        final result = await store.getAllPaged(
          query: const Query<_TestUser>()
              .orderByField('name')
              .first(10),
        );

        expect(result.items[0].name, equals('Alice'));
        expect(result.items[1].name, equals('Bob'));
        expect(result.items[2].name, equals('Charlie'));
      });

      test('throws StateError when not initialized', () async {
        final uninitializedStore = NexusStore<_TestUser, String>(
          backend: backend,
        );

        expect(
          () => uninitializedStore.getAllPaged(),
          throwsStateError,
        );
      });

      test('throws StateError when disposed', () async {
        await store.dispose();

        expect(
          () => store.getAllPaged(),
          throwsStateError,
        );
      });
    });

    group('watchAllPaged', () {
      test('emits initial empty result', () async {
        final stream = store.watchAllPaged();

        final result = await stream.first;
        expect(result.isEmpty, isTrue);
      });

      test('emits updates when data changes', () async {
        final emissions = <PagedResult<_TestUser>>[];
        final subscription = store.watchAllPaged(
          query: const Query<_TestUser>().first(10),
        ).listen(emissions.add);

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, hasLength(1));
        expect(emissions.first.isEmpty, isTrue);

        // Add data
        backend.addToStorage('1', _TestUser('1', 'Alice'));

        // Wait for update
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, hasLength(2));
        expect(emissions.last.items.length, equals(1));

        await subscription.cancel();
      });

      test('respects query parameters', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice', status: 'active'));
        backend.addToStorage('2', _TestUser('2', 'Bob', status: 'inactive'));

        final stream = store.watchAllPaged(
          query: const Query<_TestUser>()
              .where('status', isEqualTo: 'active')
              .first(10),
        );

        final result = await stream.first;
        expect(result.items.length, equals(1));
        expect(result.items.first.name, equals('Alice'));
      });

      test('throws StateError when not initialized', () {
        final uninitializedStore = NexusStore<_TestUser, String>(
          backend: backend,
        );

        expect(
          () => uninitializedStore.watchAllPaged(),
          throwsStateError,
        );
      });
    });

    group('pagination patterns', () {
      test('load all pages pattern', () async {
        for (var i = 1; i <= 55; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final allItems = <_TestUser>[];
        Cursor? cursor;

        do {
          final query = cursor != null
              ? const Query<_TestUser>().after(cursor).first(20)
              : const Query<_TestUser>().first(20);

          final page = await store.getAllPaged(query: query);
          allItems.addAll(page.items);
          cursor = page.nextCursor;
        } while (cursor != null);

        expect(allItems.length, equals(55));
      });

      test('backward pagination from middle', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        // Get to middle of the list
        final middleCursor = Cursor.fromValues({'_index': 15});
        final result = await store.getAllPaged(
          query: const Query<_TestUser>().before(middleCursor).last(5),
        );

        expect(result.items.length, equals(5));
        expect(result.pageInfo.hasPreviousPage, isTrue);
      });

      test('combined filter and pagination', () async {
        for (var i = 1; i <= 30; i++) {
          final status = i % 2 == 0 ? 'active' : 'inactive';
          backend.addToStorage('$i', _TestUser('$i', 'User $i', status: status));
        }

        final result = await store.getAllPaged(
          query: const Query<_TestUser>()
              .where('status', isEqualTo: 'active')
              .first(5),
        );

        expect(result.items.length, equals(5));
        expect(result.items.every((u) => u.status == 'active'), isTrue);
        expect(result.hasMore, isTrue);
      });
    });

    group('PagedResult helpers', () {
      test('map transforms items while preserving pageInfo', () async {
        backend.addToStorage('1', _TestUser('1', 'Alice'));
        backend.addToStorage('2', _TestUser('2', 'Bob'));

        final result = await store.getAllPaged(
          query: const Query<_TestUser>().first(10),
        );

        final names = result.map((user) => user.name);

        expect(names.items, equals(['Alice', 'Bob']));
        expect(names.pageInfo, equals(result.pageInfo));
      });

      test('convenience accessors work correctly', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestUser('$i', 'User $i'));
        }

        final result = await store.getAllPaged(
          query: const Query<_TestUser>().first(10),
        );

        expect(result.hasMore, equals(result.pageInfo.hasNextPage));
        expect(result.nextCursor, equals(result.pageInfo.endCursor));
        expect(result.previousCursor, equals(result.pageInfo.startCursor));
        expect(result.totalCount, equals(result.pageInfo.totalCount));
        expect(result.length, equals(result.items.length));
        expect(result.isEmpty, equals(result.items.isEmpty));
        expect(result.isNotEmpty, equals(result.items.isNotEmpty));
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
