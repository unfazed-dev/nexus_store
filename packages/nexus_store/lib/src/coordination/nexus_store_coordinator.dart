import 'dart:async';

import 'package:uuid/uuid.dart';

import '../core/nexus_store.dart';
import 'saga_coordinator.dart';
import 'saga_event.dart';
import 'saga_persistence.dart';
import 'saga_result.dart';
import 'saga_step.dart';

/// Coordinates transactions across multiple NexusStore instances.
///
/// Provides automatic compensation for save/delete operations, ensuring
/// that if any step fails, all previous operations are rolled back.
///
/// ## Example
///
/// ```dart
/// final coordinator = NexusStoreCoordinator();
///
/// final result = await coordinator.transaction((ctx) async {
///   await ctx.save(orderStore, order);
///   await ctx.save(inventoryStore, updatedInventory);
///   await ctx.save(paymentStore, payment);
/// });
///
/// result.when(
///   success: (_) => print('Order completed!'),
///   failure: (_, failedStep, compensated) =>
///       print('Failed at $failedStep, rolled back: $compensated'),
///   partialFailure: (_, failedStep, errors) =>
///       print('CRITICAL: Compensation failed!'),
/// );
/// ```
///
/// ## Auto-Generated Compensations
///
/// - **Save (new item)**: Compensation deletes the saved item
/// - **Save (update)**: Compensation restores the original value
/// - **Delete**: Compensation restores the deleted item
///
/// ## Custom Steps
///
/// For operations that aren't simple save/delete, use custom steps:
///
/// ```dart
/// await coordinator.transaction((ctx) async {
///   await ctx.save(orderStore, order);
///   await ctx.step(
///     'send-notification',
///     () => emailService.send(email),
///     (result) => emailService.cancel(result.id),
///   );
/// });
/// ```
class NexusStoreCoordinator {
  /// Creates a coordinator with optional persistence.
  ///
  /// - [persistence]: Storage for saga state (defaults to in-memory)
  /// - [timeout]: Overall timeout for transactions
  NexusStoreCoordinator({
    SagaPersistence? persistence,
    this.timeout,
  }) : _persistence = persistence ?? InMemorySagaPersistence();

  final SagaPersistence _persistence;

  /// Overall timeout for transactions.
  final Duration? timeout;

  final SagaCoordinator _sagaCoordinator = SagaCoordinator();
  bool _disposed = false;

  static const _uuid = Uuid();

  /// Stream of saga events for observability.
  Stream<SagaEventData> get events => _sagaCoordinator.events;

  /// Executes a multi-store transaction with automatic compensation.
  ///
  /// The [block] receives a [SagaTransactionContext] that tracks all
  /// operations. If any operation fails, all previous operations are
  /// automatically compensated in reverse order.
  ///
  /// Returns [SagaSuccess] if all operations complete, [SagaFailure] if
  /// an operation fails but compensations succeed, or [SagaPartialFailure]
  /// if compensations also fail.
  ///
  /// - [block]: The transaction operations to execute
  /// - [sagaId]: Optional custom ID for this transaction
  Future<SagaResult<dynamic>> transaction(
    FutureOr<void> Function(SagaTransactionContext ctx) block, {
    String? sagaId,
  }) async {
    if (_disposed) {
      throw StateError('NexusStoreCoordinator has been disposed');
    }

    final id = sagaId ?? _uuid.v4();
    final context = SagaTransactionContext._();

    try {
      // Execute the transaction block to collect steps
      await block(context);

      // Build and execute the saga
      final steps = context._buildSteps();

      if (steps.isEmpty) {
        return const SagaResult<dynamic>.success([]);
      }

      return await _sagaCoordinator.execute<dynamic>(
        steps,
        sagaId: id,
      );
    } catch (e) {
      // If an exception is thrown during block execution,
      // we need to compensate steps that were already executed
      if (context._executedSteps.isEmpty) {
        return SagaResult<dynamic>.failure(
          e,
          failedStep: 'transaction-block',
          compensatedSteps: [],
        );
      }

      // Compensate executed steps in reverse order
      final compensatedSteps = <String>[];
      final compensationErrors = <SagaCompensationError>[];

      for (final step in context._executedSteps.reversed) {
        try {
          await step.compensation(step.lastResult);
          compensatedSteps.add(step.name);
        } catch (compError, stackTrace) {
          compensationErrors.add(SagaCompensationError(
            stepName: step.name,
            error: compError,
            stackTrace: stackTrace,
          ));
        }
      }

      if (compensationErrors.isNotEmpty) {
        return SagaResult<dynamic>.partialFailure(
          e,
          failedStep: 'transaction-block',
          compensationErrors: compensationErrors,
        );
      }

      return SagaResult<dynamic>.failure(
        e,
        failedStep: 'transaction-block',
        compensatedSteps: compensatedSteps,
      );
    } finally {
      // Clean up persistence state on completion
      await _persistence.delete(id);
    }
  }

  /// Disposes the coordinator and releases resources.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _sagaCoordinator.dispose();
  }
}

/// Context for building a saga transaction.
///
/// Collects store operations and builds saga steps with automatic
/// compensation.
class SagaTransactionContext {
  SagaTransactionContext._();

  final List<_ExecutedStep> _executedSteps = [];

  /// Saves an item to a store with auto-generated compensation.
  ///
  /// The [idExtractor] function is used to get the item's ID for
  /// compensation tracking.
  ///
  /// Compensation behavior:
  /// - If the item is new (no previous value): deletes the saved item
  /// - If the item is an update: restores the original value
  ///
  /// Returns the saved item.
  Future<T> save<T, ID>(
    NexusStore<T, ID> store,
    T item, {
    required ID Function(T) idExtractor,
  }) async {
    final itemId = idExtractor(item);

    // Check if item exists (for compensation strategy)
    final original = await store.get(itemId);

    // Execute the save
    final saved = await store.save(item);

    // Register for compensation tracking
    final stepName = 'save-${store.backend.name}-$itemId';
    _executedSteps.add(_ExecutedStep(
      name: stepName,
      result: saved,
      compensation: (_) async {
        if (original == null) {
          // Was a new item - delete it
          await store.delete(itemId);
        } else {
          // Was an update - restore original
          await store.save(original);
        }
      },
    ));

    return saved;
  }

  /// Deletes an item from a store with auto-generated compensation.
  ///
  /// Compensation restores the deleted item if it existed.
  ///
  /// Returns true if an item was deleted.
  Future<bool> delete<T, ID>(NexusStore<T, ID> store, ID id) async {
    // Get the item before deleting (for compensation)
    final original = await store.get(id);

    // Execute the delete
    final deleted = await store.delete(id);

    // Register for compensation tracking
    final stepName = 'delete-${store.backend.name}-$id';
    _executedSteps.add(_ExecutedStep(
      name: stepName,
      result: deleted,
      compensation: (_) async {
        if (original != null) {
          // Restore the deleted item
          await store.save(original);
        }
      },
    ));

    return deleted;
  }

  /// Executes a custom step with manual compensation.
  ///
  /// Use this for operations that aren't simple save/delete operations
  /// on a NexusStore.
  ///
  /// Returns the result of the action.
  Future<R> step<R>(
    String name,
    Future<R> Function() action,
    Future<void> Function(R result) compensation,
  ) async {
    // Execute the action
    final result = await action();

    // Register for compensation tracking
    _executedSteps.add(_ExecutedStep(
      name: name,
      result: result,
      compensation: (r) => compensation(r as R),
    ));

    return result;
  }

  /// Builds saga steps from executed operations.
  ///
  /// This is called internally after the transaction block completes
  /// to create the saga for execution/compensation tracking.
  List<SagaStep<dynamic>> _buildSteps() {
    // Steps have already been executed inline, so we just need to
    // build the saga steps for potential compensation
    return _executedSteps.map((executed) {
      return SagaStep<dynamic>(
        name: executed.name,
        action: () async =>
            executed.result, // Already executed, just return result
        compensation: executed.compensation,
      );
    }).toList();
  }
}

/// Internal class tracking an executed step.
class _ExecutedStep {
  _ExecutedStep({
    required this.name,
    required this.result,
    required this.compensation,
  });

  final String name;
  final dynamic result;
  final Future<void> Function(dynamic result) compensation;

  dynamic get lastResult => result;
}
