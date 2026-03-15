import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Backend that tracks updateWhere calls.
class MockUpdateWhereBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final Map<String, Map<String, dynamic>> _items = {};
  int updateWhereCallCount = 0;
  Query<Map<String, dynamic>>? lastQuery;
  Map<String, dynamic>? lastUpdates;

  void addItem(String id, Map<String, dynamic> item) {
    _items[id] = item;
  }

  @override
  String get name => 'MockUpdateWhereBackend';

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
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    _items[id] = item;
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
      List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final id = item['id'] as String;
      _items[id] = item;
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;

  @override
  Future<int> updateWhere(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> updates,
  ) async {
    updateWhereCallCount++;
    lastQuery = query;
    lastUpdates = updates;
    // Default: update all items (simplified for test)
    var count = 0;
    for (final entry in _items.entries) {
      final updated = Map<String, dynamic>.from(entry.value)..addAll(updates);
      _items[entry.key] = updated;
      count++;
    }
    return count;
  }
}

void main() {
  group('StoreBackend.updateWhere', () {
    late MockUpdateWhereBackend backend;

    setUp(() {
      backend = MockUpdateWhereBackend();
    });

    test('updateWhere updates matching entities', () async {
      backend
        ..addItem('1', {'id': '1', 'name': 'Alice', 'status': 'active'})
        ..addItem('2', {'id': '2', 'name': 'Bob', 'status': 'active'});

      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');
      final count = await backend.updateWhere(query, {'status': 'archived'});

      expect(count, equals(2));
      expect(backend.updateWhereCallCount, equals(1));
      expect(backend.lastUpdates, equals({'status': 'archived'}));
    });

    test('updateWhere returns zero for no matches', () async {
      final query = Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'nonexistent');
      final count = await backend.updateWhere(query, {'status': 'archived'});

      expect(count, equals(0));
    });

    test('updateWhere passes query and updates to backend', () async {
      backend.addItem('1', {'id': '1', 'name': 'Alice'});

      final query =
          Query<Map<String, dynamic>>().where('name', isEqualTo: 'Alice');
      await backend.updateWhere(query, {'name': 'Alice Updated'});

      expect(backend.lastQuery, isNotNull);
      expect(backend.lastUpdates, equals({'name': 'Alice Updated'}));
    });
  });

  group('StoreBackendDefaults.updateWhere', () {
    test('default updateWhere throws UnsupportedError for non-empty matches',
        () async {
      final backend = _DefaultUpdateWhereBackend();
      backend.items['1'] = {'id': '1', 'name': 'Alice', 'status': 'active'};

      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');

      expect(
        () => backend.updateWhere(query, {'status': 'archived'}),
        throwsUnsupportedError,
      );
    });

    test('default updateWhere returns zero for empty updates', () async {
      final backend = _DefaultUpdateWhereBackend();
      backend.items['1'] = {'id': '1', 'name': 'Alice'};

      final query =
          Query<Map<String, dynamic>>().where('name', isEqualTo: 'Alice');
      final count = await backend.updateWhere(query, {});

      expect(count, equals(0));
    });

    test('default updateWhere returns zero when no entities match', () async {
      final backend = _DefaultUpdateWhereBackend();

      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');
      final count = await backend.updateWhere(query, {'status': 'archived'});

      expect(count, equals(0));
    });
  });
}

/// Backend that uses default updateWhere implementation.
class _DefaultUpdateWhereBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final Map<String, Map<String, dynamic>> items = {};
  int getAllCallCount = 0;
  int saveAllCallCount = 0;

  @override
  String get name => 'DefaultUpdateWhereBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async => items[id];

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
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    items[id] = item;
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
      List<Map<String, dynamic>> items) async {
    saveAllCallCount++;
    for (final item in items) {
      final id = item['id'] as String;
      this.items[id] = item;
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;
}
