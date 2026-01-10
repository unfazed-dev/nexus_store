/// Enum representing CRDT/SQLite column types.
enum CrdtColumnType {
  /// TEXT column type for strings.
  text,

  /// INTEGER column type for whole numbers.
  integer,

  /// REAL column type for floating-point numbers.
  real,

  /// BLOB column type for binary data.
  blob,
}

/// Reserved SQL keywords that cannot be used as column names.
const _reservedKeywords = {
  'select',
  'from',
  'where',
  'insert',
  'update',
  'delete',
  'create',
  'drop',
  'table',
  'index',
  'primary',
  'key',
  'foreign',
  'references',
  'null',
  'not',
  'and',
  'or',
  'order',
  'by',
  'group',
  'having',
  'limit',
  'offset',
  'join',
  'left',
  'right',
  'inner',
  'outer',
  'on',
  'as',
  'distinct',
  'all',
  'union',
  'except',
  'intersect',
  'case',
  'when',
  'then',
  'else',
  'end',
  'like',
  'in',
  'between',
  'is',
  'exists',
  'cast',
  'default',
  'constraint',
  'unique',
  'check',
  'values',
  'set',
  'into',
  'alter',
  'add',
  'column',
  'rename',
  'to',
  'trigger',
  'view',
  'if',
  'begin',
  'commit',
  'rollback',
  'transaction',
  'true',
  'false',
};

/// A type-safe column definition for CRDT/SQLite tables.
///
/// Use the factory constructors to create columns:
/// ```dart
/// CrdtColumn.text('name')
/// CrdtColumn.integer('age', nullable: true)
/// CrdtColumn.real('price', defaultValue: 0.0)
/// CrdtColumn.blob('data')
/// ```
class CrdtColumn {
  const CrdtColumn._({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
  });

  /// Creates a TEXT column.
  ///
  /// Example:
  /// ```dart
  /// CrdtColumn.text('name')
  /// CrdtColumn.text('status', nullable: false, defaultValue: 'active')
  /// ```
  factory CrdtColumn.text(
    String name, {
    bool nullable = true,
    String? defaultValue,
  }) {
    _validateColumnName(name);
    return CrdtColumn._(
      name: name,
      type: CrdtColumnType.text,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates an INTEGER column.
  ///
  /// Example:
  /// ```dart
  /// CrdtColumn.integer('age')
  /// CrdtColumn.integer('count', defaultValue: 0)
  /// ```
  factory CrdtColumn.integer(
    String name, {
    bool nullable = true,
    int? defaultValue,
  }) {
    _validateColumnName(name);
    return CrdtColumn._(
      name: name,
      type: CrdtColumnType.integer,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a REAL (floating-point) column.
  ///
  /// Example:
  /// ```dart
  /// CrdtColumn.real('price')
  /// CrdtColumn.real('amount', defaultValue: 0.0)
  /// ```
  factory CrdtColumn.real(
    String name, {
    bool nullable = true,
    double? defaultValue,
  }) {
    _validateColumnName(name);
    return CrdtColumn._(
      name: name,
      type: CrdtColumnType.real,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a BLOB column for binary data.
  ///
  /// Example:
  /// ```dart
  /// CrdtColumn.blob('data')
  /// CrdtColumn.blob('image', nullable: true)
  /// ```
  factory CrdtColumn.blob(
    String name, {
    bool nullable = true,
  }) {
    _validateColumnName(name);
    return CrdtColumn._(
      name: name,
      type: CrdtColumnType.blob,
      nullable: nullable,
    );
  }

  /// The column name.
  final String name;

  /// The column type.
  final CrdtColumnType type;

  /// Whether the column allows null values.
  final bool nullable;

  /// The default value for the column.
  final Object? defaultValue;

  /// Validates a column name.
  static void _validateColumnName(String name) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Column name cannot be empty');
    }

    if (name.contains(' ')) {
      throw ArgumentError.value(
        name,
        'name',
        'Column name cannot contain spaces',
      );
    }

    if (_reservedKeywords.contains(name.toLowerCase())) {
      throw ArgumentError.value(
        name,
        'name',
        '"$name" is a reserved SQL keyword',
      );
    }
  }

  /// Generates the SQL column definition.
  ///
  /// Returns a string like `"name" TEXT NOT NULL` or `"age" INTEGER DEFAULT 0`.
  String toSqlDefinition() {
    final buffer = StringBuffer('"$name" ');

    // Map type to SQLite type
    switch (type) {
      case CrdtColumnType.text:
        buffer.write('TEXT');
      case CrdtColumnType.integer:
        buffer.write('INTEGER');
      case CrdtColumnType.real:
        buffer.write('REAL');
      case CrdtColumnType.blob:
        buffer.write('BLOB');
    }

    // Add NOT NULL constraint if not nullable
    if (!nullable) {
      buffer.write(' NOT NULL');
    }

    // Add default value if specified
    if (defaultValue != null) {
      buffer.write(' DEFAULT ');
      switch (type) {
        case CrdtColumnType.text:
          // Quote string values
          buffer.write("'$defaultValue'");
        case CrdtColumnType.integer:
        case CrdtColumnType.real:
          buffer.write(defaultValue);
        case CrdtColumnType.blob: // coverage:ignore-line
          // Blob doesn't support default values in this impl
          break;
      }
    }

    return buffer.toString();
  }
}

/// An index definition for CRDT/SQLite tables.
///
/// Example:
/// ```dart
/// final index = CrdtIndex(
///   name: 'idx_users_email',
///   columns: ['email'],
///   unique: true,
/// );
/// ```
class CrdtIndex {
  /// Creates an index definition.
  const CrdtIndex({
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
      other is CrdtIndex &&
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
/// final definition = CrdtTableDefinition(
///   tableName: 'users',
///   columns: [
///     CrdtColumn.text('id', nullable: false),
///     CrdtColumn.text('name', nullable: false),
///     CrdtColumn.text('email'),
///   ],
///   primaryKeyColumn: 'id',
///   indexes: [
///     CrdtIndex(name: 'idx_users_email', columns: ['email']),
///   ],
/// );
///
/// final createTableSql = definition.toCreateTableSql();
/// ```
class CrdtTableDefinition {
  /// Creates a table definition.
  const CrdtTableDefinition({
    required this.tableName,
    required this.columns,
    required this.primaryKeyColumn,
    this.indexes,
  });

  /// The table name.
  final String tableName;

  /// The column definitions.
  final List<CrdtColumn> columns;

  /// The primary key column name.
  final String primaryKeyColumn;

  /// Optional indexes for the table.
  final List<CrdtIndex>? indexes;

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
  List<String> toCreateIndexSql() =>
      indexes?.map((i) => i.toSql(tableName)).toList() ?? [];
}
