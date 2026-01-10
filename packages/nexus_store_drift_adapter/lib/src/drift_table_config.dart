import 'package:nexus_store_drift_adapter/src/drift_column.dart';

/// An index definition for Drift/SQLite tables.
///
/// Example:
/// ```dart
/// final index = DriftIndex(
///   name: 'idx_users_email',
///   columns: ['email'],
///   unique: true,
/// );
/// ```
class DriftIndex {
  /// Creates an index definition.
  const DriftIndex({
    required this.name,
    required this.columns,
    this.unique = false,
  });

  /// The index name.
  final String name;

  /// The columns to include in the index.
  final List<String> columns;

  /// Whether the index should be unique.
  final bool unique;

  /// Generates the CREATE INDEX SQL statement.
  ///
  /// Example output:
  /// ```sql
  /// CREATE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email")
  /// CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email")
  /// ```
  String toSql(String tableName) {
    final uniqueStr = unique ? 'UNIQUE ' : '';
    final columnsStr = columns.map((c) => '"$c"').join(', ');
    return 'CREATE ${uniqueStr}INDEX IF NOT EXISTS "$name" '
        'ON "$tableName" ($columnsStr)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriftIndex &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(columns, other.columns) &&
          unique == other.unique;

  @override
  int get hashCode => Object.hash(name, Object.hashAll(columns), unique);

  bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A table definition containing the table name, columns, and indexes.
///
/// This is used to generate CREATE TABLE and CREATE INDEX SQL statements.
///
/// Example:
/// ```dart
/// final definition = DriftTableDefinition(
///   tableName: 'users',
///   columns: [
///     DriftColumn.text('id', nullable: false),
///     DriftColumn.text('name', nullable: false),
///     DriftColumn.text('email'),
///   ],
///   primaryKeyColumn: 'id',
///   indexes: [
///     DriftIndex(name: 'idx_users_email', columns: ['email']),
///   ],
/// );
///
/// final createTableSql = definition.toCreateTableSql();
/// ```
class DriftTableDefinition {
  /// Creates a table definition.
  const DriftTableDefinition({
    required this.tableName,
    required this.columns,
    required this.primaryKeyColumn,
    this.indexes,
  });

  /// The table name.
  final String tableName;

  /// The column definitions.
  final List<DriftColumn> columns;

  /// The primary key column name.
  final String primaryKeyColumn;

  /// Optional indexes for the table.
  final List<DriftIndex>? indexes;

  /// Generates the CREATE TABLE SQL statement.
  ///
  /// Example output:
  /// ```sql
  /// CREATE TABLE IF NOT EXISTS "users" (
  ///   "id" TEXT NOT NULL,
  ///   "name" TEXT NOT NULL,
  ///   "email" TEXT,
  ///   PRIMARY KEY ("id")
  /// )
  /// ```
  String toCreateTableSql() {
    final columnDefs = columns.map((c) => c.toSqlDefinition()).join(', ');
    return 'CREATE TABLE IF NOT EXISTS "$tableName" '
        '($columnDefs, PRIMARY KEY ("$primaryKeyColumn"))';
  }

  /// Generates all CREATE INDEX SQL statements.
  List<String> toCreateIndexSql() => indexes?.map((i) => i.toSql(tableName)).toList() ?? [];
}

/// A type-safe table configuration that bundles table metadata with
/// serialization functions.
///
/// This provides a convenient way to configure a table with all the
/// information needed for CRUD operations.
///
/// Example:
/// ```dart
/// final config = DriftTableConfig<User, String>(
///   tableName: 'users',
///   columns: [
///     DriftColumn.text('id', nullable: false),
///     DriftColumn.text('name', nullable: false),
///     DriftColumn.text('email'),
///     DriftColumn.integer('age'),
///   ],
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
/// );
/// ```
class DriftTableConfig<T, ID> {
  /// Creates a table configuration.
  const DriftTableConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    this.primaryKeyColumn = 'id',
    this.fieldMapping,
    this.indexes,
  });

  /// The table name in the database.
  final String tableName;

  /// The column definitions for the table.
  final List<DriftColumn> columns;

  /// Function to deserialize a JSON map to an entity.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Function to serialize an entity to a JSON map.
  final Map<String, dynamic> Function(T item) toJson;

  /// Function to extract the ID from an entity.
  final ID Function(T item) getId;

  /// The name of the primary key column. Defaults to 'id'.
  final String primaryKeyColumn;

  /// Optional field mapping from Dart field names to database column names.
  ///
  /// Example: `{'firstName': 'first_name'}` maps the Dart field `firstName`
  /// to the database column `first_name`.
  final Map<String, String>? fieldMapping;

  /// Optional indexes for the table.
  final List<DriftIndex>? indexes;

  /// Converts this configuration to a table definition.
  DriftTableDefinition toTableDefinition() => DriftTableDefinition(
      tableName: tableName,
      columns: columns,
      primaryKeyColumn: primaryKeyColumn,
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
