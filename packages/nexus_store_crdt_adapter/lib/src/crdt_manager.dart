import 'dart:async';

import 'package:nexus_store_crdt_adapter/src/crdt_backend.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_database_wrapper.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_peer_connector.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_table_config.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

/// A manager class for coordinating multiple [CrdtBackend] instances
/// with a shared database connection and HLC clock.
///
/// This class simplifies multi-table CRDT applications by:
/// - Managing a single database connection shared across all backends
/// - Creating table schemas automatically on initialization
/// - Providing type-safe access to individual backends
/// - Coordinating changeset sync across all tables
/// - Managing peer connector for network sync
///
/// Example:
/// ```dart
/// final manager = CrdtManager.withDatabase(
///   tables: [
///     CrdtTableConfig<User, String>(
///       tableName: 'users',
///       columns: [
///         CrdtColumn.text('id', nullable: false),
///         CrdtColumn.text('name', nullable: false),
///         CrdtColumn.text('email'),
///       ],
///       fromJson: User.fromJson,
///       toJson: (u) => u.toJson(),
///       getId: (u) => u.id,
///     ),
///     CrdtTableConfig<Post, String>(
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
///
/// // Attach peer connector for sync
/// final connector = CrdtMemoryConnector();
/// manager.attachConnector(connector);
/// await connector.connect();
/// ```
class CrdtManager {
  CrdtManager._({
    required List<CrdtTableConfig<dynamic, dynamic>> tables,
    String? databasePath,
  })  : _tables = tables,
        _databasePath = databasePath;

  /// Creates a [CrdtManager] with automatic database setup.
  ///
  /// - [tables]: List of table configurations for all tables.
  /// - [databasePath]: Optional database file path. Uses in-memory if null.
  factory CrdtManager.withDatabase({
    required List<CrdtTableConfig<dynamic, dynamic>> tables,
    String? databasePath,
  }) =>
      CrdtManager._(
        tables: tables,
        databasePath: databasePath,
      );

  /// Creates a [CrdtManager] with a pre-configured database wrapper.
  ///
  /// This is primarily for testing, allowing injection of a mock wrapper.
  factory CrdtManager.withWrapper({
    required CrdtDatabaseWrapper db,
    required List<CrdtTableConfig<dynamic, dynamic>> tables,
  }) {
    final manager = CrdtManager._(tables: tables)
      .._db = db
      .._useExternalDb = true;
    return manager;
  }

  final List<CrdtTableConfig<dynamic, dynamic>> _tables;
  final String? _databasePath;
  final Map<String, CrdtBackend<dynamic, dynamic>> _backends = {};
  CrdtDatabaseWrapper? _db;
  bool _initialized = false;
  bool _useExternalDb = false;

  CrdtPeerConnector? _connector;
  StreamSubscription<CrdtChangesetMessage>? _incomingSubscription;

  /// Whether the manager has been initialized.
  bool get isInitialized => _initialized;

  /// List of all table names.
  List<String> get tableNames => _tables.map((t) => t.tableName).toList();

  /// The unique node ID for this CRDT instance.
  ///
  /// Returns null if not yet initialized.
  String? get nodeId => _db?.nodeId;

  /// The attached peer connector, if any.
  CrdtPeerConnector? get connector => _connector;

  /// Initializes the database and creates all table schemas.
  ///
  /// This must be called before accessing any backends.
  Future<void> initialize() async {
    if (_initialized) return;

    if (!_useExternalDb) {
      // Create database
      final SqliteCrdt crdt;
      if (_databasePath != null) {
        crdt = await SqliteCrdt.open(
          _databasePath,
          version: 1,
          onCreate: _createTables,
        );
      } else {
        crdt = await SqliteCrdt.openInMemory(
          version: 1,
          onCreate: _createTables,
        );
      }
      _db = DefaultCrdtDatabaseWrapper(crdt);
    }

    // Create backends for each table
    for (final config in _tables) {
      final backend = _createBackend(config);
      await backend.initializeWithWrapper(_db!);
      _backends[config.tableName] = backend;
    }

    _initialized = true;
  }

  Future<void> _createTables(CrdtTableExecutor crdt, int version) async {
    for (final config in _tables) {
      final definition = config.toTableDefinition();
      await crdt.execute(definition.toCreateTableSql());

      // Create indexes
      for (final indexSql in definition.toCreateIndexSql()) {
        await crdt.execute(indexSql);
      }
    }
  }

  /// Gets a backend by table name.
  ///
  /// The returned backend uses dynamic types internally but works correctly
  /// with the serialization functions provided in the table config.
  ///
  /// Throws [StateError] if:
  /// - The manager has not been initialized
  /// - The table name is not found
  CrdtBackend<dynamic, dynamic> getBackend(String tableName) {
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

  /// Gets all changesets from all tables since the given HLC timestamp.
  ///
  /// If [since] is null, returns all changes (full sync).
  /// Use this to get changes to send to another peer.
  Future<CrdtChangeset> getChangesetForAll({Hlc? since}) async {
    _ensureInitialized();
    return _db!.getChangeset(modifiedAfter: since);
  }

  /// Applies a remote changeset to all tables.
  ///
  /// The sqlite_crdt library handles routing changes to the correct tables
  /// and conflict resolution automatically.
  Future<void> applyChangesetToAll(CrdtChangeset changeset) async {
    _ensureInitialized();
    await _db!.merge(changeset);
  }

  /// Attaches a peer connector for network synchronization.
  ///
  /// Incoming changesets from the connector will be automatically applied
  /// to the database. Call [sendChangeset] to push changes to peers.
  void attachConnector(CrdtPeerConnector connector) {
    _ensureInitialized();

    // Detach existing connector if any
    if (_connector != null) {
      detachConnector();
    }

    _connector = connector;

    // Listen for incoming changesets
    _incomingSubscription = connector.incomingChangesets.listen(
      _handleIncomingChangeset,
    );
  }

  /// Detaches the current peer connector.
  void detachConnector() {
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    _connector = null;
  }

  /// Sends all changes since [since] to connected peers.
  ///
  /// Returns the changeset that was sent.
  Future<CrdtChangeset> sendChangeset({Hlc? since}) async {
    _ensureInitialized();

    final changeset = await getChangesetForAll(since: since);

    if (_connector != null) {
      final message = CrdtChangesetMessage(
        sourceNodeId: nodeId!,
        payload: _changesetToPayload(changeset),
      );
      await _connector!.sendChangeset(message);
    }

    return changeset;
  }

  Future<void> _handleIncomingChangeset(CrdtChangesetMessage message) async {
    if (!_initialized) return;

    final changeset = _payloadToChangeset(message.payload);
    await applyChangesetToAll(changeset);
  }

  Map<String, dynamic> _changesetToPayload(CrdtChangeset changeset) {
    // CrdtChangeset is a Map<String, dynamic> internally
    // The keys are table names, values are lists of records
    final payload = <String, dynamic>{};
    for (final entry in changeset.entries) {
      payload[entry.key] = entry.value.map(Map<String, dynamic>.from).toList();
    }
    return payload;
  }

  CrdtChangeset _payloadToChangeset(Map<String, dynamic> payload) {
    final changeset = <String, List<Map<String, dynamic>>>{};
    for (final entry in payload.entries) {
      final records = (entry.value as List)
          .map((r) => _convertHlcStrings(Map<String, dynamic>.from(r as Map)))
          .toList();
      changeset[entry.key] = records;
    }
    return changeset;
  }

  /// Converts HLC string fields back to Hlc objects.
  ///
  /// The sqlite_crdt library expects 'hlc' and 'modified' fields to be
  /// [Hlc] objects, not strings.
  Map<String, dynamic> _convertHlcStrings(Map<String, dynamic> record) {
    final result = Map<String, dynamic>.from(record);
    for (final key in ['hlc', 'modified']) {
      if (result[key] is String) {
        result[key] = Hlc.parse(result[key] as String);
      }
    }
    return result;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Manager not initialized. Call initialize() first.',
      );
    }
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    detachConnector();

    for (final backend in _backends.values) {
      await backend.close();
    }
    _backends.clear();

    if (!_useExternalDb) {
      await _db?.close();
    }
    _db = null;
    _initialized = false;
  }

  CrdtBackend<dynamic, dynamic> _createBackend(
    CrdtTableConfig<dynamic, dynamic> config,
  ) {
    // Use the config's dynamic wrappers to bypass type contravariance
    final wrappedGetId = config.dynamicGetId;
    final wrappedFromJson = config.dynamicFromJson;
    final wrappedToJson = config.dynamicToJson;

    return CrdtBackend<dynamic, dynamic>(
      tableName: config.tableName,
      getId: wrappedGetId,
      fromJson: wrappedFromJson,
      toJson: wrappedToJson,
      primaryKeyField: config.primaryKeyColumn,
      fieldMapping: config.fieldMapping,
    );
  }
}
