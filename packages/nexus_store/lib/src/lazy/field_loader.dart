import 'dart:async';

import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';

/// Handles on-demand loading of entity fields with caching and batching support.
///
/// Used by [NexusStore] to implement lazy field loading for heavy fields
/// like images, blobs, or large text content.
///
/// ## Example
///
/// ```dart
/// final loader = FieldLoader<User, String>(
///   backend: backend,
///   config: LazyLoadConfig(
///     lazyFields: {'avatar', 'fullBio'},
///     batchSize: 10,
///   ),
/// );
///
/// // Load a single field
/// final avatar = await loader.loadField('user-123', 'avatar');
///
/// // Load field for multiple entities
/// final avatars = await loader.loadFieldBatch(
///   ['user-1', 'user-2', 'user-3'],
///   'avatar',
/// );
/// ```
class FieldLoader<T, ID> {
  /// Creates a field loader.
  FieldLoader({
    required StoreBackend<T, ID> backend,
    // ignore: unused_element - reserved for future batching configuration
    LazyLoadConfig config = const LazyLoadConfig(),
  }) : _backend = backend;

  final StoreBackend<T, ID> _backend;

  /// Cache of loaded field values: entityId -> fieldName -> value
  final Map<ID, Map<String, dynamic>> _cache = {};

  /// Cache of field states: entityId -> fieldName -> state
  final Map<ID, Map<String, LazyFieldState>> _states = {};

  /// Pending load operations for deduplication: entityId:fieldName -> Future
  final Map<String, Future<dynamic>> _pendingLoads = {};

  /// Loads a specific field for an entity.
  ///
  /// Returns the cached value if available, otherwise loads from backend.
  /// Concurrent calls for the same field are deduplicated.
  Future<dynamic> loadField(ID id, String fieldName) async {
    // Check cache first
    final cached = _cache[id]?[fieldName];
    if (cached != null || _states[id]?[fieldName] == LazyFieldState.loaded) {
      return cached;
    }

    // Check for pending load
    final pendingKey = _pendingKey(id, fieldName);
    if (_pendingLoads.containsKey(pendingKey)) {
      return _pendingLoads[pendingKey];
    }

    // Start new load
    final future = _doLoadField(id, fieldName);
    _pendingLoads[pendingKey] = future;

    try {
      return await future;
    } finally {
      _pendingLoads.remove(pendingKey);
    }
  }

  Future<dynamic> _doLoadField(ID id, String fieldName) async {
    _setFieldState(id, fieldName, LazyFieldState.loading);

    try {
      final value = await _backend.getField(id, fieldName);
      _setFieldState(id, fieldName, LazyFieldState.loaded);
      _setCachedValue(id, fieldName, value);
      return value;
    } catch (e) {
      _setFieldState(id, fieldName, LazyFieldState.error);
      rethrow;
    }
  }

  /// Loads a specific field for multiple entities.
  ///
  /// Returns a map of entity ID to field value.
  /// Entities that don't have the field are omitted from the result.
  Future<Map<ID, dynamic>> loadFieldBatch(
    List<ID> ids,
    String fieldName,
  ) async {
    // Filter out already cached IDs
    final uncachedIds = <ID>[];
    final results = <ID, dynamic>{};

    for (final id in ids) {
      if (_states[id]?[fieldName] == LazyFieldState.loaded) {
        final cached = _cache[id]?[fieldName];
        if (cached != null) {
          results[id] = cached;
        }
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) {
      return results;
    }

    // Set loading state for uncached IDs
    for (final id in uncachedIds) {
      _setFieldState(id, fieldName, LazyFieldState.loading);
    }

    try {
      // Batch load from backend
      final batchResults = await _backend.getFieldBatch(uncachedIds, fieldName);

      // Cache results and update states
      for (final entry in batchResults.entries) {
        _setCachedValue(entry.key, fieldName, entry.value);
        _setFieldState(entry.key, fieldName, LazyFieldState.loaded);
        results[entry.key] = entry.value;
      }

      // Mark entities without values as loaded (with null)
      for (final id in uncachedIds) {
        if (!batchResults.containsKey(id)) {
          _setFieldState(id, fieldName, LazyFieldState.loaded);
        }
      }

      return results;
    } catch (e) {
      // Mark all as error
      for (final id in uncachedIds) {
        _setFieldState(id, fieldName, LazyFieldState.error);
      }
      rethrow;
    }
  }

  /// Returns the current loading state for a field.
  LazyFieldState getFieldState(ID id, String fieldName) {
    return _states[id]?[fieldName] ?? LazyFieldState.notLoaded;
  }

  /// Preloads multiple fields for multiple entities.
  ///
  /// Useful for preloading fields that will be needed soon.
  Future<void> preloadFields(
    List<ID> ids,
    Set<String> fieldNames,
  ) async {
    final futures = <Future<void>>[];

    for (final fieldName in fieldNames) {
      futures.add(loadFieldBatch(ids, fieldName).then((_) {}));
    }

    await Future.wait(futures);
  }

  /// Clears all cached values and states.
  void clearCache() {
    _cache.clear();
    _states.clear();
  }

  /// Clears cached values for a specific entity.
  void clearCacheForEntity(ID id) {
    _cache.remove(id);
    _states.remove(id);
  }

  /// Disposes resources used by the loader.
  Future<void> dispose() async {
    clearCache();
    _pendingLoads.clear();
  }

  // Helper methods

  String _pendingKey(ID id, String fieldName) => '$id:$fieldName';

  void _setFieldState(ID id, String fieldName, LazyFieldState state) {
    _states[id] ??= {};
    _states[id]![fieldName] = state;
  }

  void _setCachedValue(ID id, String fieldName, dynamic value) {
    _cache[id] ??= {};
    _cache[id]![fieldName] = value;
  }
}
