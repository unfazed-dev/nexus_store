/// Base class for all NexusStore errors.
///
/// All errors thrown by NexusStore are subclasses of [StoreError],
/// allowing for type-safe error handling.
///
/// ## Example
///
/// ```dart
/// try {
///   await store.get('user-123');
/// } on NotFoundError catch (e) {
///   print('Entity not found: ${e.id}');
/// } on NetworkError catch (e) {
///   if (e.isRetryable) {
///     // Retry the operation
///   }
/// } on StoreError catch (e) {
///   // Handle any other store error
///   print('Store error: ${e.message}');
/// }
/// ```
sealed class StoreError implements Exception {
  /// Creates a store error.
  const StoreError({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable error message.
  final String message;

  /// Error code for programmatic handling.
  final String? code;

  /// Underlying cause of this error.
  final Object? cause;

  /// Stack trace when error was created.
  final StackTrace? stackTrace;

  /// Whether this error is potentially recoverable through retry.
  bool get isRetryable => false;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (cause != null) buffer.write('\nCaused by: $cause');
    return buffer.toString();
  }
}

/// Error thrown when an entity is not found.
class NotFoundError extends StoreError {
  /// Creates a not found error.
  const NotFoundError({
    required this.id,
    this.entityType,
    super.cause,
    super.stackTrace,
  }) : super(
          message: entityType != null
              ? '$entityType with id "$id" not found'
              : 'Entity with id "$id" not found',
          code: 'NOT_FOUND',
        );

  /// The ID that was not found.
  final Object id;

  /// The type of entity that was not found.
  final String? entityType;
}

/// Error thrown when a network operation fails.
class NetworkError extends StoreError {
  /// Creates a network error.
  const NetworkError({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.cause,
    super.stackTrace,
    this.statusCode,
    this.url,
  });

  /// HTTP status code, if available.
  final int? statusCode;

  /// URL that failed, if available.
  final String? url;

  @override
  bool get isRetryable =>
      statusCode == null ||
      statusCode! >= 500 ||
      statusCode == 408 ||
      statusCode == 429;
}

/// Error thrown when a timeout occurs.
class TimeoutError extends StoreError {
  /// Creates a timeout error.
  const TimeoutError({
    required this.duration,
    this.operation,
    super.cause,
    super.stackTrace,
  }) : super(
          message: operation != null
              ? 'Operation "$operation" timed out after $duration'
              : 'Operation timed out after $duration',
          code: 'TIMEOUT',
        );

  /// The timeout duration.
  final Duration duration;

  /// The operation that timed out.
  final String? operation;

  @override
  bool get isRetryable => true;
}

/// Error thrown when validation fails.
class ValidationError extends StoreError {
  /// Creates a validation error.
  const ValidationError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.field,
    this.value,
    this.violations = const [],
  }) : super(code: 'VALIDATION_ERROR');

  /// The field that failed validation.
  final String? field;

  /// The invalid value.
  final Object? value;

  /// List of validation violations.
  final List<ValidationViolation> violations;
}

/// A single validation violation.
class ValidationViolation {
  /// Creates a validation violation.
  const ValidationViolation({
    required this.field,
    required this.message,
    this.value,
    this.constraint,
  });

  /// The field that failed validation.
  final String field;

  /// Human-readable error message.
  final String message;

  /// The invalid value.
  final Object? value;

  /// The constraint that was violated.
  final String? constraint;

  @override
  String toString() => 'ValidationViolation($field: $message)';
}

/// Error thrown when a conflict occurs during sync.
class ConflictError extends StoreError {
  /// Creates a conflict error.
  const ConflictError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.localVersion,
    this.remoteVersion,
    this.conflictedFields = const [],
  }) : super(code: 'CONFLICT');

  /// The local version of the entity.
  final Object? localVersion;

  /// The remote version of the entity.
  final Object? remoteVersion;

  /// Fields that have conflicting values.
  final List<String> conflictedFields;
}

/// Error thrown when synchronization fails.
class SyncError extends StoreError {
  /// Creates a sync error.
  const SyncError({
    required super.message,
    super.code = 'SYNC_ERROR',
    super.cause,
    super.stackTrace,
    this.pendingChanges = 0,
  });

  /// Number of pending changes that couldn't be synced.
  final int pendingChanges;

  @override
  bool get isRetryable => true;
}

/// Error thrown when authentication fails.
class AuthenticationError extends StoreError {
  /// Creates an authentication error.
  const AuthenticationError({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'AUTHENTICATION_ERROR');
}

/// Error thrown when authorization fails.
class AuthorizationError extends StoreError {
  /// Creates an authorization error.
  const AuthorizationError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.requiredPermission,
  }) : super(code: 'AUTHORIZATION_ERROR');

  /// The permission that was required.
  final String? requiredPermission;
}

/// Error thrown when a transaction fails.
class TransactionError extends StoreError {
  /// Creates a transaction error.
  const TransactionError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.wasRolledBack = false,
  }) : super(code: 'TRANSACTION_ERROR');

  /// Whether the transaction was rolled back.
  final bool wasRolledBack;
}

/// Error thrown when the store is in an invalid state.
class StateError extends StoreError {
  /// Creates a state error.
  const StateError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.currentState,
    this.expectedState,
  }) : super(code: 'STATE_ERROR');

  /// The current state of the store.
  final String? currentState;

  /// The expected state.
  final String? expectedState;
}

/// Error thrown when an operation is cancelled.
class CancellationError extends StoreError {
  /// Creates a cancellation error.
  const CancellationError({
    this.operation,
    super.cause,
    super.stackTrace,
  }) : super(
          message: operation != null
              ? 'Operation "$operation" was cancelled'
              : 'Operation was cancelled',
          code: 'CANCELLED',
        );

  /// The operation that was cancelled.
  final String? operation;
}

/// Error thrown when a quota or limit is exceeded.
class QuotaExceededError extends StoreError {
  /// Creates a quota exceeded error.
  const QuotaExceededError({
    required super.message,
    super.cause,
    super.stackTrace,
    this.limit,
    this.current,
    this.quotaType,
  }) : super(code: 'QUOTA_EXCEEDED');

  /// The quota limit.
  final int? limit;

  /// The current usage.
  final int? current;

  /// The type of quota (e.g., 'storage', 'requests').
  final String? quotaType;
}
