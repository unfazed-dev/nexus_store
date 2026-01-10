import 'package:nexus_store_supabase_adapter/src/supabase_column.dart';

/// A type-safe table configuration that bundles table metadata with
/// serialization functions for Supabase tables.
///
/// This provides a convenient way to configure a table with all the
/// information needed for CRUD operations, including realtime subscriptions.
///
/// Example:
/// ```dart
/// final config = SupabaseTableConfig<User, String>(
///   tableName: 'users',
///   columns: [
///     SupabaseColumn.uuid('id', nullable: false),
///     SupabaseColumn.text('name', nullable: false),
///     SupabaseColumn.text('email'),
///     SupabaseColumn.timestamptz('created_at', defaultNow: true),
///   ],
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
///   enableRealtime: true,
/// );
/// ```
class SupabaseTableConfig<T, ID> {
  /// Creates a table configuration.
  const SupabaseTableConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    this.primaryKeyColumn = 'id',
    this.schema = 'public',
    this.enableRealtime = false,
    this.fieldMapping,
    this.indexes,
  });

  /// The table name in the database.
  final String tableName;

  /// The column definitions for the table.
  final List<SupabaseColumn> columns;

  /// Function to deserialize a JSON map to an entity.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Function to serialize an entity to a JSON map.
  final Map<String, dynamic> Function(T item) toJson;

  /// Function to extract the ID from an entity.
  final ID Function(T item) getId;

  /// The name of the primary key column. Defaults to 'id'.
  final String primaryKeyColumn;

  /// The database schema. Defaults to 'public'.
  final String schema;

  /// Whether to enable realtime subscriptions for this table.
  final bool enableRealtime;

  /// Optional field mapping from Dart field names to database column names.
  ///
  /// Example: `{'firstName': 'first_name'}` maps the Dart field `firstName`
  /// to the database column `first_name`.
  final Map<String, String>? fieldMapping;

  /// Optional indexes for the table.
  final List<SupabaseIndex>? indexes;

  /// Converts this configuration to a table definition.
  SupabaseTableDefinition toTableDefinition() => SupabaseTableDefinition(
        tableName: tableName,
        columns: columns,
        primaryKeyColumn: primaryKeyColumn,
        schema: schema,
        indexes: indexes,
      );

  /// Returns a dynamically-typed wrapper for [getId].
  ///
  /// This allows the function to be called with dynamic types,
  /// bypassing Dart's type contravariance restrictions.
  // ignore: inference_failure_on_function_return_type
  Object? Function(Object?) get dynamicGetId {
    final fn = getId as Function;
    return (item) => Function.apply(fn, [item]);
  }

  /// Returns a dynamically-typed wrapper for [fromJson].
  // ignore: inference_failure_on_function_return_type
  Object? Function(Map<String, dynamic>) get dynamicFromJson {
    final fn = fromJson as Function;
    return (Map<String, dynamic> json) => Function.apply(fn, [json]);
  }

  /// Returns a dynamically-typed wrapper for [toJson].
  Map<String, dynamic> Function(Object?) get dynamicToJson {
    final fn = toJson as Function;
    return (item) => Function.apply(fn, [item]) as Map<String, dynamic>;
  }
}
