import 'package:nexus_store_powersync_adapter/src/powersync_backend.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_database_wrapper.dart';
import 'package:nexus_store_powersync_adapter/src/ps_table_config.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase/supabase.dart';

/// Manages multiple PowerSync backends sharing a single database connection.
///
/// Use this class when your app has multiple tables that need to sync.
/// The manager creates a shared PowerSync database and provides access
/// to individual backends for each table.
///
/// Example:
/// ```dart
/// final manager = PowerSyncManager.withSupabase(
///   supabase: Supabase.instance.client,
///   powerSyncUrl: 'https://xxx.powersync.co',
///   tables: [
///     PSTableConfig<User, String>(
///       tableName: 'users',
///       columns: [PSColumn.text('name'), PSColumn.text('email')],
///       fromJson: User.fromJson,
///       toJson: (u) => u.toJson(),
///       getId: (u) => u.id,
///     ),
///     PSTableConfig<Post, String>(
///       tableName: 'posts',
///       columns: [PSColumn.text('title'), PSColumn.text('content')],
///       fromJson: Post.fromJson,
///       toJson: (p) => p.toJson(),
///       getId: (p) => p.id,
///     ),
///   ],
/// );
///
/// await manager.initialize();
///
/// final userBackend = manager.getBackend<User, String>('users');
/// final postBackend = manager.getBackend<Post, String>('posts');
///
/// await manager.dispose();
/// ```
class PowerSyncManager {
  PowerSyncManager._({
    required this.powerSyncUrl,
    required this.supabase,
    required List<PSTableConfig<dynamic, dynamic>> tables,
    this.dbPath,
  }) : _tableConfigs = {for (final t in tables) t.tableName: t};

  /// Creates a PowerSyncManager with Supabase integration.
  ///
  /// - [supabase]: The Supabase client for authentication and data sync.
  /// - [powerSyncUrl]: The PowerSync service URL.
  /// - [tables]: List of table configurations.
  /// - [dbPath]: Optional custom database path.
  factory PowerSyncManager.withSupabase({
    required SupabaseClient supabase,
    required String powerSyncUrl,
    required List<PSTableConfig<dynamic, dynamic>> tables,
    String? dbPath,
  }) => PowerSyncManager._(
      supabase: supabase,
      powerSyncUrl: powerSyncUrl,
      tables: tables,
      dbPath: dbPath,
    );

  /// The PowerSync service URL.
  final String powerSyncUrl;

  /// The Supabase client.
  final SupabaseClient supabase;

  /// Optional custom database path.
  final String? dbPath;

  /// Table configurations by table name.
  final Map<String, PSTableConfig<dynamic, dynamic>> _tableConfigs;

  /// The shared PowerSync database (created on initialize).
  ps.PowerSyncDatabase? _database;

  /// The shared connector (created on initialize).
  SupabasePowerSyncConnector? _connector;

  /// Backends by table name (created on initialize).
  final Map<String, PowerSyncBackend<dynamic, dynamic>> _backends = {};

  /// Whether the manager has been initialized.
  bool _initialized = false;

  /// Whether the manager has been disposed.
  bool _disposed = false;

  /// Whether the manager has been initialized.
  bool get isInitialized => _initialized;

  /// List of all registered table names.
  List<String> get tableNames => _tableConfigs.keys.toList();

  /// Checks if a table is registered.
  bool hasTable(String tableName) => _tableConfigs.containsKey(tableName);

  /// Generates the combined schema for all tables.
  ps.Schema generateSchema() {
    final tables = _tableConfigs.values
        .map((config) => config.toTableDefinition().toTable())
        .toList();

    return ps.Schema(tables);
  }

  /// Initializes the manager, creating the shared database and all backends.
  ///
  /// This must be called before accessing backends via [getBackend].
  Future<void> initialize() async {
    if (_initialized) return;
    if (_disposed) {
      throw StateError('Cannot initialize a disposed PowerSyncManager');
    }

    // Generate combined schema
    final schema = generateSchema();

    // Create database path
    final path =
        dbPath ?? 'powersync_${DateTime.now().millisecondsSinceEpoch}.db';

    // Create and initialize the shared database
    _database = ps.PowerSyncDatabase(schema: schema, path: path);
    await _database!.initialize();

    // Create the shared connector
    _connector = SupabasePowerSyncConnector.withClient(
      supabase: supabase,
      powerSyncUrl: powerSyncUrl,
    );

    // Connect the database
    await _database!.connect(connector: _connector!);

    // Create a shared wrapper
    final wrapper = DefaultPowerSyncDatabaseWrapper(_database!);

    // Create backends for each table
    for (final entry in _tableConfigs.entries) {
      final tableName = entry.key;
      final config = entry.value;

      final backend = PowerSyncBackend<dynamic, dynamic>.withWrapper(
        db: wrapper,
        tableName: tableName,
        fromJson: config.fromJson,
        toJson: config.toJson,
        getId: config.getId,
        primaryKeyColumn: config.primaryKeyColumn,
        fieldMapping: config.fieldMapping,
      );

      await backend.initialize();
      _backends[tableName] = backend;
    }

    _initialized = true;
  }

  /// Gets the backend for a specific table.
  ///
  /// Throws [StateError] if the manager is not initialized.
  /// Throws [ArgumentError] if the table is not registered.
  PowerSyncBackend<T, ID> getBackend<T, ID>(String tableName) {
    if (!_initialized) {
      throw StateError(
        'PowerSyncManager not initialized. Call initialize() first.',
      );
    }

    if (!_backends.containsKey(tableName)) {
      throw ArgumentError('Table "$tableName" not registered');
    }

    return _backends[tableName]! as PowerSyncBackend<T, ID>;
  }

  /// Disposes of all resources.
  ///
  /// This closes all backends and the shared database connection.
  Future<void> dispose() async {
    if (_disposed) return;

    // Close all backends
    for (final backend in _backends.values) {
      await backend.close();
    }
    _backends.clear();

    // Disconnect and close the database
    if (_database != null) {
      await _database!.disconnect();
      await _database!.close();
      _database = null;
    }

    _connector = null;
    _initialized = false;
    _disposed = true;
  }
}
