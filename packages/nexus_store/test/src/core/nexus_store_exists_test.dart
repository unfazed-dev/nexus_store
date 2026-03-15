import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Mock backend that tracks exists calls.
class MockExistsBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final Map<String, Map<String, dynamic>> _items = {};
  bool? existsResult;
  bool? existsWhereResult;
  int existsCallCount = 0;
  int existsWhereCallCount = 0;
  String? lastExistsId;
  Query<Map<String, dynamic>>? lastExistsWhereQuery;

  void addItem(String id, Map<String, dynamic> item) {
    _items[id] = item;
  }

  @override
  String get name => 'MockExistsBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async => _items[id];

  @override
  Future<List<Map<String, dynamic>>> getAll(
          {Query<Map<String, dynamic>>? query}) async =>
      _items.values.toList();

  @override
  Stream<Map<String, dynamic>?> watch(String id) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async => item;

  @override
  Future<List<Map<String, dynamic>>> saveAll(
          List<Map<String, dynamic>> items) async =>
      items;

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;

  @override
  Future<bool> exists(String id) async {
    existsCallCount++;
    lastExistsId = id;
    if (existsResult != null) return existsResult!;
    return _items.containsKey(id);
  }

  @override
  Future<bool> existsWhere(Query<Map<String, dynamic>> query) async {
    existsWhereCallCount++;
    lastExistsWhereQuery = query;
    if (existsWhereResult != null) return existsWhereResult!;
    return _items.isNotEmpty;
  }
}

void main() {
  group('NexusStore.exists', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockExistsBackend backend;

    setUp(() {
      backend = MockExistsBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('returns true when entity exists', () async {
      backend.addItem('user-1', {'id': 'user-1', 'name': 'Alice'});

      final result = await store.exists('user-1');

      expect(result, isTrue);
      expect(backend.existsCallCount, equals(1));
      expect(backend.lastExistsId, equals('user-1'));
    });

    test('returns false when entity does not exist', () async {
      final result = await store.exists('nonexistent');

      expect(result, isFalse);
      expect(backend.existsCallCount, equals(1));
    });

    test('delegates to backend exists method', () async {
      backend.existsResult = true;

      final result = await store.exists('any-id');

      expect(result, isTrue);
      expect(backend.existsCallCount, equals(1));
    });

    test('throws when store not initialized', () async {
      final uninitializedStore = NexusStore<Map<String, dynamic>, String>(
        backend: backend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitializedStore.exists('id'),
        throwsStateError,
      );
    });
  });

  group('NexusStore.existsWhere', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockExistsBackend backend;

    setUp(() {
      backend = MockExistsBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('returns true when matching entities exist', () async {
      backend.existsWhereResult = true;
      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');

      final result = await store.existsWhere(query);

      expect(result, isTrue);
      expect(backend.existsWhereCallCount, equals(1));
      expect(backend.lastExistsWhereQuery, isNotNull);
    });

    test('returns false when no matching entities', () async {
      backend.existsWhereResult = false;
      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'deleted');

      final result = await store.existsWhere(query);

      expect(result, isFalse);
    });

    test('passes query to backend', () async {
      backend.existsWhereResult = true;
      final query =
          Query<Map<String, dynamic>>().where('age', isGreaterThan: 18);

      await store.existsWhere(query);

      expect(backend.lastExistsWhereQuery, isNotNull);
    });
  });

  group('StoreBackendDefaults.exists', () {
    test('default exists uses get', () async {
      final backend = _DefaultExistsBackend();
      backend.items['id-1'] = {'id': 'id-1'};

      expect(await backend.exists('id-1'), isTrue);
      expect(await backend.exists('nonexistent'), isFalse);
      expect(backend.getCallCount, equals(2));
    });

    test('default existsWhere uses getAll with limit', () async {
      final backend = _DefaultExistsBackend();
      backend.items['id-1'] = {'id': 'id-1', 'status': 'active'};

      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');
      final result = await backend.existsWhere(query);

      expect(result, isTrue);
      expect(backend.getAllCallCount, equals(1));
    });

    test('default existsWhere returns false for empty results', () async {
      final backend = _DefaultExistsBackend();

      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');
      final result = await backend.existsWhere(query);

      expect(result, isFalse);
    });
  });

  group('NexusStore.exists interceptor chain', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockExistsBackend backend;

    setUp(() {
      backend = MockExistsBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('exists passes through interceptor chain', () async {
      backend.existsResult = true;

      final result = await store.exists('test-id');

      expect(result, isTrue);
    });

    test('existsWhere passes through interceptor chain', () async {
      backend.existsWhereResult = true;
      final query =
          Query<Map<String, dynamic>>().where('field', isEqualTo: 'value');

      final result = await store.existsWhere(query);

      expect(result, isTrue);
    });
  });
}

/// Backend that uses default exists/existsWhere implementations.
class _DefaultExistsBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final Map<String, Map<String, dynamic>> items = {};
  int getCallCount = 0;
  int getAllCallCount = 0;

  @override
  String get name => 'DefaultExistsBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    getCallCount++;
    return items[id];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
      {Query<Map<String, dynamic>>? query}) async {
    getAllCallCount++;
    return items.values.toList();
  }

  @override
  Stream<Map<String, dynamic>?> watch(String id) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async => item;

  @override
  Future<List<Map<String, dynamic>>> saveAll(
          List<Map<String, dynamic>> items) async =>
      items;

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;
}
