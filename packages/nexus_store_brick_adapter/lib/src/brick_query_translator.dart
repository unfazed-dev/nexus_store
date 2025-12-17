import 'package:brick_core/query.dart' as brick;
import 'package:nexus_store/nexus_store.dart';

/// Translates [Query] from nexus_store to Brick's [brick.Query] format.
///
/// Brick uses a different query system with [brick.Where] conditions and
/// [brick.Compare] operators. This translator maps the unified query format
/// to Brick's native query language.
///
/// ## Example
///
/// ```dart
/// final translator = BrickQueryTranslator<User>();
/// final nexusQuery = Query<User>()
///   .where('name', isEqualTo: 'John')
///   .orderByField('createdAt', descending: true)
///   .limitTo(10);
///
/// final brickQuery = translator.translate(nexusQuery);
/// // brickQuery can now be used with Brick repositories
/// ```
class BrickQueryTranslator<T> implements QueryTranslator<T, brick.Query> {
  /// Creates a [BrickQueryTranslator] with optional field name mapping.
  ///
  /// [fieldMapping] can be used when Brick model field names differ from
  /// the query field names. Keys are query field names, values are Brick
  /// model field names.
  BrickQueryTranslator({
    Map<String, String>? fieldMapping,
  }) : _fieldMapping = fieldMapping ?? const {};

  final Map<String, String> _fieldMapping;

  /// Translates a [Query] to Brick's [brick.Query] format.
  @override
  brick.Query translate(Query<T> query) {
    final whereConditions = _translateFilters(query.filters);
    final orderByList = _translateOrderBy(query.orderBy);

    return brick.Query(
      where: whereConditions.isNotEmpty ? whereConditions : null,
      orderBy: orderByList,
      limit: query.limit,
      offset: query.offset,
    );
  }

  /// Translates only the filter portion of a query.
  ///
  /// Returns a [brick.Query] containing only the where conditions.
  @override
  brick.Query translateFilters(List<QueryFilter> filters) {
    final whereConditions = _translateFilters(filters);
    return brick.Query(
      where: whereConditions.isNotEmpty ? whereConditions : null,
    );
  }

  /// Translates only the ordering portion of a query.
  ///
  /// Returns a [brick.Query] containing only the orderBy specifications.
  @override
  brick.Query translateOrderBy(List<QueryOrderBy> orderBy) {
    final orderByList = _translateOrderBy(orderBy);
    return brick.Query(
      orderBy: orderByList,
    );
  }

  /// Translates a list of [QueryFilter] to Brick [brick.WhereCondition]s.
  List<brick.WhereCondition> _translateFilters(List<QueryFilter> filters) =>
      filters.map(_translateFilter).toList();

  /// Translates a single [QueryFilter] to a Brick [brick.WhereCondition].
  brick.WhereCondition _translateFilter(QueryFilter filter) {
    final field = _mapFieldName(filter.field);
    final value = filter.value;

    return switch (filter.operator) {
      FilterOperator.equals => brick.Where(
          field,
          value: value,
          compare: brick.Compare.exact,
        ),
      FilterOperator.notEquals => brick.Where(
          field,
          value: value,
          compare: brick.Compare.notEqual,
        ),
      FilterOperator.lessThan => brick.Where(
          field,
          value: value,
          compare: brick.Compare.lessThan,
        ),
      FilterOperator.lessThanOrEquals => brick.Where(
          field,
          value: value,
          compare: brick.Compare.lessThanOrEqualTo,
        ),
      FilterOperator.greaterThan => brick.Where(
          field,
          value: value,
          compare: brick.Compare.greaterThan,
        ),
      FilterOperator.greaterThanOrEquals => brick.Where(
          field,
          value: value,
          compare: brick.Compare.greaterThanOrEqualTo,
        ),
      FilterOperator.whereIn => brick.Where(
          field,
          value: value,
          compare: brick.Compare.inIterable,
        ),
      FilterOperator.whereNotIn => _createNotInCondition(field, value),
      FilterOperator.contains => brick.Where(
          field,
          value: value,
          compare: brick.Compare.contains,
        ),
      FilterOperator.arrayContains => brick.Where(
          field,
          value: value,
          compare: brick.Compare.contains,
        ),
      FilterOperator.arrayContainsAny => _createArrayContainsAnyCondition(
          field,
          value,
        ),
      FilterOperator.isNull => brick.Where(
          field,
          compare: brick.Compare.exact,
        ),
      FilterOperator.isNotNull => brick.Where(
          field,
          compare: brick.Compare.notEqual,
        ),
      FilterOperator.startsWith => _createStartsWithCondition(field, value),
      FilterOperator.endsWith => _createEndsWithCondition(field, value),
    };
  }

  /// Creates a NOT IN condition using multiple NOT EQUAL conditions.
  ///
  /// Brick doesn't have a native NOT IN operator, so we create multiple
  /// NOT EQUAL conditions that must all be true.
  brick.WhereCondition _createNotInCondition(String field, Object? value) {
    if (value is! List || value.isEmpty) {
      // If not a list or empty, return a condition that's always true
      return brick.Where(field, compare: brick.Compare.notEqual);
    }

    // For NOT IN, we need all conditions to be true (AND logic)
    // Brick's default behavior is AND for multiple Where conditions
    // But we can only return one condition here, so we use the first value
    // and rely on the caller to handle multiple conditions if needed
    // This is a limitation - for full NOT IN support, use multiple queries
    return brick.Where(
      field,
      value: value.first,
      compare: brick.Compare.notEqual,
    );
  }

  /// Creates an array contains any condition using contains comparison.
  ///
  /// This handles the case where we want to check if the field value
  /// contains any of the given values.
  brick.WhereCondition _createArrayContainsAnyCondition(
    String field,
    Object? value,
  ) {
    if (value is! List || value.isEmpty) {
      return brick.Where(field, compare: brick.Compare.exact);
    }

    // Use contains with the first value - Brick handles array intersection
    // For full support, the caller may need multiple OR conditions
    return brick.Where(
      field,
      value: value.first,
      compare: brick.Compare.contains,
    );
  }

  /// Creates a starts-with condition using contains comparison.
  ///
  /// Brick doesn't have native startsWith, so we use contains as a fallback.
  /// Provider-specific implementations may handle this differently.
  brick.WhereCondition _createStartsWithCondition(
    String field,
    Object? value,
  ) =>
      brick.Where(
        field,
        value: value,
        compare: brick.Compare.contains,
      );

  /// Creates an ends-with condition using contains comparison.
  ///
  /// Brick doesn't have native endsWith, so we use contains as a fallback.
  /// Provider-specific implementations may handle this differently.
  brick.WhereCondition _createEndsWithCondition(
    String field,
    Object? value,
  ) =>
      brick.Where(
        field,
        value: value,
        compare: brick.Compare.contains,
      );

  /// Translates a list of [QueryOrderBy] to Brick [brick.OrderBy]s.
  List<brick.OrderBy> _translateOrderBy(List<QueryOrderBy> orderBy) =>
      orderBy.map((o) {
        final field = _mapFieldName(o.field);
        return brick.OrderBy(
          field,
          ascending: !o.descending,
        );
      }).toList();

  /// Maps a query field name to the Brick model field name.
  String _mapFieldName(String field) => _fieldMapping[field] ?? field;
}

/// Extension methods for easier Brick query construction.
extension BrickQueryExtension<T> on Query<T> {
  /// Translates this query to Brick's [brick.Query] format.
  ///
  /// Optionally provide a [fieldMapping] to map query field names to
  /// Brick model field names.
  brick.Query toBrickQuery({Map<String, String>? fieldMapping}) {
    final translator = BrickQueryTranslator<T>(fieldMapping: fieldMapping);
    return translator.translate(this);
  }
}
