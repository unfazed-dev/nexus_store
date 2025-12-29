# TRACKER: Cross-Store Transactions (Saga Pattern)

## Status: COMPLETE

## Overview

Implement saga pattern for coordinating transactions across multiple NexusStore instances, with compensating actions for rollback on failure.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-029, Task 26
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Implementation Summary

**Total Tests**: 144 tests
- saga_step_test.dart: 13 tests (+6 nested saga tests)
- saga_result_test.dart: 28 tests
- saga_event_test.dart: 9 tests
- saga_coordinator_test.dart: 30 tests (+7 nested saga integration tests)
- saga_context_test.dart: 25 tests
- saga_persistence_test.dart: 18 tests
- nexus_store_coordinator_test.dart: 28 tests

## Tasks

### Data Models
- [x] Create `SagaStep<T>` class
  - [x] `action: Future<T> Function()` - The forward action
  - [x] `compensation: Future<void> Function(T result)` - Rollback action
  - [x] `name: String` - Step identifier for logging
  - [x] `timeout: Duration?` - Per-step timeout

- [x] Create `SagaResult<T>` sealed class
  - [x] `SagaSuccess<T>` - All steps completed
  - [x] `SagaFailure` - Step failed, compensations executed
  - [x] `SagaPartialFailure` - Compensation also failed
  - [x] Pattern matching with `when()` and `maybeWhen()`

- [x] Create `SagaEvent` for observability
  - [x] `sagaStarted`, `sagaCompleted`, `sagaFailed`
  - [x] `stepStarted`, `stepCompleted`, `stepFailed`
  - [x] `compensationStarted`, `compensationCompleted`, `compensationFailed`
  - [x] `SagaEventData` class with full metadata

### Core Implementation
- [x] Create `SagaCoordinator` class
  - [x] `execute(List<SagaStep> steps)` - Run saga
  - [x] Track step results for compensation
  - [x] Execute compensations in reverse order on failure
  - [x] Event stream for observability

- [x] Implement compensation logic
  - [x] Pass step result to compensation function
  - [x] Handle compensation failures gracefully (SagaPartialFailure)
  - [x] Compensation errors collected with stack traces

- [x] Implement timeout handling
  - [x] Per-step timeouts
  - [x] Overall saga timeout
  - [x] Cancel pending steps on timeout

### NexusStore Integration
- [x] Create `NexusStoreCoordinator` facade
  - [x] `transaction((ctx) => ...)` syntax
  - [x] Auto-generate compensating actions for save operations
  - [x] Auto-generate compensating actions for delete operations

- [x] Create `SagaContext` for transaction scope
  - [x] Track completed steps
  - [x] Provide stepsToCompensate in reverse order
  - [x] Duration tracking

- [x] Create `SagaTransactionContext` for multi-store transactions
  - [x] `save<T, ID>(store, item, idExtractor)` with auto-compensation
  - [x] `delete<T, ID>(store, id)` with auto-compensation
  - [x] `step<R>(name, action, compensation)` for custom steps

### Advanced Features
- [x] Implement nested sagas
  - [x] Sub-sagas as single steps (`SagaStep.nested()`)
  - [x] Proper compensation ordering (nested compensates first, then parent)

- [x] Implement saga persistence
  - [x] `SagaState` and `SagaStepState` for serialization
  - [x] `SagaPersistence` interface
  - [x] `InMemorySagaPersistence` implementation
  - [x] `SagaStatus` and `StepStatus` enums with terminal state detection

### Unit Tests
- [x] `test/src/coordination/saga_step_test.dart` (13 tests)
  - [x] Basic step construction and execution
  - [x] Nested step factory (`SagaStep.nested()`)
  - [x] Nested step compensation ordering
- [x] `test/src/coordination/saga_result_test.dart` (28 tests)
- [x] `test/src/coordination/saga_event_test.dart` (9 tests)
- [x] `test/src/coordination/saga_coordinator_test.dart` (30 tests)
  - [x] All steps succeed
  - [x] Middle step fails, compensations run
  - [x] Compensation failure handling
  - [x] Timeout handling
  - [x] Nested saga as single step
  - [x] Nested saga compensation ordering
  - [x] Deeply nested sagas
- [x] `test/src/coordination/saga_context_test.dart` (25 tests)
- [x] `test/src/coordination/saga_persistence_test.dart` (18 tests)
- [x] `test/src/coordination/nexus_store_coordinator_test.dart` (28 tests)
  - [x] Auto-compensation for saves
  - [x] Auto-compensation for deletes
  - [x] Multi-store rollback
  - [x] Custom steps integration

## Files

**Source Files:**
```
packages/nexus_store/lib/src/coordination/
├── saga_coordinator.dart       # SagaCoordinator class
├── saga_step.dart              # SagaStep model
├── saga_result.dart            # SagaResult sealed class with pattern matching
├── saga_event.dart             # SagaEvent enum and SagaEventData
├── saga_context.dart           # SagaContext for execution tracking
├── saga_state.dart             # SagaState/SagaStepState for persistence
├── saga_persistence.dart       # SagaPersistence interface + InMemory impl
└── nexus_store_coordinator.dart # Multi-store facade with auto-compensation
```

**Test Files:**
```
packages/nexus_store/test/src/coordination/
├── saga_step_test.dart
├── saga_result_test.dart
├── saga_event_test.dart
├── saga_coordinator_test.dart
├── saga_context_test.dart
├── saga_persistence_test.dart
└── nexus_store_coordinator_test.dart
```

**Updated Files:**
- `packages/nexus_store/lib/src/errors/store_errors.dart` - Added `SagaError` class
- `packages/nexus_store/lib/nexus_store.dart` - Added coordination exports

## Dependencies

- Transaction support (Task 16) - for single-store transactions
- Core package (Task 1, complete)

## API Preview

```dart
// Basic saga with manual steps
final saga = SagaCoordinator();
final result = await saga.execute([
  SagaStep(
    name: 'decrement-inventory',
    action: () => inventoryStore.save(inventory.copyWith(count: count - 1)),
    compensation: (result) => inventoryStore.save(inventory),
  ),
  SagaStep(
    name: 'create-order',
    action: () => orderStore.save(order),
    compensation: (result) => orderStore.delete(result.id),
  ),
  SagaStep(
    name: 'charge-payment',
    action: () => paymentService.charge(order.total),
    compensation: (result) => paymentService.refund(result.transactionId),
  ),
]);

result.when(
  success: (results) => print('Order completed!'),
  failure: (error, failedStep, compensated) =>
      print('Failed: $error, rolled back: $compensated'),
  partialFailure: (error, failedStep, compensationErrors) =>
      print('Critical: compensation failed!'),
);

// Using NexusStoreCoordinator for common patterns with auto-compensation
final coordinator = NexusStoreCoordinator();
await coordinator.transaction((ctx) async {
  await ctx.save(orderStore, order, idExtractor: (o) => o.id);
  await ctx.save(inventoryStore, updatedInventory, idExtractor: (i) => i.id);
  await ctx.save(userStore, updatedUser, idExtractor: (u) => u.id);
  // All succeed or all roll back automatically
});

// With events for observability
coordinator.events.listen((event) {
  if (event.event == SagaEvent.stepFailed) {
    logger.error('Step ${event.stepName} failed: ${event.error}');
  }
});

// Nested sagas - sub-saga as atomic step
final saga = SagaCoordinator();
await saga.execute([
  SagaStep(
    name: 'create-order',
    action: () => orderStore.save(order),
    compensation: (result) => orderStore.delete(result.id),
  ),
  // Nested saga for inventory management
  SagaStep.nested(
    name: 'manage-inventory',
    subSteps: [
      SagaStep(
        name: 'reserve-items',
        action: () => inventoryStore.reserve(items),
        compensation: (result) => inventoryStore.unreserve(result),
      ),
      SagaStep(
        name: 'update-stock',
        action: () => inventoryStore.decrementStock(items),
        compensation: (result) => inventoryStore.incrementStock(items),
      ),
    ],
    onNestedSuccess: (results) => results.last,
    compensation: (result) async {
      // Optional: cleanup after nested saga compensates internally
    },
  ),
  SagaStep(
    name: 'charge-payment',
    action: () => paymentService.charge(order.total),
    compensation: (result) => paymentService.refund(result.transactionId),
  ),
]);
```

## Notes

- Sagas are NOT ACID transactions - they provide eventual consistency
- Compensations should be idempotent (safe to retry)
- Saga IDs provided for distributed tracing
- Network partitions can cause partial execution - design compensations accordingly
- Saga persistence available for crash recovery
- Compensation execution order is reverse of action order
- Auto-compensation for save: deletes new items, restores original for updates
- Auto-compensation for delete: restores the deleted item
- Nested sagas: `SagaStep.nested()` wraps sub-steps as atomic units
- Nested compensation order: sub-steps compensate internally first (reverse order), then parent step
