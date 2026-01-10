import 'package:nexus_store_powersync_adapter/src/powersync_database_wrapper.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart' as ps;

/// Abstract interface for PowerSync database lifecycle management.
///
/// This abstraction (option 3) allows for easy mocking of database
/// lifecycle operations in tests, enabling full unit test coverage
/// of [PowerSyncManager] without requiring native SQLite extensions.
///
/// Example usage in production:
/// ```dart
/// final adapter = DefaultPowerSyncDatabaseAdapter(schema, path);
/// await adapter.initialize();
/// await adapter.connect(connector);
/// ```
///
/// Example usage in tests:
/// ```dart
/// final mockAdapter = MockPowerSyncDatabaseAdapter();
/// when(() => mockAdapter.initialize()).thenAnswer((_) async {});
/// when(() => mockAdapter.wrapper).thenReturn(mockWrapper);
/// ```
abstract class PowerSyncDatabaseAdapter {
  /// Initializes the database.
  Future<void> initialize();

  /// Connects to the PowerSync service using the provided connector.
  Future<void> connect(SupabasePowerSyncConnector connector);

  /// Disconnects from the PowerSync service.
  Future<void> disconnect();

  /// Closes the database connection.
  Future<void> close();

  /// Returns a wrapper for executing database operations.
  PowerSyncDatabaseWrapper get wrapper;

  /// Whether the database has been initialized.
  bool get isInitialized;
}

/// Factory function type for creating [PowerSyncDatabaseAdapter] instances.
///
/// This abstraction (option 2) allows dependency injection of the factory
/// for testing purposes.
///
/// Example:
/// ```dart
/// // Production usage
/// final manager = PowerSyncManager.withSupabase(
///   supabase: client,
///   powerSyncUrl: url,
///   tables: tables,
/// );
///
/// // Test usage with mock factory
/// final manager = PowerSyncManager.withSupabase(
///   supabase: client,
///   powerSyncUrl: url,
///   tables: tables,
///   databaseAdapterFactory: (schema, path) => mockAdapter,
/// );
/// ```
typedef PowerSyncDatabaseAdapterFactory = PowerSyncDatabaseAdapter Function(
  ps.Schema schema,
  String path,
);

/// Default implementation that wraps a real [ps.PowerSyncDatabase].
///
/// This class handles the lifecycle of a PowerSync database including
/// initialization, connection, disconnection, and cleanup.
class DefaultPowerSyncDatabaseAdapter implements PowerSyncDatabaseAdapter {
  /// Creates an adapter for a PowerSync database.
  ///
  /// - [schema]: The database schema definition.
  /// - [path]: The file path for the SQLite database.
  /// - [openFactory]: Optional custom factory for database creation.
  ///   Use this for testing on desktop platforms that require special
  ///   SQLite configuration (e.g., Homebrew SQLite on macOS).
  DefaultPowerSyncDatabaseAdapter({
    required ps.Schema schema,
    required String path,
    ps.PowerSyncOpenFactory? openFactory,
  })  : _schema = schema,
        _path = path,
        _openFactory = openFactory;

  final ps.Schema _schema;
  final String _path;
  final ps.PowerSyncOpenFactory? _openFactory;

  ps.PowerSyncDatabase? _database;
  PowerSyncDatabaseWrapper? _wrapper;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    if (_openFactory != null) {
      _database = ps.PowerSyncDatabase.withFactory(
        _openFactory,
        schema: _schema,
      );
    } else {
      _database = ps.PowerSyncDatabase(schema: _schema, path: _path);
    }
    await _database!.initialize();
    _wrapper = DefaultPowerSyncDatabaseWrapper(_database!);
    _initialized = true;
  }

  @override
  Future<void> connect(SupabasePowerSyncConnector connector) async {
    _ensureInitialized();
    await _database!.connect(connector: connector);
  }

  @override
  Future<void> disconnect() async {
    if (_database != null) {
      await _database!.disconnect();
    }
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _wrapper = null;
      _initialized = false;
    }
  }

  @override
  PowerSyncDatabaseWrapper get wrapper {
    _ensureInitialized();
    return _wrapper!;
  }

  @override
  bool get isInitialized => _initialized;

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'PowerSyncDatabaseAdapter not initialized. Call initialize() first.',
      );
    }
  }
}

/// Default factory function that creates [DefaultPowerSyncDatabaseAdapter].
PowerSyncDatabaseAdapter defaultPowerSyncDatabaseAdapterFactory(
  ps.Schema schema,
  String path,
) =>
    DefaultPowerSyncDatabaseAdapter(schema: schema, path: path);
