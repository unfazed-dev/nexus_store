# TRACKER: Cross-Store Transactions (Saga Pattern)

## Status: PENDING

## Overview

Implement saga pattern for coordinating transactions across multiple NexusStore instances, with compensating actions for rollback on failure.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-029, Task 26
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `SagaStep<T>` class
  - [ ] `action: Future<T> Function()` - The forward action
  - [ ] `compensation: Future<void> Function(T result)` - Rollback action
  - [ ] `name: String` - Step identifier for logging
  - [ ] `timeout: Duration?` - Per-step timeout

- [ ] Create `SagaResult<T>` sealed class
  - [ ] `SagaSuccess<T>` - All steps completed
  - [ ] `SagaFailure` - Step failed, compensations executed
  - [ ] `SagaPartialFailure` - Compensation also failed

- [ ] Create `SagaEvent` for observability
  - [ ] `stepStarted`, `stepCompleted`, `stepFailed`
  - [ ] `compensationStarted`, `compensationCompleted`, `compensationFailed`

### Core Implementation
- [ ] Create `SagaCoordinator` class
  - [ ] `execute(List<SagaStep> steps)` - Run saga
  - [ ] Track step results for compensation
  - [ ] Execute compensations in reverse order on failure

- [ ] Implement compensation logic
  - [ ] Pass step result to compensation function
  - [ ] Handle compensation failures gracefully
  - [ ] Log all compensation attempts

- [ ] Implement timeout handling
  - [ ] Per-step timeouts
  - [ ] Overall saga timeout
  - [ ] Cancel pending steps on timeout

### NexusStore Integration
- [ ] Create `NexusStoreCoordinator` factory
  - [ ] `transaction([store1, store2], (ctx) => ...)` syntax
  - [ ] Auto-generate compensating actions for common operations

- [ ] Create `SagaContext` for transaction scope
  - [ ] Track all operations across stores
  - [ ] Provide unified rollback

### Advanced Features
- [ ] Implement nested sagas
  - [ ] Sub-sagas as single steps
  - [ ] Proper compensation ordering

- [ ] Implement saga persistence (optional)
  - [ ] Save saga state for recovery
  - [ ] Resume incomplete sagas

### Unit Tests
- [ ] `test/src/coordination/saga_coordinator_test.dart`
  - [ ] All steps succeed
  - [ ] Middle step fails, compensations run
  - [ ] Compensation failure handling
  - [ ] Timeout handling
  - [ ] Nested sagas

## Files

**Source Files:**
```
packages/nexus_store/lib/src/coordination/
├── saga_coordinator.dart       # SagaCoordinator class
├── saga_step.dart              # SagaStep model
├── saga_result.dart            # SagaResult sealed class
├── compensating_action.dart    # Compensation utilities
└── nexus_store_coordinator.dart # Multi-store facade
```

**Test Files:**
```
packages/nexus_store/test/src/coordination/
├── saga_coordinator_test.dart
└── nexus_store_coordinator_test.dart
```

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
  failure: (error, compensated) => print('Failed: $error, rolled back: $compensated'),
  partialFailure: (error, compensationErrors) => print('Critical: compensation failed!'),
);

// Using NexusStoreCoordinator for common patterns
final coordinator = NexusStoreCoordinator([orderStore, inventoryStore, userStore]);
await coordinator.transaction((ctx) async {
  await ctx.save(orderStore, order);
  await ctx.save(inventoryStore, updatedInventory);
  await ctx.save(userStore, updatedUser);
  // All succeed or all roll back
});

// With events for observability
saga.events.listen((event) {
  if (event is SagaStepFailed) {
    logger.error('Step ${event.stepName} failed: ${event.error}');
  }
});
```

## Notes

- Sagas are NOT ACID transactions - they provide eventual consistency
- Compensations should be idempotent (safe to retry)
- Consider adding saga IDs for distributed tracing
- Network partitions can cause partial execution - design compensations accordingly
- For critical paths, consider saga persistence for crash recovery
- Document that compensation execution order is reverse of action order
