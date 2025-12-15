import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_entry.freezed.dart';
part 'audit_log_entry.g.dart';

/// An immutable audit log entry for compliance tracking.
///
/// Captures all information about a data operation for HIPAA, SOX, or
/// other compliance requirements.
///
/// ## Example
///
/// ```dart
/// final entry = AuditLogEntry(
///   action: AuditAction.read,
///   entityType: 'Patient',
///   entityId: 'patient-123',
///   userId: 'user-456',
///   fields: ['name', 'ssn'],
/// );
/// ```
@freezed
abstract class AuditLogEntry with _$AuditLogEntry {
  /// Creates an audit log entry.
  const factory AuditLogEntry({
    /// Unique identifier for this log entry.
    required String id,

    /// Timestamp when the action occurred.
    required DateTime timestamp,

    /// The action that was performed.
    required AuditAction action,

    /// Type of entity that was accessed/modified.
    required String entityType,

    /// Identifier of the entity.
    required String entityId,

    /// User or service that performed the action.
    required String actorId,

    /// Type of actor (user, service, system).
    @Default(ActorType.user) ActorType actorType,

    /// Fields that were accessed or modified.
    @Default([]) List<String> fields,

    /// Previous values (for updates/deletes).
    Map<String, dynamic>? previousValues,

    /// New values (for creates/updates).
    Map<String, dynamic>? newValues,

    /// IP address of the client.
    String? ipAddress,

    /// User agent string.
    String? userAgent,

    /// Session identifier.
    String? sessionId,

    /// Request identifier for correlation.
    String? requestId,

    /// Whether the operation succeeded.
    @Default(true) bool success,

    /// Error message if operation failed.
    String? errorMessage,

    /// Additional metadata.
    @Default({}) Map<String, dynamic> metadata,

    /// Hash of previous log entry (for chain integrity).
    String? previousHash,

    /// Hash of this entry (computed after creation).
    String? hash,
  }) = _AuditLogEntry;

  const AuditLogEntry._();

  /// Creates an entry from JSON.
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);
}

/// Actions that can be audited.
enum AuditAction {
  /// Entity was created.
  create,

  /// Entity was read/retrieved.
  read,

  /// Entity was updated.
  update,

  /// Entity was deleted.
  delete,

  /// Multiple entities were listed/queried.
  list,

  /// Entity was exported.
  export_,

  /// Entity was imported.
  import_,

  /// Access was denied.
  accessDenied,

  /// Login attempt.
  login,

  /// Logout.
  logout,

  /// Encryption key was accessed.
  keyAccess,

  /// Data was decrypted.
  decrypt,
}

/// Types of actors that can perform actions.
enum ActorType {
  /// Human user.
  user,

  /// Automated service.
  service,

  /// System process.
  system,

  /// External API client.
  apiClient,

  /// Anonymous/unauthenticated.
  anonymous,
}
