import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_change.freezed.dart';

/// The type of operation for a pending change.
enum PendingChangeOperation {
  /// A new entity is being created.
  create,

  /// An existing entity is being updated.
  update,

  /// An existing entity is being deleted.
  delete,
}

/// Represents a pending change that has not yet been synced to the server.
///
/// Pending changes are tracked to provide visibility into the sync queue
/// and to support retry and cancellation operations.
///
/// ## Example
///
/// ```dart
/// store.pendingChanges.listen((changes) {
///   for (final change in changes) {
///     print('${change.operation}: ${change.item}');
///     if (change.hasFailed) {
///       print('  Failed after ${change.retryCount} retries');
///       print('  Error: ${change.lastError}');
///     }
///   }
/// });
/// ```
@freezed
abstract class PendingChange<T> with _$PendingChange<T> {
  /// Creates a pending change.
  const factory PendingChange({
    /// Unique identifier for this pending change.
    required String id,

    /// The entity being changed.
    required T item,

    /// The type of operation (create, update, delete).
    required PendingChangeOperation operation,

    /// When this change was first queued.
    required DateTime createdAt,

    /// The original value before the change (for undo support).
    ///
    /// For create operations, this is null.
    /// For update operations, this is the value before the update.
    /// For delete operations, this is the deleted entity.
    T? originalValue,

    /// Number of retry attempts.
    @Default(0) int retryCount,

    /// The last error that occurred during sync, if any.
    Object? lastError,

    /// When the last sync attempt was made.
    DateTime? lastAttempt,
  }) = _PendingChange<T>;

  const PendingChange._();

  /// Returns `true` if this change has failed to sync.
  bool get hasFailed => lastError != null;

  /// Returns `true` if this change can be reverted.
  ///
  /// - Create operations can always be reverted (delete the created item).
  /// - Update operations can be reverted if originalValue is available.
  /// - Delete operations can be reverted if originalValue is available.
  bool get canRevert {
    return switch (operation) {
      PendingChangeOperation.create => true,
      PendingChangeOperation.update => originalValue != null,
      PendingChangeOperation.delete => originalValue != null,
    };
  }
}
