import 'package:nexus_store/nexus_store.dart';

/// Translates [Query] objects to SQL statements for Drift.
///
/// Drift uses SQLite internally, so this translator generates
/// parameterized SQL queries with proper escaping.
///
/// Example:
/// ```dart
/// final translator = DriftQueryTranslator<User>();
/// final query = Query<User>().where('name', isEqualTo: 'John');
/// final (sql, args) = translator.toSelectSql(
///   tableName: 'users',
///   query: query,
/// );
/// // sql: 'SELECT * FROM users WHERE name = ?'
/// // args: ['John']
/// ```
class DriftQueryTranslator<T>
    with SqlQueryTranslatorMixin<T>
    implements QueryTranslator<T, String> {
  /// Creates a Drift query translator.
  ///
  /// [fieldMapping] - Optional map to translate field names to column names.
  DriftQueryTranslator({
    Map<String, String>? fieldMapping,
  }) : _fieldMapping = fieldMapping ?? const {};

  final Map<String, String> _fieldMapping;

  /// Generates a SELECT SQL statement with optional WHERE, ORDER BY,
  /// LIMIT, and OFFSET clauses.
  ///
  /// Returns a tuple of (sql, arguments) for parameterized query execution.
  (String sql, List<Object?> args) toSelectSql({
    required String tableName,
    Query<T>? query,
  }) {
    final args = <Object?>[];
    final buffer = StringBuffer('SELECT * FROM $tableName');

    if (query != null && query.filters.isNotEmpty) {
      buffer
        ..write(' WHERE ')
        ..write(_buildWhereClause(query.filters, args));
    }

    if (query != null && query.orderBy.isNotEmpty) {
      buffer
        ..write(' ORDER BY ')
        ..write(_buildOrderByClause(query.orderBy));
    }

    if (query?.limit != null) {
      buffer.write(' LIMIT ${query!.limit}');
    }

    if (query?.offset != null) {
      buffer.write(' OFFSET ${query!.offset}');
    }

    return (buffer.toString(), args);
  }

  /// Generates a DELETE SQL statement with optional WHERE clause.
  ///
  /// Returns a tuple of (sql, arguments) for parameterized query execution.
  (String sql, List<Object?> args) toDeleteSql({
    required String tableName,
    required Query<T> query,
  }) {
    final args = <Object?>[];
    final buffer = StringBuffer('DELETE FROM $tableName');

    if (query.filters.isNotEmpty) {
      buffer
        ..write(' WHERE ')
        ..write(_buildWhereClause(query.filters, args));
    }

    return (buffer.toString(), args);
  }

  String _buildWhereClause(List<QueryFilter> filters, List<Object?> args) {
    final conditions = <String>[];

    for (final filter in filters) {
      final column = _mapFieldName(filter.field);
      final condition = _buildCondition(column, filter, args);
      conditions.add(condition);
    }

    return conditions.join(' AND ');
  }

  String _buildCondition(
    String column,
    QueryFilter filter,
    List<Object?> args,
  ) =>
      switch (filter.operator) {
        FilterOperator.equals => _equalCondition(column, filter.value, args),
        FilterOperator.notEquals =>
          _notEqualCondition(column, filter.value, args),
        FilterOperator.lessThan =>
          _comparisonCondition(column, '<', filter.value, args),
        FilterOperator.lessThanOrEquals =>
          _comparisonCondition(column, '<=', filter.value, args),
        FilterOperator.greaterThan =>
          _comparisonCondition(column, '>', filter.value, args),
        FilterOperator.greaterThanOrEquals =>
          _comparisonCondition(column, '>=', filter.value, args),
        FilterOperator.whereIn => _inCondition(column, filter.value, args),
        FilterOperator.whereNotIn =>
          _notInCondition(column, filter.value, args),
        FilterOperator.isNull => '$column IS NULL',
        FilterOperator.isNotNull => '$column IS NOT NULL',
        FilterOperator.contains => _likeCondition(column, filter.value, args),
        FilterOperator.startsWith =>
          _startsWithCondition(column, filter.value, args),
        FilterOperator.endsWith =>
          _endsWithCondition(column, filter.value, args),
        FilterOperator.arrayContains =>
          _likeCondition(column, filter.value, args),
        FilterOperator.arrayContainsAny =>
          _arrayContainsAnyCondition(column, filter.value, args),
      };

  String _equalCondition(String column, Object? value, List<Object?> args) {
    args.add(value);
    return '$column = ?';
  }

  String _notEqualCondition(String column, Object? value, List<Object?> args) {
    args.add(value);
    return '$column != ?';
  }

  String _comparisonCondition(
    String column,
    String op,
    Object? value,
    List<Object?> args,
  ) {
    args.add(value);
    return '$column $op ?';
  }

  String _inCondition(String column, Object? value, List<Object?> args) {
    if (value is! List || value.isEmpty) {
      return '1 = 0'; // Always false for empty IN
    }
    final placeholders = List.filled(value.length, '?').join(', ');
    args.addAll(value);
    return '$column IN ($placeholders)';
  }

  String _notInCondition(String column, Object? value, List<Object?> args) {
    if (value is! List || value.isEmpty) {
      return '1 = 1'; // Always true for empty NOT IN
    }
    final placeholders = List.filled(value.length, '?').join(', ');
    args.addAll(value);
    return '$column NOT IN ($placeholders)';
  }

  String _likeCondition(String column, Object? value, List<Object?> args) {
    args.add('%$value%');
    return '$column LIKE ?';
  }

  String _startsWithCondition(
    String column,
    Object? value,
    List<Object?> args,
  ) {
    args.add('$value%');
    return '$column LIKE ?';
  }

  String _endsWithCondition(String column, Object? value, List<Object?> args) {
    args.add('%$value');
    return '$column LIKE ?';
  }

  String _arrayContainsAnyCondition(
    String column,
    Object? value,
    List<Object?> args,
  ) {
    if (value is! List || value.isEmpty) {
      return '1 = 0';
    }
    // For JSON arrays, use json_each
    final placeholders = List.filled(value.length, '?').join(', ');
    args.addAll(value);
    return 'EXISTS (SELECT 1 FROM json_each($column) WHERE value IN '
        '($placeholders))';
  }

  String _buildOrderByClause(List<QueryOrderBy> orderBy) => orderBy.map((o) {
        final column = _mapFieldName(o.field);
        final direction = o.descending ? 'DESC' : 'ASC';
        return '$column $direction';
      }).join(', ');

  String _mapFieldName(String field) => _fieldMapping[field] ?? field;

  // QueryTranslator interface implementation

  @override
  String translate(Query<T> query) {
    final args = <Object?>[];
    final buffer = StringBuffer();

    if (query.filters.isNotEmpty) {
      buffer
        ..write('WHERE ')
        ..write(_buildWhereClause(query.filters, args));
    }

    if (query.orderBy.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer
        ..write('ORDER BY ')
        ..write(_buildOrderByClause(query.orderBy));
    }

    if (query.limit != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('LIMIT ${query.limit}');
    }

    if (query.offset != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('OFFSET ${query.offset}');
    }

    return buffer.toString();
  }

  @override
  String translateFilters(List<QueryFilter> filters) {
    final args = <Object?>[];
    return _buildWhereClause(filters, args);
  }

  @override
  String translateOrderBy(List<QueryOrderBy> orderBy) =>
      _buildOrderByClause(orderBy);
}

/// Extension methods for easier Drift query construction.
extension DriftQueryExtension<T> on Query<T> {
  /// Translates this query to SQL SELECT statement.
  (String sql, List<Object?> args) toSql(
    String tableName, {
    Map<String, String>? fieldMapping,
  }) {
    final translator = DriftQueryTranslator<T>(fieldMapping: fieldMapping);
    return translator.toSelectSql(tableName: tableName, query: this);
  }
}
