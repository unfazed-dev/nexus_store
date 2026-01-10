import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/column_definition.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_backend_factory.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_database_wrapper.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_query_translator.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:rxdart/rxdart.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

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
            PowerSyncQueryTranslator<T>(fieldMapping: fieldMapping),
        _ownsDatabase = false,
        _supabaseClient = null,
        _config = null,
        _openFactory = null {
    _pendingChangesManager = nexus.PendingChangesManager<T, ID>(
      idExtractor: getId,
    );
  }

  /// Creates a PowerSync backend with Supabase integration.
  ///
  /// This factory creates and manages the PowerSyncDatabase internally,
  /// providing a "batteries included" experience.
  ///
  /// Example:
  /// ```dart
  /// final backend = PowerSyncBackend<User, String>.withSupabase(
  ///   supabase: Supabase.instance.client,
  ///   powerSyncUrl: 'https://xxx.powersync.co',
  ///   tableName: 'users',
  ///   columns: [
  ///     PSColumn.text('name'),
  ///     PSColumn.text('email'),
  ///     PSColumn.integer('age'),
  ///   ],
  ///   fromJson: User.fromJson,
  ///   toJson: (u) => u.toJson(),
  ///   getId: (u) => u.id,
  /// );
  ///
  /// await backend.initialize();
  /// // ... use backend ...
  /// await backend.dispose();
  /// ```
  factory PowerSyncBackend.withSupabase({
    required SupabaseClient supabase,
    required String powerSyncUrl,
    required String tableName,
    required List<PSColumn> columns,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    required ID Function(T item) getId,
    String? dbPath,
    String primaryKeyColumn = 'id',
    Map<String, String>? fieldMapping,
    @visibleForTesting ps.PowerSyncOpenFactory? openFactory,
  }) =>
      PowerSyncBackend._withSupabaseInternal(
        supabase: supabase,
        config: PowerSyncBackendConfig<T, ID>(
          tableName: tableName,
          columns: columns,
          fromJson: fromJson,
          toJson: toJson,
          getId: getId,
          powerSyncUrl: powerSyncUrl,
          dbPath: dbPath,
          primaryKeyColumn: primaryKeyColumn,
        ),
        fromJson: fromJson,
        toJson: toJson,
        getId: getId,
        primaryKeyColumn: primaryKeyColumn,
        fieldMapping: fieldMapping,
        openFactory: openFactory,
      );

  /// Internal constructor for withSupabase factory.
  PowerSyncBackend._withSupabaseInternal({
    required SupabaseClient supabase,
    required PowerSyncBackendConfig<T, ID> config,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    required ID Function(T item) getId,
    String primaryKeyColumn = 'id',
    Map<String, String>? fieldMapping,
    ps.PowerSyncOpenFactory? openFactory,
  })  : _supabaseClient = supabase,
        _config = config,
        _ownsDatabase = true,
        _tableName = config.tableName,
        _getId = getId,
        _fromJson = fromJson,
        _toJson = toJson,
        _primaryKeyColumn = primaryKeyColumn,
        _openFactory = openFactory,
        _queryTranslator =
            PowerSyncQueryTranslator<T>(fieldMapping: fieldMapping) {
    _pendingChangesManager = nexus.PendingChangesManager<T, ID>(
      idExtractor: getId,
    );
  }

  // Database wrapper - set via constructor or during initialize
  late final PowerSyncDatabaseWrapper _db;
  final String _tableName;
  final ID Function(T item) _getId;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;

  // Fields for withSupabase factory lifecycle management
  final bool _ownsDatabase;
  final SupabaseClient? _supabaseClient;
  final PowerSyncBackendConfig<T, ID>? _config;
  final ps.PowerSyncOpenFactory? _openFactory;
  ps.PowerSyncDatabase? _ownedDatabase;
  SupabasePowerSyncConnector? _connector;
  // Reserved for future cleanup functionality.
  // ignore: unused_field, use_late_for_private_fields_and_variables
  String? _generatedDbPath;
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

  /// Exposes the pending changes manager for testing.
  @visibleForTesting
  nexus.PendingChangesManager<T, ID> get testPendingChangesManager =>
      _pendingChangesManager;

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

    // If this backend owns the database (withSupabase), create it now
    if (_ownsDatabase && _ownedDatabase == null) {
      await _createAndConnectDatabase();
    }

    _setupSyncStatusListener();
    _initialized = true;
  }

  /// Creates the PowerSync database and connects it to Supabase.
  ///
  /// This is called internally during initialize() for withSupabase backends.
  Future<void> _createAndConnectDatabase() async {
    final config = _config!;

    // Generate database path if not provided
    final dbPath = config.dbPath ?? _generateDbPath(config.tableName);
    _generatedDbPath = dbPath;

    // Create schema from column definitions
    final schema = config.toSchema();

    // Create the database (use custom factory if provided for testing)
    if (_openFactory != null) {
      _ownedDatabase = ps.PowerSyncDatabase.withFactory(
        _openFactory,
        schema: schema,
      );
    } else {
      _ownedDatabase = ps.PowerSyncDatabase(
        schema: schema,
        path: dbPath,
      );
    }

    await _ownedDatabase!.initialize();

    // Update the wrapper to use the real database
    // ignore: invalid_use_of_visible_for_testing_member
    _db = DefaultPowerSyncDatabaseWrapper(_ownedDatabase!);

    // Create and connect the connector
    _connector = SupabasePowerSyncConnector.withClient(
      supabase: _supabaseClient!,
      powerSyncUrl: config.powerSyncUrl,
    );

    await _ownedDatabase!.connect(connector: _connector!);
  }

  /// Generates a unique database path for auto-created databases.
  String _generateDbPath(String tableName) {
    final uuid = const Uuid().v4();
    final tempDir = Directory.systemTemp;
    return '${tempDir.path}/powersync_${tableName}_$uuid.db';
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

  /// Disposes resources including the database if owned by this backend.
  ///
  /// This method should be called when the backend is no longer needed.
  /// For backends created with [withSupabase], this will disconnect and
  /// close the PowerSync database.
  ///
  /// After dispose, the backend can be re-initialized if needed.
  Future<void> dispose() async {
    await close();

    if (_ownsDatabase && _ownedDatabase != null) {
      await _ownedDatabase!.disconnect();
      await _ownedDatabase!.close();
      _ownedDatabase = null;
      _connector = null;
    }
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

    // PowerSync handles sync automatically, but we can trigger status updates
    // manually if needed for UI feedback
    _syncStatusSubject
      ..add(nexus.SyncStatus.syncing)
      ..add(nexus.SyncStatus.synced);
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

    // Update retry count
    _pendingChangesManager.updateChange(
      changeId,
      retryCount: change.retryCount + 1,
      lastAttempt: DateTime.now(),
    );

    // Trigger sync
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
