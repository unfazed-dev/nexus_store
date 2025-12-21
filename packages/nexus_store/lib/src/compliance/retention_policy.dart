import 'package:freezed_annotation/freezed_annotation.dart';

part 'retention_policy.freezed.dart';
part 'retention_policy.g.dart';

/// Actions that can be applied to data when retention period expires.
enum RetentionAction {
  /// Set the field value to null.
  nullify,

  /// Replace with an anonymous/pseudonymized value.
  anonymize,

  /// Delete the entire record.
  deleteRecord,

  /// Move the record to an archive store.
  archive,
}

/// Defines a retention policy for a specific field.
///
/// Retention policies specify how long data should be retained and what
/// action to take when the retention period expires.
@freezed
abstract class RetentionPolicy with _$RetentionPolicy {
  const factory RetentionPolicy({
    /// The field name to apply this policy to.
    required String field,

    /// How long to retain the data.
    required Duration duration,

    /// What action to take when the retention period expires.
    required RetentionAction action,

    /// Optional condition expression for when to apply this policy.
    /// If null, the policy applies unconditionally.
    String? condition,
  }) = _RetentionPolicy;

  const RetentionPolicy._();

  factory RetentionPolicy.fromJson(Map<String, dynamic> json) =>
      _$RetentionPolicyFromJson(json);
}

/// Result of a retention processing operation.
@freezed
abstract class RetentionResult with _$RetentionResult {
  const RetentionResult._();

  const factory RetentionResult({
    /// When the retention processing occurred.
    required DateTime processedAt,

    /// Number of fields that were nullified.
    required int nullifiedCount,

    /// Number of fields that were anonymized.
    required int anonymizedCount,

    /// Number of records that were deleted.
    required int deletedCount,

    /// Number of records that were archived.
    required int archivedCount,

    /// Any errors that occurred during processing.
    required List<RetentionError> errors,
  }) = _RetentionResult;

  /// Total number of items processed successfully.
  int get totalProcessed =>
      nullifiedCount + anonymizedCount + deletedCount + archivedCount;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;

  factory RetentionResult.fromJson(Map<String, dynamic> json) =>
      _$RetentionResultFromJson(json);
}

/// An error that occurred during retention processing.
@freezed
abstract class RetentionError with _$RetentionError {
  const factory RetentionError({
    /// The ID of the entity that caused the error.
    required String entityId,

    /// The field being processed when the error occurred.
    required String field,

    /// Description of the error.
    required String message,
  }) = _RetentionError;

  const RetentionError._();

  factory RetentionError.fromJson(Map<String, dynamic> json) =>
      _$RetentionErrorFromJson(json);
}
