import 'package:nexus_store/src/lazy/lazy_load_config.dart';

/// Registry for lazy field configurations per entity type.
///
/// Allows registering and retrieving [LazyLoadConfig] instances for different
/// entity types. Used by [FieldLoader] to determine which fields should be
/// loaded lazily.
///
/// ## Example
///
/// ```dart
/// final registry = LazyFieldRegistry();
///
/// // Register lazy fields for User entities
/// registry.register<User>(const LazyLoadConfig(
///   lazyFields: {'avatar', 'profileImage'},
/// ));
///
/// // Check if a field is lazy
/// print(registry.isLazy<User>('avatar')); // true
/// print(registry.isLazy<User>('name')); // false
///
/// // Get the full config
/// final config = registry.getConfig<User>();
/// ```
class LazyFieldRegistry {
  final Map<Type, LazyLoadConfig> _configs = {};

  /// Registers a lazy load configuration for entity type [T].
  ///
  /// If a configuration was previously registered for this type, it is
  /// replaced with the new [config].
  void register<T>(LazyLoadConfig config) {
    _configs[T] = config;
  }

  /// Returns the configuration for entity type [T], or `null` if not registered.
  LazyLoadConfig? getConfig<T>() {
    return _configs[T];
  }

  /// Returns `true` if [fieldName] is configured as lazy for entity type [T].
  ///
  /// Returns `false` if the type is not registered or if the field is not
  /// in the lazy fields set.
  bool isLazy<T>(String fieldName) {
    final config = _configs[T];
    if (config == null) return false;
    return config.isLazyField(fieldName);
  }

  /// Clears all registered configurations.
  void clear() {
    _configs.clear();
  }
}
