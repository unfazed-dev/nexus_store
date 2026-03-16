import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('NexusStore.watchPaged', () {
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

    test('returns Stream of PagedResult', () async {
      backend.addToStorage('1', _TestUser('1', 'Alice'));

      final stream = store.watchPaged(pageSize: 10);
      expect(stream, isA<Stream<PagedResult<_TestUser>>>());

      final result = await stream.first;
      expect(result, isA<PagedResult<_TestUser>>());
      expect(result.items.length, equals(1));
    });

    test('applies pageSize to limit results', () async {
      for (var i = 1; i <= 10; i++) {
        backend.addToStorage('$i', _TestUser('$i', 'User $i'));
      }

      final stream = store.watchPaged(pageSize: 5);
      final result = await stream.first;

      expect(result.items.length, equals(5));
    });

    test('re-emits when underlying data changes', () async {
      final emissions = <PagedResult<_TestUser>>[];
      final subscription = store.watchPaged(pageSize: 10).listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));
      expect(emissions.first.isEmpty, isTrue);

      backend.addToStorage('1', _TestUser('1', 'Alice'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, hasLength(2));
      expect(emissions.last.items.length, equals(1));

      await subscription.cancel();
    });

    test('hasMore is true when more items exist than pageSize', () async {
      for (var i = 1; i <= 8; i++) {
        backend.addToStorage('$i', _TestUser('$i', 'User $i'));
      }

      final stream = store.watchPaged(pageSize: 5);
      final result = await stream.first;

      expect(result.items.length, equals(5));
      expect(result.hasMore, isTrue);
    });

    test('works with additional query filters', () async {
      backend.addToStorage('1', _TestUser('1', 'Alice', status: 'active'));
      backend.addToStorage('2', _TestUser('2', 'Bob', status: 'inactive'));
      backend.addToStorage('3', _TestUser('3', 'Carol', status: 'active'));

      final stream = store.watchPaged(
        query: const Query<_TestUser>().where('status', isEqualTo: 'active'),
        pageSize: 10,
      );
      final result = await stream.first;

      expect(result.items.length, equals(2));
      expect(result.items.every((u) => u.status == 'active'), isTrue);
      expect(result.hasMore, isFalse);
    });

    test('handles empty data with hasMore false', () async {
      final stream = store.watchPaged(pageSize: 10);
      final result = await stream.first;

      expect(result.isEmpty, isTrue);
      expect(result.hasMore, isFalse);
    });

    test('throws StateError when not initialized', () {
      final uninitializedStore = NexusStore<_TestUser, String>(
        backend: backend,
      );

      expect(
        () => uninitializedStore.watchPaged(pageSize: 10),
        throwsStateError,
      );
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
