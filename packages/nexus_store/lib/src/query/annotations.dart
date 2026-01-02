/// Annotations for code generation of type-safe entity field accessors.
///
/// These annotations are used with `build_runner` and the
/// `nexus_store_entity_generator` package to generate type-safe
/// field accessor classes.
// coverage:ignore-file
library;

/// Marks a class for entity field code generation.
///
/// When applied to a class, the build_runner will generate a `$ModelFields`
/// class with type-safe field accessors that can be used with `Query<T>`.
///
/// ## Example
///
/// ```dart
/// @NexusEntity()
/// class User {
///   final String id;
///   final String name;
///   final int age;
///   final DateTime createdAt;
///   final List<String> tags;
///
///   User({
///     required this.id,
///     required this.name,
///     required this.age,
///     required this.createdAt,
///     required this.tags,
///   });
/// }
///
/// // Generated: UserFields class with:
/// // - StringField<User> for String fields
/// // - ComparableField<User, int> for int fields
/// // - ComparableField<User, DateTime> for DateTime fields
/// // - ListField<User, String> for List<String> fields
///
/// // Usage:
/// final query = Query<User>()
///   .whereExpression(UserFields.age.greaterThan(18))
///   .whereExpression(UserFields.name.startsWith('Dr.'));
/// ```
class NexusEntity {
  /// Creates a NexusEntity annotation.
  ///
  /// If [generateFields] is true (default), generates a `$ModelFields` class.
  /// Use [fieldsSuffix] to customize the class name suffix (default: 'Fields').
  const NexusEntity({
    this.generateFields = true,
    this.fieldsSuffix = 'Fields',
  });

  /// Whether to generate the Fields class.
  ///
  /// Set to `false` to skip code generation for this entity.
  final bool generateFields;

  /// The suffix for the generated Fields class name.
  ///
  /// Default is 'Fields', so `User` generates `UserFields`.
  /// Set to 'Columns' to generate `UserColumns` instead.
  final String fieldsSuffix;
}
