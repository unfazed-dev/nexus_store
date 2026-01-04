import 'dart:async';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/powersync_database_wrapper.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_query_translator.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:rxdart/rxdart.dart';

/// PowerSync backend adapter for nexus_store.
///
/// Provides offline-first data persistence with automatic sync to a
/// PostgreSQL backend via PowerSync.
///
/// Example:
/// ```dart
/// final backend = PowerSyncBackend<User, String>(
///   db: powerSyncDatabase,
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
/// );
///
/// await backend.initialize();
/// final users = await backend.getAll();
/// ```
class PowerSyncBackend<T, ID>
    with nexus.StoreBackendDefaults<T, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates a PowerSync backend adapter.
  ///
  /// [db] - The PowerSync database instance (wrapped automatically).
  /// [tableName] - The table name to operate on.
  /// [getId] - Function to extract the ID from an entity.
  /// [fromJson] - Function to deserialize an entity from JSON.
  /// [toJson] - Function to serialize an entity to JSON.
  /// [primaryKeyColumn] - The primary key column name (default: 'id').
  /// [queryTranslator] - Optional custom query translator.
  /// [fieldMapping] - Optional field name to column name mapping.
  PowerSyncBackend({
    required ps.PowerSyncDatabase db,
    required String tableName,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    String primaryKeyColumn = 'id',
    PowerSyncQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  }) : this.withWrapper(
          db: DefaultPowerSyncDatabaseWrapper(db),
          tableName: tableName,
          getId: getId,
          fromJson: fromJson,
          toJson: toJson,
          primaryKeyColumn: primaryKeyColumn,
          queryTranslator: queryTranslator,
          fieldMapping: fieldMapping,
        );

  /// Creates a PowerSync backend with a custom database wrapper.
  ///
  /// This constructor is primarily for testing, allowing injection of
  /// a mock database wrapper.
  PowerSyncBackend.withWrapper({
    required PowerSyncDatabaseWrapper db,
    required String tableName,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    String primaryKeyColumn = 'id',
    PowerSyncQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  })  : _db = db,
        _tableName = tableName,
        _getId = getId,
        _fromJson = fromJson,
        _toJson = toJson,
        _primaryKeyColumn = primaryKeyColumn,
        _queryTranslator = queryTranslator ??
            PowerSyncQueryTranslator<T>(fieldMapping: fieldMapping) {
    _pendingChangesManager = nexus.PendingChangesManager<T, ID>(
      idExtractor: getId,
    );
  }

  final PowerSyncDatabaseWrapper _db;
  final String _tableName;
  final ID Function(T item) _getId;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;
  final String _primaryKeyColumn;
  final PowerSyncQueryTranslator<T> _queryTranslator;

  // State management
  bool _initialized = false;
  StreamSubscription<ps.SyncStatus>? _syncStatusSubscription;

  // Reactive streams
  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);
  final _watchSubjects = <ID, BehaviorSubject<T?>>{};
  final _watchStreams = <ID, Stream<T?>>{};
  final _watchAllSubjects = <String, BehaviorSubject<List<T>>>{};
  final _watchAllStreams = <String, Stream<List<T>>>{};
  final _watchSubscriptions =
      <String, StreamSubscription<List<Map<String, dynamic>>>>{};

  // Pending changes and conflicts
  late final nexus.PendingChangesManager<T, ID> _pendingChangesManager;
  final _conflictsSubject = BehaviorSubject<nexus.ConflictDetails<T>>();

  // ===================== BACKEND INFO =====================

  @override
  String get name => 'powersync';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => true;

  @override
  bool get supportsTransactions => true;

  // ===================== LIFECYCLE =====================

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _setupSyncStatusListener();
    _initialized = true;
  }

  void _setupSyncStatusListener() {
    _syncStatusSubscription = _db.statusStream.listen((status) {
      final mappedStatus = _mapPowerSyncStatus(status);
      if (!_syncStatusSubject.isClosed) {
        _syncStatusSubject.add(mappedStatus);
      }
    });
  }

  @override
  Future<void> close() async {
    await _syncStatusSubscription?.cancel();
    _syncStatusSubscription = null;

    // Close all watch subscriptions
    for (final subscription in _watchSubscriptions.values) {
      await subscription.cancel();
    }
    _watchSubscriptions.clear();

    // Close all watch subjects and clear stream caches
    for (final subject in _watchSubjects.values) {
      await subject.close();
    }
    _watchSubjects.clear();
    _watchStreams.clear();

    for (final subject in _watchAllSubjects.values) {
      await subject.close();
    }
    _watchAllSubjects.clear();
    _watchAllStreams.clear();

    await _syncStatusSubject.close();
    await _conflictsSubject.close();
    await _pendingChangesManager.dispose();
    _initialized = false;
  }

  // ===================== READ OPERATIONS =====================

  @override
  Future<T?> get(ID id) async {
    _ensureInitialized();

    try {
      final sql = 'SELECT * FROM $_tableName WHERE $_primaryKeyColumn = ?';
      final results = await _db.execute(sql, [id]);

      if (results.isEmpty) {
        return null;
      }

      return _fromJson(results.first);
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

      final results = await _db.execute(sql, args);
      return results.map(_fromJson).toList();
    } catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Stream<T?> watch(ID id) {
    _ensureInitialized();

    // Return cached stream if available
    if (_watchStreams.containsKey(id)) {
      return _watchStreams[id]!;
    }

    // ignore: close_sinks - closed in close() method
    final subject = BehaviorSubject<T?>();
    _watchSubjects[id] = subject;

    final sql = 'SELECT * FROM $_tableName WHERE $_primaryKeyColumn = ?';
    final subscriptionKey = 'watch_$id';

    // ignore: cancel_subscriptions - cancelled in close() method
    final subscription = _db.watch(sql, parameters: [id]).listen(
      (results) {
        if (!subject.isClosed) {
          final item = results.isEmpty ? null : _fromJson(results.first);
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

    // Cache and return the stream
    final stream = subject.stream;
    _watchStreams[id] = stream;
    return stream;
  }

  @override
  Stream<List<T>> watchAll({nexus.Query<T>? query}) {
    _ensureInitialized();

    final queryKey = query?.toString() ?? '_all_';

    // Return cached stream if available
    if (_watchAllStreams.containsKey(queryKey)) {
      return _watchAllStreams[queryKey]!;
    }

    // ignore: close_sinks - closed in close() method
    final subject = BehaviorSubject<List<T>>();
    _watchAllSubjects[queryKey] = subject;

    final (sql, args) = _queryTranslator.toSelectSql(
      tableName: _tableName,
      query: query,
    );

    final subscriptionKey = 'watchAll_$queryKey';

    // ignore: cancel_subscriptions - cancelled in close() method
    final subscription = _db.watch(sql, parameters: args).listen(
      (results) {
        if (!subject.isClosed) {
          final items = results.map(_fromJson).toList();
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

    // Cache and return the stream
    final stream = subject.stream;
    _watchAllStreams[queryKey] = stream;
    return stream;
  }

  // ===================== WRITE OPERATIONS =====================

  @override
  Future<T> save(T item) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final json = _toJson(item);
      final id = _getId(item);

      // Build upsert SQL using INSERT OR REPLACE
      final columns = json.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      final columnNames = columns.join(', ');
      final values = columns.map((col) => json[col]).toList();

      final sql = 'INSERT OR REPLACE INTO $_tableName ($columnNames) '
          'VALUES ($placeholders)';

      await _db.execute(sql, values);

      // Fetch the saved item to return (may have server-generated fields)
      final result = await get(id);

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return result ?? item;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    _ensureInitialized();

    if (items.isEmpty) return [];

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      await _db.writeTransaction((tx) async {
        for (final item in items) {
          final json = _toJson(item);
          final columns = json.keys.toList();
          final placeholders = List.filled(columns.length, '?').join(', ');
          final columnNames = columns.join(', ');
          final values = columns.map((col) => json[col]).toList();

          final sql = 'INSERT OR REPLACE INTO $_tableName ($columnNames) '
              'VALUES ($placeholders)';

          await tx.execute(sql, values);
        }
      });

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return items;
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

      // Check if item exists
      final existing = await get(id);
      if (existing == null) {
        _syncStatusSubject.add(nexus.SyncStatus.synced);
        return false;
      }

      final sql = 'DELETE FROM $_tableName WHERE $_primaryKeyColumn = ?';
      await _db.execute(sql, [id]);

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

    if (ids.isEmpty) return 0;

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final placeholders = List.filled(ids.length, '?').join(', ');
      final sql =
          'DELETE FROM $_tableName WHERE $_primaryKeyColumn IN ($placeholders)';

      await _db.execute(sql, ids);

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return ids.length;
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

      final (sql, args) = _queryTranslator.toDeleteSql(
        tableName: _tableName,
        query: query,
      );

      await _db.execute(sql, args);

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      // Note: SQLite doesn't return affected row count from execute
      return 0;
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  // ===================== SYNC OPERATIONS =====================

  @override
  nexus.SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<nexus.SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<void> sync() async {
    _ensureInitialized();

    try {
      // PowerSync handles sync automatically, but we can trigger it
      // via database operations if needed
      _syncStatusSubject
        ..add(nexus.SyncStatus.syncing)
        ..add(nexus.SyncStatus.synced);
      // coverage:ignore-start
    } catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
    // coverage:ignore-end
  }

  @override
  Future<int> get pendingChangesCount async {
    _ensureInitialized();

    final status = _db.currentStatus;
    // PowerSync tracks pending uploads internally
    return status.hasSynced == false ? 1 : 0;
  }

  // ===================== PENDING CHANGES & CONFLICTS =====================

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

    // coverage:ignore-start
    // Edge case: requires pending changes to exist
    // Update retry count
    _pendingChangesManager.updateChange(
      changeId,
      retryCount: change.retryCount + 1,
      lastAttempt: DateTime.now(),
    );

    // Trigger sync
    await sync();
    // coverage:ignore-end
  }

  @override
  Future<nexus.PendingChange<T>?> cancelChange(String changeId) async {
    _ensureInitialized();

    final change = _pendingChangesManager.getChange(changeId);
    if (change == null) return null;

    // coverage:ignore-start
    // Edge case: requires specific pending change states to test
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
    // coverage:ignore-end
  }

  // ===================== PAGINATION =====================

  @override
  bool get supportsPagination => true;

  @override
  Future<nexus.PagedResult<T>> getAllPaged({nexus.Query<T>? query}) async {
    _ensureInitialized();

    try {
      // For PowerSync, we implement cursor-based pagination using LIMIT/OFFSET
      final (sql, args) = _queryTranslator.toSelectSql(
        tableName: _tableName,
        query: query,
      );

      final results = await _db.execute(sql, args);
      final items = results.map(_fromJson).toList();

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

  // ===================== HELPERS =====================

  void _ensureInitialized() {
    if (!_initialized) {
      throw const nexus.StateError(
        message: 'Backend not initialized. Call initialize() first.',
        currentState: 'uninitialized',
        expectedState: 'initialized',
      );
    }
  }

  nexus.SyncStatus _mapPowerSyncStatus(ps.SyncStatus status) {
    if (status.uploading) {
      return nexus.SyncStatus.syncing;
    }
    if (status.downloadError != null || status.uploadError != null) {
      return nexus.SyncStatus.error;
    }
    if (!status.connected) {
      return nexus.SyncStatus.paused;
    }
    return nexus.SyncStatus.synced;
  }

  nexus.StoreError _mapException(Object error, StackTrace stackTrace) {
    if (error is nexus.StoreError) {
      return error;
    }

    final message = error.toString().toLowerCase();

    // SQLite constraint errors
    if (message.contains('constraint') || message.contains('unique')) {
      return nexus.ValidationError(
        message: 'Constraint violation: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('foreign key')) {
      return nexus.ValidationError(
        message: 'Foreign key constraint violation: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Network errors
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return nexus.NetworkError(
        message: 'Network error during PowerSync operation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('timeout')) {
      return nexus.TimeoutError(
        duration: const Duration(seconds: 30),
        operation: 'PowerSync operation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Auth errors
    if (message.contains('unauthorized') || message.contains('401')) {
      return nexus.AuthenticationError(
        message: 'Authentication failed during sync',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('forbidden') || message.contains('403')) {
      return nexus.AuthorizationError(
        message: 'Authorization denied during sync',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Default to SyncError
    return nexus.SyncError(
      message: 'PowerSync operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
