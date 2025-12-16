# TRACKER: Delta Sync Support

## Status: PENDING

## Overview

Implement field-level change tracking and delta sync to minimize bandwidth by only syncing changed fields rather than entire records.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-031, Task 28
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `FieldChange` class
  - [ ] `fieldName: String`
  - [ ] `oldValue: dynamic`
  - [ ] `newValue: dynamic`
  - [ ] `timestamp: DateTime`

- [ ] Create `DeltaChange<T>` class
  - [ ] `entityId: ID`
  - [ ] `changes: List<FieldChange>`
  - [ ] `baseVersion: int?` - For optimistic concurrency
  - [ ] `timestamp: DateTime`

- [ ] Create `DeltaSyncConfig` class
  - [ ] `enabled: bool`
  - [ ] `excludeFields: Set<String>` - Always sync full
  - [ ] `mergeStrategy: DeltaMergeStrategy`

- [ ] Create `DeltaMergeStrategy` enum
  - [ ] `lastWriteWins` - Latest timestamp wins
  - [ ] `fieldLevel` - Per-field conflict resolution
  - [ ] `custom` - Delegate to callback

### Change Tracking
- [ ] Create `DeltaTracker<T>` class
  - [ ] `trackChanges(T original, T modified)` - Detect changes
  - [ ] `getChangedFields(T original, T modified)` - List changed fields
  - [ ] Support nested object comparison

- [ ] Implement dirty field detection
  - [ ] Deep equality comparison
  - [ ] Support for collections (List, Map, Set)
  - [ ] Ignore computed/derived fields

- [ ] Create `TrackedEntity<T>` wrapper
  - [ ] Stores original snapshot
  - [ ] Tracks modifications
  - [ ] Provides `getDelta()` method

### Sync Integration
- [ ] Update `StoreBackend` interface
  - [ ] `saveDelta(ID id, DeltaChange<T> delta)` method
  - [ ] `getDelta(ID id, int fromVersion)` method

- [ ] Implement delta sync flow
  - [ ] Collect changed fields on save
  - [ ] Send only delta to remote
  - [ ] Apply incoming deltas to local state

- [ ] Update pending changes queue
  - [ ] Store delta instead of full entity
  - [ ] Merge multiple deltas to same entity

### Merge Logic
- [ ] Implement `DeltaMerger<T>` class
  - [ ] Merge incoming delta with local state
  - [ ] Handle field-level conflicts
  - [ ] Emit merge events

- [ ] Implement conflict detection
  - [ ] Same field changed locally and remotely
  - [ ] Version mismatch detection

- [ ] Implement merge strategies
  - [ ] Last-write-wins per field
  - [ ] Custom merge callbacks

### StoreConfig Integration
- [ ] Add `deltaSync` to `StoreConfig`
  - [ ] Enable/disable delta sync
  - [ ] Configure merge strategy

### Unit Tests
- [ ] `test/src/sync/delta_tracker_test.dart`
  - [ ] Detects changed fields correctly
  - [ ] Handles nested objects
  - [ ] Handles collections

- [ ] `test/src/sync/delta_merger_test.dart`
  - [ ] Merges non-conflicting changes
  - [ ] Handles conflicts per strategy
  - [ ] Preserves unchanged fields

## Files

**Source Files:**
```
packages/nexus_store/lib/src/sync/
├── delta_tracker.dart        # DeltaTracker class
├── delta_change.dart         # DeltaChange, FieldChange models
├── delta_merger.dart         # DeltaMerger class
├── delta_sync_config.dart    # Configuration
└── tracked_entity.dart       # TrackedEntity wrapper
```

**Test Files:**
```
packages/nexus_store/test/src/sync/
├── delta_tracker_test.dart
├── delta_merger_test.dart
└── delta_sync_integration_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Conflict Resolution (Task 19) - for conflict handling

## API Preview

```dart
// Enable delta sync
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    deltaSync: DeltaSyncConfig(
      enabled: true,
      excludeFields: {'updatedAt'}, // Always sync full
      mergeStrategy: DeltaMergeStrategy.fieldLevel,
    ),
  ),
);

// Manual delta tracking
final tracker = DeltaTracker<User>();
final original = await store.get('user-123');
final modified = original!.copyWith(
  name: 'New Name',
  email: 'new@email.com',
);

final delta = tracker.trackChanges(original, modified);
// delta.changes = [
//   FieldChange(fieldName: 'name', oldValue: 'Old', newValue: 'New Name'),
//   FieldChange(fieldName: 'email', oldValue: 'old@email.com', newValue: 'new@email.com'),
// ]

// Save with delta (automatic when deltaSync enabled)
await store.save(modified); // Only sends name + email fields

// Custom merge strategy
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    deltaSync: DeltaSyncConfig(
      enabled: true,
      mergeStrategy: DeltaMergeStrategy.custom,
      onMergeConflict: (field, local, remote) {
        // Custom resolution per field
        if (field == 'lastLoginAt') {
          return remote; // Remote wins for timestamps
        }
        return local; // Local wins for other fields
      },
    ),
  ),
);

// Using tracked entity wrapper
final tracked = TrackedEntity(await store.get('user-123')!);
tracked.value = tracked.value.copyWith(name: 'Updated');
tracked.value = tracked.value.copyWith(age: 30);

final delta = tracked.getDelta();
// Captures all changes since original snapshot
```

## Notes

- Delta sync requires backend support for partial updates
- Some backends (CRDT) have native delta support
- Consider bandwidth vs computation tradeoff
- Large blob fields benefit most from delta sync
- Version vectors help with concurrent delta resolution
- Document incompatibility with some sync patterns
- Consider adding delta compression for very large changesets
