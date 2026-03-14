# TRACKER: Brick Adapter Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_brick_adapter` including table configuration, sync policy configuration, factory methods, and multi-entity manager coordination.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-002, REQ-003, REQ-004, REQ-006

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Sync Configuration
- [x] Create `BrickSyncPolicy` enum (immediate, batch, manual)
- [x] Create `BrickSyncConfig` class
- [x] Create `BrickRetryPolicy` class
- [x] Create `BrickConflictResolution` enum

### Phase 2: Table Configuration
- [x] Create `BrickTableConfig<T, ID>` class
- [x] Add sync policy support
- [x] Add field mapping support
- [x] Add primary key configuration

### Phase 3: Factory Method
- [x] Add `BrickBackend.withConfig()` factory
- [x] Wire up sync policy
- [x] Handle lifecycle management

### Phase 4: Manager Class
- [x] Create `BrickManager` class
- [x] Implement `BrickManager.withRepository()` factory
- [x] Implement `initialize()` method
- [x] Implement `getBackend(tableName)` method
- [x] Implement `syncAll()` method
- [x] Implement `totalPendingChanges` getter
- [x] Implement `syncStatusStream` getter
- [x] Implement `dispose()` method

### Phase 5: Integration
- [x] Update barrel export
- [x] Add unit tests for sync config (13 tests)
- [x] Add unit tests for table config (14 tests)
- [x] Add integration tests for manager (12 tests)
- [x] Update README with examples

## Files

### New Files
| File | Description |
|------|-------------|
| `lib/src/brick_table_config.dart` | Table configuration bundling |
| `lib/src/brick_sync_config.dart` | Sync policy configuration |
| `lib/src/brick_manager.dart` | Multi-entity coordination |

### Modified Files
| File | Changes |
|------|---------|
| `lib/src/brick_backend.dart` | Add `withRepository()` factory |
| `lib/nexus_store_brick_adapter.dart` | Export new classes |
| `README.md` | Document batteries-included usage |

### Test Files
| File | Description |
|------|-------------|
| `test/unit/brick_sync_config_test.dart` | Sync config tests |
| `test/unit/brick_table_config_test.dart` | Table config tests |
| `test/integration/brick_manager_test.dart` | Manager tests |

## Dependencies

- brick_offline_first: ^3.0.0 (existing)

## API Design

```dart
// Sync configuration
final syncConfig = BrickSyncConfig(
  retryPolicy: BrickRetryPolicy(
    maxAttempts: 3,
    backoffMs: 1000,
    exponentialBackoff: true,
  ),
  conflictResolution: BrickConflictResolution.serverWins,
  batchSize: 50,
);

// Table configuration
final userConfig = BrickTableConfig<User, String>(
  tableName: 'users',
  getId: (u) => u.id,
  syncPolicy: BrickSyncPolicy.immediate,
);

// Single table factory
final backend = BrickBackend<User, String>.withRepository(
  repository: myOfflineFirstRepository,
  tableName: 'users',
  getId: (u) => u.id,
  syncPolicy: BrickSyncPolicy.immediate,
);

// Multi-entity manager
final manager = BrickManager.withRepository(
  repository: myOfflineFirstRepository,
  tables: [
    BrickTableConfig<User, String>(...),
    BrickTableConfig<Post, String>(...),
  ],
);
await manager.initialize();

// Sync all entities
await manager.syncAll();
final pending = manager.totalPendingChanges;
```

## Notes

- Brick has its own annotation/code-gen system
- This enhancement complements Brick's patterns, doesn't replace
- Focus on coordination and policy configuration
- Less room for column definitions (Brick uses annotations)

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Completed: All 5 phases implemented with 90+ tests passing |
