import 'package:nexus_store/src/transaction/transaction_operation.dart';

/// Internal context for managing transaction state.
///
/// Tracks all operations performed within a transaction, manages savepoints
/// for nested transactions, and handles commit/rollback state.
class TransactionContext<T, ID> {
  /// Creates a new transaction context.
  ///
  /// - [id]: Unique identifier for this transaction
  /// - [parentContext]: Parent context for nested transactions (savepoints)
  TransactionContext({
    required this.id,
    this.parentContext,
  }) : startedAt = DateTime.now();

  /// Unique transaction identifier.
  final String id;

  /// When this transaction started.
  final DateTime startedAt;

  /// Parent context for nested transactions (savepoints).
  ///
  /// If non-null, this transaction is nested and will create a savepoint
  /// in the parent rather than a separate transaction.
  final TransactionContext<T, ID>? parentContext;

  /// Pending operations in this transaction.
  ///
  /// Operations are added as they're performed and applied on commit,
  /// or reverted in reverse order on rollback.
  final List<TransactionOperation<T, ID>> operations = [];

  /// Savepoint markers (indices into the operations list).
  ///
  /// Each savepoint marks a position that can be rolled back to
  /// without rolling back the entire transaction.
  final List<int> savepoints = [];

  /// Whether this transaction has been successfully committed.
  bool isCommitted = false;

  /// Whether this transaction has been rolled back.
  bool isRolledBack = false;

  /// Whether this is a nested transaction (has parent context).
  bool get isNested => parentContext != null;

  /// Whether this transaction is still active (not committed or rolled back).
  bool get isActive => !isCommitted && !isRolledBack;

  /// The depth of nesting (0 for top-level transactions).
  int get depth {
    var d = 0;
    var ctx = parentContext;
    while (ctx != null) {
      d++;
      ctx = ctx.parentContext;
    }
    return d;
  }

  /// Creates a savepoint at the current position.
  ///
  /// Returns the savepoint index that can be used with [rollbackToSavepoint].
  int createSavepoint() {
    final index = operations.length;
    savepoints.add(index);
    return index;
  }

  /// Rolls back to a specific savepoint.
  ///
  /// Removes all operations after the savepoint and returns them in reverse
  /// order (for reverting). Throws [ArgumentError] if the savepoint is invalid.
  List<TransactionOperation<T, ID>> rollbackToSavepoint(int savepointIndex) {
    if (!savepoints.contains(savepointIndex)) {
      throw ArgumentError('Invalid savepoint index: $savepointIndex');
    }

    // Get operations to rollback (in reverse order)
    final operationsToRollback =
        operations.sublist(savepointIndex).reversed.toList();

    // Remove operations after savepoint
    operations.removeRange(savepointIndex, operations.length);

    // Remove savepoints at or after this index
    savepoints.removeWhere((s) => s >= savepointIndex);

    return operationsToRollback;
  }

  /// Gets all operations in reverse order (for rollback).
  List<TransactionOperation<T, ID>> get operationsReversed =>
      operations.reversed.toList();

  @override
  String toString() => 'TransactionContext('
      'id: $id, '
      'operations: ${operations.length}, '
      'savepoints: ${savepoints.length}, '
      'isActive: $isActive)';
}
