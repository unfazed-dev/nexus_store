import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_drift_adapter/src/drift_query_translator.dart';
import 'package:rxdart/rxdart.dart';

/// A [nexus.StoreBackend] implementation using Drift for local SQLite storage.
///
/// This adapter provides local-only database operations through Drift's
/// SQLite implementation. Since Drift is local-only, all sync operations
/// are no-ops and always report as synced.
///
/// ## Usage
///
/// ```dart
/// // Create backend with database executor
/// final backend = DriftBackend<User, String>(
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
///   primaryKeyField: 'id',
/// );
///
/// // Initialize with a database executor
/// await backend.initializeWithExecutor(database);
///
/// // Perform operations
/// final users = await backend.getAll();
/// ```
class DriftBackend<T, ID>
    with nexus.StoreBackendDefaults<T, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates a [DriftBackend] with the specified configuration.
  ///
  /// - [tableName]: The name of the SQLite table.
  /// - [getId]: Function to extract the ID from an entity.
  /// - [fromJson]: Function to create entity from JSON map.
  /// - [toJson]: Function to convert entity to JSON map.
  /// - [primaryKeyField]: The name of the primary key column.
  /// - [queryTranslator]: Optional custom query translator.
  /// - [fieldMapping]: Optional field name mapping for queries.
  DriftBackend({
    required String tableName,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    required String primaryKeyField,
    DriftQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  })  : _tableName = tableName,
        _getId = getId,
        _fromJson = fromJson,
        _toJson = toJson,
        _primaryKeyField = primaryKeyField,
        _queryTranslator = queryTranslator ??
            DriftQueryTranslator<T>(fieldMapping: fieldMapping) {
    _pendingChangesManager = nexus.PendingChangesManager<T, ID>(
      idExtractor: getId,
    );
  }

  final String _tableName;
  final ID Function(T item) _getId;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;
  final String _primaryKeyField;
  final DriftQueryTranslator<T> _queryTranslator;

  DatabaseConnectionUser? _executor;

  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);
  final _watchSubjects = <ID, BehaviorSubject<T?>>{};
  final _watchAllSubjects = <String, BehaviorSubject<List<T>>>{};
  bool _initialized = false;

  // Pending changes and conflicts
  late final nexus.PendingChangesManager<T, ID> _pendingChangesManager;
  final _conflictsSubject = BehaviorSubject<nexus.ConflictDetails<T>>();

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  @override
  String get name => 'drift';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    // No-op - use initializeWithExecutor instead
  }

  /// Initializes the backend with a Drift database executor.
  ///
  /// This must be called before any database operations.
  Future<void> initializeWithExecutor(DatabaseConnectionUser executor) async {
    if (_initialized) return;

    _executor = executor;
    _initialized = true;
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
    await _conflictsSubject.close();
    await _pendingChangesManager.dispose();
    _executor = null;
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T?> get(ID id) async {
    _ensureInitialized();

    try {
      final query = nexus.Query<T>().where(_primaryKeyField, isEqualTo: id);
      final (sql, args) = _queryTranslator.toSelectSql(
        tableName: _tableName,
        query: query,
      );

      final results = await _executor!.customSelect(
        sql,
        variables: [for (final arg in args) Variable(arg)],
      ).get();

      if (results.isEmpty) {
        return null;
      }

      return _fromJson(results.first.data);
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> getAll({nexus.Query<T>? query}) async {
    _ensureInitialized();

    try {
      final (sql, args) = _queryTranslator.toSelectSql(
        tableName: _tableName,
        query: query,
      );

      final results = await _executor!.customSelect(
        sql,
        variables: [for (final arg in args) Variable(arg)],
      ).get();

      return results.map((row) => _fromJson(row.data)).toList();
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

    // ignore: close_sinks - closed in close() method
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

    // ignore: close_sinks - closed in close() method
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
      final json = _toJson(item);
      final columns = json.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      final columnNames = columns.join(', ');

      // Use INSERT OR REPLACE for upsert behavior
      final sql = 'INSERT OR REPLACE INTO $_tableName '
          '($columnNames) VALUES ($placeholders)';

      await _executor!.customStatement(sql, [
        for (final col in columns) json[col],
      ]);

      _notifyWatchers(item);
      return item;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    _ensureInitialized();

    try {
      final results = <T>[];

      await _executor!.transaction(() async {
        for (final item in items) {
          final json = _toJson(item);
          final columns = json.keys.toList();
          final placeholders = List.filled(columns.length, '?').join(', ');
          final columnNames = columns.join(', ');

          final sql = 'INSERT OR REPLACE INTO $_tableName '
              '($columnNames) VALUES ($placeholders)';

          await _executor!.customStatement(sql, [
            for (final col in columns) json[col],
          ]);

          results.add(item);
        }
      });

      for (final item in results) {
        _notifyWatchers(item);
      }

      return results;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<bool> delete(ID id) async {
    _ensureInitialized();

    try {
      final sql = 'DELETE FROM $_tableName WHERE $_primaryKeyField = ?';
      final affectedRows = await _executor!.customUpdate(
        sql,
        variables: [Variable(id)],
        updates: {},
      );

      if (affectedRows > 0) {
        _notifyDeletion(id);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    _ensureInitialized();

    if (ids.isEmpty) return 0;

    try {
      var deleted = 0;

      await _executor!.transaction(() async {
        for (final id in ids) {
          final sql = 'DELETE FROM $_tableName WHERE $_primaryKeyField = ?';
          final affected = await _executor!.customUpdate(
            sql,
            variables: [Variable(id)],
            updates: {},
          );
          if (affected > 0) {
            deleted++;
            _notifyDeletion(id);
          }
        }
      });

      return deleted;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteWhere(nexus.Query<T> query) async {
    _ensureInitialized();

    try {
      final (sql, args) = _queryTranslator.toDeleteSql(
        tableName: _tableName,
        query: query,
      );

      final deleted = await _executor!.customUpdate(
        sql,
        variables: [for (final arg in args) Variable(arg)],
        updates: {},
      );

      // Refresh watchers since we don't know which items were deleted
      _refreshAllWatchers();

      return deleted;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync Operations (Local-Only Stubs)
  // ---------------------------------------------------------------------------

  @override
  nexus.SyncStatus get syncStatus => nexus.SyncStatus.synced;

  @override
  Stream<nexus.SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<void> sync() async {
    // No-op for local-only database
  }

  @override
  Future<int> get pendingChangesCount async => 0;

  // ---------------------------------------------------------------------------
  // Pending Changes & Conflicts
  // ---------------------------------------------------------------------------

  @override
  Stream<List<nexus.PendingChange<T>>> get pendingChangesStream =>
      _pendingChangesManager.pendingChangesStream;

  @override
  Stream<nexus.ConflictDetails<T>> get conflictsStream =>
      _conflictsSubject.stream;

  @override
  Future<void> retryChange(String changeId) async {
    _ensureInitialized();

    final change = _pendingChangesManager.getChange(changeId);
    if (change == null) return;

    // Update retry count
    _pendingChangesManager.updateChange(
      changeId,
      retryCount: change.retryCount + 1,
      lastAttempt: DateTime.now(),
    );

    // Drift is local-only, so sync is a no-op
    await sync();
  }

  @override
  Future<nexus.PendingChange<T>?> cancelChange(String changeId) async {
    _ensureInitialized();

    final change = _pendingChangesManager.getChange(changeId);
    if (change == null) return null;

    // If we have an original value and this was an update, restore it
    if (change.originalValue != null &&
        change.operation == nexus.PendingChangeOperation.update) {
      await save(change.originalValue as T);
    }

    // If this was a create, delete the item
    if (change.operation == nexus.PendingChangeOperation.create) {
      await delete(_getId(change.item));
    }

    // If this was a delete and we have original, restore it
    if (change.operation == nexus.PendingChangeOperation.delete &&
        change.originalValue != null) {
      await save(change.originalValue as T);
    }

    // Remove from pending changes
    return _pendingChangesManager.removeChange(changeId);
  }

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  @override
  bool get supportsPagination => true;

  @override
  Future<nexus.PagedResult<T>> getAllPaged({nexus.Query<T>? query}) async {
    _ensureInitialized();

    try {
      final items = await getAll(query: query);

      // Handle cursor-based pagination
      final firstCount = query?.firstCount;
      final afterCursor = query?.afterCursor;

      var startIndex = 0;
      if (afterCursor != null) {
        final cursorIndex = afterCursor.toValues()['_index'] as int?;
        if (cursorIndex != null) {
          startIndex = cursorIndex;
        }
      }

      var endIndex = items.length;
      if (firstCount != null) {
        endIndex = (startIndex + firstCount).clamp(0, items.length);
      }

      final pageItems = items.sublist(startIndex, endIndex);
      final hasNextPage = endIndex < items.length;
      final hasPreviousPage = startIndex > 0;

      nexus.Cursor? startCursor;
      nexus.Cursor? endCursor;

      if (pageItems.isNotEmpty) {
        startCursor = nexus.Cursor.fromValues({'_index': startIndex});
        if (hasNextPage) {
          endCursor = nexus.Cursor.fromValues({'_index': endIndex});
        }
      }

      return nexus.PagedResult<T>(
        items: pageItems,
        pageInfo: nexus.PageInfo(
          hasNextPage: hasNextPage,
          hasPreviousPage: hasPreviousPage,
          startCursor: startCursor,
          endCursor: endCursor,
          totalCount: items.length,
        ),
      );
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Stream<nexus.PagedResult<T>> watchAllPaged({nexus.Query<T>? query}) {
    _ensureInitialized();

    return watchAll(query: query).map((items) {
      final firstCount = query?.firstCount;
      final afterCursor = query?.afterCursor;

      var startIndex = 0;
      if (afterCursor != null) {
        final cursorIndex = afterCursor.toValues()['_index'] as int?;
        if (cursorIndex != null) {
          startIndex = cursorIndex;
        }
      }

      var endIndex = items.length;
      if (firstCount != null) {
        endIndex = (startIndex + firstCount).clamp(0, items.length);
      }

      final pageItems = items.sublist(startIndex, endIndex);
      final hasNextPage = endIndex < items.length;
      final hasPreviousPage = startIndex > 0;

      nexus.Cursor? startCursor;
      nexus.Cursor? endCursor;

      if (pageItems.isNotEmpty) {
        startCursor = nexus.Cursor.fromValues({'_index': startIndex});
        if (hasNextPage) {
          endCursor = nexus.Cursor.fromValues({'_index': endIndex});
        }
      }

      return nexus.PagedResult<T>(
        items: pageItems,
        pageInfo: nexus.PageInfo(
          hasNextPage: hasNextPage,
          hasPreviousPage: hasPreviousPage,
          startCursor: startCursor,
          endCursor: endCursor,
          totalCount: items.length,
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw const nexus.StateError(
        message:
            'Backend not initialized. Call initializeWithExecutor() first.',
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
      // ignore: close_sinks - subject is from _watchAllSubjects, closed in close()
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

    final message = error.toString().toLowerCase();

    // Map SQLite-specific errors
    if (message.contains('unique constraint') ||
        message.contains('uniqueviolation')) {
      return nexus.ValidationError(
        message: 'Unique constraint violation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('foreign key') ||
        message.contains('foreignkeyviolation')) {
      return nexus.ValidationError(
        message: 'Foreign key constraint violation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('database is locked') || message.contains('busy')) {
      return nexus.TransactionError(
        message: 'Database is locked',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('no such table')) {
      return nexus.StateError(
        message: 'Table does not exist',
        cause: error,
        stackTrace: stackTrace,
        currentState: 'table_missing',
        expectedState: 'table_exists',
      );
    }

    return nexus.SyncError(
      message: 'Drift operation failed: $message',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
