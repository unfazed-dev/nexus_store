// coverage:ignore-file
import 'package:meta/meta.dart';

/// Base class for entity field definitions.
///
/// Each entity should have a corresponding Fields class that defines
/// its queryable fields using [Field], [ComparableField], [StringField],
/// or [ListField] instances.
///
/// ## Example
///
/// ```dart
/// class UserFields extends Fields<User> {
///   UserFields._();
///   static const instance = UserFields._();
///
///   static final id = StringField<User>('id');
///   static final name = StringField<User>('name');
///   static final age = ComparableField<User, int>('age');
///   static final createdAt = ComparableField<User, DateTime>('createdAt');
///   static final tags = ListField<User, String>('tags');
/// }
///
/// // Usage
/// final query = Query<User>()
///   .whereExpression(UserFields.age.greaterThan(18))
///   .whereExpression(UserFields.name.isNotNull());
/// ```
///
/// ## Code Generation
///
/// For larger projects, consider using the `nexus_store_generator` package
/// to automatically generate Fields classes from your entity definitions.
@immutable
abstract class Fields<T> {
  /// Creates a Fields instance.
  const Fields();
}
