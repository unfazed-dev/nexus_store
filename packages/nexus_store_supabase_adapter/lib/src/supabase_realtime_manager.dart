import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:supabase/supabase.dart';

/// Callback type for converting a JSON payload to an entity.
typedef FromJsonCallback<T> = T Function(Map<String, dynamic> json);

/// Callback type for extracting an ID from an entity.
typedef GetIdCallback<T, ID> = ID Function(T item);

/// Manages Supabase Realtime subscriptions for watch operations.
///
/// This class handles:
/// - Creating and managing Realtime channels
/// - Converting INSERT/UPDATE/DELETE events to entity changes
/// - Broadcasting changes to BehaviorSubject streams
/// - Proper cleanup on dispose
///
/// ## Example
///
/// ```dart
/// final manager = SupabaseRealtimeManager<User, String>(
///   client: supabaseClient,
///   tableName: 'users',
///   fromJson: User.fromJson,
///   getId: (user) => user.id,
/// );
///
/// await manager.initialize();
///
/// // Watch a single item
/// final stream = manager.watchItem('user-123');
///
/// // Watch all items
/// final allStream = manager.watchAll();
///
/// // Cleanup
/// await manager.dispose();
/// ```
class SupabaseRealtimeManager<T, ID> {
  /// Creates a [SupabaseRealtimeManager].
  ///
  /// - [client]: The Supabase client for accessing Realtime.
  /// - [tableName]: The database table name to watch.
  /// - [fromJson]: Function to convert JSON payload to entity type.
  /// - [getId]: Function to extract ID from an entity.
  /// - [primaryKeyColumn]: The primary key column name (default: 'id').
  /// - [schema]: The database schema (default: 'public').
  SupabaseRealtimeManager({
    required SupabaseClient client,
    required String tableName,
    required FromJsonCallback<T> fromJson,
    required GetIdCallback<T, ID> getId,
    String primaryKeyColumn = 'id',
    String schema = 'public',
  })  : _client = client,
        _tableName = tableName,
        _fromJson = fromJson,
        _getId = getId,
        _primaryKeyColumn = primaryKeyColumn,
        _schema = schema;

  final SupabaseClient _client;
  final String _tableName;
  final FromJsonCallback<T> _fromJson;
  final GetIdCallback<T, ID> _getId;
  final String _primaryKeyColumn;
  final String _schema;

  /// Active channel for table-level subscriptions.
  RealtimeChannel? _tableChannel;

  /// Subjects for individual item watches, keyed by ID.
  final _itemSubjects = <ID, BehaviorSubject<T?>>{};

  /// Subject for watching all items.
  BehaviorSubject<List<T>>? _allItemsSubject;

  /// Current list of all items for the watchAll stream.
  final _allItems = <ID, T>{};

  /// Whether the manager has been initialized.
  bool _initialized = false;

  /// Whether the manager has been disposed.
  bool _disposed = false;

  /// Whether the manager is initialized.
  bool get isInitialized => _initialized;

  /// Initializes the Realtime manager.
  ///
  /// Sets up the table-level channel for receiving database changes.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;

    _tableChannel = _client.channel('${_tableName}_changes');

    _tableChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: _schema,
          table: _tableName,
          callback: _handleRealtimeEvent,
        )
        .subscribe();

    _initialized = true;
  }

  /// Disposes of all resources.
  ///
  /// Unsubscribes from all channels and closes all subjects.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // Unsubscribe from table channel
    if (_tableChannel != null) {
      await _client.removeChannel(_tableChannel!);
      _tableChannel = null;
    }

    // Close all item subjects
    for (final subject in _itemSubjects.values) {
      await subject.close();
    }
    _itemSubjects.clear();

    // Close all items subject
    if (_allItemsSubject != null) {
      await _allItemsSubject!.close();
      _allItemsSubject = null;
    }

    _allItems.clear();
    _initialized = false;
  }

  /// Returns a stream for watching a single item by ID.
  ///
  /// The stream emits the current item value and updates when the item
  /// changes. Emits `null` if the item is deleted.
  ///
  /// [initialValue] can be provided to seed the stream with the current value.
  Stream<T?> watchItem(ID id, {T? initialValue}) {
    _ensureInitialized();

    if (_itemSubjects.containsKey(id)) {
      return _itemSubjects[id]!.stream;
    }

    // ignore: close_sinks - Subject is stored in _itemSubjects and closed in dispose()
    final subject = BehaviorSubject<T?>.seeded(initialValue);
    _itemSubjects[id] = subject;

    return subject.stream;
  }

  /// Returns a stream for watching all items.
  ///
  /// The stream emits the current list of items and updates when any item
  /// is added, modified, or deleted.
  ///
  /// [initialValue] can be provided to seed the stream with the current list.
  Stream<List<T>> watchAll({List<T>? initialValue}) {
    _ensureInitialized();

    if (_allItemsSubject != null) {
      return _allItemsSubject!.stream;
    }

    // Initialize all items map from initial value
    if (initialValue != null) {
      for (final item in initialValue) {
        final id = _getId(item);
        _allItems[id] = item;
      }
    }

    _allItemsSubject = BehaviorSubject<List<T>>.seeded(
      initialValue ?? _allItems.values.toList(),
    );

    return _allItemsSubject!.stream;
  }

  /// Manually updates the stream for a single item.
  ///
  /// Used to update the stream after a write operation.
  void notifyItemChanged(T item) {
    final id = _getId(item);

    // Update individual item subject
    if (_itemSubjects.containsKey(id)) {
      _itemSubjects[id]!.add(item);
    }

    // Update all items map and subject
    _allItems[id] = item;
    _notifyAllItemsChanged();
  }

  /// Manually notifies that an item was deleted.
  ///
  /// Used to update streams after a delete operation.
  void notifyItemDeleted(ID id) {
    // Update individual item subject with null
    if (_itemSubjects.containsKey(id)) {
      _itemSubjects[id]!.add(null);
    }

    // Remove from all items and notify
    _allItems.remove(id);
    _notifyAllItemsChanged();
  }

  /// Handles incoming Realtime events.
  void _handleRealtimeEvent(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload);
      case PostgresChangeEvent.update:
        _handleUpdate(payload);
      case PostgresChangeEvent.delete:
        _handleDelete(payload);
      case PostgresChangeEvent.all:
        // This shouldn't happen in a callback, but handle gracefully
        break;
    }
  }

  /// Handles INSERT events.
  void _handleInsert(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    try {
      final item = _fromJson(newRecord);
      notifyItemChanged(item);
    } on Object {
      // Log error but don't crash the stream
      // In production, this could be logged to a monitoring service
    }
  }

  /// Handles UPDATE events.
  void _handleUpdate(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    try {
      final item = _fromJson(newRecord);
      notifyItemChanged(item);
    } on Object {
      // Log error but don't crash the stream
    }
  }

  /// Handles DELETE events.
  void _handleDelete(PostgresChangePayload payload) {
    final oldRecord = payload.oldRecord;
    if (oldRecord.isEmpty) return;

    try {
      // Extract ID from the old record
      final idValue = oldRecord[_primaryKeyColumn];
      if (idValue == null) return;

      // Cast to ID type - this assumes ID is a simple type like String or int
      final id = idValue as ID;
      notifyItemDeleted(id);
    } on Object {
      // Log error but don't crash the stream
    }
  }

  /// Notifies the all items subject of changes.
  void _notifyAllItemsChanged() {
    if (_allItemsSubject != null && !_allItemsSubject!.isClosed) {
      _allItemsSubject!.add(_allItems.values.toList());
    }
  }

  /// Ensures the manager is initialized before use.
  void _ensureInitialized() {
    if (_disposed) {
      throw StateError('SupabaseRealtimeManager has been disposed');
    }
    if (!_initialized) {
      throw StateError(
        'SupabaseRealtimeManager not initialized. Call initialize() first.',
      );
    }
  }
}
