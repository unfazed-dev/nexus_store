import 'package:meta/meta.dart';

/// Fluent query builder for filtering, sorting, and paginating data.
///
/// Queries are immutable - each method returns a new [Query] instance.
///
/// ## Example
///
/// ```dart
/// final query = Query<User>()
///   .where('status', isEqualTo: 'active')
///   .where('age', isGreaterThan: 18)
///   .orderBy('createdAt', descending: true)
///   .limit(10)
///   .offset(20);
/// ```
@immutable
class Query<T> {
  /// Creates an empty query.
  const Query()
      : _filters = const [],
        _orderBy = const [],
        _limit = null,
        _offset = null;

  const Query._({
    required List<QueryFilter> filters,
    required List<QueryOrderBy> orderBy,
    required int? limit,
    required int? offset,
  })  : _filters = filters,
        _orderBy = orderBy,
        _limit = limit,
        _offset = offset;

  final List<QueryFilter> _filters;
  final List<QueryOrderBy> _orderBy;
  final int? _limit;
  final int? _offset;

  /// The filter conditions for this query.
  List<QueryFilter> get filters => List.unmodifiable(_filters);

  /// The ordering specifications for this query.
  List<QueryOrderBy> get orderBy => List.unmodifiable(_orderBy);

  /// The maximum number of results to return, or `null` for unlimited.
  int? get limit => _limit;

  /// The number of results to skip, or `null` for none.
  int? get offset => _offset;

  // ---------------------------------------------------------------------------
  // Filter Methods
  // ---------------------------------------------------------------------------

  /// Adds an equality filter.
  Query<T> where(
    String field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final newFilters = List<QueryFilter>.from(_filters);

    if (isEqualTo != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.equals, value: isEqualTo),
      );
    }
    if (isNotEqualTo != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.notEquals, value: isNotEqualTo),
      );
    }
    if (isLessThan != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.lessThan, value: isLessThan),
      );
    }
    if (isLessThanOrEqualTo != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.lessThanOrEquals,
          value: isLessThanOrEqualTo,
        ),
      );
    }
    if (isGreaterThan != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.greaterThan, value: isGreaterThan),
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.greaterThanOrEquals,
          value: isGreaterThanOrEqualTo,
        ),
      );
    }
    if (arrayContains != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.arrayContains, value: arrayContains),
      );
    }
    if (arrayContainsAny != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.arrayContainsAny,
          value: arrayContainsAny,
        ),
      );
    }
    if (whereIn != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.whereIn, value: whereIn),
      );
    }
    if (whereNotIn != null) {
      newFilters.add(
        QueryFilter(field: field, operator: FilterOperator.whereNotIn, value: whereNotIn),
      );
    }
    if (isNull != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: isNull ? FilterOperator.isNull : FilterOperator.isNotNull,
          value: null,
        ),
      );
    }

    return Query._(
      filters: newFilters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
    );
  }

  // ---------------------------------------------------------------------------
  // Ordering Methods
  // ---------------------------------------------------------------------------

  /// Adds an ordering specification.
  Query<T> orderByField(String field, {bool descending = false}) {
    final newOrderBy = List<QueryOrderBy>.from(_orderBy)
      ..add(QueryOrderBy(field: field, descending: descending));

    return Query._(
      filters: _filters,
      orderBy: newOrderBy,
      limit: _limit,
      offset: _offset,
    );
  }

  // ---------------------------------------------------------------------------
  // Pagination Methods
  // ---------------------------------------------------------------------------

  /// Sets the maximum number of results to return.
  Query<T> limitTo(int count) {
    assert(count > 0, 'Limit must be positive');
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: count,
      offset: _offset,
    );
  }

  /// Sets the number of results to skip.
  Query<T> offsetBy(int count) {
    assert(count >= 0, 'Offset must be non-negative');
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: count,
    );
  }

  // ---------------------------------------------------------------------------
  // Query Composition
  // ---------------------------------------------------------------------------

  /// Returns `true` if this query has no filters, ordering, or pagination.
  bool get isEmpty =>
      _filters.isEmpty && _orderBy.isEmpty && _limit == null && _offset == null;

  /// Returns `true` if this query has any conditions.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this query with the specified changes.
  Query<T> copyWith({
    List<QueryFilter>? filters,
    List<QueryOrderBy>? orderBy,
    int? limit,
    int? offset,
  }) =>
      Query._(
        filters: filters ?? _filters,
        orderBy: orderBy ?? _orderBy,
        limit: limit ?? _limit,
        offset: offset ?? _offset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Query<T> &&
          runtimeType == other.runtimeType &&
          _listsEqual(_filters, other._filters) &&
          _listsEqual(_orderBy, other._orderBy) &&
          _limit == other._limit &&
          _offset == other._offset;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_filters),
        Object.hashAll(_orderBy),
        _limit,
        _offset,
      );

  @override
  String toString() => 'Query<$T>('
      'filters: $_filters, '
      'orderBy: $_orderBy, '
      'limit: $_limit, '
      'offset: $_offset)';

  static bool _listsEqual<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Filter operators for query conditions.
enum FilterOperator {
  /// Equal to (`=`).
  equals,

  /// Not equal to (`!=`).
  notEquals,

  /// Less than (`<`).
  lessThan,

  /// Less than or equal to (`<=`).
  lessThanOrEquals,

  /// Greater than (`>`).
  greaterThan,

  /// Greater than or equal to (`>=`).
  greaterThanOrEquals,

  /// Array contains value.
  arrayContains,

  /// Array contains any of the values.
  arrayContainsAny,

  /// Value is in the given list.
  whereIn,

  /// Value is not in the given list.
  whereNotIn,

  /// Value is null.
  isNull,

  /// Value is not null.
  isNotNull,

  /// String contains substring (case-sensitive).
  contains,

  /// String starts with prefix.
  startsWith,

  /// String ends with suffix.
  endsWith,
}

/// A single filter condition in a query.
@immutable
class QueryFilter {
  /// Creates a filter condition.
  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// The field name to filter on.
  final String field;

  /// The comparison operator.
  final FilterOperator operator;

  /// The value to compare against.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryFilter &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);

  @override
  String toString() => 'QueryFilter($field ${operator.name} $value)';
}

/// An ordering specification in a query.
@immutable
class QueryOrderBy {
  /// Creates an ordering specification.
  const QueryOrderBy({
    required this.field,
    this.descending = false,
  });

  /// The field name to order by.
  final String field;

  /// Whether to sort in descending order.
  final bool descending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryOrderBy &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          descending == other.descending;

  @override
  int get hashCode => Object.hash(field, descending);

  @override
  String toString() =>
      'QueryOrderBy($field ${descending ? 'DESC' : 'ASC'})';
}
