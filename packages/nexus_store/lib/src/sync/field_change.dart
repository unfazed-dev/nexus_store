import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_change.freezed.dart';

/// Represents a change to a single field within an entity.
///
/// Used for delta sync to track which fields have changed between
/// the original and modified versions of an entity.
///
/// ## Example
///
/// ```dart
/// final change = FieldChange(
///   fieldName: 'name',
///   oldValue: 'John',
///   newValue: 'Jane',
///   timestamp: DateTime.now(),
/// );
///
/// if (change.hasChanged) {
///   print('${change.fieldName} changed from ${change.oldValue} to ${change.newValue}');
/// }
/// ```
@freezed
abstract class FieldChange with _$FieldChange {
  /// Creates a field change record.
  const factory FieldChange({
    /// The name of the field that changed.
    required String fieldName,

    /// The previous value of the field (null if field was added).
    required dynamic oldValue,

    /// The new value of the field (null if field was removed).
    required dynamic newValue,

    /// When the change was detected.
    required DateTime timestamp,
  }) = _FieldChange;

  const FieldChange._();

  /// Returns `true` if the field value actually changed.
  ///
  /// Returns `false` if both oldValue and newValue are equal or both null.
  bool get hasChanged => oldValue != newValue;

  /// Returns `true` if this represents a new field being added.
  ///
  /// A field is considered added when oldValue is null and newValue is not.
  bool get isAddition => oldValue == null && newValue != null;

  /// Returns `true` if this represents a field being removed.
  ///
  /// A field is considered removed when oldValue exists and newValue is null.
  bool get isRemoval => oldValue != null && newValue == null;

  /// Returns `true` if this represents a modification to an existing field.
  ///
  /// A field is considered modified when both values exist and differ.
  bool get isModification =>
      oldValue != null && newValue != null && oldValue != newValue;
}
