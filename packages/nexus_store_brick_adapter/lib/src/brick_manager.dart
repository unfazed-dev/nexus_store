import 'dart:async';

import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/src/brick_backend.dart';
import 'package:nexus_store_brick_adapter/src/brick_sync_config.dart';
import 'package:nexus_store_brick_adapter/src/brick_table_config.dart';
import 'package:rxdart/rxdart.dart';

/// A manager class for coordinating multiple [BrickBackend] instances
/// with a shared repository.
///
/// This class simplifies multi-table Brick applications by:
/// - Managing a single repository shared across all backends
/// - Providing type-safe access to individual backends
/// - Coordinating sync across all tables
/// - Aggregating pending changes count
///
/// Example:
/// ```dart
/// final manager = BrickManager.withRepository(
///   repository: myBrickRepository,
///   tables: [
///     BrickTableConfig<User, String>(
///       tableName: 'users',
///       getId: (u) => u.id,
///       fromJson: User.fromJson,
///       toJson: (u) => u.toJson(),
///     ),
///     BrickTableConfig<Post, String>(
///       tableName: 'posts',
///       getId: (p) => p.id,
///       fromJson: Post.fromJson,
///       toJson: (p) => p.toJson(),
///     ),
///   ],
/// );
///
/// await manager.initialize();
///
/// final userBackend = manager.getBackend('users');
/// final postBackend = manager.getBackend('posts');
///
/// // Sync all entities
/// await manager.syncAll();
/// final pending = await manager.totalPendingChanges;
/// ```
class BrickManager {
  BrickManager._({
    required OfflineFirstRepository<dynamic> repository,
    required List<BrickTableConfig<dynamic, dynamic>> tables,
    BrickSyncConfig? syncConfig,
  })  : _repository = repository,
        _tables = tables,
        _syncConfig = syncConfig ?? const BrickSyncConfig();

  /// Creates a [BrickManager] with a shared repository.
  ///
  /// - [repository]: The Brick offline-first repository to use.
  /// - [tables]: List of table configurations for all tables.
  /// - [syncConfig]: Optional global sync configuration override.
  factory BrickManager.withRepository({
    required OfflineFirstRepository<dynamic> repository,
    required List<BrickTableConfig<dynamic, dynamic>> tables,
    BrickSyncConfig? syncConfig,
  }) =>
      BrickManager._(
        repository: repository,
        tables: tables,
        syncConfig: syncConfig,
      );

  final OfflineFirstRepository<dynamic> _repository;
  final List<BrickTableConfig<dynamic, dynamic>> _tables;
  final BrickSyncConfig _syncConfig;
  final Map<String, BrickBackend<OfflineFirstModel, dynamic>> _backends = {};
  bool _initialized = false;

  final _syncStatusSubject =
      BehaviorSubject<nexus.SyncStatus>.seeded(nexus.SyncStatus.synced);

  /// Whether the manager has been initialized.
  bool get isInitialized => _initialized;

  /// List of all table names.
  List<String> get tableNames => _tables.map((t) => t.tableName).toList();

  /// The global sync configuration.
  BrickSyncConfig get syncConfig => _syncConfig;

  /// Stream of combined sync status from all backends.
  Stream<nexus.SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  /// Current combined sync status.
  nexus.SyncStatus get syncStatus => _syncStatusSubject.value;

  /// Initializes the repository and creates all backends.
  ///
  /// This must be called before accessing any backends.
  Future<void> initialize() async {
    if (_initialized) return;

    // Create backends for each table
    // The first backend.initialize() will initialize the shared repository
    for (final config in _tables) {
      final backend = _createBackend(config);
      await backend.initialize();
      _backends[config.tableName] = backend;

      // Subscribe to backend sync status
      backend.syncStatusStream.listen(_updateCombinedSyncStatus);
    }

    _initialized = true;
  }

  /// Gets a backend by table name.
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  BrickBackend<OfflineFirstModel, dynamic> getBackend(String tableName) {
    if (!_initialized) {
      throw StateError(
        'Manager not initialized. Call initialize() first.',
      );
    }

    final backend = _backends[tableName];
    if (backend == null) {
      throw StateError(
        'Table "$tableName" not found. '
        'Available tables: ${tableNames.join(", ")}',
      );
    }

    return backend;
  }

  /// Syncs all backends.
  Future<void> syncAll() async {
    _ensureInitialized();

    _syncStatusSubject.add(nexus.SyncStatus.syncing);

    try {
      for (final backend in _backends.values) {
        await backend.sync();
      }
      _syncStatusSubject.add(nexus.SyncStatus.synced);
    } catch (e) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
      rethrow;
    }
  }

  /// Gets the total pending changes count from all backends.
  Future<int> get totalPendingChanges async {
    _ensureInitialized();

    var total = 0;
    for (final backend in _backends.values) {
      total += await backend.pendingChangesCount;
    }
    return total;
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    if (!_initialized) return;

    for (final backend in _backends.values) {
      await backend.close();
    }
    _backends.clear();

    await _syncStatusSubject.close();
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Manager not initialized. Call initialize() first.',
      );
    }
  }

  void _updateCombinedSyncStatus(nexus.SyncStatus status) {
    // Priority: error > syncing > pending > synced
    if (status == nexus.SyncStatus.error) {
      _syncStatusSubject.add(nexus.SyncStatus.error);
    } else if (status == nexus.SyncStatus.syncing) {
      if (_syncStatusSubject.value != nexus.SyncStatus.error) {
        _syncStatusSubject.add(nexus.SyncStatus.syncing);
      }
    } else if (status == nexus.SyncStatus.pending) {
      if (_syncStatusSubject.value == nexus.SyncStatus.synced) {
        _syncStatusSubject.add(nexus.SyncStatus.pending);
      }
    }
    // synced only if all backends are synced (handled in syncAll)
  }

  BrickBackend<OfflineFirstModel, dynamic> _createBackend(
    BrickTableConfig<dynamic, dynamic> config,
  ) {
    // Use the config's dynamic wrappers to bypass type contravariance
    final wrappedGetId = config.dynamicGetId;

    return BrickBackend<OfflineFirstModel, dynamic>(
      repository: _repository as OfflineFirstRepository<OfflineFirstModel>,
      getId: wrappedGetId,
      primaryKeyField: config.primaryKeyField,
      fieldMapping: config.fieldMapping,
      syncConfig: config.syncConfig ?? _syncConfig,
    );
  }
}
