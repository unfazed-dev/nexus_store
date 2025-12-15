import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/gdpr_service.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/policy/fetch_policy_handler.dart';
import 'package:nexus_store/src/policy/write_policy_handler.dart';
import 'package:nexus_store/src/query/query.dart';
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
  NexusStore({
    required StoreBackend<T, ID> backend,
    StoreConfig? config,
    AuditService? auditService,
    String? subjectIdField,
  })  : _backend = backend,
        _config = config ?? StoreConfig.defaults,
        _auditService = auditService {
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
  // Write Operations
  // ---------------------------------------------------------------------------

  /// Saves an entity (creates or updates).
  ///
  /// Uses the configured [WritePolicy] or the provided [policy] override.
  /// Returns the saved entity, which may include server-generated fields.
  Future<T> save(T item, {WritePolicy? policy}) async {
    _ensureInitialized();

    // Encrypt fields if configured
    // Note: For proper implementation, T should be serializable to Map
    // This is a simplified version - full implementation would use
    // a serializer interface

    final result = await _writeHandler.save(item, policy: policy);

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
  Future<List<T>> saveAll(List<T> items, {WritePolicy? policy}) async {
    _ensureInitialized();

    final results = await _writeHandler.saveAll(items, policy: policy);

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
}
