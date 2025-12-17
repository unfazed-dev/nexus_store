import 'package:nexus_store/nexus_store.dart';
import 'package:supabase/supabase.dart';

/// Translates [Query] from nexus_store to Supabase PostgREST query format.
///
/// Supabase uses PostgREST under the hood, which provides a RESTful API
/// for PostgreSQL. This translator converts the unified query format
/// to Supabase's filter builder methods.
///
/// ## Example
///
/// ```dart
/// final translator = SupabaseQueryTranslator<User>();
/// final nexusQuery = Query<User>()
///   .where('name', isEqualTo: 'John')
///   .orderByField('createdAt', descending: true)
///   .limitTo(10);
///
/// // Apply translation to Supabase query builder
/// final result = await translator.apply(
///   supabase.from('users').select(),
///   nexusQuery,
/// );
/// ```
class SupabaseQueryTranslator<T> implements QueryTranslator<T, void> {
  /// Creates a [SupabaseQueryTranslator] with optional field name mapping.
  ///
  /// [fieldMapping] can be used when database column names differ from
  /// the query field names. Keys are query field names, values are database
  /// column names.
  SupabaseQueryTranslator({
    Map<String, String>? fieldMapping,
  }) : _fieldMapping = fieldMapping ?? const {};

  final Map<String, String> _fieldMapping;

  /// Translates a [Query] to void - use [apply] instead for Supabase.
  ///
  /// Since Supabase uses a builder pattern that returns different types,
  /// the translation is done via the [apply] method instead.
  @override
  void translate(Query<T> query) {
    // No-op: Use apply methods instead for Supabase
  }

  /// Translates only the filter portion of a query.
  @override
  void translateFilters(List<QueryFilter> filters) {
    // No-op: Use applyFilters instead for Supabase
  }

  /// Translates only the ordering portion of a query.
  @override
  void translateOrderBy(List<QueryOrderBy> orderBy) {
    // No-op: Use applyOrderBy instead for Supabase
  }

  /// Applies all query components to a Supabase [PostgrestFilterBuilder].
  ///
  /// Returns a [PostgrestTransformBuilder] with filters, ordering, and
  /// pagination applied. The result can be awaited to execute the query.
  PostgrestTransformBuilder<List<Map<String, dynamic>>> apply(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    Query<T> query,
  ) {
    final filtered = applyFilters(builder, query.filters);
    final ordered = applyOrderBy(filtered, query.orderBy);
    final paginated = applyPagination(ordered, query);
    return paginated;
  }

  /// Applies filters to a Supabase query builder.
  ///
  /// Translates each [QueryFilter] to the corresponding PostgREST filter.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> applyFilters(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    List<QueryFilter> filters,
  ) {
    var result = builder;

    for (final filter in filters) {
      result = _applyFilter(result, filter);
    }

    return result;
  }

  /// Applies ordering to a Supabase query builder.
  ///
  /// Takes a [PostgrestFilterBuilder] and returns a [PostgrestTransformBuilder]
  /// since `.order()` transforms the builder type.
  PostgrestTransformBuilder<List<Map<String, dynamic>>> applyOrderBy(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    List<QueryOrderBy> orderBy,
  ) {
    if (orderBy.isEmpty) {
      // Return the builder as-is, cast to transform builder
      // The PostgrestFilterBuilder can be used as a PostgrestTransformBuilder
      return builder;
    }

    // Apply first order
    final first = orderBy.first;
    final firstColumn = _mapFieldName(first.field);
    var result = builder.order(firstColumn, ascending: !first.descending);

    // Apply remaining orders
    for (var i = 1; i < orderBy.length; i++) {
      final order = orderBy[i];
      final column = _mapFieldName(order.field);
      result = result.order(column, ascending: !order.descending);
    }

    return result;
  }

  /// Applies pagination (limit/offset) to a Supabase query builder.
  PostgrestTransformBuilder<List<Map<String, dynamic>>> applyPagination(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> builder,
    Query<T> query,
  ) {
    if (query.limit == null && query.offset == null) {
      return builder;
    }

    final from = query.offset ?? 0;
    final to = query.limit != null ? from + query.limit! - 1 : from + 999;
    return builder.range(from, to);
  }

  /// Applies a single filter to the query builder.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyFilter(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    QueryFilter filter,
  ) {
    final column = _mapFieldName(filter.field);
    final value = filter.value;

    return switch (filter.operator) {
      FilterOperator.equals => builder.eq(column, value!),
      FilterOperator.notEquals => builder.neq(column, value!),
      FilterOperator.lessThan => builder.lt(column, value!),
      FilterOperator.lessThanOrEquals => builder.lte(column, value!),
      FilterOperator.greaterThan => builder.gt(column, value!),
      FilterOperator.greaterThanOrEquals => builder.gte(column, value!),
      FilterOperator.whereIn => _applyInFilter(builder, column, value),
      FilterOperator.whereNotIn => _applyNotInFilter(builder, column, value),
      FilterOperator.isNull => builder.isFilter(column, null),
      FilterOperator.isNotNull => builder.not(column, 'is', null),
      FilterOperator.contains => builder.ilike(column, '%$value%'),
      FilterOperator.startsWith => builder.ilike(column, '$value%'),
      FilterOperator.endsWith => builder.ilike(column, '%$value'),
      FilterOperator.arrayContains => builder.contains(column, [value]),
      FilterOperator.arrayContainsAny =>
        _applyArrayContainsAny(builder, column, value),
    };
  }

  /// Applies an IN filter for whereIn operator.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyInFilter(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    String column,
    Object? value,
  ) {
    if (value is! List || value.isEmpty) {
      // Return empty result for empty IN clause
      return builder.eq(column, '__impossible_value__');
    }
    return builder.inFilter(column, value);
  }

  /// Applies a NOT IN filter for whereNotIn operator.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyNotInFilter(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    String column,
    Object? value,
  ) {
    if (value is! List || value.isEmpty) {
      // No exclusions, return as-is
      return builder;
    }
    // Use .not with 'in' operator
    return builder.not(column, 'in', '(${value.join(",")})');
  }

  /// Applies an array contains any filter.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyArrayContainsAny(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    String column,
    Object? value,
  ) {
    if (value is! List || value.isEmpty) {
      return builder;
    }
    // Use overlaps for array contains any
    return builder.overlaps(column, value);
  }

  /// Maps a query field name to the database column name.
  String _mapFieldName(String field) => _fieldMapping[field] ?? field;
}

/// Extension methods for easier Supabase query construction.
extension SupabaseQueryExtension<T> on Query<T> {
  /// Applies this query to a Supabase [PostgrestFilterBuilder].
  ///
  /// Optionally provide a [fieldMapping] to map query field names to
  /// database column names.
  PostgrestTransformBuilder<List<Map<String, dynamic>>> applyToSupabase(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder, {
    Map<String, String>? fieldMapping,
  }) {
    final translator = SupabaseQueryTranslator<T>(fieldMapping: fieldMapping);
    return translator.apply(builder, this);
  }
}
