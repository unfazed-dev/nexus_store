/// Annotations for code generation of lazy field accessors.
///
/// These annotations are used with `build_runner` to generate
/// typed accessor methods for lazy-loaded fields.
library;

/// Marks a field as lazy-loaded.
///
/// Use this annotation on fields that should be loaded on-demand
/// rather than with the initial entity fetch.
///
/// ## Example
///
/// ```dart
/// @NexusLazy()
/// class MediaItem {
///   final String id;
///   final String name;
///
///   @Lazy(placeholder: 'loading.png')
///   final String? thumbnail;
///
///   @Lazy()
///   final Uint8List? fullResolutionImage;
///
///   MediaItem({required this.id, required this.name, this.thumbnail, this.fullResolutionImage});
/// }
/// ```
class Lazy {
  /// Creates a lazy field annotation.
  ///
  /// The [placeholder] value is returned when the field hasn't been loaded yet.
  /// If [preloadOnWatch] is true, the field will be automatically loaded
  /// when the entity is watched.
  const Lazy({
    this.placeholder,
    this.preloadOnWatch = false,
  });

  /// Default value to return when the field hasn't been loaded.
  final Object? placeholder;

  /// Whether to automatically load this field when the entity is watched.
  final bool preloadOnWatch;
}

/// Marks a class for lazy loading code generation.
///
/// When applied to a class, the build_runner will generate:
/// - Typed accessor methods for each `@Lazy` annotated field
/// - A wrapper class with lazy loading support (if [generateWrapper] is true)
///
/// ## Example
///
/// ```dart
/// @NexusLazy()
/// class User {
///   final String id;
///   final String name;
///
///   @Lazy()
///   final String? avatar;
///
///   User({required this.id, required this.name, this.avatar});
/// }
///
/// // Generated code provides:
/// // - UserLazyAccessors mixin with typed loadAvatar() method
/// // - LazyUser wrapper class
/// ```
class NexusLazy {
  /// Creates a NexusLazy annotation.
  ///
  /// If [generateAccessors] is true, generates typed accessor methods.
  /// If [generateWrapper] is true, generates a LazyEntity wrapper class.
  const NexusLazy({
    this.generateAccessors = true,
    this.generateWrapper = true,
  });

  /// Whether to generate typed accessor methods for lazy fields.
  final bool generateAccessors;

  /// Whether to generate a typed LazyEntity wrapper class.
  final bool generateWrapper;
}

/// Annotation for generated lazy field accessor methods.
///
/// This is used internally by the generator to mark generated accessor methods.
/// It provides metadata about which field the accessor loads.
///
/// ## Example (generated code)
///
/// ```dart
/// mixin UserLazyAccessors on LazyEntity<User, String> {
///   @LazyAccessor('avatar', returnType: 'String')
///   Future<String?> loadAvatar() => loadField('avatar') as Future<String?>;
/// }
/// ```
class LazyAccessor {
  /// Creates a lazy field accessor annotation.
  ///
  /// The [fieldName] is the name of the lazy field this accessor loads.
  /// The [returnType] is the expected return type (for documentation).
  const LazyAccessor(
    this.fieldName, {
    this.returnType,
  });

  /// The name of the lazy field this accessor loads.
  final String fieldName;

  /// The expected return type of the loaded field.
  final String? returnType;
}
