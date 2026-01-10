import 'package:powersync/powersync.dart' as ps;

/// Enum representing PowerSync column types.
enum PSColumnType {
  /// Text/string column type.
  text,

  /// Integer column type.
  integer,

  /// Real/floating-point column type.
  real,
}

/// A column definition for PowerSync tables.
///
/// Use the factory constructors to create columns:
/// ```dart
/// PSColumn.text('name')
/// PSColumn.integer('age')
/// PSColumn.real('price')
/// ```
class PSColumn {
  const PSColumn._({
    required this.name,
    required this.type,
    this.nullable = true,
  });

  /// Creates a text column.
  factory PSColumn.text(String name, {bool nullable = true}) =>
      PSColumn._(name: name, type: PSColumnType.text, nullable: nullable);

  /// Creates an integer column.
  factory PSColumn.integer(String name, {bool nullable = true}) =>
      PSColumn._(name: name, type: PSColumnType.integer, nullable: nullable);

  /// Creates a real (floating point) column.
  factory PSColumn.real(String name, {bool nullable = true}) =>
      PSColumn._(name: name, type: PSColumnType.real, nullable: nullable);

  /// The column name.
  final String name;

  /// The column type.
  final PSColumnType type;

  /// Whether the column allows null values.
  final bool nullable;

  /// Converts this column to a PowerSync Column.
  ps.Column toPowerSyncColumn() =>
      ps.Column(name, _toPowerSyncColumnType(type));

  ps.ColumnType _toPowerSyncColumnType(PSColumnType type) {
    switch (type) {
      case PSColumnType.text:
        return ps.ColumnType.text;
      case PSColumnType.integer:
        return ps.ColumnType.integer;
      case PSColumnType.real:
        return ps.ColumnType.real;
    }
  }
}

/// A table definition containing the table name and column definitions.
///
/// Example:
/// ```dart
/// final tableDef = PSTableDefinition(
///   tableName: 'users',
///   columns: [
///     PSColumn.text('name'),
///     PSColumn.integer('age'),
///   ],
/// );
///
/// // Local-only table (not synced to backend)
/// final localTableDef = PSTableDefinition(
///   tableName: 'local_settings',
///   columns: [PSColumn.text('value')],
///   localOnly: true,
/// );
/// ```
class PSTableDefinition {
  /// Creates a table definition with the given name and columns.
  ///
  /// Set [localOnly] to true for tables that should not sync to the backend.
  const PSTableDefinition({
    required this.tableName,
    required this.columns,
    this.localOnly = false,
  });

  /// The table name.
  final String tableName;

  /// The column definitions.
  final List<PSColumn> columns;

  /// Whether this table is local-only (not synced to the backend).
  final bool localOnly;

  /// Generates a PowerSync Table from this definition.
  ///
  /// If [localOnly] is true, creates a local-only table that won't sync
  /// to the PowerSync backend.
  ps.Table toTable() {
    final psColumns = columns.map((c) => c.toPowerSyncColumn()).toList();
    if (localOnly) {
      return ps.Table.localOnly(tableName, psColumns);
    }
    return ps.Table(tableName, psColumns);
  }

  /// Generates a PowerSync Schema containing this table.
  ps.Schema toSchema() => ps.Schema([toTable()]);
}
