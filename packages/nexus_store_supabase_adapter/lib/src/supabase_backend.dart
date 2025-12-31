import 'dart:async';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/src/supabase_query_translator.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_realtime_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase/supabase.dart';

/// A [nexus.StoreBackend] implementation using Supabase.
///
/// This adapter provides online-only access to Supabase with real-time
/// subscriptions via Supabase Realtime for watch operations.
///
/// ## Usage
///
/// ```dart
/// final backend = SupabaseBackend<User, String>(
///   client: supabaseClient,
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
/// );
///
/// await backend.initialize();
/// final users = await backend.getAll();
/// ```
///
/// ## Note
///
/// This backend is online-only - it does not support offline operations.
/// For offline-first capabilities, consider using the PowerSync or Brick
/// adapters instead.
class SupabaseBackend<T, ID>
    with nexus.StoreBackendDefaults<T, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates a [SupabaseBackend] with the specified client and converters.
  ///
  /// - [client]: The Supabase client to use for database operations.
  /// - [tableName]: The name of the database table.
  /// - [getId]: Function to extract the ID from an entity.
  /// - [fromJson]: Function to convert JSON to entity type.
  /// - [toJson]: Function to convert entity to JSON.
  /// - [primaryKeyColumn]: The name of the primary key column (default: 'id').
  /// - [queryTranslator]: Optional custom query translator.
  /// - [fieldMapping]: Optional field name mapping for queries.
  /// - [schema]: The database schema (default: 'public').
  SupabaseBackend({
    required SupabaseClient client,
    required String tableName,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    String primaryKeyColumn = 'id',
    SupabaseQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
    String schema = 'public',
  })  : _client = client,
        _tableName = tableName,
        _getId = getId,
        _fromJson = fromJson,
        _toJson = toJson,
        _primaryKeyColumn = primaryKeyColumn,
        _queryTranslator = queryTranslator ??
            SupabaseQueryTranslator<T>(fieldMapping: fieldMapping),
        _schema = schema;

  final SupabaseClient _client;
  final String _tableName;
  final ID Function(T item) _getId;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;
  final String _primaryKeyColumn;
  final SupabaseQueryTranslator<T> _queryTranslator;
  final String _schema;

  /// Realtime manager for watch operations.
  SupabaseRealtimeManager<T, ID>? _realtimeManager;

  /// Sync status subject - always synced for online-only backend.
  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);

  /// Subjects for individual item watches.
  final _watchSubjects = <ID, BehaviorSubject<T?>>{};

  /// Subjects for watchAll queries.
  final _watchAllSubjects = <String, BehaviorSubject<List<T>>>{};

  /// Whether the backend has been initialized.
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  @override
  String get name => 'supabase';

  @override
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => true;

  @override
  bool get supportsTransactions => false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize realtime manager
      _realtimeManager = SupabaseRealtimeManager<T, ID>(
        client: _client,
        tableName: _tableName,
        fromJson: _fromJson,
        getId: _getId,
        primaryKeyColumn: _primaryKeyColumn,
        schema: _schema,
      );
      await _realtimeManager!.initialize();

      _initialized = true;
      _syncStatusSubject.add(nexus.SyncStatus.synced);
    } on Object catch (e, stackTrace) {
      throw nexus.SyncError(
        message: 'Failed to initialize Supabase backend',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    // Dispose realtime manager
    if (_realtimeManager != null) {
      await _realtimeManager!.dispose();
      _realtimeManager = null;
    }

    // Close all watch subjects
    for (final subject in _watchSubjects.values) {
      await subject.close();
    }
    _watchSubjects.clear();

    // Close all watchAll subjects
    for (final subject in _watchAllSubjects.values) {
      await subject.close();
    }
    _watchAllSubjects.clear();

    // Close sync status subject
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
      final response = await _client
          .from(_tableName)
          .select()
          .eq(_primaryKeyColumn, id as Object)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _fromJson(response);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> getAll({nexus.Query<T>? query}) async {
    _ensureInitialized();

    try {
      final builder = _client.from(_tableName).select();

      final List<Map<String, dynamic>> response;
      if (query != null && query.isNotEmpty) {
        final transformedBuilder = _queryTranslator.apply(builder, query);
        response = await transformedBuilder;
      } else {
        response = await builder;
      }

      return response.map(_fromJson).toList();
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Stream<T?> watch(ID id) {
    _ensureInitialized();

    if (_watchSubjects.containsKey(id)) {
      return _watchSubjects[id]!.stream;
    }

    // ignore: close_sinks - Subject stored in _watchSubjects, closed in close()
    final subject = BehaviorSubject<T?>();
    _watchSubjects[id] = subject;

    // Initial load
    get(id).then(subject.add).catchError((Object e) {
      if (!subject.isClosed) {
        subject.addError(e);
      }
    });

    // Also register with realtime manager for updates
    if (_realtimeManager != null) {
      _realtimeManager!.watchItem(id).listen(
        (item) {
          if (!subject.isClosed) {
            subject.add(item);
          }
        },
        onError: (Object e) {
          if (!subject.isClosed) {
            subject.addError(e);
          }
        },
      );
    }

    return subject.stream;
  }

  @override
  Stream<List<T>> watchAll({nexus.Query<T>? query}) {
    _ensureInitialized();

    final queryKey = query?.toString() ?? '_all_';

    if (_watchAllSubjects.containsKey(queryKey)) {
      return _watchAllSubjects[queryKey]!.stream;
    }

    // ignore: close_sinks - Subject stored in _watchAllSubjects, closed in close()
    final subject = BehaviorSubject<List<T>>();
    _watchAllSubjects[queryKey] = subject;

    // Initial load
    getAll(query: query).then(subject.add).catchError((Object e) {
      if (!subject.isClosed) {
        subject.addError(e);
      }
    });

    // For watchAll without query, use realtime manager
    if (query == null && _realtimeManager != null) {
      _realtimeManager!.watchAll().listen(
        (items) {
          if (!subject.isClosed) {
            subject.add(items);
          }
        },
        onError: (Object e) {
          if (!subject.isClosed) {
            subject.addError(e);
          }
        },
      );
    }

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

      final json = _toJson(item);
      final response = await _client
          .from(_tableName)
          .upsert(json)
          .select()
          .single();

      final result = _fromJson(response);

      _notifyWatchers(result);
      _syncStatusSubject.add(nexus.SyncStatus.synced);

      return result;
    } on Object catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      final jsonList = items.map(_toJson).toList();
      final response = await _client
          .from(_tableName)
          .upsert(jsonList)
          .select();

      final results = response.map(_fromJson).toList();

      for (final item in results) {
        _notifyWatchers(item);
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return results;
    } on Object catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<bool> delete(ID id) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      // Check if item exists first
      final existing = await get(id);
      if (existing == null) {
        _syncStatusSubject.add(nexus.SyncStatus.synced);
        return false;
      }

      await _client
          .from(_tableName)
          .delete()
          .eq(_primaryKeyColumn, id as Object);

      _notifyDeletion(id);
      _syncStatusSubject.add(nexus.SyncStatus.synced);

      return true;
    } on Object catch (e, stackTrace) {
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

      await _client
          .from(_tableName)
          .delete()
          .inFilter(_primaryKeyColumn, ids.cast<Object>());

      for (final id in ids) {
        _notifyDeletion(id);
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return ids.length;
    } on Object catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<int> deleteWhere(nexus.Query<T> query) async {
    _ensureInitialized();

    try {
      _syncStatusSubject.add(nexus.SyncStatus.pending);

      // First get items to delete for notification
      final items = await getAll(query: query);
      if (items.isEmpty) {
        _syncStatusSubject.add(nexus.SyncStatus.synced);
        return 0;
      }

      // Delete each item by ID - more reliable than complex delete queries
      for (final item in items) {
        final id = _getId(item);
        await _client
            .from(_tableName)
            .delete()
            .eq(_primaryKeyColumn, id as Object);
      }

      // Notify watchers
      for (final item in items) {
        final id = _getId(item);
        _notifyDeletion(id);
      }

      _syncStatusSubject.add(nexus.SyncStatus.synced);
      return items.length;
    } on Object catch (e, stackTrace) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      throw _mapException(e, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync Operations (Online-Only)
  // ---------------------------------------------------------------------------

  @override
  nexus.SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<nexus.SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<void> sync() async {
    // No-op for online-only backend
    // Data is always synced with the server
    _ensureInitialized();
  }

  @override
  Future<int> get pendingChangesCount async => 0;

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Ensures the backend is initialized before operations.
  void _ensureInitialized() {
    if (!_initialized) {
      throw const nexus.StateError(
        message: 'Backend not initialized. Call initialize() first.',
        currentState: 'uninitialized',
        expectedState: 'initialized',
      );
    }
  }

  /// Notifies watch streams of item changes.
  void _notifyWatchers(T item) {
    final id = _getId(item);

    // Update individual watch
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(item);
    }

    // Update realtime manager
    _realtimeManager?.notifyItemChanged(item);

    // Refresh all watchAll subjects
    _refreshAllWatchers();
  }

  /// Notifies watch streams of item deletion.
  void _notifyDeletion(ID id) {
    // Update individual watch with null
    if (_watchSubjects.containsKey(id)) {
      _watchSubjects[id]!.add(null);
    }

    // Update realtime manager
    _realtimeManager?.notifyItemDeleted(id);

    // Refresh all watchAll subjects
    _refreshAllWatchers();
  }

  /// Refreshes all watchAll subjects with fresh data.
  void _refreshAllWatchers() {
    for (final entry in _watchAllSubjects.entries) {
      final queryKey = entry.key;
      // ignore: close_sinks - Subject is from map, managed elsewhere
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

  /// Maps Supabase exceptions to nexus_store error types.
  nexus.StoreError _mapException(Object error, StackTrace stackTrace) {
    if (error is nexus.StoreError) {
      return error;
    }

    // Handle PostgrestException
    if (error is PostgrestException) {
      return _mapPostgrestException(error, stackTrace);
    }

    // Handle AuthException
    if (error is AuthException) {
      return nexus.AuthenticationError(
        message: 'Authentication failed: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Map common network/timeout errors
    final message = error.toString().toLowerCase();

    if (message.contains('network') ||
        message.contains('socketexception') ||
        message.contains('connection')) {
      return nexus.NetworkError(
        message: 'Network error during Supabase operation',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('timeout') || message.contains('timeoutexception')) {
      return nexus.TimeoutError(
        duration: const Duration(seconds: 30),
        operation: 'Supabase operation',
      );
    }

    // Default to SyncError
    return nexus.SyncError(
      message: 'Supabase operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps PostgrestException to appropriate error type.
  nexus.StoreError _mapPostgrestException(
    PostgrestException error,
    StackTrace stackTrace,
  ) {
    final code = error.code;
    final message = error.message;

    // Not found
    if (code == 'PGRST116' || message.contains('not found')) {
      return nexus.NotFoundError(
        id: 'unknown',
        entityType: _tableName,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Unique constraint violation
    if (code == '23505' || message.contains('unique constraint')) {
      return nexus.ValidationError(
        message: 'Unique constraint violation: $message',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Foreign key violation
    if (code == '23503' || message.contains('foreign key')) {
      return nexus.ValidationError(
        message: 'Foreign key constraint violation: $message',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // RLS (Row Level Security) violation - authorization
    if (code == '42501' ||
        code == 'PGRST301' ||
        message.contains('row-level security') ||
        message.contains('permission denied')) {
      return nexus.AuthorizationError(
        message: 'Authorization denied: $message',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // JWT errors - authentication
    if (code == 'PGRST301' || message.contains('jwt')) {
      return nexus.AuthenticationError(
        message: 'Authentication failed: $message',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Default to SyncError for other Postgrest errors
    return nexus.SyncError(
      message: 'Supabase query error: $message (code: $code)',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
