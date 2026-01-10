import 'package:nexus_store_supabase_adapter/src/supabase_backend.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_table_config.dart';
import 'package:supabase/supabase.dart';

/// A manager class for coordinating multiple [SupabaseBackend] instances
/// with a shared Supabase client.
///
/// This class simplifies multi-table applications by:
/// - Managing a single Supabase client shared across all backends
/// - Creating backends automatically from table configurations
/// - Providing type-safe access to individual backends
/// - Coordinating realtime subscriptions across tables
///
/// Example:
/// ```dart
/// final manager = SupabaseManager.withClient(
///   client: Supabase.instance.client,
///   tables: [
///     SupabaseTableConfig<User, String>(
///       tableName: 'users',
///       columns: [
///         SupabaseColumn.uuid('id', nullable: false),
///         SupabaseColumn.text('name', nullable: false),
///       ],
///       fromJson: User.fromJson,
///       toJson: (u) => u.toJson(),
///       getId: (u) => u.id,
///       enableRealtime: true,
///     ),
///     SupabaseTableConfig<Post, String>(
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
/// final userBackend = manager.getBackend<User, String>('users');
/// final postBackend = manager.getBackend<Post, String>('posts');
/// ```
class SupabaseManager {
  SupabaseManager._({
    required List<SupabaseTableConfig<dynamic, dynamic>> tables,
    SupabaseClient? client,
  })  : _tables = tables,
        _client = client;

  /// Creates a [SupabaseManager] with a Supabase client.
  ///
  /// - [client]: The Supabase client to use for all database operations.
  /// - [tables]: List of table configurations for all tables.
  factory SupabaseManager.withClient({
    required SupabaseClient client,
    required List<SupabaseTableConfig<dynamic, dynamic>> tables,
  }) =>
      SupabaseManager._(tables: tables, client: client);

  /// Creates a [SupabaseManager] with only table configurations.
  ///
  /// This constructor is useful for testing or when you want to configure
  /// tables before providing a client.
  ///
  /// Note: You must provide a client via [initialize] or [setClient]
  /// before using the backends.
  factory SupabaseManager.withTables({
    required List<SupabaseTableConfig<dynamic, dynamic>> tables,
  }) =>
      SupabaseManager._(tables: tables);

  final List<SupabaseTableConfig<dynamic, dynamic>> _tables;
  SupabaseClient? _client;
  final Map<String, SupabaseBackend<dynamic, dynamic>> _backends = {};
  bool _initialized = false;

  /// Whether the manager has been initialized.
  bool get isInitialized => _initialized;

  /// List of all table names.
  List<String> get tableNames => _tables.map((t) => t.tableName).toList();

  /// All table configurations.
  List<SupabaseTableConfig<dynamic, dynamic>> get tables =>
      List.unmodifiable(_tables);

  /// Whether any tables have realtime enabled.
  bool get hasRealtimeTables => _tables.any((t) => t.enableRealtime);

  /// Sets the Supabase client for this manager.
  ///
  /// This must be called before [initialize] if using [withTables] constructor.
  void setClient(SupabaseClient client) {
    if (_initialized) {
      throw StateError(
        'Cannot set client after initialization. '
        'Create a new manager instead.',
      );
    }
    _client = client;
  }

  /// Initializes all backends.
  ///
  /// This must be called before accessing any backends.
  Future<void> initialize() async {
    if (_initialized) return;

    if (_client == null) {
      throw StateError(
        'No Supabase client provided. '
        'Use withClient() or call setClient() before initialize().',
      );
    }

    // Create and initialize backends
    for (final config in _tables) {
      final backend = _createBackend(config);
      await backend.initialize();
      _backends[config.tableName] = backend;
    }

    _initialized = true;
  }

  /// Gets a backend by table name.
  ///
  /// The returned backend is typed as `SupabaseBackend<dynamic, dynamic>`.
  /// For type-safe access, use [getTypedBackend] instead.
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  SupabaseBackend<dynamic, dynamic> getBackend(String tableName) {
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

  /// Gets a typed backend by table name.
  ///
  /// This method provides type-safe access to a backend, but requires
  /// the caller to know the correct types.
  ///
  /// Example:
  /// ```dart
  /// final userBackend = manager.getTypedBackend<User, String>('users');
  /// ```
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  SupabaseBackend<T, ID> getTypedBackend<T, ID>(String tableName) {
    final backend = getBackend(tableName);
    return backend as SupabaseBackend<T, ID>;
  }

  /// Disposes all backends and releases resources.
  Future<void> dispose() async {
    for (final backend in _backends.values) {
      await backend.close();
    }
    _backends.clear();
    _initialized = false;
  }

  SupabaseBackend<dynamic, dynamic> _createBackend(
    SupabaseTableConfig<dynamic, dynamic> config,
  ) {
    // Use the config's dynamic wrappers to bypass type contravariance
    final wrappedGetId = config.dynamicGetId;
    final wrappedFromJson = config.dynamicFromJson;
    final wrappedToJson = config.dynamicToJson;

    return SupabaseBackend<dynamic, dynamic>(
      client: _client!,
      tableName: config.tableName,
      getId: wrappedGetId,
      fromJson: wrappedFromJson,
      toJson: wrappedToJson,
      primaryKeyColumn: config.primaryKeyColumn,
      fieldMapping: config.fieldMapping,
      schema: config.schema,
    );
  }
}
