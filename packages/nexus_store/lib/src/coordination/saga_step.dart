import 'package:meta/meta.dart';

import 'saga_coordinator.dart';

/// Represents a single step in a saga with an action and its compensating action.
///
/// Each saga step consists of:
/// - A forward [action] that performs the business logic
/// - A [compensation] that undoes the action if a later step fails
/// - An optional [timeout] for the action
///
/// ## Example
///
/// ```dart
/// final step = SagaStep<Order>(
///   name: 'create-order',
///   action: () => orderStore.save(order),
///   compensation: (createdOrder) => orderStore.delete(createdOrder.id),
///   timeout: Duration(seconds: 30),
/// );
/// ```
///
/// ## Compensation Pattern
///
/// The compensation function receives the result of the action, allowing
/// it to properly undo the operation:
///
/// ```dart
/// SagaStep<PaymentResult>(
///   name: 'charge-payment',
///   action: () => paymentService.charge(amount),
///   compensation: (result) => paymentService.refund(result.transactionId),
/// );
/// ```
@immutable
class SagaStep<T> {
  /// Creates a saga step.
  ///
  /// - [name]: Unique identifier for this step (used in logging and events)
  /// - [action]: The forward action to execute
  /// - [compensation]: The rollback action, receives the action's result
  /// - [timeout]: Optional timeout for the action (compensation has no timeout)
  const SagaStep({
    required this.name,
    required this.action,
    required this.compensation,
    this.timeout,
  });

  /// Creates a step that executes a nested saga as an atomic unit.
  ///
  /// The [subSteps] are executed by a child [SagaCoordinator].
  /// If any sub-step fails, the nested saga compensates internally first,
  /// then the parent saga sees this step as failed and compensates parent steps.
  ///
  /// [onNestedSuccess] extracts a result from the nested saga for compensation.
  /// [compensation] receives the extracted result for rollback.
  ///
  /// ## Example
  ///
  /// ```dart
  /// SagaStep.nested(
  ///   name: 'manage-inventory',
  ///   subSteps: [
  ///     SagaStep(
  ///       name: 'reserve-items',
  ///       action: () => inventoryStore.reserve(items),
  ///       compensation: (result) => inventoryStore.unreserve(result),
  ///     ),
  ///     SagaStep(
  ///       name: 'update-stock',
  ///       action: () => inventoryStore.decrementStock(items),
  ///       compensation: (result) => inventoryStore.incrementStock(items),
  ///     ),
  ///   ],
  ///   onNestedSuccess: (results) => results.last,
  ///   compensation: (result) async {
  ///     // Optional: additional cleanup after nested saga compensates internally
  ///   },
  /// );
  /// ```
  factory SagaStep.nested({
    required String name,
    required List<SagaStep<dynamic>> subSteps,
    required T Function(List<dynamic> subResults) onNestedSuccess,
    required Future<void> Function(T result) compensation,
    Duration? timeout,
  }) {
    // Wrap sub-steps to handle type coercion properly.
    // This is needed because SagaStep<int>'s compensation is typed as
    // Future<void> Function(int), which is not a subtype of
    // Future<void> Function(dynamic) due to contravariance.
    final wrappedSteps = subSteps.map((step) {
      // Cast to dynamic to bypass static type checking when accessing fields
      // ignore: avoid_dynamic_calls
      final dynamicStep = step as dynamic;
      return SagaStep<dynamic>(
        name: step.name,
        // ignore: avoid_dynamic_calls
        action: () async => await dynamicStep.action() as dynamic,
        // ignore: avoid_dynamic_calls
        compensation: (result) async => await dynamicStep.compensation(result),
        timeout: step.timeout,
      );
    }).toList();

    return SagaStep<T>(
      name: name,
      action: () async {
        final nestedCoordinator = SagaCoordinator();
        try {
          final result = await nestedCoordinator.execute<dynamic>(wrappedSteps);
          return result.when(
            success: (results) => onNestedSuccess(results),
            failure: (error, _, __) => throw error,
            partialFailure: (error, _, __) => throw error,
          );
        } finally {
          await nestedCoordinator.dispose();
        }
      },
      compensation: compensation,
      timeout: timeout,
    );
  }

  /// Unique identifier for this step.
  ///
  /// Used for logging, events, and identifying which step failed.
  final String name;

  /// The forward action to execute.
  ///
  /// Should be idempotent when possible. Returns a value that will be
  /// passed to the compensation function if rollback is needed.
  final Future<T> Function() action;

  /// The compensation (rollback) action.
  ///
  /// Receives the result of [action] so it can properly undo the operation.
  /// Compensations should be idempotent (safe to retry).
  final Future<void> Function(T result) compensation;

  /// Optional timeout for the action.
  ///
  /// If the action doesn't complete within this duration, it's considered
  /// failed and compensation of previous steps will begin.
  ///
  /// Note: Compensation functions do not have timeouts - they must complete.
  final Duration? timeout;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaStep<T> &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    final buffer = StringBuffer('SagaStep<$T>(name: $name');
    if (timeout != null) {
      buffer.write(', timeout: ${timeout!.inSeconds}s');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
