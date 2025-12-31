import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('StoreBackend pagination', () {
    group('supportsPagination', () {
      test('FakeStoreBackend supports pagination by default', () {
        final backend = FakeStoreBackend<String, String>(
          idExtractor: (s) => s,
        );

        expect(backend.supportsPagination, isTrue);
      });

      test('default mixin returns false for supportsPagination', () {
        final backend = _MinimalBackend<String, String>();

        expect(backend.supportsPagination, isFalse);
      });
    });

    group('getAllPaged', () {
      late FakeStoreBackend<_TestEntity, String> backend;

      setUp(() {
        backend = FakeStoreBackend<_TestEntity, String>(
          idExtractor: (e) => e.id,
        );
        // Set up field accessor for test entity
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
      });

      test('returns empty PagedResult when no data', () async {
        final result = await backend.getAllPaged();

        expect(result.isEmpty, isTrue);
        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
      });

      test('returns all items when count is less than first', () async {
        backend.addToStorage('1', _TestEntity('1', 'Alice'));
        backend.addToStorage('2', _TestEntity('2', 'Bob'));

        final query = const Query<_TestEntity>().first(10);
        final result = await backend.getAllPaged(query: query);

        expect(result.length, equals(2));
        expect(result.hasMore, isFalse);
      });

      test('returns first N items with hasMore true', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final query = const Query<_TestEntity>().first(10);
        final result = await backend.getAllPaged(query: query);

        expect(result.length, equals(10));
        expect(result.hasMore, isTrue);
        expect(result.nextCursor, isNotNull);
      });

      test('supports cursor-based forward pagination', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        // Get first page
        final firstPage = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(10),
        );

        expect(firstPage.length, equals(10));
        expect(firstPage.hasMore, isTrue);
        expect(firstPage.nextCursor, isNotNull);

        // Get second page using cursor
        final secondPage = await backend.getAllPaged(
          query:
              const Query<_TestEntity>().after(firstPage.nextCursor!).first(10),
        );

        expect(secondPage.length, equals(10));
        expect(secondPage.hasMore, isTrue);

        // Items should be different
        final firstPageIds = firstPage.items.map((e) => e.id).toSet();
        final secondPageIds = secondPage.items.map((e) => e.id).toSet();
        expect(firstPageIds.intersection(secondPageIds), isEmpty);
      });

      test('returns last page correctly', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        // Get to last page
        final firstPage = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(10),
        );
        final secondPage = await backend.getAllPaged(
          query:
              const Query<_TestEntity>().after(firstPage.nextCursor!).first(10),
        );
        final thirdPage = await backend.getAllPaged(
          query: const Query<_TestEntity>()
              .after(secondPage.nextCursor!)
              .first(10),
        );

        expect(thirdPage.length, equals(5));
        expect(thirdPage.hasMore, isFalse);
        expect(thirdPage.nextCursor, isNull);
      });

      test('respects filters in query', () async {
        backend.addToStorage('1', _TestEntity('1', 'Alice', status: 'active'));
        backend.addToStorage('2', _TestEntity('2', 'Bob', status: 'inactive'));
        backend.addToStorage('3', _TestEntity('3', 'Carol', status: 'active'));

        final query = const Query<_TestEntity>()
            .where('status', isEqualTo: 'active')
            .first(10);

        final result = await backend.getAllPaged(query: query);

        expect(result.length, equals(2));
        expect(result.items.every((e) => e.status == 'active'), isTrue);
      });

      test('respects ordering in query', () async {
        backend.addToStorage('1', _TestEntity('1', 'Charlie'));
        backend.addToStorage('2', _TestEntity('2', 'Alice'));
        backend.addToStorage('3', _TestEntity('3', 'Bob'));

        final query = const Query<_TestEntity>().orderByField('name').first(10);

        final result = await backend.getAllPaged(query: query);

        expect(result.items[0].name, equals('Alice'));
        expect(result.items[1].name, equals('Bob'));
        expect(result.items[2].name, equals('Charlie'));
      });

      test('provides totalCount when available', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final query = const Query<_TestEntity>().first(10);
        final result = await backend.getAllPaged(query: query);

        expect(result.totalCount, equals(25));
      });

      test('backward pagination with before cursor', () async {
        for (var i = 1; i <= 25; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        // Now paginate backwards from the middle
        final middleCursor = Cursor.fromValues({'_index': 15});
        final previousPage = await backend.getAllPaged(
          query: const Query<_TestEntity>().before(middleCursor).last(10),
        );

        expect(previousPage.items, isNotEmpty);
        expect(previousPage.items.length, equals(10));
        expect(previousPage.pageInfo.hasPreviousPage, isTrue);
      });

      test('empty query returns first page', () async {
        for (var i = 1; i <= 5; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final result = await backend.getAllPaged();

        expect(result.items.length, equals(5));
        expect(result.hasMore, isFalse);
      });
    });

    group('watchAllPaged', () {
      late FakeStoreBackend<_TestEntity, String> backend;

      setUp(() {
        backend = FakeStoreBackend<_TestEntity, String>(
          idExtractor: (e) => e.id,
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
      });

      test('emits initial empty result', () async {
        final stream = backend.watchAllPaged();

        expect(
          stream,
          emits(predicate<PagedResult<_TestEntity>>(
            (result) => result.isEmpty,
          )),
        );
      });

      test('emits updates when data changes', () async {
        final emissions = <PagedResult<_TestEntity>>[];
        final stream = backend.watchAllPaged(
          query: const Query<_TestEntity>().first(10),
        );

        // Listen to stream
        final subscription = stream.listen(emissions.add);

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, hasLength(1));
        expect(emissions.first.isEmpty, isTrue);

        // Add data
        backend.addToStorage('1', _TestEntity('1', 'Alice'));

        // Wait for update emission
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, hasLength(2));
        expect(emissions.last.items.length, equals(1));

        await subscription.cancel();
      });

      test('respects query parameters', () async {
        backend.addToStorage('1', _TestEntity('1', 'Alice', status: 'active'));
        backend.addToStorage('2', _TestEntity('2', 'Bob', status: 'inactive'));

        final stream = backend.watchAllPaged(
          query: const Query<_TestEntity>()
              .where('status', isEqualTo: 'active')
              .first(10),
        );

        final result = await stream.first;
        expect(result.items.length, equals(1));
        expect(result.items.first.name, equals('Alice'));
      });
    });

    group('PageInfo correctness', () {
      late FakeStoreBackend<_TestEntity, String> backend;

      setUp(() {
        backend = FakeStoreBackend<_TestEntity, String>(
          idExtractor: (e) => e.id,
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
      });

      test('startCursor points to first item', () async {
        for (var i = 1; i <= 10; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final result = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(5),
        );

        expect(result.pageInfo.startCursor, isNotNull);
      });

      test('endCursor points to last item', () async {
        for (var i = 1; i <= 10; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final result = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(5),
        );

        expect(result.pageInfo.endCursor, isNotNull);
      });

      test('hasPreviousPage is false for first page', () async {
        for (var i = 1; i <= 10; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final result = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(5),
        );

        expect(result.pageInfo.hasPreviousPage, isFalse);
      });

      test('hasPreviousPage is true for subsequent pages', () async {
        for (var i = 1; i <= 10; i++) {
          backend.addToStorage('$i', _TestEntity('$i', 'User $i'));
        }

        final firstPage = await backend.getAllPaged(
          query: const Query<_TestEntity>().first(5),
        );

        final secondPage = await backend.getAllPaged(
          query:
              const Query<_TestEntity>().after(firstPage.nextCursor!).first(5),
        );

        expect(secondPage.pageInfo.hasPreviousPage, isTrue);
      });

      test('empty result has null cursors', () async {
        final result = await backend.getAllPaged();

        expect(result.pageInfo.startCursor, isNull);
        expect(result.pageInfo.endCursor, isNull);
      });
    });
  });
}

/// Minimal backend using only the defaults mixin.
class _MinimalBackend<T, ID> with StoreBackendDefaults<T, ID> {
  @override
  Future<T?> get(ID id) async => null;

  @override
  Future<List<T>> getAll({Query<T>? query}) async => [];

  @override
  Stream<T?> watch(ID id) => const Stream.empty();

  @override
  Stream<List<T>> watchAll({Query<T>? query}) => const Stream.empty();

  @override
  Future<T> save(T item) async => item;

  @override
  Future<List<T>> saveAll(List<T> items) async => items;

  @override
  Future<bool> delete(ID id) async => false;

  @override
  Future<int> deleteAll(List<ID> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<T> query) async => 0;

  @override
  String get name => 'MinimalBackend';
}

/// Test entity for pagination tests.
class _TestEntity {
  const _TestEntity(this.id, this.name, {this.status = 'active'});

  final String id;
  final String name;
  final String status;

  @override
  String toString() => '_TestEntity($id, $name, $status)';
}
