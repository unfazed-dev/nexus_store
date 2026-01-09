/// Represents a SELECT query for PowerSync sync rules.
///
/// Use the [PSQuery.select] factory to create queries for bucket definitions.
///
/// Example:
/// ```dart
/// final query = PSQuery.select(
///   table: 'users',
///   columns: ['id', 'name', 'email'],
///   filter: 'id = bucket.user_id',
/// );
/// ```
class PSQuery {
  /// Creates a SELECT query for PowerSync sync rules.
  ///
  /// - [table]: The table name to query.
  /// - [columns]: Columns to select. Defaults to all columns (`*`).
  /// - [filter]: Optional WHERE clause (e.g., `id = bucket.user_id`).
  const PSQuery.select({
    required this.table,
    this.columns = const ['*'],
    this.filter,
  });

  /// The table name to select from.
  final String table;

  /// The columns to select. Defaults to `['*']` for all columns.
  final List<String> columns;

  /// Optional WHERE clause filter. Uses PowerSync bucket parameters.
  final String? filter;

  /// Generates the SQL SELECT statement for this query.
  ///
  /// Returns a string like:
  /// - `SELECT * FROM users`
  /// - `SELECT id, name FROM users WHERE id = bucket.user_id`
  String toSql() {
    final columnsStr = columns.join(', ');
    final selectClause = 'SELECT $columnsStr FROM $table';

    if (filter != null) {
      return '$selectClause WHERE $filter';
    }

    return selectClause;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PSQuery) return false;

    return other.table == table &&
        _listEquals(other.columns, columns) &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(table, Object.hashAll(columns), filter);

  @override
  String toString() =>
      'PSQuery.select(table: $table, columns: $columns, filter: $filter)';
}

/// Helper function to compare lists for equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
