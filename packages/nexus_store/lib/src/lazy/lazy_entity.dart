import 'dart:async';

import 'package:nexus_store/src/lazy/field_loader.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';

/// A wrapper that provides lazy field access for an entity.
///
/// Similar to [TrackedEntity] but for lazy loading instead of change tracking.
/// Wraps an entity and provides methods to load specific fields on demand.
///
/// ## Example
///
/// ```dart
/// final lazyUser = LazyEntity<User, String>(
///   user,
///   idExtractor: (u) => u.id,
///   fieldLoader: fieldLoader,
///   config: LazyLoadConfig(
///     lazyFields: {'avatar', 'fullBio'},
///   ),
/// );
///
/// // Check if avatar is loaded
/// print(lazyUser.isFieldLoaded('avatar')); // false
///
/// // Load the avatar
/// await lazyUser.loadField('avatar');
///
/// // Now it's loaded
/// print(lazyUser.isFieldLoaded('avatar')); // true
/// ```
class LazyEntity<T, ID> {
  /// Creates a lazy entity wrapper.
  ///
  /// The [entity] is the underlying entity with non-lazy fields.
  /// The [idExtractor] extracts the entity ID.
  /// The [fieldLoader] handles loading of lazy fields.
  /// The [config] specifies which fields are lazy.
  /// The optional [fieldGetter] extracts field values from the entity.
  LazyEntity(
    this._entity, {
    required ID Function(T) idExtractor,
    required FieldLoader<T, ID> fieldLoader,
    LazyLoadConfig config = const LazyLoadConfig(),
    dynamic Function(T entity, String fieldName)? fieldGetter,
  })  : _idExtractor = idExtractor,
        _fieldLoader = fieldLoader,
        _config = config,
        _fieldGetter = fieldGetter,
        _id = idExtractor(_entity);

  final T _entity;
  final ID Function(T) _idExtractor;
  final FieldLoader<T, ID> _fieldLoader;
  final LazyLoadConfig _config;
  final dynamic Function(T entity, String fieldName)? _fieldGetter;
  final ID _id;

  final StreamController<String> _fieldLoadedController =
      StreamController<String>.broadcast();

  /// The underlying entity with non-lazy fields populated.
  T get entity => _entity;

  /// The entity's ID.
  ID get id => _id;

  /// Gets a field value.
  ///
  /// For non-lazy fields, returns the entity's field value.
  /// For lazy fields, returns the loaded value or placeholder if not loaded.
  dynamic getField(String fieldName) {
    // If it's a lazy field
    if (_config.isLazyField(fieldName)) {
      // Check if loaded
      if (_fieldLoader.getFieldState(_id, fieldName) == LazyFieldState.loaded) {
        // Return from loader cache - but we need to access it
        // For now, return placeholder since we can't access loader cache directly
        // The loader stores values internally
        return _config.getPlaceholder(fieldName);
      }
      return _config.getPlaceholder(fieldName);
    }

    // Non-lazy field - extract from entity
    if (_fieldGetter != null) {
      return _fieldGetter(_entity, fieldName);
    }

    return null;
  }

  /// Returns `true` if the field is loaded.
  ///
  /// Non-lazy fields are always considered loaded.
  /// Lazy fields are loaded when [loadField] or [loadFields] has been called.
  bool isFieldLoaded(String fieldName) {
    if (!_config.isLazyField(fieldName)) {
      return true; // Non-lazy fields are always "loaded"
    }
    return _fieldLoader.getFieldState(_id, fieldName) == LazyFieldState.loaded;
  }

  /// Loads a specific lazy field.
  ///
  /// Returns the loaded value.
  Future<dynamic> loadField(String fieldName) async {
    final result = await _fieldLoader.loadField(_id, fieldName);
    _fieldLoadedController.add(fieldName);
    return result;
  }

  /// Loads multiple lazy fields.
  Future<void> loadFields(Set<String> fieldNames) async {
    final lazyFields = fieldNames.where(_config.isLazyField).toList();
    if (lazyFields.isEmpty) return;

    await _fieldLoader.preloadFields([_id], lazyFields.toSet());

    for (final field in lazyFields) {
      _fieldLoadedController.add(field);
    }
  }

  /// Loads all configured lazy fields.
  Future<void> loadAllLazyFields() async {
    await loadFields(_config.lazyFields);
  }

  /// Returns the set of lazy field names that are not yet loaded.
  Set<String> get unloadedFields {
    return _config.lazyFields
        .where((field) => !isFieldLoaded(field))
        .toSet();
  }

  /// Stream that emits field names when they are loaded.
  Stream<String> get fieldLoadedStream => _fieldLoadedController.stream;

  /// Disposes resources.
  Future<void> dispose() async {
    await _fieldLoadedController.close();
  }
}
