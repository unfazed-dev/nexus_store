import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/field.dart';
import 'package:nexus_store/src/query/query.dart';

/// Extension methods for type-safe query building on [Query].
///
/// These methods allow mixing type-safe expressions with the existing
/// string-based query API.
///
/// ## Example
///
/// ```dart
/// class UserFields extends Fields<User> {
///   static final age = ComparableField<User, int>('age');
///   static final name = StringField<User>('name');
/// }
///
/// final query = Query<User>()
///   .where('status', isEqualTo: 'active')  // String-based
///   .whereExpression(UserFields.age.greaterThan(18))  // Type-safe
///   .orderByTyped(UserFields.name);  // Type-safe ordering
/// ```
extension QueryExpressionExtension<T> on Query<T> {
  /// Adds a type-safe expression filter to the query.
  ///
  /// The expression is converted to [QueryFilter]s and appended to
  /// the existing filters.
  ///
  /// For AND expressions, the filters are flattened into the query.
  /// OR expressions are not supported via this method because they
  /// cannot be represented as a flat list of filters. Use
  /// [InMemoryQueryEvaluator.matchesExpression] for full OR support.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final query = Query<User>()
  ///   .whereExpression(UserFields.age.greaterThan(18))
  ///   .whereExpression(UserFields.status.equals('active'));
  ///
  /// // AND expressions are flattened
  /// final query2 = Query<User>()
  ///   .whereExpression(
  ///     UserFields.age.greaterThan(18).and(UserFields.age.lessThan(65))
  ///   );
  /// ```
  ///
  /// Throws [UnsupportedError] if the expression contains OR conditions.
  Query<T> whereExpression(Expression<T> expression) {
    final newFilters = expression.toFilters();
    return copyWith(
      filters: [...filters, ...newFilters],
    );
  }

  /// Adds a type-safe ordering specification to the query.
  ///
  /// Uses the field's name for ordering, ensuring type safety.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final query = Query<User>()
  ///   .orderByTyped(UserFields.createdAt, descending: true)
  ///   .orderByTyped(UserFields.name);
  /// ```
  Query<T> orderByTyped<F>(Field<T, F> field, {bool descending = false}) {
    return orderByField(field.name, descending: descending);
  }
}
