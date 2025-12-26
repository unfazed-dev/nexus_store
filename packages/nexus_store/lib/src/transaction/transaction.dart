import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/errors/store_errors.dart';
import 'package:nexus_store/src/transaction/transaction_context.dart';
import 'package:nexus_store/src/transaction/transaction_operation.dart';

/// User-facing transaction API for collecting operations.
///
/// Operations are queued and only applied when the transaction commits.
/// If the transaction fails, all operations are rolled back automatically.
///
/// ## Example
///
/// ```dart
/// await store.transaction((tx) async {
///   await tx.save(user);
///   await tx.save(profile);
///   return user.id;
/// });
/// ```
///
/// ## Important Notes
///
/// - Operations are not applied immediately; they're queued until commit
/// - Original values are fetched for rollback support
/// - Transaction objects become invalid after commit or rollback
class Transaction<T, ID> {
  /// Creates a transaction.
  ///
  /// **Note:** This constructor is for internal use only.
  /// Use `NexusStore.transaction()` to create transactions.
  Transaction.internal({
    required this.context,
    required StoreBackend<T, ID> backend,
    required ID Function(T)? idExtractor,
  })  : _backend = backend,
        _idExtractor = idExtractor;

  /// The internal context managing this transaction's state.
  final TransactionContext<T, ID> context;

  /// Backend for fetching original values.
  final StoreBackend<T, ID> _backend;

  /// Function to extract ID from entity.
  final ID Function(T)? _idExtractor;

  /// Queues a save operation within this transaction.
  ///
  /// The item is not immediately saved; it's queued and applied on commit.
  /// Returns the item that will be saved.
  ///
  /// Throws [TransactionError] if the transaction is no longer active.
  Future<T> save(T item) async {
    _ensureActive();

    final id = _extractId(item);
    T? originalValue;

    // Fetch original value for rollback support
    if (id != null) {
      originalValue = await _backend.get(id);
    }

    context.operations.add(SaveOperation<T, ID>(
      item: item,
      id: id as ID,
      originalValue: originalValue,
      timestamp: DateTime.now(),
    ));

    return item;
  }

  /// Queues multiple save operations within this transaction.
  ///
  /// More efficient than calling [save] multiple times.
  /// Returns the items that will be saved.
  ///
  /// Throws [TransactionError] if the transaction is no longer active.
  Future<List<T>> saveAll(List<T> items) async {
    _ensureActive();

    for (final item in items) {
      await save(item);
    }
    return items;
  }

  /// Queues a delete operation within this transaction.
  ///
  /// The item is not immediately deleted; it's queued and applied on commit.
  ///
  /// Throws [TransactionError] if the transaction is no longer active.
  Future<void> delete(ID id) async {
    _ensureActive();

    // Fetch original value for rollback support
    final originalValue = await _backend.get(id);

    context.operations.add(DeleteOperation<T, ID>(
      id: id,
      originalValue: originalValue,
      timestamp: DateTime.now(),
    ));
  }

  /// Queues multiple delete operations within this transaction.
  ///
  /// More efficient than calling [delete] multiple times.
  ///
  /// Throws [TransactionError] if the transaction is no longer active.
  Future<void> deleteAll(List<ID> ids) async {
    _ensureActive();

    for (final id in ids) {
      await delete(id);
    }
  }

  /// Extracts the ID from an item using the configured extractor.
  ID? _extractId(T item) {
    if (_idExtractor != null) {
      return _idExtractor(item);
    }
    return null;
  }

  /// Ensures the transaction is still active.
  void _ensureActive() {
    if (context.isCommitted) {
      throw const TransactionError(
        message: 'Cannot perform operations on committed transaction',
      );
    }
    if (context.isRolledBack) {
      throw const TransactionError(
        message: 'Cannot perform operations on rolled back transaction',
        wasRolledBack: true,
      );
    }
  }
}
