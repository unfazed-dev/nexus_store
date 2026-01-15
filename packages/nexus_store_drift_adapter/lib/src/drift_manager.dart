import 'package:drift/drift.dart';
import 'package:nexus_store_drift_adapter/src/drift_backend.dart';
import 'package:nexus_store_drift_adapter/src/drift_table_config.dart';

/// A manager class for coordinating multiple [DriftBackend] instances
/// with a shared database connection.
///
/// This class simplifies multi-table applications by:
/// - Managing a single database connection shared across all backends
/// - Creating table schemas automatically on initialization
/// - Providing type-safe access to individual backends
///
/// Example:
/// ```dart
/// final manager = DriftManager.withDatabase(
///   tables: [
///     DriftTableConfig<User, String>(
///       tableName: 'users',
///       columns: [
///         DriftColumn.text('id', nullable: false),
///         DriftColumn.text('name', nullable: false),
///         DriftColumn.text('email'),
///       ],
///       fromJson: User.fromJson,
///       toJson: (u) => u.toJson(),
///       getId: (u) => u.id,
///     ),
///     DriftTableConfig<Post, String>(
///       tableName: 'posts',
///       columns: [...],
///       fromJson: Post.fromJson,
///       toJson: (p) => p.toJson(),
///       getId: (p) => p.id,
///     ),
///   ],
/// );
///
/// await manager.initialize();
///
/// // Dynamic backend (original API)
/// final dynamicBackend = manager.getBackend('users');
///
/// // Typed backend for use with NexusStore<T, ID>
/// final typedBackend = await manager.createTypedBackend<User, String>('users');
/// final store = NexusStore<User, String>(backend: typedBackend);
/// ```
class DriftManager {
  DriftManager._({
    required List<DriftTableConfig<dynamic, dynamic>> tables,
    required QueryExecutor executor,
  })  : _tables = tables,
        _executor = executor;

  /// Creates a [DriftManager] with automatic database setup.
  ///
  /// - [tables]: List of table configurations for all tables.
  /// - [executor]: Optional query executor (defaults to in-memory database).
  factory DriftManager.withDatabase({
    required List<DriftTableConfig<dynamic, dynamic>> tables,
    QueryExecutor? executor,
  }) =>
      DriftManager._(
        tables: tables,
        executor: executor ?? _createInMemoryExecutor(),
      );

  final List<DriftTableConfig<dynamic, dynamic>> _tables;
  final QueryExecutor _executor;
  final Map<String, DriftBackend<dynamic, dynamic>> _backends = {};
  final Map<String, DriftTableConfig<dynamic, dynamic>> _configsByName = {};
  _ManagerDatabase? _database;
  bool _initialized = false;

  /// Whether the manager has been initialized.
  bool get isInitialized => _initialized;

  /// List of all table names.
  List<String> get tableNames => _tables.map((t) => t.tableName).toList();

  /// Initializes the database and creates all table schemas.
  ///
  /// This must be called before accessing any backends.
  Future<void> initialize() async {
    if (_initialized) return;

    // Create database wrapper
    _database = _ManagerDatabase(_executor);

    // Create all table schemas and store configs by name
    for (final config in _tables) {
      _configsByName[config.tableName] = config;

      final definition = config.toTableDefinition();
      await _database!.customStatement(definition.toCreateTableSql());

      // Create indexes
      for (final indexSql in definition.toCreateIndexSql()) {
        await _database!.customStatement(indexSql);
      }
    }

    // Create backends
    for (final config in _tables) {
      final backend = _createBackend(config);
      await backend.initializeWithExecutor(_database!);
      _backends[config.tableName] = backend;
    }

    _initialized = true;
  }

  /// Gets a backend by table name.
  ///
  /// The returned backend uses dynamic types internally but works correctly
  /// with the serialization functions provided in the table config.
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  DriftBackend<dynamic, dynamic> getBackend(String tableName) {
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

  /// Creates a typed backend for use with `NexusStore<T, ID>`.
  ///
  /// Unlike [getBackend], this method returns a properly typed backend that
  /// can be used directly with typed NexusStore instances.
  ///
  /// The type parameters must match the types used in [DriftTableConfig]:
  /// - [T] must match the entity type
  /// - [ID] must match the ID type
  ///
  /// Example:
  /// ```dart
  /// final backend = await manager.createTypedBackend<User, String>('users');
  /// final store = NexusStore<User, String>(
  ///   backend: backend,
  ///   config: StoreConfig.defaults,
  /// );
  /// await store.initialize();
  /// ```
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  Future<DriftBackend<T, ID>> createTypedBackend<T, ID>(
    String tableName,
  ) async {
    if (!_initialized) {
      throw StateError(
        'Manager not initialized. Call initialize() first.',
      );
    }

    final config = _configsByName[tableName];
    if (config == null) {
      throw StateError(
        'Table "$tableName" not found. '
        'Available tables: ${tableNames.join(", ")}',
      );
    }

    // Create a typed backend using the config's original typed functions
    final typedConfig = config as DriftTableConfig<T, ID>;
    final backend = DriftBackend<T, ID>(
      tableName: typedConfig.tableName,
      getId: typedConfig.getId,
      fromJson: typedConfig.fromJson,
      toJson: typedConfig.toJson,
      primaryKeyField: typedConfig.primaryKeyColumn,
      fieldMapping: typedConfig.fieldMapping,
    );

    await backend.initializeWithExecutor(_database!);
    return backend;
  }

  /// Exposes the shared database for advanced use cases.
  ///
  /// This allows creating custom backends that share the same database
  /// connection as the manager.
  ///
  /// Returns `null` if the manager has not been initialized.
  DatabaseConnectionUser? get sharedDatabase => _database;

  /// Disposes all resources.
  Future<void> dispose() async {
    for (final backend in _backends.values) {
      await backend.close();
    }
    _backends.clear();

    await _database?.close();
    _database = null;
    _initialized = false;
  }

  DriftBackend<dynamic, dynamic> _createBackend(
    DriftTableConfig<dynamic, dynamic> config,
  ) {
    // Use the config's dynamic wrappers to bypass type contravariance
    final wrappedGetId = config.dynamicGetId;
    final wrappedFromJson = config.dynamicFromJson;
    final wrappedToJson = config.dynamicToJson;

    return DriftBackend<dynamic, dynamic>(
      tableName: config.tableName,
      getId: wrappedGetId,
      fromJson: wrappedFromJson,
      toJson: wrappedToJson,
      primaryKeyField: config.primaryKeyColumn,
      fieldMapping: config.fieldMapping,
    );
  }

  static QueryExecutor _createInMemoryExecutor() {
    // This is a placeholder - in real usage, you'd use NativeDatabase.memory()
    // but we avoid importing drift/native here to keep the core library pure
    throw UnsupportedError(
      'No executor provided. Please provide a QueryExecutor, '
      'e.g., NativeDatabase.memory() from drift/native.dart',
    );
  }
}

/// Internal database wrapper for the manager.
// coverage:ignore-start
class _ManagerDatabase extends GeneratedDatabase {
  _ManagerDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Schema creation is handled manually by the manager
        },
      );
}
// coverage:ignore-end
