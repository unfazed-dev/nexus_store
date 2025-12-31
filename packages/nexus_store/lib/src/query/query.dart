import 'package:meta/meta.dart';
import 'package:nexus_store/src/pagination/cursor.dart';

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
///
/// // Cursor-based pagination
/// final cursorQuery = Query<User>()
///   .orderByField('createdAt', descending: true)
///   .after(cursor)
///   .first(20);
/// ```
@immutable
class Query<T> {
  /// Creates an empty query.
  const Query()
      : _filters = const [],
        _orderBy = const [],
        _limit = null,
        _offset = null,
        _afterCursor = null,
        _beforeCursor = null,
        _first = null,
        _last = null,
        _preloadFields = const {};

  const Query._({
    required List<QueryFilter> filters,
    required List<QueryOrderBy> orderBy,
    required int? limit,
    required int? offset,
    Cursor? afterCursor,
    Cursor? beforeCursor,
    int? first,
    int? last,
    Set<String> preloadFields = const {},
  })  : _filters = filters,
        _orderBy = orderBy,
        _limit = limit,
        _offset = offset,
        _afterCursor = afterCursor,
        _beforeCursor = beforeCursor,
        _first = first,
        _last = last,
        _preloadFields = preloadFields;

  final List<QueryFilter> _filters;
  final List<QueryOrderBy> _orderBy;
  final int? _limit;
  final int? _offset;
  final Cursor? _afterCursor;
  final Cursor? _beforeCursor;
  final int? _first;
  final int? _last;
  final Set<String> _preloadFields;

  /// The filter conditions for this query.
  List<QueryFilter> get filters => List.unmodifiable(_filters);

  /// The ordering specifications for this query.
  List<QueryOrderBy> get orderBy => List.unmodifiable(_orderBy);

  /// The maximum number of results to return, or `null` for unlimited.
  int? get limit => _limit;

  /// The number of results to skip, or `null` for none.
  int? get offset => _offset;

  /// Cursor to start after for forward pagination.
  Cursor? get afterCursor => _afterCursor;

  /// Cursor to end before for backward pagination.
  Cursor? get beforeCursor => _beforeCursor;

  /// Number of items to fetch forward from cursor.
  int? get firstCount => _first;

  /// Number of items to fetch backward from cursor.
  int? get lastCount => _last;

  /// Fields to preload when executing this query.
  ///
  /// These fields will be eagerly loaded alongside the main query results,
  /// useful for lazy fields that are known to be needed.
  Set<String> get preloadFields => Set.unmodifiable(_preloadFields);

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
        QueryFilter(
          field: field,
          operator: FilterOperator.equals,
          value: isEqualTo,
        ),
      );
    }
    if (isNotEqualTo != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.notEquals,
          value: isNotEqualTo,
        ),
      );
    }
    if (isLessThan != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.lessThan,
          value: isLessThan,
        ),
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
        QueryFilter(
          field: field,
          operator: FilterOperator.greaterThan,
          value: isGreaterThan,
        ),
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
        QueryFilter(
          field: field,
          operator: FilterOperator.arrayContains,
          value: arrayContains,
        ),
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
        QueryFilter(
          field: field,
          operator: FilterOperator.whereIn,
          value: whereIn,
        ),
      );
    }
    if (whereNotIn != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.whereNotIn,
          value: whereNotIn,
        ),
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
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
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
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
    );
  }

  // ---------------------------------------------------------------------------
  // Offset Pagination Methods
  // ---------------------------------------------------------------------------

  /// Sets the maximum number of results to return.
  Query<T> limitTo(int count) {
    assert(count > 0, 'Limit must be positive');
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: count,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
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
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
    );
  }

  // ---------------------------------------------------------------------------
  // Cursor Pagination Methods
  // ---------------------------------------------------------------------------

  /// Sets the cursor position to start after for forward pagination.
  ///
  /// Use with [first] to paginate forward through results.
  ///
  /// Example:
  /// ```dart
  /// final nextPage = Query<User>()
  ///   .orderByField('createdAt', descending: true)
  ///   .after(previousPage.endCursor)
  ///   .first(20);
  /// ```
  Query<T> after(Cursor cursor) {
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: cursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
    );
  }

  /// Sets the cursor position to end before for backward pagination.
  ///
  /// Use with [last] to paginate backward through results.
  ///
  /// Example:
  /// ```dart
  /// final previousPage = Query<User>()
  ///   .orderByField('createdAt', descending: true)
  ///   .before(currentPage.startCursor)
  ///   .last(20);
  /// ```
  Query<T> before(Cursor cursor) {
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: cursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
    );
  }

  /// Sets the number of items to fetch in forward direction.
  ///
  /// Use with [after] for cursor-based forward pagination.
  ///
  /// Example:
  /// ```dart
  /// final firstPage = Query<User>()
  ///   .orderByField('createdAt', descending: true)
  ///   .first(20);
  /// ```
  Query<T> first(int count) {
    assert(count > 0, 'First count must be positive');
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: count,
      last: _last,
      preloadFields: _preloadFields,
    );
  }

  /// Sets the number of items to fetch in backward direction.
  ///
  /// Use with [before] for cursor-based backward pagination.
  ///
  /// Example:
  /// ```dart
  /// final previousPage = Query<User>()
  ///   .orderByField('createdAt', descending: true)
  ///   .before(cursor)
  ///   .last(20);
  /// ```
  Query<T> last(int count) {
    assert(count > 0, 'Last count must be positive');
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: count,
      preloadFields: _preloadFields,
    );
  }

  // ---------------------------------------------------------------------------
  // Preload Methods (Lazy Loading)
  // ---------------------------------------------------------------------------

  /// Specifies fields to preload with query results.
  ///
  /// These fields will be eagerly loaded alongside the main query results.
  /// Useful for lazy fields that are known to be needed.
  ///
  /// Example:
  /// ```dart
  /// final query = Query<User>()
  ///   .where('status', isEqualTo: 'active')
  ///   .preload({'thumbnail', 'avatar'});
  /// ```
  Query<T> preload(Set<String> fields) {
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: {..._preloadFields, ...fields},
    );
  }

  /// Specifies a single field to preload with query results.
  ///
  /// Convenience method for preloading a single field.
  ///
  /// Example:
  /// ```dart
  /// final query = Query<User>()
  ///   .where('status', isEqualTo: 'active')
  ///   .preloadField('thumbnail');
  /// ```
  Query<T> preloadField(String field) {
    return Query._(
      filters: _filters,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: {..._preloadFields, field},
    );
  }

  // ---------------------------------------------------------------------------
  // Query Composition
  // ---------------------------------------------------------------------------

  /// Returns `true` if this query has no filters, ordering, pagination, or preloads.
  bool get isEmpty =>
      _filters.isEmpty &&
      _orderBy.isEmpty &&
      _limit == null &&
      _offset == null &&
      _afterCursor == null &&
      _beforeCursor == null &&
      _first == null &&
      _last == null &&
      _preloadFields.isEmpty;

  /// Returns `true` if this query has any conditions.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this query with the specified changes.
  Query<T> copyWith({
    List<QueryFilter>? filters,
    List<QueryOrderBy>? orderBy,
    int? limit,
    int? offset,
    Cursor? afterCursor,
    Cursor? beforeCursor,
    int? first,
    int? last,
    Set<String>? preloadFields,
  }) =>
      Query._(
        filters: filters ?? _filters,
        orderBy: orderBy ?? _orderBy,
        limit: limit ?? _limit,
        offset: offset ?? _offset,
        afterCursor: afterCursor ?? _afterCursor,
        beforeCursor: beforeCursor ?? _beforeCursor,
        first: first ?? _first,
        last: last ?? _last,
        preloadFields: preloadFields ?? _preloadFields,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Query<T> &&
          runtimeType == other.runtimeType &&
          _listsEqual(_filters, other._filters) &&
          _listsEqual(_orderBy, other._orderBy) &&
          _limit == other._limit &&
          _offset == other._offset &&
          _afterCursor == other._afterCursor &&
          _beforeCursor == other._beforeCursor &&
          _first == other._first &&
          _last == other._last &&
          _setsEqual(_preloadFields, other._preloadFields);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_filters),
        Object.hashAll(_orderBy),
        _limit,
        _offset,
        _afterCursor,
        _beforeCursor,
        _first,
        _last,
        Object.hashAll(_preloadFields),
      );

  @override
  String toString() => 'Query<$T>('
      'filters: $_filters, '
      'orderBy: $_orderBy, '
      'limit: $_limit, '
      'offset: $_offset, '
      'afterCursor: $_afterCursor, '
      'beforeCursor: $_beforeCursor, '
      'first: $_first, '
      'last: $_last, '
      'preloadFields: $_preloadFields)';

  static bool _listsEqual<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _setsEqual<E>(Set<E> a, Set<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
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
  String toString() => 'QueryOrderBy($field ${descending ? 'DESC' : 'ASC'})';
}
