/// Sealed class representing a single operation within a transaction.
///
/// Operations store the data needed to apply and rollback the change:
/// - [SaveOperation] stores the item to save and original value for rollback
/// - [DeleteOperation] stores the ID and original value for restoration
sealed class TransactionOperation<T, ID> {
  /// Creates a transaction operation with timestamp.
  const TransactionOperation({required this.timestamp});

  /// When this operation was created.
  final DateTime timestamp;
}

/// Represents a save (insert or update) operation within a transaction.
final class SaveOperation<T, ID> extends TransactionOperation<T, ID> {
  /// Creates a save operation.
  const SaveOperation({
    required this.item,
    required this.id,
    this.originalValue,
    required super.timestamp,
  });

  /// The item to save.
  final T item;

  /// The ID of the item being saved.
  final ID id;

  /// The original value before this save (null if insert, value if update).
  ///
  /// Used for rollback: if originalValue is null, delete the item;
  /// if originalValue exists, restore it.
  final T? originalValue;

  /// Whether this is an insert (no original value) or update.
  bool get isInsert => originalValue == null;

  /// Whether this is an update (has original value).
  bool get isUpdate => originalValue != null;
}

/// Represents a delete operation within a transaction.
final class DeleteOperation<T, ID> extends TransactionOperation<T, ID> {
  /// Creates a delete operation.
  const DeleteOperation({
    required this.id,
    this.originalValue,
    required super.timestamp,
  });

  /// The ID of the item to delete.
  final ID id;

  /// The original value before deletion (for rollback restoration).
  final T? originalValue;

  /// Whether the item existed before deletion.
  bool get hadValue => originalValue != null;
}
