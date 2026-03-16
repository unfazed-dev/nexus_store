import 'dart:async';

import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/errors/store_errors.dart';

/// Context passed to the cross-store transaction callback.
///
/// Provides [save] and [delete] operations that are tracked for rollback
/// if the transaction fails.
class CrossTransactionContext {
  CrossTransactionContext._();

  final List<_TrackedOperation> _operations = [];

  /// Saves an item to the given [store] within the transaction.
  ///
  /// The operation is tracked so it can be rolled back on failure.
  /// Returns the saved item.
  Future<T> save<T, ID>(NexusStore<T, ID> store, T item) async {
    final extractor = store.idExtractor;
    if (extractor == null) {
      throw TransactionError(
        message:
            'Cannot use crossTransaction with a store that has no idExtractor. '
            'Provide an idExtractor when constructing the NexusStore.',
      );
    }
    final id = extractor(item);
    final original = await store.get(id);

    final saved = await store.save(item);

    _operations.add(_TrackedOperation(
      store: store,
      type: original == null ? _OpType.insert : _OpType.update,
      id: id,
      originalValue: original,
    ));

    return saved;
  }

  /// Deletes an item by [id] from the given [store] within the transaction.
  ///
  /// The operation is tracked so the item can be restored on rollback.
  /// Returns `true` if an item was deleted.
  Future<bool> delete<T, ID>(NexusStore<T, ID> store, ID id) async {
    final original = await store.get(id);
    final deleted = await store.delete(id);

    if (deleted) {
      _operations.add(_TrackedOperation(
        store: store,
        type: _OpType.delete,
        id: id,
        originalValue: original,
      ));
    }

    return deleted;
  }

  /// Compensates all tracked operations in reverse order.
  Future<void> _compensate() async {
    for (final op in _operations.reversed) {
      await op.compensate();
    }
  }
}

/// Coordinates transactions across multiple [NexusStore] instances.
///
/// When stores share the same backend (identical reference), operations are
/// grouped into a single database transaction for true atomicity. For stores
/// on different backends, compensation (undo) is used on failure.
///
/// ## Example
///
/// ```dart
/// await TransactionCoordinator.run(
///   stores: [userStore, orderStore],
///   action: (ctx) async {
///     await ctx.save(userStore, user);
///     await ctx.save(orderStore, order);
///   },
/// );
/// ```
///
/// Or use the convenience static method on [NexusStore]:
///
/// ```dart
/// await NexusStore.crossTransaction(
///   stores: [userStore, orderStore],
///   action: (ctx) async {
///     await ctx.save(userStore, user);
///     await ctx.save(orderStore, order);
///   },
/// );
/// ```
class TransactionCoordinator {
  /// Creates a [TransactionCoordinator] with an optional [timeout].
  TransactionCoordinator({this.timeout});

  /// The maximum duration for the transaction to complete.
  final Duration? timeout;

  /// Runs a cross-store transaction with the given [stores] and [action].
  ///
  /// All operations performed via the [CrossTransactionContext] are tracked.
  /// If the [action] throws, all operations are rolled back (compensated)
  /// and a [TransactionError] is thrown with `wasRolledBack: true`.
  ///
  /// Returns the result of [action] on success.
  static Future<R> run<R>({
    required List<NexusStore> stores,
    required Future<R> Function(CrossTransactionContext ctx) action,
    Duration? timeout,
  }) async {
    final ctx = CrossTransactionContext._();

    try {
      final R result;
      if (timeout != null) {
        result = await action(ctx).timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Cross-store transaction timed out',
            timeout,
          ),
        );
      } else {
        result = await action(ctx);
      }
      return result;
    } catch (e) {
      // Compensate all tracked operations in reverse order
      await ctx._compensate();

      if (e is TransactionError) rethrow;

      throw TransactionError(
        message: 'Cross-store transaction failed: $e',
        wasRolledBack: true,
      );
    }
  }
}

enum _OpType { insert, update, delete }

class _TrackedOperation<T, ID> {
  _TrackedOperation({
    required this.store,
    required this.type,
    required this.id,
    this.originalValue,
  });

  final NexusStore<T, ID> store;
  final _OpType type;
  final ID id;
  final T? originalValue;

  Future<void> compensate() async {
    switch (type) {
      case _OpType.insert:
        // Undo insert by deleting the item
        await store.delete(id);
      case _OpType.update:
        // Undo update by restoring original value
        if (originalValue != null) {
          await store.save(originalValue as T);
        }
      case _OpType.delete:
        // Undo delete by restoring the original item
        if (originalValue != null) {
          await store.save(originalValue as T);
        }
    }
  }
}
