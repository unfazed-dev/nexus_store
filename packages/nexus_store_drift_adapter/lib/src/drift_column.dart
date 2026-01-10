/// Enum representing Drift/SQLite column types.
enum DriftColumnType {
  /// TEXT column type for strings.
  text,

  /// INTEGER column type for whole numbers.
  integer,

  /// REAL column type for floating-point numbers.
  real,

  /// BLOB column type for binary data.
  blob,

  /// BOOLEAN column type (stored as INTEGER 0/1 in SQLite).
  boolean,

  /// DATETIME column type (stored as INTEGER epoch milliseconds in SQLite).
  dateTime,
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

/// A type-safe column definition for Drift/SQLite tables.
///
/// Use the factory constructors to create columns:
/// ```dart
/// DriftColumn.text('name')
/// DriftColumn.integer('age', nullable: true)
/// DriftColumn.real('price', defaultValue: 0.0)
/// DriftColumn.boolean('active', defaultValue: true)
/// DriftColumn.dateTime('createdAt')
/// DriftColumn.blob('data')
/// ```
class DriftColumn {
  const DriftColumn._({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
  });

  /// Creates a TEXT column.
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.text('name')
  /// DriftColumn.text('status', nullable: false, defaultValue: 'active')
  /// ```
  factory DriftColumn.text(
    String name, {
    bool nullable = true,
    String? defaultValue,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.text,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates an INTEGER column.
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.integer('age')
  /// DriftColumn.integer('count', defaultValue: 0)
  /// ```
  factory DriftColumn.integer(
    String name, {
    bool nullable = true,
    int? defaultValue,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.integer,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a REAL (floating-point) column.
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.real('price')
  /// DriftColumn.real('amount', defaultValue: 0.0)
  /// ```
  factory DriftColumn.real(
    String name, {
    bool nullable = true,
    double? defaultValue,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.real,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a BOOLEAN column (stored as INTEGER 0/1 in SQLite).
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.boolean('active')
  /// DriftColumn.boolean('enabled', defaultValue: true)
  /// ```
  factory DriftColumn.boolean(
    String name, {
    bool nullable = true,
    bool? defaultValue,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.boolean,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a DATETIME column (stored as INTEGER epoch milliseconds).
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.dateTime('createdAt')
  /// DriftColumn.dateTime('updatedAt', nullable: true)
  /// ```
  factory DriftColumn.dateTime(
    String name, {
    bool nullable = true,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.dateTime,
      nullable: nullable,
    );
  }

  /// Creates a BLOB column for binary data.
  ///
  /// Example:
  /// ```dart
  /// DriftColumn.blob('data')
  /// DriftColumn.blob('image', nullable: true)
  /// ```
  factory DriftColumn.blob(
    String name, {
    bool nullable = true,
  }) {
    _validateColumnName(name);
    return DriftColumn._(
      name: name,
      type: DriftColumnType.blob,
      nullable: nullable,
    );
  }

  /// The column name.
  final String name;

  /// The column type.
  final DriftColumnType type;

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
      case DriftColumnType.text:
        buffer.write('TEXT');
      case DriftColumnType.integer:
        buffer.write('INTEGER');
      case DriftColumnType.real:
        buffer.write('REAL');
      case DriftColumnType.blob:
        buffer.write('BLOB');
      case DriftColumnType.boolean:
        // SQLite stores booleans as INTEGER 0/1
        buffer.write('INTEGER');
      case DriftColumnType.dateTime:
        // SQLite stores datetime as INTEGER (epoch milliseconds)
        buffer.write('INTEGER');
    }

    // Add NOT NULL constraint if not nullable
    if (!nullable) {
      buffer.write(' NOT NULL');
    }

    // Add default value if specified
    if (defaultValue != null) {
      buffer.write(' DEFAULT ');
      switch (type) {
        case DriftColumnType.text:
          // Quote string values
          buffer.write("'$defaultValue'");
        case DriftColumnType.boolean:
          // Convert boolean to 0/1
          buffer.write((defaultValue! as bool) ? '1' : '0');
        case DriftColumnType.integer:
        case DriftColumnType.real:
          buffer.write(defaultValue);
        // coverage:ignore-start
        case DriftColumnType.blob:
        case DriftColumnType.dateTime:
          // Blob and dateTime don't support default values in this impl
          // These cases are unreachable - factory methods don't allow defaults
          break;
        // coverage:ignore-end
      }
    }

    return buffer.toString();
  }
}
