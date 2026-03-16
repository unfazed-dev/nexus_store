import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/core/aggregate_result.dart';
import 'package:nexus_store/src/core/conflict_strategy.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/sync/conflict_details.dart';
import 'package:nexus_store/src/sync/pending_change.dart';

/// Abstract interface for storage backends.
///
/// Each backend adapter (PowerSync, Drift, Supabase, etc.) implements this
/// interface to provide a consistent API for data operations.
///
/// ## Type Parameters
///
/// - `T`: The entity type being stored
/// - `ID`: The identifier type (typically `String` or `int`)
///
/// ## Example Implementation
///
/// ```dart
/// class DriftBackend<T, ID> implements StoreBackend<T, ID> {
///   DriftBackend(this._database, this._table);
///
///   final GeneratedDatabase _database;
///   final String _table;
///
///   @override
///   Future<T?> get(ID id) async {
///     // Implementation using Drift
///   }
/// }
/// ```
abstract interface class StoreBackend<T, ID> {
  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  /// Retrieves a single entity by its identifier.
  ///
  /// Returns `null` if no entity exists with the given [id].
  Future<T?> get(ID id);

  /// Retrieves all entities matching the optional [query].
  ///
  /// If [query] is `null`, returns all entities in the collection.
  Future<List<T>> getAll({Query<T>? query});

  /// Watches a single entity for changes.
  ///
  /// Returns a stream that emits the current value immediately (if available)
  /// and subsequent updates.
  Stream<T?> watch(ID id);

  /// Watches all entities matching the optional [query] for changes.
  ///
  /// Returns a stream that emits the current list immediately and subsequent
  /// updates when entities are added, modified, or removed.
  Stream<List<T>> watchAll({Query<T>? query});

  /// Returns the count of entities matching the optional [query].
  ///
  /// If [query] is `null`, returns the total count of all entities.
  /// Backends should implement this using efficient SQL (e.g., `SELECT COUNT(*)`)
  /// rather than loading all entities into memory.
  Future<int> count({Query<T>? query});

  /// Computes an aggregate value for a numeric [field].
  ///
  /// Returns the result of applying [type] (sum, avg, min, max) to [field]
  /// across all entities matching the optional [query].
  ///
  /// Returns `null` if no entities match or if the field contains only nulls.
  /// Backends should implement this using efficient SQL (e.g., `SELECT SUM(field)`)
  /// rather than loading all entities into memory.
  Future<num?> aggregate(
    String field,
    AggregateType type, {
    Query<T>? query,
  });

  /// Retrieves multiple entities by their identifiers.
  ///
  /// Returns a list of found entities. Missing IDs are silently skipped.
  /// More efficient than calling [get] multiple times for batch operations.
  Future<List<T>> getByIds(List<ID> ids);

  /// Returns `true` if an entity with the given [id] exists.
  ///
  /// More efficient than `get(id) != null` as backends can use
  /// `SELECT EXISTS(SELECT 1 FROM table WHERE id = ?)`.
  Future<bool> exists(ID id);

  /// Returns `true` if any entity matches the given [query].
  ///
  /// More efficient than `getAll(query: query).isNotEmpty` as backends can
  /// use `SELECT EXISTS(SELECT 1 FROM table WHERE ...)`.
  Future<bool> existsWhere(Query<T> query);

  // ---------------------------------------------------------------------------
  // Write Operations
  // ---------------------------------------------------------------------------

  /// Saves an entity (creates or updates).
  ///
  /// Returns the saved entity, which may include server-generated fields
  /// (e.g., timestamps, computed values).
  Future<T> save(T item);

  /// Saves multiple entities in a batch operation.
  ///
  /// More efficient than calling [save] multiple times for bulk operations.
  Future<List<T>> saveAll(List<T> items);

  /// Deletes an entity by its identifier.
  ///
  /// Returns `true` if an entity was deleted, `false` if no entity existed.
  Future<bool> delete(ID id);

  /// Deletes multiple entities by their identifiers.
  ///
  /// Returns the count of entities actually deleted.
  Future<int> deleteAll(List<ID> ids);

  /// Deletes all entities matching the [query].
  ///
  /// Returns the count of entities deleted.
  Future<int> deleteWhere(Query<T> query);

  /// Updates all entities matching the [query] with the given [updates].
  ///
  /// The [updates] map contains field names and their new values.
  /// Returns the count of entities updated.
  ///
  /// Backends should implement this using efficient SQL
  /// (e.g., `UPDATE table SET field=value WHERE ...`) rather than
  /// loading all entities into memory.
  Future<int> updateWhere(Query<T> query, Map<String, dynamic> updates);

  /// Partially updates a single entity by its [id] with the given [updates].
  ///
  /// The [updates] map contains field names and their new values. Only the
  /// specified fields are modified; all other fields are preserved.
  ///
  /// Returns the updated entity, or `null` if no entity exists with [id].
  ///
  /// Backends should implement this using efficient SQL
  /// (e.g., `UPDATE table SET field=value WHERE id = ?`) rather than
  /// loading the full entity into memory.
  Future<T?> patch(ID id, Map<String, dynamic> updates);

  /// Inserts or updates an entity atomically based on the [onConflict] strategy.
  ///
  /// If no entity with the same ID exists, inserts it. If an entity already
  /// exists, applies the [onConflict] strategy:
  /// - [ConflictStrategy.update]: Updates the existing entity (default)
  /// - [ConflictStrategy.ignore]: Keeps the existing entity unchanged
  /// - [ConflictStrategy.replace]: Replaces the existing entity entirely
  /// - [ConflictStrategy.error]: Throws a [StateError]
  ///
  /// The [idExtractor] is used to extract the ID from the entity for
  /// existence checking in the default implementation.
  ///
  /// Backends should implement this using efficient SQL
  /// (e.g., `INSERT OR REPLACE INTO ...`) rather than loading the entity
  /// into memory first.
  Future<T> upsert(
    T item, {
    ConflictStrategy onConflict = ConflictStrategy.update,
  });

  /// Inserts or updates multiple entities atomically.
  ///
  /// Applies the [onConflict] strategy to each entity individually.
  /// Returns the list of resulting entities (inserted or existing).
  ///
  /// Backends should implement this using efficient batch SQL
  /// operations where possible.
  Future<List<T>> upsertAll(
    List<T> items, {
    ConflictStrategy onConflict = ConflictStrategy.update,
  });

  // ---------------------------------------------------------------------------
  // Sync Operations
  // ---------------------------------------------------------------------------

  /// Returns the current synchronization status.
  SyncStatus get syncStatus;

  /// Returns a stream of sync status changes.
  Stream<SyncStatus> get syncStatusStream;

  /// Triggers a manual sync operation.
  ///
  /// Returns when sync completes or throws on failure.
  Future<void> sync();

  /// Returns the count of pending changes awaiting sync.
  Future<int> get pendingChangesCount;

  /// Returns a stream of pending changes with details.
  ///
  /// Emits whenever changes are added, removed, or updated.
  Stream<List<PendingChange<T>>> get pendingChangesStream;

  /// Returns a stream of detected conflicts.
  ///
  /// Emits when conflicts are detected during sync operations.
  Stream<ConflictDetails<T>> get conflictsStream;

  /// Retries a specific pending change.
  ///
  /// Throws if the change is not found or retry fails.
  Future<void> retryChange(String changeId);

  /// Cancels a pending change and reverts local state.
  ///
  /// Returns the cancelled change, or `null` if not found.
  Future<PendingChange<T>?> cancelChange(String changeId);

  // ---------------------------------------------------------------------------
  // Pagination Operations
  // ---------------------------------------------------------------------------

  /// Retrieves a page of entities matching the optional [query].
  ///
  /// Uses cursor-based pagination. The [query] can specify:
  /// - `first(n)` to get the first n items
  /// - `after(cursor)` to start after a specific cursor
  /// - `last(n)` to get the last n items
  /// - `before(cursor)` to end before a specific cursor
  ///
  /// Returns a [PagedResult] containing the items and pagination metadata.
  Future<PagedResult<T>> getAllPaged({Query<T>? query});

  /// Watches a page of entities matching the optional [query] for changes.
  ///
  /// Returns a stream that emits [PagedResult] updates when data changes.
  Stream<PagedResult<T>> watchAllPaged({Query<T>? query});

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  /// Returns the name of this backend for logging/debugging.
  String get name;

  /// Returns `true` if this backend supports offline operations.
  bool get supportsOffline;

  /// Returns `true` if this backend supports real-time subscriptions.
  bool get supportsRealtime;

  /// Returns `true` if this backend supports transactions.
  bool get supportsTransactions;

  /// Returns `true` if this backend supports cursor-based pagination.
  bool get supportsPagination;

  /// Returns `true` if this backend supports field-level operations.
  ///
  /// When `true`, [getField] and [getFieldBatch] can be used for lazy loading.
  bool get supportsFieldOperations;

  // ---------------------------------------------------------------------------
  // Field Operations (Lazy Loading)
  // ---------------------------------------------------------------------------

  /// Retrieves a specific field value for an entity.
  ///
  /// Returns the field value if the entity exists, or `null` if the entity
  /// or field doesn't exist.
  ///
  /// Backends that don't support field-level access can throw
  /// [UnsupportedError] or load the full entity and extract the field.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Load just the thumbnail field
  /// final thumbnail = await backend.getField('user-123', 'thumbnail');
  /// ```
  Future<dynamic> getField(ID id, String fieldName);

  /// Retrieves a specific field value for multiple entities.
  ///
  /// Returns a map of ID to field value. Entities that don't exist or don't
  /// have the field are omitted from the result.
  ///
  /// More efficient than calling [getField] multiple times for batch operations.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Load thumbnails for multiple users
  /// final thumbnails = await backend.getFieldBatch(
  ///   ['user-1', 'user-2', 'user-3'],
  ///   'thumbnail',
  /// );
  /// ```
  Future<Map<ID, dynamic>> getFieldBatch(List<ID> ids, String fieldName);

  // ---------------------------------------------------------------------------
  // Transaction Operations
  // ---------------------------------------------------------------------------

  /// Begins a new transaction.
  ///
  /// Returns a transaction identifier that can be used for commit/rollback.
  /// Throws [TransactionError] if transactions are not supported.
  Future<String> beginTransaction();

  /// Commits a transaction by its identifier.
  ///
  /// Applies all pending operations atomically.
  /// Throws [TransactionError] if the transaction is invalid or commit fails.
  Future<void> commitTransaction(String transactionId);

  /// Rolls back a transaction by its identifier.
  ///
  /// Reverts all operations performed within the transaction.
  /// Throws [TransactionError] if the transaction is invalid.
  Future<void> rollbackTransaction(String transactionId);

  /// Executes operations within a transaction context.
  ///
  /// This is a higher-level API that handles begin/commit/rollback automatically.
  /// If the callback throws, the transaction is rolled back.
  Future<R> runInTransaction<R>(Future<R> Function() callback);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initializes the backend (e.g., opens database connections).
  ///
  /// Must be called before any other operations.
  Future<void> initialize();

  /// Closes the backend and releases resources.
  ///
  /// After calling [close], the backend should not be used.
  Future<void> close();
}

/// Mixin providing default implementations for optional [StoreBackend] methods.
///
/// Backend implementations can mix this in to get sensible defaults for
/// methods they don't need to customize.
mixin StoreBackendDefaults<T, ID> implements StoreBackend<T, ID> {
  @override
  SyncStatus get syncStatus => SyncStatus.synced;

  @override
  Stream<SyncStatus> get syncStatusStream => Stream.value(SyncStatus.synced);

  @override
  Future<void> sync() async {}

  @override
  Future<int> get pendingChangesCount async => 0;

  @override
  Stream<List<PendingChange<T>>> get pendingChangesStream =>
      Stream.value(const []);

  @override
  Stream<ConflictDetails<T>> get conflictsStream => const Stream.empty();

  @override
  Future<void> retryChange(String changeId) async {
    // No-op by default
  }

  @override
  Future<PendingChange<T>?> cancelChange(String changeId) async {
    return null;
  }

  @override
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  @override
  bool get supportsPagination => false;

  @override
  bool get supportsFieldOperations => false;

  @override
  Future<dynamic> getField(ID id, String fieldName) async {
    throw UnsupportedError(
      'Field-level operations not supported by this backend. '
      'Use get() and extract the field manually, or use a backend that '
      'supports field operations.',
    );
  }

  @override
  Future<Map<ID, dynamic>> getFieldBatch(
    List<ID> ids,
    String fieldName,
  ) async {
    // Default implementation: call getField for each ID
    final results = <ID, dynamic>{};
    for (final id in ids) {
      try {
        final value = await getField(id, fieldName);
        if (value != null) {
          results[id] = value;
        }
      } catch (_) {
        // Skip entities that fail to load
      }
    }
    return results;
  }

  @override
  Future<String> beginTransaction() async {
    // Generate unique transaction ID
    return 'tx_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> commitTransaction(String transactionId) async {
    // No-op for optimistic fallback - operations already applied
  }

  @override
  Future<void> rollbackTransaction(String transactionId) async {
    // Optimistic fallback cannot truly rollback
    // The NexusStore handles rollback by reverting individual operations
  }

  @override
  Future<R> runInTransaction<R>(Future<R> Function() callback) async {
    // Simple implementation without true atomicity
    return callback();
  }

  @override
  Future<PagedResult<T>> getAllPaged({Query<T>? query}) async {
    // Default implementation: wrap getAll result in PagedResult
    final items = await getAll(query: query);
    return PagedResult<T>(
      items: items,
      pageInfo: const PageInfo.empty(),
    );
  }

  @override
  Stream<PagedResult<T>> watchAllPaged({Query<T>? query}) {
    // Default implementation: wrap watchAll stream in PagedResult
    return watchAll(query: query).map(
      (items) => PagedResult<T>(
        items: items,
        pageInfo: const PageInfo.empty(),
      ),
    );
  }

  @override
  Future<List<T>> getByIds(List<ID> ids) async {
    if (ids.isEmpty) return [];
    final uniqueIds = ids.toSet();
    final results = <T>[];
    for (final id in uniqueIds) {
      final item = await get(id);
      if (item != null) {
        results.add(item);
      }
    }
    return results;
  }

  @override
  Future<int> count({Query<T>? query}) async {
    final items = await getAll(query: query);
    return items.length;
  }

  @override
  Future<bool> exists(ID id) async {
    final item = await get(id);
    return item != null;
  }

  @override
  Future<bool> existsWhere(Query<T> query) async {
    final items = await getAll(query: query);
    return items.isNotEmpty;
  }

  @override
  Future<num?> aggregate(
    String field,
    AggregateType type, {
    Query<T>? query,
  }) async {
    // Default in-memory implementation: load all matching entities
    // and compute the aggregate from their JSON representations.
    final items = await getAll(query: query);
    if (items.isEmpty) return null;

    // Subclasses with toJson should override this for proper field access.
    // This default throws UnsupportedError since we can't extract fields
    // from generic T without serialization knowledge.
    throw UnsupportedError(
      'In-memory aggregate requires a backend with field extraction support. '
      'Override aggregate() in your backend or use an SQL-based backend.',
    );
  }

  @override
  Future<int> updateWhere(
    Query<T> query,
    Map<String, dynamic> updates,
  ) async {
    if (updates.isEmpty) return 0;

    // Default in-memory implementation: load matching entities,
    // apply updates, and save them back.
    final items = await getAll(query: query);
    if (items.isEmpty) return 0;

    // Subclasses with toJson/fromJson should override this for proper
    // field-level updates. This default throws UnsupportedError since
    // we can't update fields on generic T without serialization knowledge.
    throw UnsupportedError(
      'In-memory updateWhere requires a backend with field update support. '
      'Override updateWhere() in your backend or use an SQL-based backend.',
    );
  }

  @override
  Future<T?> patch(ID id, Map<String, dynamic> updates) async {
    // Default implementation: get entity, but can't apply field-level
    // updates to generic T without serialization knowledge.
    // Subclasses with toJson/fromJson should override this.
    throw UnsupportedError(
      'In-memory patch requires a backend with field update support. '
      'Override patch() in your backend or use an SQL-based backend.',
    );
  }

  @override
  Future<T> upsert(
    T item, {
    ConflictStrategy onConflict = ConflictStrategy.update,
  }) async {
    // Default implementation: delegates to save() which already handles
    // create-or-update semantics in most backends.
    return save(item);
  }

  @override
  Future<List<T>> upsertAll(
    List<T> items, {
    ConflictStrategy onConflict = ConflictStrategy.update,
  }) async {
    // Default implementation: upsert each item individually.
    final results = <T>[];
    for (final item in items) {
      results.add(await upsert(item, onConflict: onConflict));
    }
    return results;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}
}
