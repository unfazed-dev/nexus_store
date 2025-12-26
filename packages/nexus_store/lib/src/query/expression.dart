import 'package:meta/meta.dart';
import 'package:nexus_store/src/query/query.dart';

/// Base class for type-safe query expressions.
///
/// Expressions form a tree that represents query conditions. They can be
/// combined using [and], [or], and [not] operators.
///
/// ## Example
///
/// ```dart
/// final expr = ComparisonExpression<User>(
///   fieldName: 'age',
///   operator: FilterOperator.greaterThan,
///   value: 18,
/// ).and(
///   ComparisonExpression<User>(
///     fieldName: 'status',
///     operator: FilterOperator.equals,
///     value: 'active',
///   ),
/// );
/// ```
@immutable
sealed class Expression<T> {
  /// Creates an expression.
  const Expression();

  /// Combines this expression with [other] using logical AND.
  Expression<T> and(Expression<T> other) => AndExpression<T>(this, other);

  /// Combines this expression with [other] using logical OR.
  Expression<T> or(Expression<T> other) => OrExpression<T>(this, other);

  /// Negates this expression.
  Expression<T> not() => NotExpression<T>(this);

  /// Converts this expression to a list of [QueryFilter]s.
  ///
  /// AND expressions are flattened into a list of filters.
  /// OR expressions throw [UnsupportedError] as they cannot be represented
  /// as a flat list - use [InMemoryQueryEvaluator.matchesExpression] for
  /// full expression support.
  List<QueryFilter> toFilters();
}

/// A comparison expression that compares a field to a value.
///
/// This is the leaf node of the expression tree.
@immutable
final class ComparisonExpression<T> extends Expression<T> {
  /// Creates a comparison expression.
  const ComparisonExpression({
    required this.fieldName,
    required this.operator,
    required this.value,
  });

  /// The name of the field to compare.
  final String fieldName;

  /// The comparison operator.
  final FilterOperator operator;

  /// The value to compare against.
  final Object? value;

  @override
  List<QueryFilter> toFilters() {
    return [
      QueryFilter(
        field: fieldName,
        operator: operator,
        value: value,
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonExpression<T> &&
          runtimeType == other.runtimeType &&
          fieldName == other.fieldName &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(fieldName, operator, value);

  @override
  String toString() =>
      'ComparisonExpression<$T>($fieldName ${operator.name} $value)';
}

/// An AND expression that combines two expressions with logical AND.
@immutable
final class AndExpression<T> extends Expression<T> {
  /// Creates an AND expression.
  const AndExpression(this.left, this.right);

  /// The left-hand side expression.
  final Expression<T> left;

  /// The right-hand side expression.
  final Expression<T> right;

  @override
  List<QueryFilter> toFilters() {
    // AND expressions flatten naturally to a list of filters
    return [...left.toFilters(), ...right.toFilters()];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndExpression<T> &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(left, right);

  @override
  String toString() => 'AndExpression<$T>($left AND $right)';
}

/// An OR expression that combines two expressions with logical OR.
@immutable
final class OrExpression<T> extends Expression<T> {
  /// Creates an OR expression.
  const OrExpression(this.left, this.right);

  /// The left-hand side expression.
  final Expression<T> left;

  /// The right-hand side expression.
  final Expression<T> right;

  @override
  List<QueryFilter> toFilters() {
    // OR expressions cannot be flattened to a simple filter list
    throw UnsupportedError(
      'OR expressions cannot be converted to QueryFilter list. '
      'Use InMemoryQueryEvaluator.matchesExpression for full expression support.',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrExpression<T> &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(left, right);

  @override
  String toString() => 'OrExpression<$T>($left OR $right)';
}

/// A NOT expression that negates an expression.
@immutable
final class NotExpression<T> extends Expression<T> {
  /// Creates a NOT expression.
  const NotExpression(this.expression);

  /// The expression to negate.
  final Expression<T> expression;

  @override
  List<QueryFilter> toFilters() {
    // If the inner expression is an OR, we can't flatten it
    if (expression is OrExpression<T>) {
      throw UnsupportedError(
        'NOT on OR expressions cannot be converted to QueryFilter list. '
        'Use InMemoryQueryEvaluator.matchesExpression for full expression support.',
      );
    }

    // Get filters from inner expression and invert each operator
    final innerFilters = expression.toFilters();
    return innerFilters.map((filter) {
      return QueryFilter(
        field: filter.field,
        operator: _invertOperator(filter.operator),
        value: filter.value,
      );
    }).toList();
  }

  /// Inverts a filter operator.
  static FilterOperator _invertOperator(FilterOperator op) {
    return switch (op) {
      FilterOperator.equals => FilterOperator.notEquals,
      FilterOperator.notEquals => FilterOperator.equals,
      FilterOperator.lessThan => FilterOperator.greaterThanOrEquals,
      FilterOperator.lessThanOrEquals => FilterOperator.greaterThan,
      FilterOperator.greaterThan => FilterOperator.lessThanOrEquals,
      FilterOperator.greaterThanOrEquals => FilterOperator.lessThan,
      FilterOperator.isNull => FilterOperator.isNotNull,
      FilterOperator.isNotNull => FilterOperator.isNull,
      FilterOperator.whereIn => FilterOperator.whereNotIn,
      FilterOperator.whereNotIn => FilterOperator.whereIn,
      // These operators don't have direct inverses
      FilterOperator.contains => throw UnsupportedError(
          'Cannot invert contains operator. Use expression evaluation instead.',
        ),
      FilterOperator.startsWith => throw UnsupportedError(
          'Cannot invert startsWith operator. Use expression evaluation instead.',
        ),
      FilterOperator.endsWith => throw UnsupportedError(
          'Cannot invert endsWith operator. Use expression evaluation instead.',
        ),
      FilterOperator.arrayContains => throw UnsupportedError(
          'Cannot invert arrayContains operator. Use expression evaluation instead.',
        ),
      FilterOperator.arrayContainsAny => throw UnsupportedError(
          'Cannot invert arrayContainsAny operator. Use expression evaluation instead.',
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotExpression<T> &&
          runtimeType == other.runtimeType &&
          expression == other.expression;

  @override
  int get hashCode => expression.hashCode;

  @override
  String toString() => 'NotExpression<$T>(NOT $expression)';
}
