import 'package:nexus_store_powersync_adapter/src/column_definition.dart';

/// Configuration for a single table in a multi-table PowerSync setup.
///
/// Use this class with [PowerSyncManager] to configure multiple tables
/// that share a single PowerSync database connection.
///
/// Example:
/// ```dart
/// final userConfig = PSTableConfig<User, String>(
///   tableName: 'users',
///   columns: [
///     PSColumn.text('name'),
///     PSColumn.text('email'),
///   ],
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
/// );
/// ```
class PSTableConfig<T, ID> {
  /// Creates a table configuration.
  ///
  /// - [tableName]: The name of the table in the database.
  /// - [columns]: The column definitions for the table.
  /// - [fromJson]: Function to deserialize JSON to the entity type.
  /// - [toJson]: Function to serialize the entity to JSON.
  /// - [getId]: Function to extract the ID from an entity.
  /// - [primaryKeyColumn]: The primary key column name (defaults to 'id').
  /// - [fieldMapping]: Optional field name mapping for queries.
  /// - [localOnly]: If true, the table is local-only and won't sync to the
  ///   backend. Use this for device-local settings, caches, or UI state that
  ///   should not be uploaded to the server.
  const PSTableConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    this.primaryKeyColumn = 'id',
    this.fieldMapping,
    this.localOnly = false,
  });

  /// The name of the table in the database.
  final String tableName;

  /// The column definitions for the table.
  final List<PSColumn> columns;

  /// Function to deserialize JSON to the entity type.
  final T Function(Map<String, dynamic>) fromJson;

  /// Function to serialize the entity to JSON.
  final Map<String, dynamic> Function(T) toJson;

  /// Function to extract the ID from an entity.
  final ID Function(T) getId;

  /// The primary key column name (defaults to 'id').
  final String primaryKeyColumn;

  /// Optional field name mapping for queries.
  final Map<String, String>? fieldMapping;

  /// Whether this table is local-only (not synced to the backend).
  ///
  /// When true, data in this table will only be stored locally and will not
  /// be uploaded to the PowerSync backend or Supabase. Use this for:
  /// - Device-local UI state (e.g., collapse/expand preferences)
  /// - Local caches
  /// - Settings that should not sync across devices
  final bool localOnly;

  /// Converts this configuration to a [PSTableDefinition].
  PSTableDefinition toTableDefinition() => PSTableDefinition(
        tableName: tableName,
        columns: columns,
        localOnly: localOnly,
      );
}
