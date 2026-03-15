import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// In-memory backend that uses default exists/existsWhere from mixin.
class InMemoryExistsBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final List<Map<String, dynamic>> _items = [];

  @override
  String get name => 'InMemoryExistsBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async =>
      _items.where((item) => item['id'] == id).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> getAll(
      {Query<Map<String, dynamic>>? query}) async {
    return List.from(_items);
  }

  @override
  Stream<Map<String, dynamic>?> watch(String id) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    _items.removeWhere((i) => i['id'] == item['id']);
    _items.add(item);
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
          List<Map<String, dynamic>> items) async =>
      items;

  @override
  Future<bool> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((i) => i['id'] == id);
    return _items.length < before;
  }

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;
}

void main() {
  group('StoreBackendDefaults.exists', () {
    late InMemoryExistsBackend backend;

    setUp(() {
      backend = InMemoryExistsBackend();
    });

    test('returns true when item exists by ID', () async {
      await backend.save({'id': 'user-1', 'name': 'Alice'});

      final result = await backend.exists('user-1');

      expect(result, isTrue);
    });

    test('returns false when item does not exist', () async {
      final result = await backend.exists('nonexistent');

      expect(result, isFalse);
    });

    test('handles multiple items correctly', () async {
      await backend.save({'id': 'user-1', 'name': 'Alice'});
      await backend.save({'id': 'user-2', 'name': 'Bob'});

      expect(await backend.exists('user-1'), isTrue);
      expect(await backend.exists('user-2'), isTrue);
      expect(await backend.exists('user-3'), isFalse);
    });
  });

  group('StoreBackendDefaults.existsWhere', () {
    late InMemoryExistsBackend backend;

    setUp(() {
      backend = InMemoryExistsBackend();
    });

    test('returns true when matching items exist', () async {
      await backend.save({'id': 'user-1', 'name': 'Alice', 'active': true});

      final query =
          Query<Map<String, dynamic>>().where('active', isEqualTo: true);
      final result = await backend.existsWhere(query);

      expect(result, isTrue);
    });

    test('returns false when no items exist', () async {
      final query =
          Query<Map<String, dynamic>>().where('active', isEqualTo: true);
      final result = await backend.existsWhere(query);

      expect(result, isFalse);
    });
  });
}
