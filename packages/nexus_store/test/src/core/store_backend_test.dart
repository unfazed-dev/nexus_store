import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Minimal implementation using StoreBackendDefaults mixin.
class TestBackendWithDefaults with StoreBackendDefaults<String, String> {
  final Map<String, String> _storage = {};

  @override
  String get name => 'TestBackendWithDefaults';

  @override
  Future<String?> get(String id) async => _storage[id];

  @override
  Future<List<String>> getAll({Query<String>? query}) async =>
      _storage.values.toList();

  @override
  Stream<String?> watch(String id) => Stream.value(_storage[id]);

  @override
  Stream<List<String>> watchAll({Query<String>? query}) =>
      Stream.value(_storage.values.toList());

  @override
  Future<String> save(String item) async {
    _storage[item] = item;
    return item;
  }

  @override
  Future<List<String>> saveAll(List<String> items) async {
    for (final item in items) {
      _storage[item] = item;
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async {
    final existed = _storage.containsKey(id);
    _storage.remove(id);
    return existed;
  }

  @override
  Future<int> deleteAll(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      if (_storage.remove(id) != null) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<String> query) async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }
}

void main() {
  group('StoreBackendDefaults', () {
    late TestBackendWithDefaults backend;

    setUp(() {
      backend = TestBackendWithDefaults();
    });

    group('default properties', () {
      test('should have synced status by default', () {
        expect(backend.syncStatus, equals(SyncStatus.synced));
      });

      test('should emit synced status in stream', () async {
        final status = await backend.syncStatusStream.first;
        expect(status, equals(SyncStatus.synced));
      });

      test('should have zero pending changes by default', () async {
        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });

      test('should not support offline by default', () {
        expect(backend.supportsOffline, isFalse);
      });

      test('should not support realtime by default', () {
        expect(backend.supportsRealtime, isFalse);
      });

      test('should not support transactions by default', () {
        expect(backend.supportsTransactions, isFalse);
      });
    });

    group('default methods', () {
      test('sync should complete without error', () async {
        await expectLater(backend.sync(), completes);
      });

      test('initialize should complete without error', () async {
        await expectLater(backend.initialize(), completes);
      });

      test('close should complete without error', () async {
        await expectLater(backend.close(), completes);
      });
    });

    group('custom implementations', () {
      test('name should return custom name', () {
        expect(backend.name, equals('TestBackendWithDefaults'));
      });

      test('get should return stored item', () async {
        await backend.save('test-item');
        final result = await backend.get('test-item');
        expect(result, equals('test-item'));
      });

      test('get should return null for non-existent item', () async {
        final result = await backend.get('non-existent');
        expect(result, isNull);
      });

      test('getAll should return all items', () async {
        await backend.saveAll(['item-1', 'item-2', 'item-3']);
        final results = await backend.getAll();
        expect(results, hasLength(3));
      });

      test('watch should emit current value', () async {
        await backend.save('watched-item');
        final result = await backend.watch('watched-item').first;
        expect(result, equals('watched-item'));
      });

      test('watchAll should emit all values', () async {
        await backend.saveAll(['a', 'b']);
        final results = await backend.watchAll().first;
        expect(results, hasLength(2));
      });

      test('save should add item to storage', () async {
        final result = await backend.save('new-item');
        expect(result, equals('new-item'));
        expect(await backend.get('new-item'), equals('new-item'));
      });

      test('saveAll should add multiple items', () async {
        final items = ['a', 'b', 'c'];
        final results = await backend.saveAll(items);
        expect(results, equals(items));
        expect(await backend.getAll(), hasLength(3));
      });

      test('delete should remove item and return true', () async {
        await backend.save('to-delete');
        final result = await backend.delete('to-delete');
        expect(result, isTrue);
        expect(await backend.get('to-delete'), isNull);
      });

      test('delete should return false for non-existent item', () async {
        final result = await backend.delete('non-existent');
        expect(result, isFalse);
      });

      test('deleteAll should remove multiple items', () async {
        await backend.saveAll(['a', 'b', 'c']);
        final count = await backend.deleteAll(['a', 'b']);
        expect(count, equals(2));
        expect(await backend.getAll(), hasLength(1));
      });

      test('deleteWhere should clear all items', () async {
        await backend.saveAll(['a', 'b', 'c']);
        final count = await backend.deleteWhere(const Query<String>());
        expect(count, equals(3));
        expect(await backend.getAll(), isEmpty);
      });
    });
  });

  group('SyncStatus', () {
    test('should have all expected values', () {
      expect(SyncStatus.values, hasLength(6));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.error));
      expect(SyncStatus.values, contains(SyncStatus.paused));
      expect(SyncStatus.values, contains(SyncStatus.conflict));
    });
  });
}
