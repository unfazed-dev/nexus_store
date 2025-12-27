import 'package:collection/collection.dart';
import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/field_change.dart';

/// Tracks field-level changes between entity versions.
///
/// Uses JSON representation to compare entities field-by-field,
/// enabling delta sync with minimal bandwidth.
///
/// ## Example
///
/// ```dart
/// final tracker = DeltaTracker();
/// final original = User(name: 'John', email: 'john@example.com');
/// final modified = User(name: 'Jane', email: 'john@example.com');
///
/// final delta = tracker.trackChanges(
///   original: original,
///   modified: modified,
///   entityId: 'user-123',
/// );
///
/// print(delta.changedFields); // {name}
/// ```
class DeltaTracker {
  /// Creates a delta tracker with optional configuration.
  DeltaTracker({DeltaSyncConfig? config}) : _config = config;

  final DeltaSyncConfig? _config;

  /// Tracks changes between two entity versions.
  ///
  /// Entities must implement `toJson()` method that returns
  /// a `Map<String, dynamic>` representation.
  ///
  /// Returns a [DeltaChange] containing all field-level changes.
  DeltaChange<ID> trackChanges<ID>({
    required dynamic original,
    required dynamic modified,
    required ID entityId,
    int? baseVersion,
  }) {
    final originalJson = _toJsonMap(original);
    final modifiedJson = _toJsonMap(modified);

    return trackChangesFromJson(
      original: originalJson,
      modified: modifiedJson,
      entityId: entityId,
      baseVersion: baseVersion,
    );
  }

  /// Tracks changes between two JSON maps.
  ///
  /// Useful when you already have JSON representations of entities.
  DeltaChange<ID> trackChangesFromJson<ID>({
    required Map<String, dynamic> original,
    required Map<String, dynamic> modified,
    required ID entityId,
    int? baseVersion,
  }) {
    final timestamp = DateTime.now();
    final changes = <FieldChange>[];

    // Get all field names from both versions
    final allFields = {...original.keys, ...modified.keys};

    for (final fieldName in allFields) {
      // Skip excluded fields
      final config = _config;
      if (config != null && !config.shouldTrackField(fieldName)) {
        continue;
      }

      final oldValue = original[fieldName];
      final newValue = modified[fieldName];

      if (!_deepEquals(oldValue, newValue)) {
        changes.add(FieldChange(
          fieldName: fieldName,
          oldValue: oldValue,
          newValue: newValue,
          timestamp: timestamp,
        ));
      }
    }

    return DeltaChange<ID>(
      entityId: entityId,
      changes: changes,
      timestamp: timestamp,
      baseVersion: baseVersion,
    );
  }

  /// Returns a list of changed field names.
  List<String> getChangedFields({
    required dynamic original,
    required dynamic modified,
  }) {
    final originalJson = _toJsonMap(original);
    final modifiedJson = _toJsonMap(modified);

    final changedFields = <String>[];
    final allFields = {...originalJson.keys, ...modifiedJson.keys};

    for (final fieldName in allFields) {
      final config = _config;
      if (config != null && !config.shouldTrackField(fieldName)) {
        continue;
      }

      if (!_deepEquals(originalJson[fieldName], modifiedJson[fieldName])) {
        changedFields.add(fieldName);
      }
    }

    return changedFields;
  }

  /// Returns `true` if there are any changes between entities.
  bool hasChanges({
    required dynamic original,
    required dynamic modified,
  }) {
    final originalJson = _toJsonMap(original);
    final modifiedJson = _toJsonMap(modified);

    final allFields = {...originalJson.keys, ...modifiedJson.keys};

    for (final fieldName in allFields) {
      final config = _config;
      if (config != null && !config.shouldTrackField(fieldName)) {
        continue;
      }

      if (!_deepEquals(originalJson[fieldName], modifiedJson[fieldName])) {
        return true;
      }
    }

    return false;
  }

  /// Converts an entity to a JSON map.
  ///
  /// Supports entities with toJson() method or raw Map<String, dynamic>.
  Map<String, dynamic> _toJsonMap(dynamic entity) {
    if (entity is Map<String, dynamic>) {
      return entity;
    }

    // Try to call toJson() method
    try {
      // ignore: avoid_dynamic_calls
      final json = entity.toJson();
      if (json is Map<String, dynamic>) {
        return json;
      }
      throw ArgumentError(
        'Entity toJson() must return Map<String, dynamic>, got ${json.runtimeType}',
      );
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError(
        'Entity must implement toJson() method or be a Map<String, dynamic>',
      );
    }
  }

  /// Deep equality comparison for values.
  ///
  /// Handles nested maps, lists, and primitive values.
  bool _deepEquals(dynamic a, dynamic b) {
    return const DeepCollectionEquality().equals(a, b);
  }
}
