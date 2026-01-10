/// Enum representing PostgreSQL column types for Supabase.
enum SupabaseColumnType {
  /// TEXT column type for strings.
  text,

  /// INTEGER column type for 32-bit whole numbers.
  integer,

  /// BIGINT column type for 64-bit whole numbers.
  bigint,

  /// FLOAT8 (double precision) column type for floating-point numbers.
  float8,

  /// BOOLEAN column type.
  boolean,

  /// TIMESTAMPTZ column type for timestamps with timezone.
  timestamptz,

  /// UUID column type.
  uuid,

  /// JSONB column type for JSON data.
  jsonb,
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

/// A type-safe column definition for PostgreSQL/Supabase tables.
///
/// Use the factory constructors to create columns:
/// ```dart
/// SupabaseColumn.text('name')
/// SupabaseColumn.uuid('id', nullable: false)
/// SupabaseColumn.timestamptz('created_at', defaultNow: true)
/// SupabaseColumn.jsonb('metadata', nullable: true)
/// ```
class SupabaseColumn {
  const SupabaseColumn._({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
    this.defaultNow = false,
    this.defaultGenerate = false,
  });

  /// Creates a TEXT column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.text('name')
  /// SupabaseColumn.text('status', nullable: false, defaultValue: 'active')
  /// ```
  factory SupabaseColumn.text(
    String name, {
    bool nullable = true,
    String? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.text,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates an INTEGER column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.integer('count')
  /// SupabaseColumn.integer('count', defaultValue: 0)
  /// ```
  factory SupabaseColumn.integer(
    String name, {
    bool nullable = true,
    int? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.integer,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a BIGINT column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.bigint('big_id')
  /// SupabaseColumn.bigint('timestamp_ms', nullable: false)
  /// ```
  factory SupabaseColumn.bigint(
    String name, {
    bool nullable = true,
    int? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.bigint,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a FLOAT8 (double precision) column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.float8('price')
  /// SupabaseColumn.float8('amount', defaultValue: 0.0)
  /// ```
  factory SupabaseColumn.float8(
    String name, {
    bool nullable = true,
    double? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.float8,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a BOOLEAN column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.boolean('active')
  /// SupabaseColumn.boolean('enabled', defaultValue: true)
  /// ```
  factory SupabaseColumn.boolean(
    String name, {
    bool nullable = true,
    bool? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.boolean,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a TIMESTAMPTZ column.
  ///
  /// Use [defaultNow] to set the default to `now()`.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.timestamptz('created_at')
  /// SupabaseColumn.timestamptz('created_at', defaultNow: true)
  /// ```
  factory SupabaseColumn.timestamptz(
    String name, {
    bool nullable = true,
    bool defaultNow = false,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.timestamptz,
      nullable: nullable,
      defaultNow: defaultNow,
    );
  }

  /// Creates a UUID column.
  ///
  /// Use [defaultGenerate] to set the default to `gen_random_uuid()`.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.uuid('id', nullable: false)
  /// SupabaseColumn.uuid('id', defaultGenerate: true)
  /// ```
  factory SupabaseColumn.uuid(
    String name, {
    bool nullable = true,
    bool defaultGenerate = false,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.uuid,
      nullable: nullable,
      defaultGenerate: defaultGenerate,
    );
  }

  /// Creates a JSONB column.
  ///
  /// Example:
  /// ```dart
  /// SupabaseColumn.jsonb('metadata')
  /// SupabaseColumn.jsonb('metadata', defaultValue: "'{}'::jsonb")
  /// ```
  factory SupabaseColumn.jsonb(
    String name, {
    bool nullable = true,
    String? defaultValue,
  }) {
    _validateColumnName(name);
    return SupabaseColumn._(
      name: name,
      type: SupabaseColumnType.jsonb,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// The column name.
  final String name;

  /// The column type.
  final SupabaseColumnType type;

  /// Whether the column allows null values.
  final bool nullable;

  /// The default value for the column.
  final Object? defaultValue;

  /// Whether to use `now()` as the default value (for timestamptz).
  final bool defaultNow;

  /// Whether to use `gen_random_uuid()` as the default value (for uuid).
  final bool defaultGenerate;

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
  /// Returns a string like `"name" TEXT NOT NULL` or
  /// `"id" UUID DEFAULT gen_random_uuid()`.
  String toSqlDefinition() {
    final buffer = StringBuffer('"$name" ');

    // Map type to PostgreSQL type
    switch (type) {
      case SupabaseColumnType.text:
        buffer.write('TEXT');
      case SupabaseColumnType.integer:
        buffer.write('INTEGER');
      case SupabaseColumnType.bigint:
        buffer.write('BIGINT');
      case SupabaseColumnType.float8:
        buffer.write('FLOAT8');
      case SupabaseColumnType.boolean:
        buffer.write('BOOLEAN');
      case SupabaseColumnType.timestamptz:
        buffer.write('TIMESTAMPTZ');
      case SupabaseColumnType.uuid:
        buffer.write('UUID');
      case SupabaseColumnType.jsonb:
        buffer.write('JSONB');
    }

    // Add NOT NULL constraint if not nullable
    if (!nullable) {
      buffer.write(' NOT NULL');
    }

    // Add default value if specified
    if (defaultNow) {
      buffer.write(' DEFAULT now()');
    } else if (defaultGenerate) {
      buffer.write(' DEFAULT gen_random_uuid()');
    } else if (defaultValue != null) {
      buffer.write(' DEFAULT ');
      switch (type) {
        case SupabaseColumnType.text:
          // Quote string values
          buffer.write("'$defaultValue'");
        case SupabaseColumnType.boolean:
          buffer.write(defaultValue);
        case SupabaseColumnType.integer:
        case SupabaseColumnType.bigint:
        case SupabaseColumnType.float8:
          buffer.write(defaultValue);
        case SupabaseColumnType.jsonb:
          // JSONB default values are passed as-is (e.g., "'{}'::jsonb")
          buffer.write(defaultValue);
        // coverage:ignore-start
        case SupabaseColumnType.timestamptz:
        case SupabaseColumnType.uuid:
          // These use defaultNow/defaultGenerate instead
          break;
        // coverage:ignore-end
      }
    }

    return buffer.toString();
  }
}

/// An index definition for PostgreSQL/Supabase tables.
///
/// Example:
/// ```dart
/// final index = SupabaseIndex(
///   name: 'idx_users_email',
///   columns: ['email'],
///   unique: true,
/// );
/// ```
class SupabaseIndex {
  /// Creates an index definition.
  const SupabaseIndex({
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
      other is SupabaseIndex &&
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
/// final definition = SupabaseTableDefinition(
///   tableName: 'users',
///   columns: [
///     SupabaseColumn.uuid('id', nullable: false),
///     SupabaseColumn.text('name', nullable: false),
///     SupabaseColumn.text('email'),
///   ],
///   primaryKeyColumn: 'id',
///   enableRLS: true,
/// );
///
/// final createTableSql = definition.toCreateTableSql();
/// ```
class SupabaseTableDefinition {
  /// Creates a table definition.
  const SupabaseTableDefinition({
    required this.tableName,
    required this.columns,
    required this.primaryKeyColumn,
    this.schema = 'public',
    this.indexes,
    this.enableRLS = false,
  });

  /// The table name.
  final String tableName;

  /// The column definitions.
  final List<SupabaseColumn> columns;

  /// The primary key column name.
  final String primaryKeyColumn;

  /// The database schema. Defaults to 'public'.
  final String schema;

  /// Optional indexes for the table.
  final List<SupabaseIndex>? indexes;

  /// Whether to enable Row Level Security on the table.
  final bool enableRLS;

  /// Generates the CREATE TABLE SQL statement.
  ///
  /// Example output:
  /// ```sql
  /// CREATE TABLE IF NOT EXISTS "public"."users" (
  ///   "id" UUID NOT NULL,
  ///   "name" TEXT NOT NULL,
  ///   "email" TEXT,
  ///   PRIMARY KEY ("id")
  /// )
  /// ```
  String toCreateTableSql() {
    final columnDefs = columns.map((c) => c.toSqlDefinition()).join(', ');
    final schemaPrefix = schema == 'public' ? '' : '"$schema".';
    return 'CREATE TABLE IF NOT EXISTS $schemaPrefix"$tableName" '
        '($columnDefs, PRIMARY KEY ("$primaryKeyColumn"))';
  }

  /// Generates all CREATE INDEX SQL statements.
  List<String> toCreateIndexSql() =>
      indexes?.map((i) => i.toSql(tableName)).toList() ?? [];

  /// Generates the ALTER TABLE ENABLE ROW LEVEL SECURITY SQL statement.
  ///
  /// Returns null if RLS is not enabled.
  String? toEnableRLSSql() {
    if (!enableRLS) return null;
    return 'ALTER TABLE "$tableName" ENABLE ROW LEVEL SECURITY';
  }
}
