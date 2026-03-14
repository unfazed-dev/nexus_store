# TRACKER: Delta Sync Support

## Status: COMPLETE

## Overview

Implement field-level change tracking and delta sync to minimize bandwidth by only syncing changed fields rather than entire records.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-031, Task 28
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Summary

Delta sync support has been fully implemented with **136 tests** across 7 test files. The implementation provides:
- Field-level change tracking using JSON comparison
- Multiple merge strategies (lastWriteWins, fieldLevel, custom)
- Conflict detection and resolution
- TrackedEntity wrapper for convenient change tracking
- Integration with StoreConfig

## Tasks

### Data Models
- [x] Create `FieldChange` class
  - [x] `fieldName: String`
  - [x] `oldValue: dynamic`
  - [x] `newValue: dynamic`
  - [x] `timestamp: DateTime`

- [x] Create `DeltaChange<T>` class
  - [x] `entityId: ID`
  - [x] `changes: List<FieldChange>`
  - [x] `baseVersion: int?` - For optimistic concurrency
  - [x] `timestamp: DateTime`

- [x] Create `DeltaSyncConfig` class
  - [x] `enabled: bool`
  - [x] `excludeFields: Set<String>` - Always sync full
  - [x] `mergeStrategy: DeltaMergeStrategy`

- [x] Create `DeltaMergeStrategy` enum
  - [x] `lastWriteWins` - Latest timestamp wins
  - [x] `fieldLevel` - Per-field conflict resolution
  - [x] `custom` - Delegate to callback

### Change Tracking
- [x] Create `DeltaTracker<T>` class
  - [x] `trackChanges(T original, T modified)` - Detect changes
  - [x] `getChangedFields(T original, T modified)` - List changed fields
  - [x] Support nested object comparison

- [x] Implement dirty field detection
  - [x] Deep equality comparison
  - [x] Support for collections (List, Map, Set)
  - [x] Ignore computed/derived fields

- [x] Create `TrackedEntity<T>` wrapper
  - [x] Stores original snapshot
  - [x] Tracks modifications
  - [x] Provides `getDelta()` method

### Merge Logic
- [x] Implement `DeltaMerger<T>` class
  - [x] Merge incoming delta with local state
  - [x] Handle field-level conflicts
  - [x] Emit merge events

- [x] Implement conflict detection
  - [x] Same field changed locally and remotely
  - [x] Version mismatch detection

- [x] Implement merge strategies
  - [x] Last-write-wins per field
  - [x] Custom merge callbacks

### StoreConfig Integration
- [x] Add `deltaSync` to `StoreConfig`
  - [x] Enable/disable delta sync
  - [x] Configure merge strategy

### Unit Tests
- [x] `test/src/sync/field_change_test.dart` - 25 tests
- [x] `test/src/sync/delta_change_test.dart` - 25 tests
- [x] `test/src/sync/delta_sync_config_test.dart` - 20 tests
- [x] `test/src/sync/delta_tracker_test.dart` - 25 tests
- [x] `test/src/sync/tracked_entity_test.dart` - 20 tests
- [x] `test/src/sync/delta_merger_test.dart` - 22 tests
- [x] `test/src/sync/delta_sync_integration_test.dart` - 18 tests

## Files

**Source Files:**
```
packages/nexus_store/lib/src/sync/
├── delta_merge_strategy.dart    # Enum (3 strategies)
├── field_change.dart            # FieldChange model (freezed)
├── field_change.freezed.dart    # Generated
├── delta_change.dart            # DeltaChange model (freezed)
├── delta_change.freezed.dart    # Generated
├── delta_sync_config.dart       # Configuration (freezed)
├── delta_sync_config.freezed.dart # Generated
├── delta_tracker.dart           # Change tracking
├── tracked_entity.dart          # Entity wrapper
└── delta_merger.dart            # Merge logic + conflict resolution
```

**Test Files:**
```
packages/nexus_store/test/src/sync/
├── field_change_test.dart
├── delta_change_test.dart
├── delta_sync_config_test.dart
├── delta_tracker_test.dart
├── tracked_entity_test.dart
├── delta_merger_test.dart
└── delta_sync_integration_test.dart
```

**Modified Files:**
- `packages/nexus_store/lib/src/config/store_config.dart` - Added `deltaSync` field
- `packages/nexus_store/lib/nexus_store.dart` - Added exports

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
