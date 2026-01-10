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
/// final userBackend = manager.getBackend('users');
/// final postBackend = manager.getBackend('posts');
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
  }) => DriftManager._(
      tables: tables,
      executor: executor ?? _createInMemoryExecutor(),
    );

  final List<DriftTableConfig<dynamic, dynamic>> _tables;
  final QueryExecutor _executor;
  final Map<String, DriftBackend<dynamic, dynamic>> _backends = {};
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

    // Create all table schemas
    for (final config in _tables) {
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
