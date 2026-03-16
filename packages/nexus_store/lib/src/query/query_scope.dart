import 'package:meta/meta.dart';
import 'package:nexus_store/src/query/query.dart';

/// Abstract base class for query scopes that automatically apply
/// filters to all read queries.
///
/// Scopes are composable — multiple scopes can be chained together
/// to build up complex default filtering behavior.
///
/// ## Example
///
/// ```dart
/// // Scope that excludes soft-deleted records
/// final scope = SoftDeleteScope();
///
/// // Apply to a query
/// final filtered = scope.apply(Query<User>().where('status', isEqualTo: 'active'));
/// // Now also includes: WHERE deleted_at IS NULL
/// ```
@immutable
abstract class QueryScope<T> {
  /// Creates a query scope.
  const QueryScope();

  /// Applies this scope's filters to the given [query].
  ///
  /// Returns a new [Query] with additional filters appended.
  /// The original query's filters are preserved.
  Query<T> apply(Query<T> query);
}

/// A query scope that excludes soft-deleted records.
///
/// Appends a `WHERE <field> IS NULL` filter to exclude records
/// that have a non-null deletion timestamp.
///
/// ## Example
///
/// ```dart
/// // Default: filters on 'deleted_at'
/// final scope = SoftDeleteScope<User>();
///
/// // Custom field name
/// final scope = SoftDeleteScope<User>(field: 'removed_at');
/// ```
@immutable
class SoftDeleteScope<T> extends QueryScope<T> {
  /// Creates a soft-delete scope.
  ///
  /// [field] defaults to `'deleted_at'`.
  const SoftDeleteScope({this.field = 'deleted_at'});

  /// The field that holds the deletion timestamp.
  final String field;

  @override
  Query<T> apply(Query<T> query) {
    return query.where(field, isNull: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoftDeleteScope<T> &&
          runtimeType == other.runtimeType &&
          field == other.field;

  @override
  int get hashCode => field.hashCode;

  @override
  String toString() => 'SoftDeleteScope<$T>(field: $field)';
}

/// A query scope that filters records by owner.
///
/// Appends a `WHERE <field> = <ownerId>` filter to restrict
/// results to a specific owner.
///
/// ## Example
///
/// ```dart
/// final scope = OwnerScope<Document>(ownerId: 'user-123');
/// ```
@immutable
class OwnerScope<T> extends QueryScope<T> {
  /// Creates an owner scope.
  ///
  /// [field] defaults to `'owner_id'`.
  const OwnerScope({required this.ownerId, this.field = 'owner_id'});

  /// The owner identifier to filter by.
  final Object ownerId;

  /// The field that holds the owner identifier.
  final String field;

  @override
  Query<T> apply(Query<T> query) {
    return query.where(field, isEqualTo: ownerId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerScope<T> &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          field == other.field;

  @override
  int get hashCode => Object.hash(ownerId, field);

  @override
  String toString() => 'OwnerScope<$T>(ownerId: $ownerId, field: $field)';
}
