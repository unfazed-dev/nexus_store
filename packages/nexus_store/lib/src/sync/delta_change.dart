import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/sync/field_change.dart';

part 'delta_change.freezed.dart';

/// Represents a set of field-level changes to an entity.
///
/// Used for delta sync to track which fields have changed between versions
/// of an entity, enabling bandwidth-efficient synchronization.
///
/// ## Example
///
/// ```dart
/// final delta = DeltaChange<String>(
///   entityId: 'user-123',
///   changes: [
///     FieldChange(
///       fieldName: 'name',
///       oldValue: 'John',
///       newValue: 'Jane',
///       timestamp: DateTime.now(),
///     ),
///   ],
///   timestamp: DateTime.now(),
///   baseVersion: 5, // For optimistic concurrency
/// );
///
/// print('Changed fields: ${delta.changedFields}');
/// // Output: Changed fields: {name}
/// ```
@freezed
abstract class DeltaChange<ID> with _$DeltaChange<ID> {
  /// Creates a delta change record.
  const factory DeltaChange({
    /// The unique identifier of the entity that changed.
    required ID entityId,

    /// List of individual field changes.
    required List<FieldChange> changes,

    /// When this delta was created.
    required DateTime timestamp,

    /// The base version of the entity before changes.
    ///
    /// Used for optimistic concurrency control. When applying a delta,
    /// the current version must match this base version.
    int? baseVersion,
  }) = _DeltaChange<ID>;

  const DeltaChange._();

  /// Returns `true` if there are no changes.
  bool get isEmpty => changes.isEmpty;

  /// Returns `true` if there are any changes.
  bool get isNotEmpty => changes.isNotEmpty;

  /// Returns the number of changed fields.
  int get fieldCount => changes.length;

  /// Returns a set of all changed field names.
  Set<String> get changedFields =>
      changes.map((c) => c.fieldName).toSet();

  /// Gets the change for a specific field, or null if not changed.
  FieldChange? getChange(String fieldName) {
    for (final change in changes) {
      if (change.fieldName == fieldName) {
        return change;
      }
    }
    return null;
  }

  /// Returns `true` if the specified field has a change.
  bool hasField(String fieldName) => getChange(fieldName) != null;
}
