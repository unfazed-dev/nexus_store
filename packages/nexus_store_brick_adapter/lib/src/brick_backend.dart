import 'dart:async';

import 'package:brick_core/query.dart' as brick;
import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/src/brick_query_translator.dart';
import 'package:rxdart/rxdart.dart';

/// A [nexus.StoreBackend] implementation using Brick's offline-first repository.
///
/// This adapter provides offline-first capabilities through Brick's repository
/// pattern, with automatic local caching and background synchronization.
///
/// ## Usage
///
/// ```dart
/// final backend = BrickBackend<User, String>(
///   repository: myBrickRepository,
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
///   primaryKeyField: 'id',
/// );
///
/// await backend.initialize();
/// final users = await backend.getAll();
/// ```
class BrickBackend<T extends OfflineFirstModel, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates a [BrickBackend] with the specified repository and converters.
  ///
  /// - [repository]: The Brick offline-first repository to use.
  /// - [getId]: Function to extract the ID from an entity.
  /// - [primaryKeyField]: The name of the primary key field in the model.
  /// - [queryTranslator]: Optional custom query translator.
  /// - [fieldMapping]: Optional field name mapping for queries.
  BrickBackend({
    required OfflineFirstRepository<T> repository,
    required ID Function(T item) getId,
    required String primaryKeyField,
    BrickQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  })  : _repository = repository,
        _getId = getId,
        _primaryKeyField = primaryKeyField,
        _queryTranslator = queryTranslator ??
            BrickQueryTranslator<T>(fieldMapping: fieldMapping);

  final OfflineFirstRepository<T> _repository;
  final ID Function(T item) _getId;
  final String _primaryKeyField;
  final BrickQueryTranslator<T> _queryTranslator;

  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);
  final _watchSubjects = <ID, BehaviorSubject<T?>>{};
  final _watchAllSubjects = <String, BehaviorSubject<List<T>>>{};
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  @override
  String get name => 'brick';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => true;

  @override
  bool get supportsTransactions => true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _repository.initialize();
      _initialized = true;
      _syncStatusSubject.add(nexus.SyncStatus.synced);
    } catch (e, stackTrace) {
      throw nexus.SyncError(
        message: 'Failed to initialize Brick repository',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    for (final subject in _watchSubjects.values) {
      await subject.close();
    }
    _watchSubjects.clear();

    for (final subject in _watchAllSubjects.values) {
      await subject.close();
    }
    _watchAllSubjects.clear();

    await _syncStatusSubject.close();
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T?> get(ID id) async {
    _ensureInitialized();

    try {
      final query = brick.Query.where(_primaryKeyField, id);
      final results = await _repository.get<T>(query: query);

      if (results.isEmpty) {
        return null;
      }

      return results.first;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> getAll({nexus.Query<T>? query}) async {
    _ensureInitialized();

    try {
      final brickQuery =
          query != null ? _queryTranslator.translate(query) : null;
      final results = await _repository.get<T>(query: brickQuery);
      return results;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Stream<T?> watch(ID id) {
    _ensureInitialized();

    if (_watchSubjects.containsKey(id)) {
      return _watchSubjects[id]!.stream;
    }

    final subject = BehaviorSubject<T?>();
    _watchSubjects[id] = subject;

    // Initial load
    get(id).then(subject.add).catchError((Object e) {
      if (!subject.isClosed) {
        subject.addError(e);
      }
    });

    return subject.stream;
  }

  @override
  Stream<List<T>> watchAll({nexus.Query<T>? query}) {
    _ensureInitialized();

    final queryKey = query?.toString() ?? '_all_';

    if (_watchAllSubjects.containsKey(queryKey)) {
      return _watchAllSubjects[queryKey]!.stream;
    }

    final subject = BehaviorSubject<List<T>>();
    _watchAllSubjects[queryKey] = subject;

    // Initial load
    getAll(query: query).then(subject.add).catchError((Object e) {
      if (!subject.isClosed) {
        subject.addError(e);
      }
    });

    return subject.stream;
  }

  // ---------------------------------------------------------------------------
  // Write Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T> save(T item) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final result = await _repository.upsert<T>(item);

      _notifyWatchers(result);
      _syncStatusSubject.add(nexus.SyncStatus.synced);

      return result;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final results = <T>[];
      for (final item in items) {
        final result = await _repository.upsert<T>(item);
        results.add(result);
      }

      for (final item in results) {
        _notifyWatchers(item);
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return results;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<bool> delete(ID id) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final item = await get(id);
      if (item == null) {
        _syncStatusSubject.add(nexus.SyncStatus.synced);
        return false;
      }

      await _repository.delete<T>(item);

      _notifyDeletion(id);
      _syncStatusSubject.add(nexus.SyncStatus.synced);

      return true;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      var deleted = 0;
      for (final id in ids) {
        if (await delete(id)) {
          deleted++;
        }
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return deleted;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteWhere(nexus.Query<T> query) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final items = await getAll(query: query);
      var deleted = 0;

      for (final item in items) {
        final id = _getId(item);
        if (await delete(id)) {
          deleted++;
        }
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return deleted;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync Operations
  // ---------------------------------------------------------------------------

  @override
  nexus.SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<nexus.SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<void> sync() async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.syncing);

      // Brick repositories handle sync automatically through their providers
      // Trigger a refresh by getting all items
      await _repository.get<T>();

      _syncStatusSubject.add(nexus.SyncStatus.synced);
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> get pendingChangesCount async {
    // Brick handles its offline queue internally
    // This would require access to the SQLite provider's queue
    // For now, return 0 if synced, or estimate based on status
    return syncStatus == nexus.SyncStatus.pending ? 1 : 0;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw nexus.StateError(
        message: 'Backend not initialized. Call initialize() first.',
        currentState: 'uninitialized',
        expectedState: 'initialized',
      );
    }
  }

  void _notifyWatchers(T item) {
    final id = _getId(item);

    // Update individual watch
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(item);
    }

    // Update all watchAll subjects
    _refreshAllWatchers();
  }

  void _notifyDeletion(ID id) {
    // Update individual watch
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(null);
    }

    // Update all watchAll subjects
    _refreshAllWatchers();
  }

  void _refreshAllWatchers() {
    for (final entry in _watchAllSubjects.entries) {
      final queryKey = entry.key;
      final subject = entry.value;

      // Refresh all with no query for simplicity
      if (queryKey == '_all_') {
        getAll().then(subject.add).catchError((Object e) {
          if (!subject.isClosed) {
            subject.addError(e);
          }
        });
      }
    }
  }

  nexus.StoreError _mapException(Object error, StackTrace stackTrace) {
    if (error is nexus.StoreError) {
      return error;
    }

    // Map common Brick/network exceptions
    final message = error.toString();

    if (message.contains('network') ||
        message.contains('SocketException') ||
        message.contains('Connection')) {
      return nexus.NetworkError(
        message: 'Network error during Brick operation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('timeout') || message.contains('TimeoutException')) {
      return nexus.TimeoutError(
        duration: const Duration(seconds: 30),
        operation: 'Brick repository operation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('conflict') || message.contains('Conflict')) {
      return nexus.ConflictError(
        message: 'Conflict during Brick sync',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return nexus.SyncError(
      message: 'Brick operation failed: $message',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
