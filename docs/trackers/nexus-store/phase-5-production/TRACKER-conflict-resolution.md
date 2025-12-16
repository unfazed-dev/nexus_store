# TRACKER: Conflict Resolution & Pending Changes

## Status: PENDING

## Overview

Implement conflict resolution callbacks for manual merge control and pending changes visibility for sync queue management. Combines REQ-020 and REQ-021 as they are closely related sync features.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-020, REQ-021, Task 19, Task 20
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Conflict Resolution (REQ-020)

#### Data Models
- [ ] Create `ConflictDetails<T>` class
  - [ ] `localValue: T` - Local version of item
  - [ ] `remoteValue: T` - Remote version of item
  - [ ] `localTimestamp: DateTime` - When local was modified
  - [ ] `remoteTimestamp: DateTime` - When remote was modified
  - [ ] `conflictingFields: Set<String>?` - Fields that differ (optional)

- [ ] Create `ConflictAction<T>` sealed class
  - [ ] `ConflictAction.keepLocal()` - Use local version
  - [ ] `ConflictAction.keepRemote()` - Use remote version
  - [ ] `ConflictAction.merge(T merged)` - Use custom merged value
  - [ ] `ConflictAction.skip()` - Don't resolve, keep conflicted

- [ ] Create `ConflictResolver<T>` typedef
  - [ ] `Future<ConflictAction<T>> Function(ConflictDetails<T> details)`

#### Configuration
- [ ] Add `onConflict` to `StoreConfig`
  - [ ] Optional `ConflictResolver<T>` callback
  - [ ] Falls back to `defaultConflictResolution` if not provided

- [ ] Update `ConflictResolution` enum usage
  - [ ] `serverWins` - Default when no callback
  - [ ] `clientWins` - Alternative default
  - [ ] `custom` - Triggers callback

#### Integration
- [ ] Integrate with sync flow
  - [ ] Detect conflicts during sync
  - [ ] Call resolver callback when conflict detected
  - [ ] Apply resolution action

- [ ] Add conflict stream
  - [ ] `Stream<ConflictDetails<T>> get conflicts`
  - [ ] Emits unresolved conflicts for UI display

### Pending Changes Visibility (REQ-021)

#### Data Models
- [ ] Create `PendingChange<T>` class
  - [ ] `id: String` - Unique change ID
  - [ ] `item: T` - The item being changed
  - [ ] `operation: PendingChangeOperation` - Type of change
  - [ ] `createdAt: DateTime` - When change was queued
  - [ ] `retryCount: int` - Number of retry attempts
  - [ ] `lastError: Object?` - Last sync error
  - [ ] `lastAttempt: DateTime?` - Last retry timestamp

- [ ] Create `PendingChangeOperation` enum
  - [ ] `create` - New item
  - [ ] `update` - Modified item
  - [ ] `delete` - Deleted item

- [ ] Create `PendingChangesState` class
  - [ ] `changes: List<PendingChange<T>>`
  - [ ] `totalCount: int`
  - [ ] `failedCount: int`

#### NexusStore Integration
- [ ] Add `pendingChanges` stream
  - [ ] `Stream<List<PendingChange<T>>> get pendingChanges`
  - [ ] Emits on every queue change

- [ ] Add `retryPendingChange(String changeId)`
  - [ ] Immediately retry specific change
  - [ ] Returns success/failure

- [ ] Add `cancelPendingChange(String changeId)`
  - [ ] Remove from queue
  - [ ] Revert local state if needed
  - [ ] Returns cancelled change

- [ ] Add `retryAllPending()`
  - [ ] Retry all failed changes
  - [ ] Respects retry config

- [ ] Add `cancelAllPending()`
  - [ ] Clear entire queue
  - [ ] Revert all local changes

#### Backend Integration
- [ ] Update `StoreBackend` interface
  - [ ] `Stream<List<PendingChange<T>>> get pendingChangesStream`
  - [ ] `Future<void> retryChange(String id)`
  - [ ] `Future<void> cancelChange(String id)`

### Unit Tests
- [ ] `test/src/sync/conflict_resolver_test.dart`
  - [ ] Callback receives correct conflict details
  - [ ] keepLocal preserves local value
  - [ ] keepRemote accepts remote value
  - [ ] merge uses custom value
  - [ ] Default resolution when no callback

- [ ] `test/src/sync/pending_changes_test.dart`
  - [ ] Pending changes stream emits on change
  - [ ] Retry triggers immediate sync attempt
  - [ ] Cancel removes from queue and reverts
  - [ ] Error tracking updates retryCount

## Files

**Source Files:**
```
packages/nexus_store/lib/src/sync/
├── conflict_details.dart       # ConflictDetails<T> class
├── conflict_action.dart        # ConflictAction sealed class
├── conflict_resolver.dart      # ConflictResolver typedef and integration
├── pending_change.dart         # PendingChange<T> class
└── pending_changes_manager.dart # Pending changes tracking

packages/nexus_store/lib/src/config/
└── store_config.dart           # Update with onConflict
```

**Test Files:**
```
packages/nexus_store/test/src/sync/
├── conflict_resolver_test.dart
└── pending_changes_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Policy engine (Task 5, complete)

## API Preview

```dart
// Conflict resolution callback
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    onConflict: (details) async {
      // Show UI for user to decide
      final choice = await showConflictDialog(
        local: details.localValue,
        remote: details.remoteValue,
      );

      return switch (choice) {
        'local' => ConflictAction.keepLocal(),
        'remote' => ConflictAction.keepRemote(),
        'merge' => ConflictAction.merge(
          details.localValue.copyWith(
            name: details.remoteValue.name,
            // Keep local email
          ),
        ),
      };
    },
  ),
);

// Listen to conflicts
store.conflicts.listen((conflict) {
  showNotification('Conflict on ${conflict.localValue.id}');
});

// Pending changes visibility
store.pendingChanges.listen((changes) {
  updateSyncIndicator(
    pending: changes.length,
    failed: changes.where((c) => c.lastError != null).length,
  );
});

// Retry specific change
await store.retryPendingChange('change-123');

// Cancel and revert
final cancelled = await store.cancelPendingChange('change-456');
print('Reverted: ${cancelled.item}');

// Bulk operations
await store.retryAllPending();
await store.cancelAllPending();
```

## Notes

- Conflict resolution UI is application-specific, this provides the hooks
- Consider adding field-level merge for automatic non-conflicting fields
- Pending changes should persist across app restarts
- Retry backoff should follow RetryConfig settings
- Cancel should audit log the action
- Consider adding change priority for retry ordering
