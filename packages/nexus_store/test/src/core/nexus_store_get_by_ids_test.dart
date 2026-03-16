import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  late FakeStoreBackend<TestUser, String> backend;
  late NexusStore<TestUser, String> store;

  setUp(() async {
    backend = FakeStoreBackend<TestUser, String>(
      idExtractor: (u) => u.id,
    );
    store = NexusStore<TestUser, String>(
      backend: backend,
      config: StoreConfig(),
      idExtractor: (u) => u.id,
    );
    await store.initialize();

    // Seed data
    backend.addToStorage(
      'user-1',
      TestFixtures.createUser(id: 'user-1', name: 'Alice'),
    );
    backend.addToStorage(
      'user-2',
      TestFixtures.createUser(id: 'user-2', name: 'Bob'),
    );
    backend.addToStorage(
      'user-3',
      TestFixtures.createUser(id: 'user-3', name: 'Charlie'),
    );
  });

  tearDown(() async {
    await store.dispose();
  });

  group('NexusStore.getByIds', () {
    test('returns all entities when all IDs exist', () async {
      final result = await store.getByIds(['user-1', 'user-2', 'user-3']);

      expect(result, hasLength(3));
      expect(
          result.map((u) => u.id), containsAll(['user-1', 'user-2', 'user-3']));
    });

    test('returns only found entities for partial matches', () async {
      final result = await store.getByIds(['user-1', 'user-missing', 'user-3']);

      expect(result, hasLength(2));
      expect(result.map((u) => u.id), containsAll(['user-1', 'user-3']));
    });

    test('returns empty list when no IDs match', () async {
      final result = await store.getByIds(['missing-1', 'missing-2']);

      expect(result, isEmpty);
    });

    test('returns empty list for empty ID list', () async {
      final result = await store.getByIds([]);

      expect(result, isEmpty);
    });

    test('handles duplicate IDs', () async {
      final result = await store.getByIds(['user-1', 'user-1', 'user-2']);

      // Should return unique entities even if IDs are duplicated
      expect(result, hasLength(2));
      expect(result.map((u) => u.id), containsAll(['user-1', 'user-2']));
    });

    test('works with single ID', () async {
      final result = await store.getByIds(['user-2']);

      expect(result, hasLength(1));
      expect(result.first.id, equals('user-2'));
      expect(result.first.name, equals('Bob'));
    });

    test('respects FetchPolicy parameter', () async {
      final result = await store.getByIds(
        ['user-1'],
        policy: FetchPolicy.cacheFirst,
      );

      expect(result, hasLength(1));
      expect(result.first.id, equals('user-1'));
    });
  });

  group('StoreBackendDefaults.getByIds default implementation', () {
    late _DefaultsOnlyBackend<TestUser, String> defaultsBackend;

    setUp(() {
      defaultsBackend = _DefaultsOnlyBackend<TestUser, String>();
      defaultsBackend.storage['user-1'] =
          TestFixtures.createUser(id: 'user-1', name: 'Alice');
      defaultsBackend.storage['user-2'] =
          TestFixtures.createUser(id: 'user-2', name: 'Bob');
      defaultsBackend.storage['user-3'] =
          TestFixtures.createUser(id: 'user-3', name: 'Charlie');
    });

    test('delegates to individual get() calls', () async {
      final result = await defaultsBackend.getByIds(['user-1', 'user-2']);

      expect(result, hasLength(2));
      expect(result.map((u) => u.id), containsAll(['user-1', 'user-2']));
    });

    test('filters out null results from missing IDs', () async {
      final result = await defaultsBackend.getByIds(['user-1', 'no-such-user']);

      expect(result, hasLength(1));
      expect(result.first.id, equals('user-1'));
    });

    test('returns empty list for empty input', () async {
      final result = await defaultsBackend.getByIds([]);

      expect(result, isEmpty);
    });

    test('deduplicates IDs', () async {
      final result =
          await defaultsBackend.getByIds(['user-1', 'user-1', 'user-2']);

      expect(result, hasLength(2));
    });
  });

  group('NexusStore.watchByIds', () {
    test('emits matching entities reactively', () async {
      final stream = store.watchByIds(['user-1', 'user-2']);

      final firstEmission = await stream.first;
      expect(firstEmission, hasLength(2));
      expect(
        firstEmission.map((u) => u.id),
        containsAll(['user-1', 'user-2']),
      );
    });

    test('emits empty list when no IDs match', () async {
      final stream = store.watchByIds(['missing-1', 'missing-2']);

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);
    });

    test('emits empty list for empty ID list', () async {
      final stream = store.watchByIds([]);

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);
    });

    test('emits updates when watched entities change', () async {
      final emissions = <List<TestUser>>[];
      final stream = store.watchByIds(['user-1', 'user-2']);
      final sub = stream.listen(emissions.add);

      // Wait for initial emission
      await Future<void>.delayed(Duration.zero);

      // Modify a watched entity
      await store.save(
        TestFixtures.createUser(id: 'user-1', name: 'Alice Updated'),
      );

      // Wait for change to propagate
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      // First emission: original data
      expect(
          emissions.first.map((u) => u.id), containsAll(['user-1', 'user-2']));
      // Later emission should reflect the update
      final lastEmission = emissions.last;
      final alice = lastEmission.firstWhere((u) => u.id == 'user-1');
      expect(alice.name, equals('Alice Updated'));
    });
  });
}

/// Minimal backend that uses only [StoreBackendDefaults] (does NOT override getByIds).
class _DefaultsOnlyBackend<T, ID> with StoreBackendDefaults<T, ID> {
  final Map<ID, T> storage = {};

  @override
  String get name => 'DefaultsOnlyBackend';

  @override
  Future<T?> get(ID id) async => storage[id];

  @override
  Future<List<T>> getAll({Query<T>? query}) async => storage.values.toList();

  @override
  Stream<T?> watch(ID id) => Stream.value(storage[id]);

  @override
  Stream<List<T>> watchAll({Query<T>? query}) =>
      Stream.value(storage.values.toList());

  @override
  Future<T> save(T item) async => item;

  @override
  Future<List<T>> saveAll(List<T> items) async => items;

  @override
  Future<bool> delete(ID id) async => storage.remove(id) != null;

  @override
  Future<int> deleteAll(List<ID> ids) async {
    var count = 0;
    for (final id in ids) {
      if (storage.remove(id) != null) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<T> query) async {
    final count = storage.length;
    storage.clear();
    return count;
  }
}
