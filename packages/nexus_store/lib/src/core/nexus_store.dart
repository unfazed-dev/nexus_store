import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:nexus_store/src/cache/cache_stats.dart';
import 'package:nexus_store/src/cache/memory_manager.dart';
import 'package:nexus_store/src/cache/memory_metrics.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/cache/query_evaluator.dart';
import 'package:nexus_store/src/cache/size_estimator.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/gdpr_service.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/interceptors/interceptor_chain.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:nexus_store/src/lazy/field_loader.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/pagination/pagination_controller.dart';
import 'package:nexus_store/src/pagination/pagination_state.dart';
import 'package:nexus_store/src/pagination/streaming_config.dart';
import 'package:nexus_store/src/policy/fetch_policy_handler.dart';
import 'package:nexus_store/src/policy/write_policy_handler.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/errors/store_errors.dart' hide StateError;
import 'package:nexus_store/src/sync/conflict_action.dart';
import 'package:nexus_store/src/sync/conflict_details.dart';
import 'package:nexus_store/src/sync/pending_change.dart';
import 'package:nexus_store/src/telemetry/cache_metric.dart';
import 'package:nexus_store/src/transaction/transaction.dart';
import 'package:nexus_store/src/transaction/transaction_context.dart';
import 'package:nexus_store/src/transaction/transaction_operation.dart';
import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:nexus_store/src/telemetry/store_stats.dart';
import 'package:nexus_store/src/telemetry/sync_metric.dart';
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
    SizeEstimator<T>? sizeEstimator,
  })  : _backend = backend,
        _config = config ?? StoreConfig.defaults,
        _auditService = auditService,
        _idExtractor = idExtractor,
        _onConflict = onConflict,
        _sizeEstimator = sizeEstimator {
    _logger = Logger('NexusStore<$T, $ID>');
    _interceptorChain = InterceptorChain(_config.interceptors);

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

    // Initialize field loader if lazy loading is configured
    if (_config.lazyLoad != null) {
      _fieldLoader = FieldLoader<T, ID>(
        backend: _backend,
        config: _config.lazyLoad!,
      );
    }

    // Initialize memory manager if memory management is configured
    if (_config.memory != null) {
      _memoryManager = MemoryManager<T, ID>(
        config: _config.memory!,
        sizeEstimator: _sizeEstimator ?? FixedSizeEstimator<T>(1024),
        onEviction: (ids) {
          for (final id in ids) {
            _fetchHandler.removeEntry(id);
          }
        },
      );
    }

    _metricsReporter = _config.metricsReporter;
  }

  final StoreBackend<T, ID> _backend;
  final StoreConfig _config;
  final AuditService? _auditService;
  final ID Function(T)? _idExtractor;
  final ConflictResolver<T>? _onConflict;
  final SizeEstimator<T>? _sizeEstimator;

  late final Logger _logger;
  late final FetchPolicyHandler<T, ID> _fetchHandler;
  late final WritePolicyHandler<T, ID> _writeHandler;
  late final InterceptorChain _interceptorChain;
  GdprService<T, ID>? _gdprService;
  FieldLoader<T, ID>? _fieldLoader;
  MemoryManager<T, ID>? _memoryManager;

  bool _initialized = false;
  bool _disposed = false;

  // Telemetry
  late final MetricsReporter _metricsReporter;
  final math.Random _random = math.Random();

  // Stats tracking
  final Map<OperationType, int> _operationCounts = {};
  final Map<OperationType, Duration> _totalDurations = {};
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _syncSuccessCount = 0;
  int _syncFailureCount = 0;
  int _errorCount = 0;
  DateTime? _lastUpdated;

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
    _memoryManager?.dispose();
    await _fieldLoader?.dispose();
    await _metricsReporter.flush();
    await _metricsReporter.dispose();
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

    return _trackOperation(OperationType.get, () async {
      return _interceptorChain.execute<ID, T?>(
        operation: StoreOperation.get,
        request: id,
        execute: () async {
          final result = await _fetchHandler.get(id, policy: policy);

          // Track cache hit/miss and access
          if (result != null) {
            _recordCacheHit(itemId: id.toString());
            // Record access in memory manager for LRU tracking
            _memoryManager?.recordAccess(id);
          } else {
            _recordCacheMiss(itemId: id.toString());
          }

          if (_config.enableAuditLogging && result != null) {
            await _auditService?.log(
              action: AuditAction.read,
              entityType: T.toString(),
              entityId: id.toString(),
            );
          }

          return result;
        },
      );
    });
  }

  /// Retrieves all entities matching the optional [query].
  ///
  /// Uses the configured [FetchPolicy] or the provided [policy] override.
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy}) async {
    _ensureInitialized();

    return _trackOperation(OperationType.getAll, () async {
      return _interceptorChain.execute<Query<T>?, List<T>>(
        operation: StoreOperation.getAll,
        request: query,
        execute: () async {
          final results =
              await _fetchHandler.getAll(query: query, policy: policy);

          if (_config.enableAuditLogging && results.isNotEmpty) {
            await _auditService?.log(
              action: AuditAction.list,
              entityType: T.toString(),
              entityId: 'query:${query?.hashCode ?? 'all'}',
              metadata: {'count': results.length},
            );
          }

          return results;
        },
      );
    }, itemCount: 0); // itemCount updated after fetch
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

    return _trackOperation(OperationType.save, () async {
      return _interceptorChain.execute<T, T>(
        operation: StoreOperation.save,
        request: item,
        execute: () async {
          // Encrypt fields if configured
          // Note: For proper implementation, T should be serializable to Map
          // This is a simplified version - full implementation would use
          // a serializer interface

          final result = await _writeHandler.save(item, policy: policy);

          // Record in cache with tags if idExtractor is available
          if (_idExtractor != null) {
            final id = _idExtractor(result);
            _fetchHandler.recordCachedItem(id, tags: tags);
            // Record in memory manager for eviction tracking
            _memoryManager?.recordItem(id, result);
          }

          if (_config.enableAuditLogging) {
            await _auditService?.log(
              action: AuditAction.update,
              entityType: T.toString(),
              entityId: result.toString(),
            );
          }

          return result;
        },
      );
    });
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

    return _trackOperation(OperationType.saveAll, () async {
      return _interceptorChain.execute<List<T>, List<T>>(
        operation: StoreOperation.saveAll,
        request: items,
        execute: () async {
          final results = await _writeHandler.saveAll(items, policy: policy);

          // Record each item in cache with tags if idExtractor is available
          if (_idExtractor != null) {
            for (final result in results) {
              final id = _idExtractor(result);
              _fetchHandler.recordCachedItem(id, tags: tags);
              // Record in memory manager for eviction tracking
              _memoryManager?.recordItem(id, result);
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
        },
      );
    }, itemCount: items.length);
  }

  /// Deletes an entity by its identifier.
  ///
  /// Returns `true` if an entity was deleted, `false` if no entity existed.
  Future<bool> delete(ID id, {WritePolicy? policy}) async {
    _ensureInitialized();

    return _trackOperation(OperationType.delete, () async {
      return _interceptorChain.execute<ID, bool>(
        operation: StoreOperation.delete,
        request: id,
        execute: () async {
          final result = await _writeHandler.delete(id, policy: policy);

          if (result) {
            // Remove from memory manager tracking
            _memoryManager?.removeItem(id);
          }

          if (_config.enableAuditLogging && result) {
            await _auditService?.log(
              action: AuditAction.delete,
              entityType: T.toString(),
              entityId: id.toString(),
            );
          }

          return result;
        },
      );
    });
  }

  /// Deletes multiple entities by their identifiers.
  ///
  /// Returns the count of entities actually deleted.
  Future<int> deleteAll(List<ID> ids, {WritePolicy? policy}) async {
    _ensureInitialized();

    return _trackOperation(OperationType.deleteAll, () async {
      return _interceptorChain.execute<List<ID>, int>(
        operation: StoreOperation.deleteAll,
        request: ids,
        execute: () async {
          var count = 0;
          for (final id in ids) {
            if (await _writeHandler.delete(id, policy: policy)) {
              count++;
              // Remove from memory manager tracking
              _memoryManager?.removeItem(id);
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
        },
      );
    }, itemCount: ids.length);
  }

  // ---------------------------------------------------------------------------
  // Transaction Operations
  // ---------------------------------------------------------------------------

  /// Current transaction context (for nested transaction support).
  TransactionContext<T, ID>? _currentTransactionContext;

  /// Executes operations within an atomic transaction.
  ///
  /// All operations within the callback will be applied atomically.
  /// If the callback throws an exception, all operations are rolled back.
  ///
  /// Example:
  /// ```dart
  /// final userId = await store.transaction((tx) async {
  ///   final user = await tx.save(newUser);
  ///   await tx.save(Profile(userId: user.id));
  ///   return user.id;
  /// });
  /// ```
  ///
  /// Nested transactions create savepoints:
  /// ```dart
  /// await store.transaction((outerTx) async {
  ///   await outerTx.save(user);
  ///   try {
  ///     await store.transaction((innerTx) async {
  ///       await innerTx.save(riskyItem);
  ///       throw Exception('Rollback inner only');
  ///     });
  ///   } catch (_) {}
  ///   await outerTx.save(safeItem); // Still commits
  /// });
  /// ```
  Future<R> transaction<R>(
    Future<R> Function(Transaction<T, ID> tx) callback, {
    Duration? timeout,
  }) async {
    _ensureInitialized();

    final isNested = _currentTransactionContext != null;
    final parentContext = _currentTransactionContext;

    final context = TransactionContext<T, ID>(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}_$hashCode',
      parentContext: parentContext,
    );

    // Create savepoint for nested transactions
    int? savepointIndex;
    if (isNested && parentContext != null) {
      savepointIndex = parentContext.createSavepoint();
    }

    final tx = Transaction<T, ID>.internal(
      context: context,
      backend: _backend,
      idExtractor: _idExtractor,
    );

    // Track nested transactions
    _currentTransactionContext = context;

    try {
      // Begin backend transaction if supported and not nested
      String? backendTxId;
      if (!isNested && _backend.supportsTransactions) {
        backendTxId = await _backend.beginTransaction();
      }

      // Execute user callback with optional timeout
      final effectiveTimeout = timeout ?? _config.transactionTimeout;
      final result = await _executeWithTimeout(
        () => callback(tx),
        effectiveTimeout,
      );

      // Commit: apply all operations
      await _commitTransaction(context, backendTxId);

      return result;
    } catch (e, stack) {
      // Rollback on any error
      if (isNested && parentContext != null && savepointIndex != null) {
        // For nested transactions, rollback to savepoint
        await _rollbackToSavepoint(parentContext, savepointIndex);
      } else {
        // For top-level transactions, full rollback
        await _rollbackTransaction(context);
      }

      context.isRolledBack = true;

      if (e is TransactionError) {
        rethrow;
      }

      throw TransactionError(
        message: 'Transaction failed: $e',
        cause: e,
        stackTrace: stack,
        wasRolledBack: true,
      );
    } finally {
      _currentTransactionContext = parentContext;
    }
  }

  /// Commits a transaction by applying all pending operations.
  Future<void> _commitTransaction(
    TransactionContext<T, ID> context,
    String? backendTxId,
  ) async {
    if (context.isNested) {
      // Nested transactions just mark as committed
      // Operations are propagated to parent context
      if (context.parentContext != null) {
        context.parentContext!.operations.addAll(context.operations);
      }
      context.isCommitted = true;
      return;
    }

    try {
      // Apply all operations to backend
      if (_backend.supportsTransactions && backendTxId != null) {
        // Use backend's native transaction
        await _backend.runInTransaction(() async {
          for (final op in context.operations) {
            await _applyOperation(op);
          }
        });
        await _backend.commitTransaction(backendTxId);
      } else {
        // Optimistic: apply operations directly
        for (final op in context.operations) {
          await _applyOperation(op);
        }
      }

      context.isCommitted = true;

      // Update cache for saved items
      _notifyTransactionComplete(context.operations);
    } catch (e) {
      // Rollback on commit failure
      await _rollbackTransaction(context);
      rethrow;
    }
  }

  /// Applies a single transaction operation to the backend.
  Future<void> _applyOperation(TransactionOperation<T, ID> op) async {
    switch (op) {
      case SaveOperation<T, ID>(:final item):
        await _backend.save(item);
      case DeleteOperation<T, ID>(:final id):
        await _backend.delete(id);
    }
  }

  /// Rolls back a transaction by reverting all operations in reverse order.
  Future<void> _rollbackTransaction(TransactionContext<T, ID> context) async {
    if (context.isRolledBack) return;

    // Revert operations in reverse order
    for (final op in context.operationsReversed) {
      try {
        await _revertOperation(op);
      } catch (e) {
        _logger.warning('Failed to revert operation during rollback: $e');
      }
    }
  }

  /// Rolls back to a savepoint in a nested transaction.
  Future<void> _rollbackToSavepoint(
    TransactionContext<T, ID> context,
    int savepointIndex,
  ) async {
    final operationsToRevert = context.rollbackToSavepoint(savepointIndex);
    for (final op in operationsToRevert) {
      try {
        await _revertOperation(op);
      } catch (e) {
        _logger.warning('Failed to revert operation to savepoint: $e');
      }
    }
  }

  /// Reverts a single transaction operation.
  Future<void> _revertOperation(TransactionOperation<T, ID> op) async {
    switch (op) {
      case SaveOperation<T, ID>(:final id, :final originalValue):
        if (originalValue != null) {
          // Was an update - restore original
          await _backend.save(originalValue);
        } else {
          // Was a create - delete it
          await _backend.delete(id);
        }
      case DeleteOperation<T, ID>(:final originalValue):
        if (originalValue != null) {
          // Restore deleted item
          await _backend.save(originalValue);
        }
    }
  }

  /// Notifies cache of changes from transaction operations.
  void _notifyTransactionComplete(List<TransactionOperation<T, ID>> operations) {
    for (final op in operations) {
      switch (op) {
        case SaveOperation<T, ID>(:final id):
          _fetchHandler.recordCachedItem(id);
        case DeleteOperation<T, ID>(:final id):
          _fetchHandler.invalidate(id);
      }
    }
  }

  /// Executes an operation with optional timeout.
  Future<R> _executeWithTimeout<R>(
    Future<R> Function() operation,
    Duration timeout,
  ) async {
    return operation().timeout(
      timeout,
      onTimeout: () {
        throw TransactionError(
          message: 'Transaction timed out after $timeout',
          wasRolledBack: true,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sync Operations
  // ---------------------------------------------------------------------------

  /// Triggers a manual sync operation.
  Future<void> sync() async {
    _ensureInitialized();

    final stopwatch = _config.metricsConfig.trackTiming ? Stopwatch() : null;
    stopwatch?.start();

    try {
      await _interceptorChain.execute<void, void>(
        operation: StoreOperation.sync,
        request: null,
        execute: () async {
          await _backend.sync();
        },
      );
      stopwatch?.stop();
      _recordSyncSuccess(duration: stopwatch?.elapsed);
    } catch (e) {
      stopwatch?.stop();
      _recordSyncFailure(error: e.toString(), duration: stopwatch?.elapsed);
      rethrow;
    }
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

  // ---------------------------------------------------------------------------
  // Lazy Field Loading
  // ---------------------------------------------------------------------------

  /// Loads a specific field value for an entity.
  ///
  /// Returns the field value if the entity exists, or `null` if the entity
  /// or field doesn't exist. Results are cached for subsequent calls.
  ///
  /// Throws [StateError] if lazy loading is not configured.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final thumbnail = await store.loadField('user-123', 'thumbnail');
  /// ```
  Future<dynamic> loadField(ID id, String fieldName) async {
    _ensureInitialized();
    _ensureLazyLoadingConfigured();
    return _fieldLoader!.loadField(id, fieldName);
  }

  /// Loads a specific field value for multiple entities.
  ///
  /// Returns a map of entity ID to field value. Entities that don't have
  /// the field are omitted from the result.
  ///
  /// Throws [StateError] if lazy loading is not configured.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final thumbnails = await store.loadFieldBatch(
  ///   ['user-1', 'user-2', 'user-3'],
  ///   'thumbnail',
  /// );
  /// ```
  Future<Map<ID, dynamic>> loadFieldBatch(
    List<ID> ids,
    String fieldName,
  ) async {
    _ensureInitialized();
    _ensureLazyLoadingConfigured();
    return _fieldLoader!.loadFieldBatch(ids, fieldName);
  }

  /// Preloads multiple fields for multiple entities.
  ///
  /// Useful for preloading fields that will be needed soon.
  ///
  /// Throws [StateError] if lazy loading is not configured.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await store.preloadFields(
  ///   ['user-1', 'user-2'],
  ///   {'thumbnail', 'fullImage'},
  /// );
  /// ```
  Future<void> preloadFields(
    List<ID> ids,
    Set<String> fieldNames,
  ) async {
    _ensureInitialized();
    _ensureLazyLoadingConfigured();
    await _fieldLoader!.preloadFields(ids, fieldNames);
  }

  /// Returns the current loading state for a field.
  ///
  /// Returns [LazyFieldState.notLoaded] if lazy loading is not configured
  /// or if the field hasn't been loaded.
  LazyFieldState getFieldState(ID id, String fieldName) {
    if (_fieldLoader == null) {
      return LazyFieldState.notLoaded;
    }
    return _fieldLoader!.getFieldState(id, fieldName);
  }

  /// Clears all cached field values.
  ///
  /// This is a no-op if lazy loading is not configured.
  void clearFieldCache() {
    _fieldLoader?.clearCache();
  }

  /// Clears cached field values for a specific entity.
  ///
  /// This is a no-op if lazy loading is not configured.
  void clearFieldCacheForEntity(ID id) {
    _fieldLoader?.clearCacheForEntity(id);
  }

  void _ensureLazyLoadingConfigured() {
    if (_fieldLoader == null) {
      throw StateError(
        'Lazy loading is not configured. '
        'Add lazyLoad to StoreConfig to enable lazy field loading.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Memory Management
  // ---------------------------------------------------------------------------

  /// Pins an item to protect it from eviction.
  ///
  /// Pinned items will not be evicted during memory pressure, even when
  /// [evictCache] or automatic eviction is triggered.
  ///
  /// This is a no-op if memory management is not configured.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Pin the current user to prevent eviction
  /// store.pin(currentUserId);
  /// ```
  void pin(ID id) {
    _memoryManager?.pin(id);
  }

  /// Unpins an item, making it eligible for eviction.
  ///
  /// This is a no-op if memory management is not configured.
  void unpin(ID id) {
    _memoryManager?.unpin(id);
  }

  /// Returns `true` if the item with [id] is pinned.
  ///
  /// Returns `false` if memory management is not configured.
  bool isPinned(ID id) {
    return _memoryManager?.isPinned(id) ?? false;
  }

  /// Returns all pinned item IDs.
  ///
  /// Returns an empty set if memory management is not configured.
  Set<ID> get pinnedIds {
    return _memoryManager?.pinnedIds ?? {};
  }

  /// Returns the current memory metrics.
  ///
  /// Returns `null` if memory management is not configured.
  MemoryMetrics? get memoryMetrics {
    return _memoryManager?.currentMetrics;
  }

  /// Returns a stream of memory metrics updates.
  ///
  /// Returns an empty stream if memory management is not configured.
  Stream<MemoryMetrics> get memoryMetricsStream {
    return _memoryManager?.metricsStream ?? const Stream.empty();
  }

  /// Returns the current memory pressure level.
  ///
  /// Returns [MemoryPressureLevel.none] if memory management is not configured.
  MemoryPressureLevel get memoryPressure {
    return _memoryManager?.currentLevel ?? MemoryPressureLevel.none;
  }

  /// Returns a stream of memory pressure level changes.
  ///
  /// Returns an empty stream if memory management is not configured.
  Stream<MemoryPressureLevel> get memoryPressureStream {
    return _memoryManager?.pressureStream ?? const Stream.empty();
  }

  /// Manually triggers cache eviction.
  ///
  /// [count] specifies the number of items to evict. If not specified,
  /// uses the configured [MemoryConfig.evictionBatchSize].
  ///
  /// Returns the list of evicted IDs, or an empty list if memory management
  /// is not configured.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Evict 10 least recently used items
  /// final evictedIds = store.evictCache(count: 10);
  /// print('Evicted ${evictedIds.length} items');
  /// ```
  List<ID> evictCache({int? count}) {
    return _memoryManager?.evict(count: count) ?? [];
  }

  /// Evicts all non-pinned items from the cache.
  ///
  /// This is useful for emergency memory pressure situations.
  /// Pinned items are preserved.
  ///
  /// This is a no-op if memory management is not configured.
  void evictUnpinnedCache() {
    _memoryManager?.evictUnpinned();
  }

  // ---------------------------------------------------------------------------
  // Telemetry
  // ---------------------------------------------------------------------------

  /// Returns aggregated store statistics.
  ///
  /// Includes operation counts, durations, cache performance, and sync stats.
  StoreStats getStats() {
    return StoreStats(
      operationCounts: Map.unmodifiable(_operationCounts),
      totalDurations: Map.unmodifiable(_totalDurations),
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      syncSuccessCount: _syncSuccessCount,
      syncFailureCount: _syncFailureCount,
      errorCount: _errorCount,
      lastUpdated: _lastUpdated,
    );
  }

  /// Resets all statistics to zero.
  void resetStats() {
    _operationCounts.clear();
    _totalDurations.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _syncSuccessCount = 0;
    _syncFailureCount = 0;
    _errorCount = 0;
    _lastUpdated = null;
  }

  /// Returns whether this operation should be sampled based on config.
  bool _shouldSample() {
    final rate = _config.metricsConfig.sampleRate;
    if (rate >= 1.0) return true;
    if (rate <= 0.0) return false;
    return _random.nextDouble() < rate;
  }

  /// Tracks an operation with timing and error reporting.
  Future<R> _trackOperation<R>(
    OperationType type,
    Future<R> Function() operation, {
    int itemCount = 1,
  }) async {
    if (!_shouldSample()) return operation();

    final stopwatch = _config.metricsConfig.trackTiming ? Stopwatch() : null;
    stopwatch?.start();

    try {
      final result = await operation();
      stopwatch?.stop();

      final duration = stopwatch?.elapsed ?? Duration.zero;
      _recordOperationSuccess(type, duration, itemCount);

      return result;
    } catch (e, stack) {
      stopwatch?.stop();

      final duration = stopwatch?.elapsed ?? Duration.zero;
      _recordOperationFailure(type, duration, e, stack);

      rethrow;
    }
  }

  void _recordOperationSuccess(
    OperationType type,
    Duration duration,
    int itemCount,
  ) {
    _operationCounts[type] = (_operationCounts[type] ?? 0) + 1;
    _totalDurations[type] =
        (_totalDurations[type] ?? Duration.zero) + duration;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportOperation(OperationMetric(
      operation: type,
      duration: duration,
      success: true,
      itemCount: itemCount,
      timestamp: DateTime.now(),
    ));
  }

  void _recordOperationFailure(
    OperationType type,
    Duration duration,
    Object error,
    StackTrace stack,
  ) {
    _operationCounts[type] = (_operationCounts[type] ?? 0) + 1;
    _totalDurations[type] =
        (_totalDurations[type] ?? Duration.zero) + duration;
    _errorCount++;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportOperation(OperationMetric(
      operation: type,
      duration: duration,
      success: false,
      errorMessage: error.toString(),
      timestamp: DateTime.now(),
    ));

    _metricsReporter.reportError(ErrorMetric(
      error: error,
      stackTrace: _config.metricsConfig.includeStackTraces ? stack : null,
      operation: type.name,
      recoverable: true,
      timestamp: DateTime.now(),
    ));
  }

  void _recordCacheHit({String? itemId}) {
    if (!_shouldSample()) return;
    _cacheHits++;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportCacheEvent(CacheMetric(
      event: CacheEvent.hit,
      itemId: itemId,
      timestamp: DateTime.now(),
    ));
  }

  void _recordCacheMiss({String? itemId}) {
    if (!_shouldSample()) return;
    _cacheMisses++;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportCacheEvent(CacheMetric(
      event: CacheEvent.miss,
      itemId: itemId,
      timestamp: DateTime.now(),
    ));
  }

  void _recordSyncSuccess({int itemsSynced = 0, Duration? duration}) {
    if (!_shouldSample()) return;
    _syncSuccessCount++;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportSyncEvent(SyncMetric(
      event: SyncEvent.completed,
      duration: duration,
      itemsSynced: itemsSynced,
      timestamp: DateTime.now(),
    ));
  }

  void _recordSyncFailure({String? error, Duration? duration}) {
    if (!_shouldSample()) return;
    _syncFailureCount++;
    _lastUpdated = DateTime.now();

    _metricsReporter.reportSyncEvent(SyncMetric(
      event: SyncEvent.failed,
      duration: duration,
      error: error,
      timestamp: DateTime.now(),
    ));
  }
}
