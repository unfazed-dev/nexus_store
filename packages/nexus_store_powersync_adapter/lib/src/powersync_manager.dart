import 'package:nexus_store_powersync_adapter/src/powersync_backend.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_database_adapter.dart';
import 'package:nexus_store_powersync_adapter/src/ps_table_config.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase/supabase.dart';

/// Factory function type for creating [SupabasePowerSyncConnector] instances.
///
/// This allows dependency injection of the connector factory for testing.
typedef ConnectorFactory = SupabasePowerSyncConnector Function(
  SupabaseClient supabase,
  String powerSyncUrl,
);

/// Factory function type for creating [PowerSyncBackend] instances.
///
/// This allows dependency injection of the backend factory for testing.
typedef BackendFactory = PowerSyncBackend<dynamic, dynamic> Function({
  required PowerSyncDatabaseAdapter adapter,
  required String tableName,
  required Function fromJson,
  required Function toJson,
  required Function getId,
  required String primaryKeyColumn,
  required Map<String, String>? fieldMapping,
});

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
    PowerSyncDatabaseAdapterFactory? databaseAdapterFactory,
    ConnectorFactory? connectorFactory,
    BackendFactory? backendFactory,
  })  : _tableConfigs = {for (final t in tables) t.tableName: t},
        _databaseAdapterFactory =
            databaseAdapterFactory ?? defaultPowerSyncDatabaseAdapterFactory,
        _connectorFactory = connectorFactory ?? _defaultConnectorFactory,
        _backendFactory = backendFactory ?? _defaultBackendFactory;

  /// Creates a PowerSyncManager with Supabase integration.
  ///
  /// - [supabase]: The Supabase client for authentication and data sync.
  /// - [powerSyncUrl]: The PowerSync service URL.
  /// - [tables]: List of table configurations.
  /// - [dbPath]: Optional custom database path.
  /// - [databaseAdapterFactory]: Optional factory for creating database
  ///   adapters (useful for testing).
  /// - [connectorFactory]: Optional factory for creating connectors
  ///   (useful for testing).
  /// - [backendFactory]: Optional factory for creating backends
  ///   (useful for testing).
  factory PowerSyncManager.withSupabase({
    required SupabaseClient supabase,
    required String powerSyncUrl,
    required List<PSTableConfig<dynamic, dynamic>> tables,
    String? dbPath,
    PowerSyncDatabaseAdapterFactory? databaseAdapterFactory,
    ConnectorFactory? connectorFactory,
    BackendFactory? backendFactory,
  }) =>
      PowerSyncManager._(
        supabase: supabase,
        powerSyncUrl: powerSyncUrl,
        tables: tables,
        dbPath: dbPath,
        databaseAdapterFactory: databaseAdapterFactory,
        connectorFactory: connectorFactory,
        backendFactory: backendFactory,
      );

  static SupabasePowerSyncConnector _defaultConnectorFactory(
    SupabaseClient supabase,
    String powerSyncUrl,
  ) =>
      SupabasePowerSyncConnector.withClient(
        supabase: supabase,
        powerSyncUrl: powerSyncUrl,
      );

  static PowerSyncBackend<dynamic, dynamic> _defaultBackendFactory({
    required PowerSyncDatabaseAdapter adapter,
    required String tableName,
    required Function fromJson,
    required Function toJson,
    required Function getId,
    required String primaryKeyColumn,
    required Map<String, String>? fieldMapping,
  }) {
    // Wrap functions to ensure correct types.
    // This is necessary because PSTableConfig<T, ID> stores typed functions,
    // and when accessed through PSTableConfig<dynamic, dynamic>, the runtime
    // types may not match. Creating new closures ensures proper typing.
    dynamic wrappedFromJson(Map<String, dynamic> json) => fromJson(json);
    Map<String, dynamic> wrappedToJson(dynamic item) =>
        toJson(item) as Map<String, dynamic>;
    dynamic wrappedGetId(dynamic item) => getId(item);

    return PowerSyncBackend<dynamic, dynamic>.withWrapper(
      db: adapter.wrapper,
      tableName: tableName,
      fromJson: wrappedFromJson,
      toJson: wrappedToJson,
      getId: wrappedGetId,
      primaryKeyColumn: primaryKeyColumn,
      fieldMapping: fieldMapping,
    );
  }

  /// The PowerSync service URL.
  final String powerSyncUrl;

  /// The Supabase client.
  final SupabaseClient supabase;

  /// Optional custom database path.
  final String? dbPath;

  /// Table configurations by table name.
  final Map<String, PSTableConfig<dynamic, dynamic>> _tableConfigs;

  /// Factory for creating database adapters.
  final PowerSyncDatabaseAdapterFactory _databaseAdapterFactory;

  /// Factory for creating connectors.
  final ConnectorFactory _connectorFactory;

  /// Factory for creating backends.
  final BackendFactory _backendFactory;

  /// The shared database adapter (created on initialize).
  PowerSyncDatabaseAdapter? _adapter;

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

    // Create and initialize the database adapter
    _adapter = _databaseAdapterFactory(schema, path);
    await _adapter!.initialize();

    // Create the shared connector
    _connector = _connectorFactory(supabase, powerSyncUrl);

    // Connect the database
    await _adapter!.connect(_connector!);

    // Create backends for each table
    for (final entry in _tableConfigs.entries) {
      final tableName = entry.key;
      final config = entry.value;

      // Extract functions as dynamic to avoid variance issues.
      // PSTableConfig<T, ID> stores typed functions, but when accessed through
      // PSTableConfig<dynamic, dynamic>, Dart's type system expects
      // (dynamic) => X functions. However, the actual runtime types are
      // (T) => X which are not subtypes due to function contravariance.
      // Using dynamic bypasses these type checks.
      final dynamic configDynamic = config;
      final fromJson = configDynamic.fromJson as Function;
      final toJson = configDynamic.toJson as Function;
      final getId = configDynamic.getId as Function;

      final backend = _backendFactory(
        adapter: _adapter!,
        tableName: tableName,
        fromJson: fromJson,
        toJson: toJson,
        getId: getId,
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
  /// Returns a [PowerSyncBackend] with dynamic type parameters. The underlying
  /// operations (save, get, etc.) still work correctly at runtime because the
  /// functions provided to [PSTableConfig] have the correct types.
  ///
  /// Note: Due to Dart's generic invariance, it's not possible to return
  /// `PowerSyncBackend<T, ID>` when backends are stored internally as
  /// `PowerSyncBackend<dynamic, dynamic>`. Use the returned backend directly
  /// or create a typed wrapper if needed.
  ///
  /// Throws [StateError] if the manager is not initialized.
  /// Throws [ArgumentError] if the table is not registered.
  PowerSyncBackend<dynamic, dynamic> getBackend<T, ID>(String tableName) {
    if (!_initialized) {
      throw StateError(
        'PowerSyncManager not initialized. Call initialize() first.',
      );
    }

    if (!_backends.containsKey(tableName)) {
      throw ArgumentError('Table "$tableName" not registered');
    }

    return _backends[tableName]!;
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
    if (_adapter != null) {
      await _adapter!.disconnect();
      await _adapter!.close();
      _adapter = null;
    }

    _connector = null;
    _initialized = false;
    _disposed = true;
  }
}
