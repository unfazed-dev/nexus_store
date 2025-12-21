import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';

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
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  @override
  bool get supportsPagination => false;

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
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}
}
