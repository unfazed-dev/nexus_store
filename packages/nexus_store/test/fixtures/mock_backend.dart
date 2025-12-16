import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:rxdart/rxdart.dart';

/// Mock implementation of [StoreBackend] for testing.
class MockStoreBackend<T, ID> extends Mock implements StoreBackend<T, ID> {}

/// Fake implementation of [StoreBackend] with controllable behavior.
///
/// Provides in-memory storage for testing without mocking.
class FakeStoreBackend<T, ID> with StoreBackendDefaults<T, ID> {
  FakeStoreBackend({
    this.idExtractor,
    this.backendName = 'FakeBackend',
  });

  /// Function to extract ID from entity.
  final ID Function(T)? idExtractor;

  /// The name of this backend.
  final String backendName;

  /// In-memory storage.
  final Map<ID, T> _storage = {};

  /// BehaviorSubjects for watching individual items.
  final Map<ID, BehaviorSubject<T?>> _watchers = {};

  /// BehaviorSubject for watching all items.
  BehaviorSubject<List<T>>? _watchAllSubject;

  /// Sync status subject.
  final BehaviorSubject<SyncStatus> _syncStatusSubject =
      BehaviorSubject.seeded(SyncStatus.synced);

  /// Track pending changes for testing.
  int pendingChangesForTest = 0;

  /// Control flags for testing.
  bool shouldFailOnGet = false;
  bool shouldFailOnSave = false;
  bool shouldFailOnDelete = false;
  bool shouldFailOnSync = false;

  /// Error to throw when operations fail.
  Exception? errorToThrow;

  @override
  String get name => backendName;

  @override
  SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<int> get pendingChangesCount async => pendingChangesForTest;

  @override
  Future<T?> get(ID id) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('Get failed');
    }
    return _storage[id];
  }

  @override
  Future<List<T>> getAll({Query<T>? query}) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('GetAll failed');
    }
    return _storage.values.toList();
  }

  @override
  Stream<T?> watch(ID id) {
    _watchers[id] ??= BehaviorSubject.seeded(_storage[id]);
    return _watchers[id]!.stream;
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) {
    _watchAllSubject ??= BehaviorSubject.seeded(_storage.values.toList());
    return _watchAllSubject!.stream;
  }

  @override
  Future<T> save(T item) async {
    if (shouldFailOnSave) {
      throw errorToThrow ?? Exception('Save failed');
    }
    final id = idExtractor?.call(item);
    if (id != null) {
      _storage[id] = item;
      _watchers[id]?.add(item);
      _watchAllSubject?.add(_storage.values.toList());
    }
    return item;
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    if (shouldFailOnSave) {
      throw errorToThrow ?? Exception('SaveAll failed');
    }
    for (final item in items) {
      final id = idExtractor?.call(item);
      if (id != null) {
        _storage[id] = item;
        _watchers[id]?.add(item);
      }
    }
    _watchAllSubject?.add(_storage.values.toList());
    return items;
  }

  @override
  Future<bool> delete(ID id) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('Delete failed');
    }
    final existed = _storage.containsKey(id);
    _storage.remove(id);
    _watchers[id]?.add(null);
    _watchAllSubject?.add(_storage.values.toList());
    return existed;
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('DeleteAll failed');
    }
    var count = 0;
    for (final id in ids) {
      if (_storage.containsKey(id)) {
        _storage.remove(id);
        _watchers[id]?.add(null);
        count++;
      }
    }
    _watchAllSubject?.add(_storage.values.toList());
    return count;
  }

  @override
  Future<int> deleteWhere(Query<T> query) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('DeleteWhere failed');
    }
    // For testing, just clear all
    final count = _storage.length;
    _storage.clear();
    _watchAllSubject?.add([]);
    return count;
  }

  @override
  Future<void> sync() async {
    if (shouldFailOnSync) {
      throw errorToThrow ?? Exception('Sync failed');
    }
    _syncStatusSubject.add(SyncStatus.syncing);
    await Future<void>.delayed(Duration.zero);
    pendingChangesForTest = 0;
    _syncStatusSubject.add(SyncStatus.synced);
  }

  /// Manually set sync status for testing.
  void setSyncStatus(SyncStatus status) {
    _syncStatusSubject.add(status);
  }

  /// Add item directly to storage for testing.
  void addToStorage(ID id, T item) {
    _storage[id] = item;
    _watchers[id]?.add(item);
    _watchAllSubject?.add(_storage.values.toList());
  }

  /// Get storage contents for verification.
  Map<ID, T> get storage => Map.unmodifiable(_storage);

  /// Clear all data.
  void clear() {
    _storage.clear();
    for (final subject in _watchers.values) {
      subject.add(null);
    }
    _watchAllSubject?.add([]);
  }

  @override
  Future<void> close() async {
    await _syncStatusSubject.close();
    for (final subject in _watchers.values) {
      await subject.close();
    }
    await _watchAllSubject?.close();
  }
}
