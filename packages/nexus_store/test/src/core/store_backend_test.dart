import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Backend with field operations support for testing line 322.
class TestBackendWithFieldSupport with StoreBackendDefaults<String, String> {
  final Map<String, String> _storage = {};

  @override
  String get name => 'TestBackendWithFieldSupport';

  @override
  bool get supportsFieldOperations => true;

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

  @override
  Future<Object?> getField(String id, String fieldName) async {
    final item = _storage[id];
    if (item == null) return null;
    // Return the length of the item string as a field value
    if (fieldName == 'length') return item.length;
    return null;
  }
}

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

  group('StoreBackendDefaults field operations', () {
    late TestBackendWithDefaults backend;

    setUp(() {
      backend = TestBackendWithDefaults();
    });

    test('supportsFieldOperations returns false by default', () {
      expect(backend.supportsFieldOperations, isFalse);
    });

    test('supportsPagination returns false by default', () {
      expect(backend.supportsPagination, isFalse);
    });

    test('getField throws UnsupportedError', () async {
      expect(
        () => backend.getField('id', 'fieldName'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('getFieldBatch iterates over ids and catches errors', () async {
      // Since getField throws UnsupportedError, all calls will fail
      // and getFieldBatch should return empty map
      final result = await backend.getFieldBatch(['id1', 'id2'], 'fieldName');
      expect(result, isEmpty);
    });

    test('getFieldBatch returns values when getField succeeds (line 322)',
        () async {
      // Use a backend that supports field operations
      final fieldBackend = TestBackendWithFieldSupport();
      await fieldBackend.save('item-1');
      await fieldBackend.save('item-2');

      final result =
          await fieldBackend.getFieldBatch(['item-1', 'item-2'], 'length');

      // Line 322: results[id] = value when value is not null
      expect(result, hasLength(2));
      expect(result['item-1'], equals(6)); // 'item-1'.length
      expect(result['item-2'], equals(6)); // 'item-2'.length
    });
  });

  group('StoreBackendDefaults transaction operations', () {
    late TestBackendWithDefaults backend;

    setUp(() {
      backend = TestBackendWithDefaults();
    });

    test('beginTransaction generates unique transaction ID', () async {
      final tx1 = await backend.beginTransaction();
      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 1));
      final tx2 = await backend.beginTransaction();

      expect(tx1, startsWith('tx_'));
      expect(tx2, startsWith('tx_'));
      expect(tx1, isNot(equals(tx2)));
    });

    test('commitTransaction completes without error', () async {
      final txId = await backend.beginTransaction();
      await expectLater(backend.commitTransaction(txId), completes);
    });

    test('rollbackTransaction completes without error', () async {
      final txId = await backend.beginTransaction();
      await expectLater(backend.rollbackTransaction(txId), completes);
    });

    test('runInTransaction executes callback and returns result', () async {
      final result = await backend.runInTransaction(() async {
        return 'test-result';
      });
      expect(result, equals('test-result'));
    });

    test('runInTransaction propagates errors from callback', () async {
      expect(
        () => backend.runInTransaction(() async {
          throw Exception('test error');
        }),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('StoreBackendDefaults pagination operations', () {
    late TestBackendWithDefaults backend;

    setUp(() {
      backend = TestBackendWithDefaults();
    });

    test('getAllPaged wraps getAll result in PagedResult', () async {
      await backend.saveAll(['item-1', 'item-2', 'item-3']);

      final result = await backend.getAllPaged();

      expect(result.items, hasLength(3));
      expect(result.pageInfo, isNotNull);
    });

    test('watchAllPaged wraps watchAll stream in PagedResult', () async {
      await backend.saveAll(['a', 'b']);

      final result = await backend.watchAllPaged().first;

      expect(result.items, hasLength(2));
      expect(result.pageInfo, isNotNull);
    });
  });

  group('StoreBackendDefaults sync operations', () {
    late TestBackendWithDefaults backend;

    setUp(() {
      backend = TestBackendWithDefaults();
    });

    test('pendingChangesStream emits empty list', () async {
      final changes = await backend.pendingChangesStream.first;
      expect(changes, isEmpty);
    });

    test('conflictsStream is empty stream', () async {
      final conflicts = await backend.conflictsStream.toList();
      expect(conflicts, isEmpty);
    });

    test('retryChange completes without error', () async {
      await expectLater(backend.retryChange('any-id'), completes);
    });

    test('cancelChange returns null', () async {
      final result = await backend.cancelChange('any-id');
      expect(result, isNull);
    });
  });
}
