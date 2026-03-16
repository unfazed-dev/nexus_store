import 'package:meta/meta.dart';
import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/query/query_relation.dart';
import 'package:nexus_store/src/query/text_search_config.dart';

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
        _filterGroups = const [],
        _orderBy = const [],
        _relations = const [],
        _limit = null,
        _offset = null,
        _afterCursor = null,
        _beforeCursor = null,
        _first = null,
        _last = null,
        _preloadFields = const {},
        _selectFields = const {},
        _distinct = false;

  const Query._({
    required List<QueryFilter> filters,
    required List<QueryFilterGroup> filterGroups,
    required List<QueryOrderBy> orderBy,
    required int? limit,
    required int? offset,
    List<QueryRelation> relations = const [],
    Cursor? afterCursor,
    Cursor? beforeCursor,
    int? first,
    int? last,
    Set<String> preloadFields = const {},
    Set<String> selectFields = const {},
    bool distinct = false,
  })  : _filters = filters,
        _filterGroups = filterGroups,
        _orderBy = orderBy,
        _relations = relations,
        _limit = limit,
        _offset = offset,
        _afterCursor = afterCursor,
        _beforeCursor = beforeCursor,
        _first = first,
        _last = last,
        _preloadFields = preloadFields,
        _selectFields = selectFields,
        _distinct = distinct;

  final List<QueryFilter> _filters;
  final List<QueryFilterGroup> _filterGroups;
  final List<QueryOrderBy> _orderBy;
  final List<QueryRelation> _relations;
  final int? _limit;
  final int? _offset;
  final Cursor? _afterCursor;
  final Cursor? _beforeCursor;
  final int? _first;
  final int? _last;
  final Set<String> _preloadFields;
  final Set<String> _selectFields;
  final bool _distinct;

  /// The filter conditions for this query.
  List<QueryFilter> get filters => List.unmodifiable(_filters);

  /// The filter groups (e.g., OR groups) for this query.
  List<QueryFilterGroup> get filterGroups => List.unmodifiable(_filterGroups);

  /// Returns `true` if this query has any filter conditions or filter groups.
  bool get hasFilters => _filters.isNotEmpty || _filterGroups.isNotEmpty;

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

  /// Fields to select (project) when executing this query.
  ///
  /// When empty, all fields are returned (`SELECT *`).
  /// When non-empty, only the specified fields are returned.
  Set<String> get selectFields => Set.unmodifiable(_selectFields);

  /// Whether this query should return only distinct (unique) results.
  bool get isDistinct => _distinct;

  /// The relations to embed via resource embedding (JOINs).
  List<QueryRelation> get relations => List.unmodifiable(_relations);

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
    String? contains,
    String? startsWith,
    String? endsWith,
    String? iContains,
    String? iStartsWith,
    String? iEndsWith,
    TextSearchConfig? textSearch,
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
    if (contains != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.contains,
          value: contains,
        ),
      );
    }
    if (startsWith != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.startsWith,
          value: startsWith,
        ),
      );
    }
    if (endsWith != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.endsWith,
          value: endsWith,
        ),
      );
    }
    if (iContains != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.iContains,
          value: iContains,
        ),
      );
    }
    if (iStartsWith != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.iStartsWith,
          value: iStartsWith,
        ),
      );
    }
    if (iEndsWith != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.iEndsWith,
          value: iEndsWith,
        ),
      );
    }
    if (textSearch != null) {
      newFilters.add(
        QueryFilter(
          field: field,
          operator: FilterOperator.textSearch,
          value: textSearch,
        ),
      );
    }

    return Query._(
      filters: newFilters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
    );
  }

  /// Adds an OR filter group to the query.
  ///
  /// The [builder] function receives an empty [Query] and should add
  /// conditions using [where]. Those conditions are OR-ed together and
  /// AND-ed with the rest of the query.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Query<User>()
  ///   .where('status', isEqualTo: 'active')
  ///   .or((q) => q
  ///     .where('role', isEqualTo: 'admin')
  ///     .where('role', isEqualTo: 'superadmin')
  ///   );
  /// // status = 'active' AND (role = 'admin' OR role = 'superadmin')
  /// ```
  Query<T> or(Query<T> Function(Query<T>) builder) {
    final subQuery = builder(const Query());
    if (subQuery.filters.isEmpty) return this;

    final group = QueryFilterGroup(
      filters: subQuery.filters,
      combinator: FilterGroupCombinator.or,
    );

    return Query._(
      filters: _filters,
      filterGroups: [..._filterGroups, group],
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
    );
  }

  /// Adds a range filter for values between [start] and [end] (inclusive).
  ///
  /// Sugar for:
  /// ```dart
  /// query.where(field, isGreaterThanOrEqualTo: start)
  ///      .where(field, isLessThanOrEqualTo: end)
  /// ```
  Query<T> whereBetween(String field, Object start, Object end) {
    return where(field, isGreaterThanOrEqualTo: start)
        .where(field, isLessThanOrEqualTo: end);
  }

  /// Adds a null check filter. Sugar for `.where(field, isNull: true)`.
  Query<T> whereNull(String field) {
    return where(field, isNull: true);
  }

  /// Adds a not-null check filter. Sugar for `.where(field, isNull: false)`.
  Query<T> whereNotNull(String field) {
    return where(field, isNull: false);
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
      filterGroups: _filterGroups,
      orderBy: newOrderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      limit: count,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
    );
  }

  /// Sets the number of results to skip.
  Query<T> offsetBy(int count) {
    assert(count >= 0, 'Offset must be non-negative');
    return Query._(
      filters: _filters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: count,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: cursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: cursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: count,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: count,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
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
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: {..._preloadFields, ...fields},
      selectFields: _selectFields,
      distinct: _distinct,
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
  Query<T> preloadField(String fieldName) {
    return Query._(
      filters: _filters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: {..._preloadFields, fieldName},
      selectFields: _selectFields,
      distinct: _distinct,
    );
  }

  // ---------------------------------------------------------------------------
  // Projection & Distinct Methods
  // ---------------------------------------------------------------------------

  /// Specifies which fields to include in query results.
  ///
  /// When set, generates `SELECT field1, field2` instead of `SELECT *`.
  /// Multiple calls merge the field sets.
  ///
  /// Example:
  /// ```dart
  /// final query = Query<User>()
  ///   .where('status', isEqualTo: 'active')
  ///   .select({'name', 'email'});
  /// ```
  Query<T> select(Set<String> fields) {
    return Query._(
      filters: _filters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: {..._selectFields, ...fields},
      distinct: _distinct,
    );
  }

  /// Marks this query to return only distinct (unique) results.
  ///
  /// Generates `SELECT DISTINCT` in SQL backends.
  ///
  /// Example:
  /// ```dart
  /// final query = Query<User>()
  ///   .select({'city'})
  ///   .distinct();
  /// ```
  Query<T> distinct() {
    return Query._(
      filters: _filters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: _relations,
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Relation Methods (Resource Embedding / JOINs)
  // ---------------------------------------------------------------------------

  /// Adds a relation to embed via resource embedding (JOIN).
  ///
  /// [foreignTable] is the name of the related table to include.
  /// [foreignKey] optionally disambiguates which FK to use.
  /// [columns] optionally limits which columns to return from the relation.
  /// [subQuery] optionally specifies nested relations.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Simple relation
  /// Query<User>().withRelation('posts');
  ///
  /// // With FK hint and nested relations
  /// Query<User>().withRelation(
  ///   'posts',
  ///   foreignKey: 'author_id',
  ///   subQuery: Query().withRelation('comments'),
  /// );
  /// ```
  Query<T> withRelation(
    String foreignTable, {
    String? foreignKey,
    Set<String>? columns,
    Query<dynamic>? subQuery,
  }) {
    return Query._(
      filters: _filters,
      filterGroups: _filterGroups,
      orderBy: _orderBy,
      relations: [
        ..._relations,
        QueryRelation(
          foreignTable: foreignTable,
          foreignKey: foreignKey,
          columns: columns,
          subQuery: subQuery,
        ),
      ],
      limit: _limit,
      offset: _offset,
      afterCursor: _afterCursor,
      beforeCursor: _beforeCursor,
      first: _first,
      last: _last,
      preloadFields: _preloadFields,
      selectFields: _selectFields,
      distinct: _distinct,
    );
  }

  // ---------------------------------------------------------------------------
  // Query Composition
  // ---------------------------------------------------------------------------

  /// Returns `true` if this query has no filters, ordering, pagination, or preloads.
  bool get isEmpty =>
      _filters.isEmpty &&
      _filterGroups.isEmpty &&
      _orderBy.isEmpty &&
      _relations.isEmpty &&
      _limit == null &&
      _offset == null &&
      _afterCursor == null &&
      _beforeCursor == null &&
      _first == null &&
      _last == null &&
      _preloadFields.isEmpty &&
      _selectFields.isEmpty &&
      !_distinct;

  /// Returns `true` if this query has any conditions.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this query with the specified changes.
  Query<T> copyWith({
    List<QueryFilter>? filters,
    List<QueryFilterGroup>? filterGroups,
    List<QueryOrderBy>? orderBy,
    List<QueryRelation>? relations,
    int? limit,
    int? offset,
    Cursor? afterCursor,
    Cursor? beforeCursor,
    int? first,
    int? last,
    Set<String>? preloadFields,
    Set<String>? selectFields,
    bool? isDistinct,
  }) =>
      Query._(
        filters: filters ?? _filters,
        filterGroups: filterGroups ?? _filterGroups,
        orderBy: orderBy ?? _orderBy,
        relations: relations ?? _relations,
        limit: limit ?? _limit,
        offset: offset ?? _offset,
        afterCursor: afterCursor ?? _afterCursor,
        beforeCursor: beforeCursor ?? _beforeCursor,
        first: first ?? _first,
        last: last ?? _last,
        preloadFields: preloadFields ?? _preloadFields,
        selectFields: selectFields ?? _selectFields,
        distinct: isDistinct ?? _distinct,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Query<T> &&
          runtimeType == other.runtimeType &&
          _listsEqual(_filters, other._filters) &&
          _listsEqual(_filterGroups, other._filterGroups) &&
          _listsEqual(_orderBy, other._orderBy) &&
          _listsEqual(_relations, other._relations) &&
          _limit == other._limit &&
          _offset == other._offset &&
          _afterCursor == other._afterCursor &&
          _beforeCursor == other._beforeCursor &&
          _first == other._first &&
          _last == other._last &&
          _setsEqual(_preloadFields, other._preloadFields) &&
          _setsEqual(_selectFields, other._selectFields) &&
          _distinct == other._distinct;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_filters),
        Object.hashAll(_filterGroups),
        Object.hashAll(_orderBy),
        Object.hashAll(_relations),
        _limit,
        _offset,
        _afterCursor,
        _beforeCursor,
        _first,
        _last,
        Object.hashAll(_preloadFields),
        Object.hashAll(_selectFields),
        _distinct,
      );

  @override
  String toString() => 'Query<$T>('
      'filters: $_filters, '
      'filterGroups: $_filterGroups, '
      'orderBy: $_orderBy, '
      'relations: $_relations, '
      'limit: $_limit, '
      'offset: $_offset, '
      'afterCursor: $_afterCursor, '
      'beforeCursor: $_beforeCursor, '
      'first: $_first, '
      'last: $_last, '
      'preloadFields: $_preloadFields, '
      'selectFields: $_selectFields, '
      'distinct: $_distinct)';

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

  /// String contains substring (case-insensitive).
  iContains,

  /// String starts with prefix (case-insensitive).
  iStartsWith,

  /// String ends with suffix (case-insensitive).
  iEndsWith,

  /// Full-text search using PostgreSQL tsvector/tsquery.
  textSearch,
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

/// Combinator for a group of filter conditions.
enum FilterGroupCombinator {
  /// All conditions combined with AND.
  and,

  /// Any condition combined with OR.
  or,
}

/// A group of filter conditions combined with a [FilterGroupCombinator].
///
/// Used to represent OR groups in queries:
/// ```dart
/// Query<User>()
///   .where('status', isEqualTo: 'active')
///   .or((q) => q
///     .where('role', isEqualTo: 'admin')
///     .where('role', isEqualTo: 'superadmin')
///   );
/// // Generates: status = 'active' AND (role = 'admin' OR role = 'superadmin')
/// ```
@immutable
class QueryFilterGroup {
  /// Creates a filter group.
  const QueryFilterGroup({
    required this.filters,
    required this.combinator,
  });

  /// The filter conditions in this group.
  final List<QueryFilter> filters;

  /// How to combine the filters (AND or OR).
  final FilterGroupCombinator combinator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryFilterGroup &&
          runtimeType == other.runtimeType &&
          combinator == other.combinator &&
          _listsEqual(filters, other.filters);

  @override
  int get hashCode => Object.hash(combinator, Object.hashAll(filters));

  @override
  String toString() =>
      'QueryFilterGroup(${combinator.name.toUpperCase()}: $filters)';

  static bool _listsEqual<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
