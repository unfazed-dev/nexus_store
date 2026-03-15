/// Operations that can be intercepted in NexusStore.
///
/// Each operation represents a specific action that can be observed
/// and modified by interceptors in the interceptor chain.
///
/// ## Categories
///
/// **Read Operations:**
/// - [get] - Single item retrieval
/// - [getAll] - Multiple item retrieval
///
/// **Stream Operations:**
/// - [watch] - Single item stream subscription
/// - [watchAll] - Multiple item stream subscription
///
/// **Write Operations:**
/// - [save] - Single item save
/// - [saveAll] - Multiple item save
/// - [delete] - Single item deletion
/// - [deleteAll] - Multiple item deletion
///
/// **Sync Operations:**
/// - [sync] - Synchronization with remote
///
/// ## Example
///
/// ```dart
/// class AuthInterceptor extends StoreInterceptor {
///   @override
///   Set<StoreOperation> get operations => {
///     StoreOperation.save,
///     StoreOperation.delete,
///   };
/// }
/// ```
enum StoreOperation {
  /// Single item retrieval by ID.
  ///
  /// Triggered when calling `store.get(id)`.
  get,

  /// Multiple item retrieval with optional query.
  ///
  /// Triggered when calling `store.getAll()`.
  getAll,

  /// Single item save (create or update).
  ///
  /// Triggered when calling `store.save(item)`.
  save,

  /// Multiple item save (create or update).
  ///
  /// Triggered when calling `store.saveAll(items)`.
  saveAll,

  /// Single item deletion by ID.
  ///
  /// Triggered when calling `store.delete(id)`.
  delete,

  /// Multiple item deletion by IDs.
  ///
  /// Triggered when calling `store.deleteAll(ids)`.
  deleteAll,

  /// Single item stream subscription.
  ///
  /// Triggered when calling `store.watch(id)`.
  watch,

  /// Multiple item stream subscription with optional query.
  ///
  /// Triggered when calling `store.watchAll()`.
  watchAll,

  /// Synchronization with remote backend.
  ///
  /// Triggered when calling `store.sync()`.
  sync,

  /// Count of entities matching an optional query.
  ///
  /// Triggered when calling `store.count()`.
  count,

  /// Deletion of entities matching a query.
  ///
  /// Triggered when calling `store.deleteWhere(query)`.
  deleteWhere,

  /// Aggregate computation on a numeric field.
  ///
  /// Triggered when calling `store.aggregate()`, `store.sum()`,
  /// `store.avg()`, `store.min()`, or `store.max()`.
  aggregate,

  /// Existence check by ID.
  ///
  /// Triggered when calling `store.exists(id)`.
  exists,

  /// Existence check by query.
  ///
  /// Triggered when calling `store.existsWhere(query)`.
  existsWhere,

  /// Update entities matching a query.
  ///
  /// Triggered when calling `store.updateWhere(query, updates)`.
  updateWhere,
}

/// Extension methods for [StoreOperation].
extension StoreOperationExtension on StoreOperation {
  /// Whether this is a read operation (get, getAll, count, aggregate, exists, existsWhere).
  bool get isRead =>
      this == StoreOperation.get ||
      this == StoreOperation.getAll ||
      this == StoreOperation.count ||
      this == StoreOperation.aggregate ||
      this == StoreOperation.exists ||
      this == StoreOperation.existsWhere;

  /// Whether this is a stream operation (watch, watchAll).
  bool get isStream =>
      this == StoreOperation.watch || this == StoreOperation.watchAll;

  /// Whether this is a write operation (save, saveAll, updateWhere).
  bool get isWrite =>
      this == StoreOperation.save ||
      this == StoreOperation.saveAll ||
      this == StoreOperation.updateWhere;

  /// Whether this is a delete operation (delete, deleteAll, deleteWhere).
  bool get isDelete =>
      this == StoreOperation.delete ||
      this == StoreOperation.deleteAll ||
      this == StoreOperation.deleteWhere;

  /// Whether this is a sync operation.
  bool get isSync => this == StoreOperation.sync;

  /// Whether this operation modifies data (write, delete, or sync).
  bool get modifiesData => isWrite || isDelete || isSync;
}
