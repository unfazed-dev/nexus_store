import 'package:nexus_store/src/query/query.dart';

/// Abstract interface for translating [Query] to backend-specific formats.
///
/// Each backend adapter implements this to convert the unified query format
/// to its native query language (SQL, Supabase PostgREST, etc.).
///
/// ## Example Implementation
///
/// ```dart
/// class DriftQueryTranslator<T> implements QueryTranslator<T, Expression<bool>> {
///   @override
///   Expression<bool> translate(Query<T> query) {
///     // Convert Query filters to Drift expressions
///   }
/// }
/// ```
abstract interface class QueryTranslator<T, R> {
  /// Translates a [Query] to the backend-specific format [R].
  R translate(Query<T> query);

  /// Translates only the filter portion of a query.
  R translateFilters(List<QueryFilter> filters);

  /// Translates only the ordering portion of a query.
  R translateOrderBy(List<QueryOrderBy> orderBy);
}

/// Mixin providing SQL-like query translation helpers.
///
/// Useful for backends that use SQL-like syntax (Drift, raw SQLite).
mixin SqlQueryTranslatorMixin<T> {
  /// Converts a [FilterOperator] to its SQL equivalent.
  String operatorToSql(FilterOperator op) => switch (op) {
        FilterOperator.equals => '=',
        FilterOperator.notEquals => '!=',
        FilterOperator.lessThan => '<',
        FilterOperator.lessThanOrEquals => '<=',
        FilterOperator.greaterThan => '>',
        FilterOperator.greaterThanOrEquals => '>=',
        FilterOperator.isNull => 'IS NULL',
        FilterOperator.isNotNull => 'IS NOT NULL',
        FilterOperator.whereIn => 'IN',
        FilterOperator.whereNotIn => 'NOT IN',
        FilterOperator.contains => 'LIKE',
        FilterOperator.startsWith => 'LIKE',
        FilterOperator.endsWith => 'LIKE',
        FilterOperator.arrayContains => 'LIKE',
        FilterOperator.arrayContainsAny => 'LIKE',
      };

  /// Escapes a string value for SQL.
  String escapeSqlString(String value) => value.replaceAll("'", "''");

  /// Formats a value for SQL based on its type.
  String formatSqlValue(Object? value) {
    if (value == null) return 'NULL';
    if (value is String) return "'${escapeSqlString(value)}'";
    if (value is bool) return value ? '1' : '0';
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is List) {
      final formatted = value.map(formatSqlValue).join(', ');
      return '($formatted)';
    }
    return value.toString();
  }
}
