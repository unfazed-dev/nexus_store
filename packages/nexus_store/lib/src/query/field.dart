import 'package:meta/meta.dart';
import 'package:nexus_store/src/query/expression.dart';
import 'package:nexus_store/src/query/query.dart';

/// A type-safe field accessor for building query expressions.
///
/// [T] is the entity type that contains this field.
/// [F] is the type of the field value.
///
/// ## Example
///
/// ```dart
/// class UserFields {
///   static final name = Field<User, String>('name');
///   static final age = ComparableField<User, int>('age');
/// }
///
/// final expr = UserFields.age.greaterThan(18);
/// ```
@immutable
class Field<T, F> {
  /// Creates a field accessor with the given [name].
  const Field(this.name);

  /// The name of the field as stored in the database/backend.
  final String name;

  /// Creates an expression that matches when the field equals [value].
  Expression<T> equals(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.equals,
        value: value,
      );

  /// Creates an expression that matches when the field does not equal [value].
  Expression<T> notEquals(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.notEquals,
        value: value,
      );

  /// Creates an expression that matches when the field is null.
  Expression<T> isNull() => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.isNull,
        value: null,
      );

  /// Creates an expression that matches when the field is not null.
  Expression<T> isNotNull() => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.isNotNull,
        value: null,
      );

  /// Creates an expression that matches when the field value is in [values].
  Expression<T> isIn(List<F> values) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.whereIn,
        value: values,
      );

  /// Creates an expression that matches when the field value is not in [values].
  Expression<T> isNotIn(List<F> values) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.whereNotIn,
        value: values,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Field<T, F> &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => Object.hash(runtimeType, name);

  @override
  String toString() => 'Field<$T, $F>($name)';
}

/// A field that supports comparison operators for [Comparable] types.
///
/// Use this for numeric fields (int, double), DateTime, and other comparable types.
///
/// ## Example
///
/// ```dart
/// final ageField = ComparableField<User, int>('age');
/// final expr = ageField.greaterThan(18).and(ageField.lessThan(65));
/// ```
@immutable
class ComparableField<T, F extends Comparable<dynamic>> extends Field<T, F> {
  /// Creates a comparable field accessor with the given [name].
  const ComparableField(super.name);

  /// Creates an expression that matches when the field is greater than [value].
  Expression<T> greaterThan(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.greaterThan,
        value: value,
      );

  /// Creates an expression that matches when the field is greater than or equal to [value].
  Expression<T> greaterThanOrEqualTo(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.greaterThanOrEquals,
        value: value,
      );

  /// Creates an expression that matches when the field is less than [value].
  Expression<T> lessThan(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.lessThan,
        value: value,
      );

  /// Creates an expression that matches when the field is less than or equal to [value].
  Expression<T> lessThanOrEqualTo(F value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.lessThanOrEquals,
        value: value,
      );
}

/// A field for string values with text-specific operators.
///
/// ## Example
///
/// ```dart
/// final nameField = StringField<User>('name');
/// final expr = nameField.startsWith('Dr.').or(nameField.startsWith('Prof.'));
/// ```
@immutable
class StringField<T> extends ComparableField<T, String> {
  /// Creates a string field accessor with the given [name].
  const StringField(super.name);

  /// Creates an expression that matches when the field contains [value].
  Expression<T> contains(String value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.contains,
        value: value,
      );

  /// Creates an expression that matches when the field starts with [value].
  Expression<T> startsWith(String value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.startsWith,
        value: value,
      );

  /// Creates an expression that matches when the field ends with [value].
  Expression<T> endsWith(String value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.endsWith,
        value: value,
      );
}

/// A field for list/array values with collection-specific operators.
///
/// [T] is the entity type.
/// [E] is the type of elements in the list.
///
/// ## Example
///
/// ```dart
/// final tagsField = ListField<User, String>('tags');
/// final expr = tagsField.arrayContains('admin');
/// ```
@immutable
class ListField<T, E> extends Field<T, List<E>> {
  /// Creates a list field accessor with the given [name].
  const ListField(super.name);

  /// Creates an expression that matches when the list contains [value].
  Expression<T> arrayContains(E value) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.arrayContains,
        value: value,
      );

  /// Creates an expression that matches when the list contains any of [values].
  Expression<T> arrayContainsAny(List<E> values) => ComparisonExpression<T>(
        fieldName: name,
        operator: FilterOperator.arrayContainsAny,
        value: values,
      );
}
