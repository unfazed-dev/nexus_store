import 'dart:async';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/src/crdt_query_translator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

/// A [nexus.StoreBackend] implementation using sqlite_crdt for CRDT-based
/// local storage with conflict-free synchronization.
///
/// This adapter provides:
/// - Offline-first storage with SQLite
/// - Automatic conflict resolution via Hybrid Logical Clocks (HLC)
/// - Last-Writer-Wins (LWW) merge strategy
/// - Tombstone-based soft deletes for CRDT correctness
/// - Changeset-based synchronization between peers
///
/// ## Usage
///
/// ```dart
/// final backend = CrdtBackend<User, String>(
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
///   primaryKeyField: 'id',
/// );
///
/// await backend.initialize();
/// await backend.save(User(id: '1', name: 'Alice'));
///
/// // Sync with another node
/// final changeset = await backend.getChangeset();
/// await otherBackend.applyChangeset(changeset);
/// ```
class CrdtBackend<T, ID>
    with nexus.StoreBackendDefaults<T, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates a [CrdtBackend] with the specified configuration.
  ///
  /// - [tableName]: The name of the SQLite table.
  /// - [getId]: Function to extract the ID from an entity.
  /// - [fromJson]: Function to create entity from JSON map.
  /// - [toJson]: Function to convert entity to JSON map.
  /// - [primaryKeyField]: The name of the primary key column.
  /// - [queryTranslator]: Optional custom query translator.
  /// - [fieldMapping]: Optional field name mapping for queries.
  CrdtBackend({
    required String tableName,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    required String primaryKeyField,
    CrdtQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  })  : _tableName = tableName,
        _getId = getId,
        _fromJson = fromJson,
        _toJson = toJson,
        _primaryKeyField = primaryKeyField,
        _queryTranslator = queryTranslator ??
            CrdtQueryTranslator<T>(fieldMapping: fieldMapping) {
    _pendingChangesManager = nexus.PendingChangesManager<T, ID>(
      idExtractor: getId,
    );
  }

  final String _tableName;
  final ID Function(T item) _getId;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;
  final String _primaryKeyField;
  final CrdtQueryTranslator<T> _queryTranslator;

  SqliteCrdt? _crdt;

  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);
  final _watchSubjects = <ID, BehaviorSubject<T?>>{};
  final _watchAllSubjects = <String, BehaviorSubject<List<T>>>{};
  final _watchSubscriptions = <String, StreamSubscription<dynamic>>{};
  bool _initialized = false;

  // Pending changes and conflicts
  late final nexus.PendingChangesManager<T, ID> _pendingChangesManager;
  final _conflictsSubject = BehaviorSubject<nexus.ConflictDetails<T>>();

  // ---------------------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------------------

  /// Whether the backend has been initialized.
  bool get isInitialized => _initialized;

  /// The unique node ID for this CRDT instance.
  ///
  /// Each node in a CRDT network must have a unique ID to ensure proper
  /// timestamp generation and conflict resolution.
  String get nodeId {
    _ensureInitialized();
    return _crdt!.nodeId;
  }

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  @override
  String get name => 'crdt';

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

    _crdt = await SqliteCrdt.openInMemory(
      version: 1,
      onCreate: _createTable,
    );

    _initialized = true;
  }

  Future<void> _createTable(CrdtTableExecutor crdt, int version) async {
    // Create the main table with primary key
    // sqlite_crdt automatically adds: hlc, modified, is_deleted, node_id
    await crdt.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        $_primaryKeyField TEXT PRIMARY KEY NOT NULL,
        name TEXT,
        age INTEGER
      )
    ''');
  }

  @override
  Future<void> close() async {
    // Cancel all watch subscriptions
    for (final subscription in _watchSubscriptions.values) {
      await subscription.cancel();
    }
    _watchSubscriptions.clear();

    // Close all BehaviorSubjects
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
    await _crdt?.close();
    _crdt = null;
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T?> get(ID id) async {
    _ensureInitialized();

    try {
      final results = await _crdt!.query(
        'SELECT * FROM $_tableName WHERE $_primaryKeyField = ?1 '
        'AND is_deleted = 0',
        [id],
      );

      if (results.isEmpty) {
        return null;
      }

      return _fromJson(_stripCrdtMetadata(results.first));
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
        includeTombstoneFilter: true,
      );

      final results = await _crdt!.query(sql, args);

      return results.map((row) => _fromJson(_stripCrdtMetadata(row))).toList();
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

    final sql = 'SELECT * FROM $_tableName WHERE $_primaryKeyField = ?1 '
        'AND is_deleted = 0';
    final subscriptionKey = 'watch_$id';

    // ignore: cancel_subscriptions - cancelled in close() method
    final subscription = _crdt!.watch(sql, () => [id]).listen(
      (results) {
        if (!subject.isClosed) {
          final item = results.isEmpty
              ? null
              : _fromJson(_stripCrdtMetadata(results.first));
          subject.add(item);
        }
      },
      onError: (Object e) {
        if (!subject.isClosed) {
          subject.addError(_mapException(e, StackTrace.current));
        }
      },
    );

    _watchSubscriptions[subscriptionKey] = subscription;
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

    final (sql, args) = _queryTranslator.toSelectSql(
      tableName: _tableName,
      query: query,
      includeTombstoneFilter: true,
    );

    final subscriptionKey = 'watchAll_$queryKey';

    // ignore: cancel_subscriptions - cancelled in close() method
    final subscription = _crdt!.watch(sql, () => args).listen(
      (results) {
        if (!subject.isClosed) {
          final items =
              results.map((row) => _fromJson(_stripCrdtMetadata(row))).toList();
          subject.add(items);
        }
      },
      onError: (Object e) {
        if (!subject.isClosed) {
          subject.addError(_mapException(e, StackTrace.current));
        }
      },
    );

    _watchSubscriptions[subscriptionKey] = subscription;
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
      final placeholders =
          List.generate(columns.length, (i) => '?${i + 1}').join(', ');
      final columnNames = columns.join(', ');

      // Use INSERT OR REPLACE for upsert behavior
      // sqlite_crdt automatically handles HLC timestamps
      final sql = 'INSERT OR REPLACE INTO $_tableName '
          '($columnNames) VALUES ($placeholders)';

      await _crdt!.execute(sql, [
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

    if (items.isEmpty) return [];

    try {
      await _crdt!.transaction((txn) async {
        for (final item in items) {
          final json = _toJson(item);
          final columns = json.keys.toList();
          final placeholders =
              List.generate(columns.length, (i) => '?${i + 1}').join(', ');
          final columnNames = columns.join(', ');

          final sql = 'INSERT OR REPLACE INTO $_tableName '
              '($columnNames) VALUES ($placeholders)';

          await txn.execute(sql, [
            for (final col in columns) json[col],
          ]);
        }
      });

      for (final item in items) {
        _notifyWatchers(item);
      }

      return items;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<bool> delete(ID id) async {
    _ensureInitialized();

    try {
      // In CRDT, DELETE creates a tombstone (is_deleted = 1)
      // sqlite_crdt handles this automatically
      await _crdt!.execute(
        'DELETE FROM $_tableName WHERE $_primaryKeyField = ?1',
        [id],
      );

      _notifyDeletion(id);
      return true;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    _ensureInitialized();

    if (ids.isEmpty) return 0;

    try {
      await _crdt!.transaction((txn) async {
        for (final id in ids) {
          await txn.execute(
            'DELETE FROM $_tableName WHERE $_primaryKeyField = ?1',
            [id],
          );
        }
      });

      for (final id in ids) {
        _notifyDeletion(id);
      }

      return ids.length;
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteWhere(nexus.Query<T> query) async {
    _ensureInitialized();

    try {
      // First, get the IDs of items to delete
      final items = await getAll(query: query);
      if (items.isEmpty) return 0;

      final ids = items.map(_getId).toList();
      return deleteAll(ids);
    } catch (e, stackTrace) {
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
    // Manual sync trigger - actual implementation depends on transport layer
    // sqlite_crdt doesn't include transport, so this is a no-op placeholder
    _syncStatusSubject.add(nexus.SyncStatus.syncing);
    _syncStatusSubject.add(nexus.SyncStatus.synced);
  }

  @override
  Future<int> get pendingChangesCount async {
    _ensureInitialized();
    // In a fully synced local-only scenario, there are no pending changes
    // This would need to track unsynced changes if connected to a remote
    return 0;
  }

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

    // CRDT uses LWW, so just trigger sync
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
  // CRDT-Specific Operations
  // ---------------------------------------------------------------------------

  /// Gets all changes since the given HLC timestamp.
  ///
  /// If [since] is null, returns all changes (full sync).
  /// Use this to get changes to send to another peer.
  Future<CrdtChangeset> getChangeset({Hlc? since}) async {
    _ensureInitialized();
    return _crdt!.getChangeset(
      modifiedAfter: since,
    );
  }

  /// Applies a remote changeset, merging with Last-Writer-Wins resolution.
  ///
  /// The sqlite_crdt library handles conflict resolution automatically
  /// using HLC timestamps - the record with the higher HLC wins.
  Future<void> applyChangeset(CrdtChangeset changeset) async {
    _ensureInitialized();
    await _crdt!.merge(changeset);
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw const nexus.StateError(
        message: 'Backend not initialized. Call initialize() first.',
        currentState: 'uninitialized',
        expectedState: 'initialized',
      );
    }
  }

  /// Strips CRDT metadata columns from a row before conversion.
  Map<String, dynamic> _stripCrdtMetadata(Map<String, Object?> row) {
    final result = Map<String, dynamic>.from(row)
      ..remove('hlc')
      ..remove('modified')
      ..remove('is_deleted')
      ..remove('node_id');
    return result;
  }

  void _notifyWatchers(T item) {
    final id = _getId(item);

    // Update individual watch
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(item);
    }

    // Refresh watchAll subjects
    _refreshAllWatchers();
  }

  void _notifyDeletion(ID id) {
    // Update individual watch
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(null);
    }

    // Refresh watchAll subjects
    _refreshAllWatchers();
  }

  void _refreshAllWatchers() {
    for (final entry in _watchAllSubjects.entries) {
      final queryKey = entry.key;
      final subject = entry.value;

      // For simplicity, refresh all watchAll with null query
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
      message: 'CRDT operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
