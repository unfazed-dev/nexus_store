# TRACKER: Transaction Support

## Status: ✅ COMPLETE

## Overview

Implement atomic transaction support for NexusStore, allowing multiple operations to be executed as a single unit of work with automatic rollback on failure.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-017, Task 16
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `Transaction<T, ID>` class
  - [x] Holds reference to parent store
  - [x] Tracks operations performed within transaction
  - [x] save(T item) method
  - [x] saveAll(List<T> items) method
  - [x] delete(ID id) method
  - [x] deleteAll(List<ID> ids) method

- [x] Create `TransactionContext` class
  - [x] Unique transaction ID
  - [x] Start timestamp
  - [x] List of pending operations
  - [x] Savepoint support for nested transactions

- [x] Create `TransactionOperation` sealed class
  - [x] SaveOperation with item
  - [x] DeleteOperation with id
  - [x] Stores original value for rollback

### Core Implementation
- [x] Add `transaction()` method to `NexusStore`
  - [x] Accept callback `Future<R> Function(Transaction<T, ID> tx)`
  - [x] Create transaction context
  - [x] Execute callback within context
  - [x] Commit on success, rollback on failure
  - [x] Return result of callback

- [x] Implement transaction commit logic
  - [x] Apply all pending operations to backend
  - [x] Update cache atomically
  - [x] Emit watch stream updates

- [x] Implement transaction rollback logic
  - [x] Revert operations in reverse order
  - [x] Restore original values from TransactionOperation
  - [x] Clean up transaction context

### Nested Transactions (Savepoints)
- [x] Implement savepoint creation
  - [x] Mark position in operation list
  - [x] Allow partial rollback to savepoint

- [x] Implement nested transaction support
  - [x] Inner transaction creates savepoint
  - [x] Inner failure rolls back to savepoint only
  - [x] Outer transaction can continue

### Backend Integration
- [x] Add transaction support to `StoreBackend` interface
  - [x] `beginTransaction()` method
  - [x] `commitTransaction()` method
  - [x] `rollbackTransaction()` method
  - [x] `runInTransaction()` method

- [x] Update backends to support transactions
  - [x] StoreBackendDefaults mixin with fallback implementations
  - [x] FakeStoreBackend with transaction tracking
  - [x] CompositeBackend delegates to primary

### Error Handling
- [x] Create `TransactionError` class (already existed)
  - [x] Wraps underlying error
  - [x] Includes operation that failed
  - [x] Includes rollback success status (wasRolledBack)

### Configuration
- [x] Add `transactionTimeout` to StoreConfig (default: 30 seconds)

### Unit Tests
- [x] `test/src/transaction/transaction_test.dart` (28 tests)
  - [x] Transaction with single save commits
  - [x] Transaction with multiple saves commits atomically
  - [x] Transaction with failure rolls back all operations
  - [x] Transaction returns callback result
  - [x] Transaction delete removes item on commit
  - [x] Transaction delete restores item on rollback
  - [x] Transaction deleteAll removes multiple items on commit
  - [x] Transaction update restores original on rollback
  - [x] Nested transaction rollback only affects inner scope
  - [x] Nested transaction success commits with outer
  - [x] Transaction context is isolated per transaction
  - [x] First transaction rollback does not affect second
  - [x] Throws TransactionError with wasRolledBack flag
  - [x] Prevents operations on committed transaction
  - [x] Prevents operations on rolled-back transaction
  - [x] Transaction with saves and deletes commits correctly
  - [x] Transaction with saves and deletes rolls back correctly
  - [x] SaveOperation isInsert/isUpdate detection
  - [x] DeleteOperation hadValue detection
  - [x] TransactionContext creation, nesting, depth tracking
  - [x] Savepoint creation and rollback

## Files

**Source Files:**
```
packages/nexus_store/lib/src/transaction/
├── transaction.dart            # Transaction<T, ID> class
├── transaction_context.dart    # TransactionContext class
└── transaction_operation.dart  # TransactionOperation sealed class

packages/nexus_store/lib/src/core/
├── nexus_store.dart            # Updated with transaction() method
├── store_backend.dart          # Updated with transaction interface
└── composite_backend.dart      # Updated to delegate transactions

packages/nexus_store/lib/src/config/
└── store_config.dart           # Added transactionTimeout field

packages/nexus_store/lib/
└── nexus_store.dart            # Export transaction types
```

**Test Files:**
```
packages/nexus_store/test/src/transaction/
└── transaction_test.dart       # 28 tests

packages/nexus_store/test/fixtures/
└── mock_backend.dart           # Updated with transaction support
```

## Dependencies

- Core package implementation (complete)
- StoreBackend interface (complete)

## API Preview

```dart
// Basic transaction
await store.transaction((tx) async {
  await tx.save(user);
  await tx.save(profile);
  await tx.save(settings);
}); // All succeed or all rollback

// Transaction with return value
final result = await store.transaction((tx) async {
  final user = await tx.save(newUser);
  await tx.save(Profile(userId: user.id));
  return user;
});

// Nested transaction (savepoint)
await store.transaction((tx) async {
  await tx.save(user);
  try {
    await store.transaction((innerTx) async {
      await innerTx.save(riskyOperation);
      throw Exception('Failed');
    });
  } catch (e) {
    // Inner rolled back, outer continues
  }
  await tx.save(safeOperation);
}); // user and safeOperation saved, riskyOperation rolled back
```

## Implementation Notes

- Transactions are scoped to a single store instance
- Cross-store transactions are not supported (use Saga pattern instead - Phase 6)
- Backend must support transactions for true atomicity; fallback uses optimistic approach
- Transaction timeout configurable via `StoreConfig.transactionTimeout`
- `TransactionError` includes `wasRolledBack` flag to indicate rollback status
- Nested transactions use savepoint pattern for partial rollback
- All 28 tests pass successfully

## Completion Date

2024-12-26
