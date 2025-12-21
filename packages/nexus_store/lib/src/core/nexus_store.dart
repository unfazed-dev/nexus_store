import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nexus_store/src/cache/cache_stats.dart';
import 'package:nexus_store/src/cache/query_evaluator.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/gdpr_service.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/pagination/pagination_controller.dart';
import 'package:nexus_store/src/pagination/pagination_state.dart';
import 'package:nexus_store/src/pagination/streaming_config.dart';
import 'package:nexus_store/src/policy/fetch_policy_handler.dart';
import 'package:nexus_store/src/policy/write_policy_handler.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/sync/conflict_action.dart';
import 'package:nexus_store/src/sync/conflict_details.dart';
import 'package:nexus_store/src/sync/pending_change.dart';
import 'package:rxdart/rxdart.dart';

/// A unified reactive data store abstraction.
///
/// [NexusStore] provides a single consistent API across multiple storage
/// backends with policy-based fetching, RxDart streams, and optional
/// compliance features.
///
/// ## Features
///
/// - **Unified API**: Works with PowerSync, Drift, Supabase, Brick, and more
/// - **Policy-based**: Apollo GraphQL-style fetch and write policies
/// - **Reactive**: RxDart BehaviorSubject for immediate value on subscribe
/// - **Encrypted**: Optional SQLCipher and field-level encryption
/// - **Compliant**: GDPR and audit logging support
///
/// ## Example
///
/// ```dart
/// // Create store with PowerSync backend
/// final userStore = NexusStore<User, String>(
///   backend: PowerSyncBackend(powerSync, 'users'),
///   config: StoreConfig(
///     fetchPolicy: FetchPolicy.cacheFirst,
///     encryption: EncryptionConfig.fieldLevel(
///       encryptedFields: {'ssn', 'email'},
///       keyProvider: () => secureStorage.getKey(),
///     ),
///   ),
/// );
///
/// // Initialize before use
/// await userStore.initialize();
///
/// // Read
/// final user = await userStore.get('user-123');
///
/// // Watch (BehaviorSubject - immediate value)
/// userStore.watch('user-123').listen((user) => print(user));
///
/// // Write
/// await userStore.save(newUser);
///
/// // Query
/// final activeUsers = await userStore.getAll(
///   query: Query<User>()
///     .where('status', isEqualTo: 'active')
///     .orderByField('createdAt', descending: true)
///     .limitTo(10),
/// );
///
/// // Cleanup
/// await userStore.dispose();
/// ```
class NexusStore<T, ID> {
  /// Creates a NexusStore with the given backend and configuration.
  ///
  /// The [idExtractor] is required for tag-based cache invalidation features.
  /// If not provided, cache tagging features will not track item IDs.
  ///
  /// The [onConflict] callback is invoked when conflicts are detected during
  /// sync operations. If not provided, conflicts are resolved using the
  /// [StoreConfig.conflictResolution] strategy.
  NexusStore({
    required StoreBackend<T, ID> backend,
    StoreConfig? config,
    AuditService? auditService,
    String? subjectIdField,
    ID Function(T)? idExtractor,
    ConflictResolver<T>? onConflict,
  })  : _backend = backend,
        _config = config ?? StoreConfig.defaults,
        _auditService = auditService,
        _idExtractor = idExtractor,
        _onConflict = onConflict {
    _logger = Logger('NexusStore<$T, $ID>');

    _fetchHandler = FetchPolicyHandler(
      backend: _backend,
      defaultPolicy: _config.fetchPolicy,
      staleDuration: _config.staleDuration,
    );

    _writeHandler = WritePolicyHandler(
      backend: _backend,
      defaultPolicy: _config.writePolicy,
    );

    if (_config.enableGdpr && subjectIdField != null) {
      _gdprService = GdprService<T, ID>(
        backend: _backend,
        subjectIdField: subjectIdField,
        auditService: _auditService,
      );
    }
  }

  final StoreBackend<T, ID> _backend;
  final StoreConfig _config;
  final AuditService? _auditService;
  final ID Function(T)? _idExtractor;
  final ConflictResolver<T>? _onConflict;

  late final Logger _logger;
  late final FetchPolicyHandler<T, ID> _fetchHandler;
  late final WritePolicyHandler<T, ID> _writeHandler;
  GdprService<T, ID>? _gdprService;

  bool _initialized = false;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// The store configuration.
  StoreConfig get config => _config;

  /// The underlying backend.
  StoreBackend<T, ID> get backend => _backend;

  /// GDPR service, if enabled.
  GdprService<T, ID>? get gdpr => _gdprService;

  /// Audit service, if provided.
  AuditService? get audit => _auditService;

  /// Whether this store has been initialized.
  bool get isInitialized => _initialized;

  /// Whether this store has been disposed.
  bool get isDisposed => _disposed;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initializes the store.
  ///
  /// Must be called before any data operations.
  Future<void> initialize() async {
    if (_initialized) return;
    if (_disposed) {
      throw StateError('Cannot initialize a disposed store');
    }

    _logger.fine('Initializing store');
    await _backend.initialize();
    _initialized = true;
    _logger.fine('Store initialized');
  }

  /// Disposes the store and releases resources.
  Future<void> dispose() async {
    if (_disposed) return;

    _logger.fine('Disposing store');
    await _backend.close();
    _disposed = true;
    _logger.fine('Store disposed');
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Store not initialized. Call initialize() before using the store.',
      );
    }
    if (_disposed) {
      throw StateError('Store has been disposed');
    }
  }

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  /// Retrieves a single entity by its identifier.
  ///
  /// Uses the configured [FetchPolicy] or the provided [policy] override.
  Future<T?> get(ID id, {FetchPolicy? policy}) async {
    _ensureInitialized();

    final result = await _fetchHandler.get(id, policy: policy);

    if (_config.enableAuditLogging && result != null) {
      await _auditService?.log(
        action: AuditAction.read,
        entityType: T.toString(),
        entityId: id.toString(),
      );
    }

    return result;
  }

  /// Retrieves all entities matching the optional [query].
  ///
  /// Uses the configured [FetchPolicy] or the provided [policy] override.
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy}) async {
    _ensureInitialized();

    final results = await _fetchHandler.getAll(query: query, policy: policy);

    if (_config.enableAuditLogging && results.isNotEmpty) {
      await _auditService?.log(
        action: AuditAction.list,
        entityType: T.toString(),
        entityId: 'query:${query?.hashCode ?? 'all'}',
        metadata: {'count': results.length},
      );
    }

    return results;
  }

  /// Watches a single entity for changes.
  ///
  /// Returns a [BehaviorSubject] stream that emits the current value
  /// immediately and subsequent updates.
  Stream<T?> watch(ID id) {
    _ensureInitialized();
    return _fetchHandler.watch(id);
  }

  /// Watches all entities matching the optional [query].
  ///
  /// Returns a [BehaviorSubject] stream that emits the current list
  /// immediately and subsequent updates.
  Stream<List<T>> watchAll({Query<T>? query}) {
    _ensureInitialized();
    return _fetchHandler.watchAll(query: query);
  }

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
  ///
  /// Example:
  /// ```dart
  /// // First page
  /// final firstPage = await store.getAllPaged(
  ///   query: Query<User>().orderByField('name').first(20),
  /// );
  ///
  /// // Next page
  /// if (firstPage.hasMore) {
  ///   final secondPage = await store.getAllPaged(
  ///     query: Query<User>()
  ///         .orderByField('name')
  ///         .after(firstPage.nextCursor!)
  ///         .first(20),
  ///   );
  /// }
  /// ```
  Future<PagedResult<T>> getAllPaged({Query<T>? query, FetchPolicy? policy}) async {
    _ensureInitialized();

    final result = await _backend.getAllPaged(query: query);

    if (_config.enableAuditLogging && result.isNotEmpty) {
      await _auditService?.log(
        action: AuditAction.list,
        entityType: T.toString(),
        entityId: 'paged_query:${query?.hashCode ?? 'all'}',
        metadata: {
          'count': result.length,
          'hasMore': result.hasMore,
          'totalCount': result.totalCount,
        },
      );
    }

    return result;
  }

  /// Watches a page of entities matching the optional [query] for changes.
  ///
  /// Returns a stream that emits [PagedResult] updates when data changes.
  ///
  /// Example:
  /// ```dart
  /// store.watchAllPaged(
  ///   query: Query<User>().orderByField('name').first(20),
  /// ).listen((page) {
  ///   print('Got ${page.length} users, hasMore: ${page.hasMore}');
  /// });
  /// ```
  Stream<PagedResult<T>> watchAllPaged({Query<T>? query}) {
    _ensureInitialized();
    return _backend.watchAllPaged(query: query);
  }

  /// Watches all entities with automatic pagination and prefetching.
  ///
  /// Returns a stream of [PaginationState] that manages loading, error,
  /// and data states for paginated content. Use [onController] to access
  /// the underlying [PaginationController] for refresh, loadMore, etc.
  ///
  /// Example:
  /// ```dart
  /// store.watchAllPaginated(
  ///   query: Query<User>().where('status', isEqualTo: 'active'),
  ///   config: const StreamingConfig(pageSize: 20, prefetchDistance: 5),
  ///   onController: (controller) {
  ///     controller.refresh(); // Load initial data
  ///     // Store controller reference for later use
  ///     _controller = controller;
  ///   },
  /// ).listen((state) {
  ///   state.when(
  ///     initial: () => print('Initial'),
  ///     loading: (_) => print('Loading...'),
  ///     loadingMore: (items, _, __) => print('Loading more...'),
  ///     data: (items, _) => print('Got ${items.length} items'),
  ///     error: (error, _, __) => print('Error: $error'),
  ///   );
  /// });
  /// ```
  Stream<PaginationState<T>> watchAllPaginated({
    Query<T>? query,
    StreamingConfig config = const StreamingConfig(),
    void Function(PaginationController<T, ID> controller)? onController,
  }) {
    _ensureInitialized();

    final controller = PaginationController<T, ID>(
      store: this,
      query: query,
      config: config,
    );

    onController?.call(controller);

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Write Operations
  // ---------------------------------------------------------------------------

  /// Saves an entity (creates or updates).
  ///
  /// Uses the configured [WritePolicy] or the provided [policy] override.
  /// Optionally associates [tags] with the cached item for tag-based invalidation.
  /// Returns the saved entity, which may include server-generated fields.
  Future<T> save(T item, {WritePolicy? policy, Set<String>? tags}) async {
    _ensureInitialized();

    // Encrypt fields if configured
    // Note: For proper implementation, T should be serializable to Map
    // This is a simplified version - full implementation would use
    // a serializer interface

    final result = await _writeHandler.save(item, policy: policy);

    // Record in cache with tags if idExtractor is available
    if (_idExtractor != null) {
      final id = _idExtractor(result);
      _fetchHandler.recordCachedItem(id, tags: tags);
    }

    if (_config.enableAuditLogging) {
      await _auditService?.log(
        action: AuditAction.update,
        entityType: T.toString(),
        entityId: result.toString(),
      );
    }

    return result;
  }

  /// Saves multiple entities in a batch operation.
  ///
  /// Optionally associates [tags] with all cached items for tag-based invalidation.
  Future<List<T>> saveAll(
    List<T> items, {
    WritePolicy? policy,
    Set<String>? tags,
  }) async {
    _ensureInitialized();

    final results = await _writeHandler.saveAll(items, policy: policy);

    // Record each item in cache with tags if idExtractor is available
    if (_idExtractor != null) {
      for (final result in results) {
        final id = _idExtractor(result);
        _fetchHandler.recordCachedItem(id, tags: tags);
      }
    }

    if (_config.enableAuditLogging && results.isNotEmpty) {
      await _auditService?.log(
        action: AuditAction.update,
        entityType: T.toString(),
        entityId: 'batch',
        metadata: {'count': results.length},
      );
    }

    return results;
  }

  /// Deletes an entity by its identifier.
  ///
  /// Returns `true` if an entity was deleted, `false` if no entity existed.
  Future<bool> delete(ID id, {WritePolicy? policy}) async {
    _ensureInitialized();

    final result = await _writeHandler.delete(id, policy: policy);

    if (_config.enableAuditLogging && result) {
      await _auditService?.log(
        action: AuditAction.delete,
        entityType: T.toString(),
        entityId: id.toString(),
      );
    }

    return result;
  }

  /// Deletes multiple entities by their identifiers.
  ///
  /// Returns the count of entities actually deleted.
  Future<int> deleteAll(List<ID> ids, {WritePolicy? policy}) async {
    _ensureInitialized();

    var count = 0;
    for (final id in ids) {
      if (await _writeHandler.delete(id, policy: policy)) {
        count++;
      }
    }

    if (_config.enableAuditLogging && count > 0) {
      await _auditService?.log(
        action: AuditAction.delete,
        entityType: T.toString(),
        entityId: 'batch',
        metadata: {'count': count},
      );
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // Sync Operations
  // ---------------------------------------------------------------------------

  /// Triggers a manual sync operation.
  Future<void> sync() async {
    _ensureInitialized();
    await _backend.sync();
  }

  /// Returns the current synchronization status.
  SyncStatus get syncStatus => _backend.syncStatus;

  /// Returns a stream of sync status changes.
  Stream<SyncStatus> get syncStatusStream => _backend.syncStatusStream;

  /// Returns the count of pending changes awaiting sync.
  Future<int> get pendingChangesCount => _backend.pendingChangesCount;

  /// Returns a stream of pending changes with details.
  ///
  /// Use this to display pending changes in the UI or track sync progress.
  Stream<List<PendingChange<T>>> get pendingChanges =>
      _backend.pendingChangesStream;

  /// Returns a stream of detected conflicts.
  ///
  /// Emits when conflicts are detected during sync operations that require
  /// resolution.
  Stream<ConflictDetails<T>> get conflicts => _backend.conflictsStream;

  /// Returns `true` if a conflict resolver callback is configured.
  bool get hasConflictResolver => _onConflict != null;

  /// Retries a specific pending change.
  ///
  /// Throws if the change is not found or retry fails.
  Future<void> retryPendingChange(String changeId) async {
    _ensureInitialized();
    await _backend.retryChange(changeId);
  }

  /// Cancels a pending change and reverts local state.
  ///
  /// Returns the cancelled change, or `null` if not found.
  Future<PendingChange<T>?> cancelPendingChange(String changeId) async {
    _ensureInitialized();
    return _backend.cancelChange(changeId);
  }

  /// Retries all failed pending changes.
  Future<void> retryAllPending() async {
    _ensureInitialized();
    final changes = await pendingChanges.first;
    for (final change in changes.where((c) => c.hasFailed)) {
      await _backend.retryChange(change.id);
    }
  }

  /// Cancels all pending changes and reverts local state.
  ///
  /// Returns the number of changes cancelled.
  Future<int> cancelAllPending() async {
    _ensureInitialized();
    final changes = await pendingChanges.first;
    var count = 0;
    for (final change in changes) {
      final cancelled = await _backend.cancelChange(change.id);
      if (cancelled != null) count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Cache Management
  // ---------------------------------------------------------------------------

  /// Marks an entity as stale, forcing next fetch to hit network.
  void invalidate(ID id) {
    _fetchHandler.invalidate(id);
  }

  /// Marks all entities as stale.
  void invalidateAll() {
    _fetchHandler.invalidateAll();
  }

  /// Invalidates all cached items with any of the given [tags].
  ///
  /// Items with matching tags will be marked as stale, forcing the next
  /// fetch to hit the network.
  void invalidateByTags(Set<String> tags) {
    _fetchHandler.invalidateByTags(tags);
  }

  /// Invalidates multiple cached items by their [ids].
  void invalidateByIds(List<ID> ids) {
    _fetchHandler.invalidateByIds(ids);
  }

  /// Invalidates cached items matching the given [query].
  ///
  /// Requires a [fieldAccessor] to extract field values from items for
  /// query evaluation.
  Future<void> invalidateWhere(
    Query<T> query, {
    required FieldAccessor<T> fieldAccessor,
  }) async {
    await _fetchHandler.invalidateWhere(query, fieldAccessor: fieldAccessor);
  }

  // ---------------------------------------------------------------------------
  // Tag Management
  // ---------------------------------------------------------------------------

  /// Gets the tags associated with a cached item.
  ///
  /// Returns an empty set if the item has no tags or is not tracked.
  Set<String> getTags(ID id) {
    return _fetchHandler.getTags(id);
  }

  /// Adds [tags] to an existing cached item.
  void addTags(ID id, Set<String> tags) {
    _fetchHandler.addTags(id, tags);
  }

  /// Removes [tags] from a cached item.
  void removeTags(ID id, Set<String> tags) {
    _fetchHandler.removeTags(id, tags);
  }

  /// Returns whether a cached item is stale.
  ///
  /// An item is stale if it has no recorded fetch time or if the
  /// staleDuration has elapsed since the last fetch.
  bool isStale(ID id) {
    return _fetchHandler.isStale(id);
  }

  /// Returns cache statistics.
  CacheStats getCacheStats() {
    return _fetchHandler.getCacheStats();
  }
}
