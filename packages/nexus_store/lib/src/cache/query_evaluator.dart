import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/query.dart';

/// Function to extract a field value from an item.
typedef FieldAccessor<T> = Object? Function(T item, String field);

/// Evaluates queries against items in memory.
///
/// Used for filtering cached items without database queries.
class InMemoryQueryEvaluator<T> {
  /// Creates a query evaluator with the given field accessor.
  const InMemoryQueryEvaluator({
    required this.fieldAccessor,
  });

  /// Function to extract field values from items.
  final FieldAccessor<T> fieldAccessor;

  /// Evaluates the query against a list of items.
  ///
  /// Returns items that match all query filters.
  List<T> evaluate(List<T> items, Query<T> query) {
    if (query.filters.isEmpty) return List.from(items);

    return items.where((item) => matches(item, query)).toList();
  }

  /// Returns true if the item matches all query filters.
  bool matches(T item, Query<T> query) {
    for (final filter in query.filters) {
      if (!_matchesFilter(item, filter)) {
        return false;
      }
    }
    return true;
  }

  bool _matchesFilter(T item, QueryFilter filter) {
    final value = fieldAccessor(item, filter.field);

    switch (filter.operator) {
      case FilterOperator.equals:
        return value == filter.value;

      case FilterOperator.notEquals:
        return value != filter.value;

      case FilterOperator.isNull:
        return value == null;

      case FilterOperator.isNotNull:
        return value != null;

      case FilterOperator.lessThan:
        return _compareValues(value, filter.value) < 0;

      case FilterOperator.lessThanOrEquals:
        return _compareValues(value, filter.value) <= 0;

      case FilterOperator.greaterThan:
        return _compareValues(value, filter.value) > 0;

      case FilterOperator.greaterThanOrEquals:
        return _compareValues(value, filter.value) >= 0;

      case FilterOperator.whereIn:
        final list = filter.value as List?;
        if (list == null || list.isEmpty) return false;
        return list.contains(value);

      case FilterOperator.whereNotIn:
        final list = filter.value as List?;
        if (list == null) return true;
        return !list.contains(value);

      case FilterOperator.arrayContains:
        final list = value as List?;
        return list?.contains(filter.value) ?? false;

      case FilterOperator.arrayContainsAny:
        final list = value as List?;
        final filterList = filter.value as List?;
        if (list == null || filterList == null) return false;
        return list.any(filterList.contains);

      case FilterOperator.contains:
        return value.toString().contains(filter.value.toString());

      case FilterOperator.startsWith:
        return value.toString().startsWith(filter.value.toString());

      case FilterOperator.endsWith:
        return value.toString().endsWith(filter.value.toString());
    }
  }

  int _compareValues(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is Comparable && b is Comparable) {
      return a.compareTo(b);
    }

    return a.toString().compareTo(b.toString());
  }

  // ---------------------------------------------------------------------------
  // Expression-based evaluation (supports OR expressions)
  // ---------------------------------------------------------------------------

  /// Evaluates items using a type-safe expression.
  ///
  /// Unlike [evaluate] which only supports AND conditions via [Query],
  /// this method fully supports OR expressions and complex nested conditions.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final expr = UserFields.age.greaterThan(18).or(
  ///   UserFields.tags.arrayContains('admin'),
  /// );
  /// final adults = evaluator.evaluateWithExpression(users, expr);
  /// ```
  List<T> evaluateWithExpression(List<T> items, Expression<T> expression) {
    return items.where((item) => matchesExpression(item, expression)).toList();
  }

  /// Returns true if the item matches the expression.
  ///
  /// Supports all expression types including [ComparisonExpression],
  /// [AndExpression], [OrExpression], and [NotExpression].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final expr = UserFields.status.equals('active').or(
  ///   UserFields.status.equals('pending'),
  /// );
  /// if (evaluator.matchesExpression(user, expr)) {
  ///   print('User is active or pending');
  /// }
  /// ```
  bool matchesExpression(T item, Expression<T> expression) {
    return switch (expression) {
      ComparisonExpression<T> e => _matchesFilter(
          item,
          QueryFilter(
            field: e.fieldName,
            operator: e.operator,
            value: e.value,
          ),
        ),
      AndExpression<T> e =>
        matchesExpression(item, e.left) && matchesExpression(item, e.right),
      OrExpression<T> e =>
        matchesExpression(item, e.left) || matchesExpression(item, e.right),
      NotExpression<T> e => !matchesExpression(item, e.expression),
    };
  }
}
