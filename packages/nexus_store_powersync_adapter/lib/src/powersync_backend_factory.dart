import 'package:nexus_store_powersync_adapter/src/column_definition.dart';
import 'package:powersync/powersync.dart' as ps;

/// Configuration for creating a PowerSync backend.
///
/// This encapsulates all the configuration needed to create a PowerSync backend
/// that connects to Supabase for authentication and data synchronization.
///
/// Example:
/// ```dart
/// final config = PowerSyncBackendConfig<User, String>(
///   tableName: 'users',
///   columns: [
///     PSColumn.text('name'),
///     PSColumn.text('email'),
///     PSColumn.integer('age'),
///   ],
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
///   powerSyncUrl: 'https://xxx.powersync.co',
/// );
/// ```
class PowerSyncBackendConfig<T, ID> {
  /// Creates a new backend configuration.
  const PowerSyncBackendConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    required this.powerSyncUrl,
    this.dbPath,
    this.primaryKeyColumn = 'id',
  });

  /// The name of the table in the database.
  final String tableName;

  /// The column definitions for this table.
  final List<PSColumn> columns;

  /// Function to deserialize an entity from JSON.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Function to serialize an entity to JSON.
  final Map<String, dynamic> Function(T item) toJson;

  /// Function to extract the ID from an entity.
  final ID Function(T item) getId;

  /// The PowerSync service URL.
  final String powerSyncUrl;

  /// Optional custom database file path.
  ///
  /// If not provided, a default path will be generated.
  final String? dbPath;

  /// The name of the primary key column (default: 'id').
  final String primaryKeyColumn;

  /// Creates a [PSTableDefinition] from this configuration.
  PSTableDefinition toTableDefinition() => PSTableDefinition(
        tableName: tableName,
        columns: columns,
      );

  /// Creates a PowerSync [Schema] from this configuration.
  ps.Schema toSchema() => toTableDefinition().toSchema();
}
