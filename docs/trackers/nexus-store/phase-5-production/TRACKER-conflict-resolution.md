# TRACKER: Conflict Resolution & Pending Changes

## Status: COMPLETE ✅

## Overview

Implement conflict resolution callbacks for manual merge control and pending changes visibility for sync queue management. Combines REQ-020 and REQ-021 as they are closely related sync features.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-020, REQ-021, Task 19, Task 20
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Conflict Resolution (REQ-020)

#### Data Models
- [x] Create `ConflictDetails<T>` class
  - [x] `localValue: T` - Local version of item
  - [x] `remoteValue: T` - Remote version of item
  - [x] `localTimestamp: DateTime` - When local was modified
  - [x] `remoteTimestamp: DateTime` - When remote was modified
  - [x] `conflictingFields: Set<String>?` - Fields that differ (optional)

- [x] Create `ConflictAction<T>` sealed class
  - [x] `ConflictAction.keepLocal()` - Use local version
  - [x] `ConflictAction.keepRemote()` - Use remote version
  - [x] `ConflictAction.merge(T merged)` - Use custom merged value
  - [x] `ConflictAction.skip()` - Don't resolve, keep conflicted

- [x] Create `ConflictResolver<T>` typedef
  - [x] `Future<ConflictAction<T>> Function(ConflictDetails<T> details)`

#### Configuration
- [x] Add `onConflict` to `NexusStore` constructor
  - [x] Optional `ConflictResolver<T>` callback
  - [x] Falls back to `defaultConflictResolution` if not provided

- [x] Update `ConflictResolution` enum usage
  - [x] `serverWins` - Default when no callback
  - [x] `clientWins` - Alternative default
  - [x] `custom` - Triggers callback

#### Integration
- [x] Integrate with sync flow
  - [x] Detect conflicts during sync
  - [x] Call resolver callback when conflict detected
  - [x] Apply resolution action

- [x] Add conflict stream
  - [x] `Stream<ConflictDetails<T>> get conflicts`
  - [x] Emits unresolved conflicts for UI display

### Pending Changes Visibility (REQ-021)

#### Data Models
- [x] Create `PendingChange<T>` class
  - [x] `id: String` - Unique change ID
  - [x] `item: T` - The item being changed
  - [x] `operation: PendingChangeOperation` - Type of change
  - [x] `createdAt: DateTime` - When change was queued
  - [x] `retryCount: int` - Number of retry attempts
  - [x] `lastError: Object?` - Last sync error
  - [x] `lastAttempt: DateTime?` - Last retry timestamp
  - [x] `originalValue: T?` - For undo/revert support

- [x] Create `PendingChangeOperation` enum
  - [x] `create` - New item
  - [x] `update` - Modified item
  - [x] `delete` - Deleted item

- [x] Create `PendingChangesManager<T, ID>` class
  - [x] In-memory tracking with BehaviorSubject stream
  - [x] addChange, removeChange, getChange, updateChange methods
  - [x] UUID generation for change IDs
  - [x] Support for original value storage (undo)

#### NexusStore Integration
- [x] Add `pendingChanges` stream
  - [x] `Stream<List<PendingChange<T>>> get pendingChanges`
  - [x] Emits on every queue change

- [x] Add `retryPendingChange(String changeId)`
  - [x] Immediately retry specific change
  - [x] Returns success/failure

- [x] Add `cancelPendingChange(String changeId)`
  - [x] Remove from queue
  - [x] Revert local state if needed
  - [x] Returns cancelled change

- [x] Add `retryAllPending()`
  - [x] Retry all failed changes
  - [x] Respects retry config

- [x] Add `cancelAllPending()`
  - [x] Clear entire queue
  - [x] Revert all local changes

#### Backend Integration
- [x] Update `StoreBackend` interface
  - [x] `Stream<List<PendingChange<T>>> get pendingChangesStream`
  - [x] `Stream<ConflictDetails<T>> get conflictsStream`
  - [x] `Future<void> retryChange(String id)`
  - [x] `Future<PendingChange<T>?> cancelChange(String id)`
  - [x] Default implementations in `StoreBackendDefaults` mixin

- [x] Update `CompositeBackend` with new methods

- [x] Update PowerSync adapter
  - [x] Implement pendingChangesStream, conflictsStream
  - [x] Implement retryChange, cancelChange with state reversion
  - [x] Add pagination support (getAllPaged, watchAllPaged)

- [x] Update CRDT adapter
  - [x] Implement pendingChangesStream, conflictsStream
  - [x] Implement retryChange, cancelChange with state reversion
  - [x] Add pagination support (getAllPaged, watchAllPaged)

- [x] Update Drift adapter
  - [x] Implement pendingChangesStream, conflictsStream
  - [x] Implement retryChange, cancelChange with state reversion
  - [x] Add pagination support (getAllPaged, watchAllPaged)

### Unit Tests
- [x] `test/src/sync/conflict_details_test.dart`
  - [x] ConflictDetails creation and fields
  - [x] isNewerLocal/isNewerRemote computed properties

- [x] `test/src/sync/conflict_action_test.dart`
  - [x] All action variants (keepLocal, keepRemote, merge, skip)
  - [x] Pattern matching works correctly
  - [x] Equality for actions

- [x] `test/src/sync/pending_change_test.dart`
  - [x] PendingChange creation and fields
  - [x] PendingChangeOperation enum values
  - [x] hasFailed and canRevert computed properties

- [x] `test/src/sync/pending_changes_manager_test.dart`
  - [x] Add/remove/get/update changes
  - [x] Stream emissions on change
  - [x] Entity-specific queries

- [x] `test/src/sync/conflict_resolver_test.dart`
  - [x] Callback receives correct conflict details
  - [x] keepLocal preserves local value
  - [x] keepRemote accepts remote value
  - [x] merge uses custom value
  - [x] Default resolution when no callback

- [x] `test/src/sync/pending_changes_test.dart`
  - [x] Pending changes stream emits on change
  - [x] Retry triggers immediate sync attempt
  - [x] Cancel removes from queue and reverts
  - [x] Error tracking updates retryCount

## Files

**Source Files:**
```
packages/nexus_store/lib/src/sync/
├── conflict_details.dart          # ConflictDetails<T> class (Freezed)
├── conflict_details.freezed.dart  # Generated
├── conflict_action.dart           # ConflictAction sealed class + ConflictResolver typedef
├── pending_change.dart            # PendingChange<T> + PendingChangeOperation (Freezed)
├── pending_change.freezed.dart    # Generated
└── pending_changes_manager.dart   # PendingChangesManager<T, ID>

packages/nexus_store/lib/src/core/
├── store_backend.dart             # Updated interface + StoreBackendDefaults
├── composite_backend.dart         # Updated with new methods
└── nexus_store.dart               # Added onConflict + public API

packages/nexus_store/lib/nexus_store.dart  # Updated exports
```

**Test Files:**
```
packages/nexus_store/test/src/sync/
├── conflict_details_test.dart
├── conflict_action_test.dart
├── pending_change_test.dart
├── pending_changes_manager_test.dart
├── conflict_resolver_test.dart
└── pending_changes_test.dart

packages/nexus_store/test/fixtures/
└── mock_backend.dart              # Updated FakeStoreBackend with new methods
```

**Adapter Updates:**
```
packages/nexus_store_powersync_adapter/lib/src/powersync_backend.dart
packages/nexus_store_crdt_adapter/lib/src/crdt_backend.dart
packages/nexus_store_drift_adapter/lib/src/drift_backend.dart
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
    conflictResolution: ConflictResolution.custom,
  ),
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
      _ => ConflictAction.skip(),
    };
  },
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

// Cancel and revert (restores original state)
final cancelled = await store.cancelPendingChange('change-456');
print('Reverted: ${cancelled?.item}');

// Bulk operations
await store.retryAllPending();
final cancelledCount = await store.cancelAllPending();
```

## Implementation Notes

- `onConflict` callback is added to `NexusStore` constructor (not `StoreConfig`) because Freezed classes cannot easily contain generic function types
- `SkipResolution` was renamed from `Skip` to avoid conflict with the `Skip` class from the test package
- `PendingChange` includes `originalValue` field for state reversion on cancel
- All adapters (PowerSync, CRDT, Drift) implement the full interface with pagination support
- Tests: 34 sync type tests + 18 manager tests + 22 store backend tests + 10 NexusStore API tests + adapter tests

## Completion Date

December 21, 2025
