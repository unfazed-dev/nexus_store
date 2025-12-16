# TRACKER: Transaction Support

## Status: PENDING

## Overview

Implement atomic transaction support for NexusStore, allowing multiple operations to be executed as a single unit of work with automatic rollback on failure.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-017, Task 16
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `Transaction<T, ID>` class
  - [ ] Holds reference to parent store
  - [ ] Tracks operations performed within transaction
  - [ ] save(T item) method
  - [ ] saveAll(List<T> items) method
  - [ ] delete(ID id) method
  - [ ] deleteAll(List<ID> ids) method

- [ ] Create `TransactionContext` class
  - [ ] Unique transaction ID
  - [ ] Start timestamp
  - [ ] List of pending operations
  - [ ] Savepoint support for nested transactions

- [ ] Create `TransactionOperation` sealed class
  - [ ] SaveOperation with item
  - [ ] DeleteOperation with id
  - [ ] Stores original value for rollback

### Core Implementation
- [ ] Add `transaction()` method to `NexusStore`
  - [ ] Accept callback `Future<R> Function(Transaction<T, ID> tx)`
  - [ ] Create transaction context
  - [ ] Execute callback within context
  - [ ] Commit on success, rollback on failure
  - [ ] Return result of callback

- [ ] Implement transaction commit logic
  - [ ] Apply all pending operations to backend
  - [ ] Update cache atomically
  - [ ] Emit watch stream updates

- [ ] Implement transaction rollback logic
  - [ ] Revert operations in reverse order
  - [ ] Restore original values from TransactionOperation
  - [ ] Clean up transaction context

### Nested Transactions (Savepoints)
- [ ] Implement savepoint creation
  - [ ] Mark position in operation list
  - [ ] Allow partial rollback to savepoint

- [ ] Implement nested transaction support
  - [ ] Inner transaction creates savepoint
  - [ ] Inner failure rolls back to savepoint only
  - [ ] Outer transaction can continue

### Backend Integration
- [ ] Add transaction support to `StoreBackend` interface
  - [ ] `beginTransaction()` method
  - [ ] `commitTransaction()` method
  - [ ] `rollbackTransaction()` method

- [ ] Update backends to support transactions
  - [ ] PowerSync: Use SQLite transactions
  - [ ] Drift: Use Drift's transaction API
  - [ ] Supabase: Use RPC with transaction
  - [ ] Fallback: Optimistic with rollback

### Error Handling
- [ ] Create `TransactionError` class
  - [ ] Wraps underlying error
  - [ ] Includes operation that failed
  - [ ] Includes rollback success status

### Unit Tests
- [ ] `test/src/core/transaction_test.dart`
  - [ ] Transaction with single save commits
  - [ ] Transaction with multiple saves commits atomically
  - [ ] Transaction with failure rolls back all operations
  - [ ] Nested transaction rollback only affects inner scope
  - [ ] Transaction context is isolated per transaction
  - [ ] Concurrent transactions are isolated

## Files

**Source Files:**
```
packages/nexus_store/lib/src/core/
├── transaction.dart          # Transaction<T, ID> class
├── transaction_context.dart  # TransactionContext class
├── transaction_operation.dart # TransactionOperation sealed class
└── nexus_store.dart          # Update with transaction() method
```

**Test Files:**
```
packages/nexus_store/test/src/core/
└── transaction_test.dart
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

## Notes

- Transactions are scoped to a single store instance
- Cross-store transactions are not supported (use Saga pattern instead)
- Backend must support transactions for true atomicity; fallback uses optimistic approach
- Transaction timeout should be configurable in StoreConfig
- Consider adding `TransactionIsolationLevel` for advanced use cases
