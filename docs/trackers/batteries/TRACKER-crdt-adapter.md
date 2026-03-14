# TRACKER: CRDT Adapter Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_crdt_adapter` including type-safe column definitions, merge strategy configuration, peer connector abstraction, table configuration, factory methods, multi-table manager, and sync rules DSL.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Column Definitions
- [x] Create `CrdtColumn` class with factory methods
  - [x] `CrdtColumn.text()`
  - [x] `CrdtColumn.integer()`
  - [x] `CrdtColumn.real()`
  - [x] `CrdtColumn.blob()`
- [x] Create `CrdtTableDefinition` class
- [x] Implement `toCreateTableSql()` method
- [x] Create `CrdtIndex` class for index definitions

### Phase 2: Merge Strategy DSL
- [x] Create `CrdtMergeStrategy` enum (lww, fww, custom)
- [x] Create `CrdtMergeConfig<T>` class
- [x] Support per-field merge strategies via `CrdtFieldMerger`
- [x] Support custom merge functions via `CrdtMergeFunction`
- [x] Create `CrdtMergeResult<T>` and `CrdtConflictDetail` classes

### Phase 3: Peer Connector Pattern
- [x] Create abstract `CrdtPeerConnector` interface
- [x] Create `CrdtPeerConnectionState` enum
- [x] Create `CrdtChangesetMessage` class
- [x] Create `CrdtMemoryConnector` for testing
- [x] Create `CrdtPeerConnectorPair` for bidirectional testing
- [x] Implement changeset send/receive streams

### Phase 4: Table Configuration
- [x] Create `CrdtTableConfig<T, ID>` class
- [x] Add merge config support
- [x] Add field mapping support
- [x] Add primary key configuration
- [x] Add dynamic type wrappers for manager compatibility

### Phase 5: Factory Method
- [x] Add `CrdtBackend.withDatabase()` factory
- [x] Handle database path configuration
- [x] Auto-generate node ID if not provided
- [x] Implement automatic schema creation from columns

### Phase 6: Manager Class
- [x] Create `CrdtManager` class
- [x] Implement `CrdtManager.withDatabase()` factory
- [x] Implement `CrdtManager.withWrapper()` factory for testing
- [x] Implement `initialize()` method
- [x] Implement `getBackend(tableName)` method
- [x] Implement `getChangesetForAll({Hlc? since})` method
- [x] Implement `applyChangesetToAll(changeset)` method
- [x] Implement `attachConnector(connector)` method
- [x] Implement `detachConnector()` method
- [x] Implement `sendChangeset({Hlc? since})` method
- [x] Implement `dispose()` method
- [x] Add shared database connection management

### Phase 7: Sync Rules DSL
- [x] Create `CrdtSyncRules` class
- [x] Create `CrdtSyncTableRule` class
- [x] Create `CrdtSyncDirection` enum (bidirectional, pushOnly, pullOnly, none)
- [x] Support filter expressions
- [x] Support priority-based ordering
- [x] Implement `filterChangeset()` method

### Phase 8: Integration
- [x] Update barrel export
- [x] Add unit tests for column definitions (31 tests)
- [x] Add unit tests for merge strategies (17 tests)
- [x] Add unit tests for peer connectors (18 tests)
- [x] Add unit tests for table config (18 tests)
- [x] Add unit tests for sync rules (27 tests)
- [x] Add integration tests for manager (17 tests)

## Files

### New Files
| File | Description |
|------|-------------|
| `lib/src/crdt_column.dart` | Type-safe column definitions |
| `lib/src/crdt_table_config.dart` | Table configuration bundling |
| `lib/src/crdt_merge_strategy.dart` | Merge configuration DSL |
| `lib/src/crdt_peer_connector.dart` | Peer sync abstraction |
| `lib/src/crdt_sync_rules.dart` | Sync filter configuration |
| `lib/src/crdt_manager.dart` | Multi-table coordination |

### Modified Files
| File | Changes |
|------|---------|
| `lib/src/crdt_backend.dart` | Add `withDatabase()` factory |
| `lib/nexus_store_crdt_adapter.dart` | Export new classes |

### Test Files
| File | Description |
|------|-------------|
| `test/unit/crdt_column_test.dart` | Column tests (31 tests) |
| `test/unit/crdt_merge_strategy_test.dart` | Merge strategy tests (17 tests) |
| `test/unit/crdt_peer_connector_test.dart` | Connector tests (18 tests) |
| `test/unit/crdt_table_config_test.dart` | Table config tests (18 tests) |
| `test/unit/crdt_sync_rules_test.dart` | Sync rules tests (27 tests) |
| `test/integration/crdt_manager_test.dart` | Manager tests (17 tests) |

## Dependencies

- sqlite_crdt: ^1.0.0 (existing)

## API Design

```dart
// Column definitions
final columns = [
  CrdtColumn.text('id', nullable: false),
  CrdtColumn.text('name', nullable: false),
  CrdtColumn.text('email'),
  CrdtColumn.integer('age', nullable: true),
];

// Merge configuration
final mergeConfig = CrdtMergeConfig<User>(
  defaultStrategy: CrdtMergeStrategy.lww,
  fieldStrategies: {
    'name': CrdtMergeStrategy.fww, // First write wins for name
  },
);

// Single table factory
final backend = CrdtBackend<User, String>.withDatabase(
  tableName: 'users',
  columns: columns,
  getId: (u) => u.id,
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
);
await backend.initialize();

// Multi-table manager
final manager = CrdtManager.withDatabase(
  tables: [
    CrdtTableConfig<User, String>(
      tableName: 'users',
      columns: userColumns,
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
      getId: (u) => u.id,
      mergeConfig: mergeConfig,
    ),
    CrdtTableConfig<Post, String>(
      tableName: 'posts',
      columns: postColumns,
      fromJson: Post.fromJson,
      toJson: (p) => p.toJson(),
      getId: (p) => p.id,
    ),
  ],
  nodeId: 'device-123', // Optional, auto-generated if null
);
await manager.initialize();

// Attach peer connector
final connector = CrdtMemoryConnector(peerId: 'peer-1');
manager.attachConnector(connector);
await connector.connect();

// Get changesets for sync
final changeset = await manager.getChangesetForAll(since: lastSyncHlc);
await manager.sendChangeset(since: lastSyncHlc);

// Sync rules
final syncRules = CrdtSyncRules(
  defaultDirection: CrdtSyncDirection.bidirectional,
  tableRules: [
    CrdtSyncTableRule(
      tableName: 'logs',
      direction: CrdtSyncDirection.pushOnly,
    ),
    CrdtSyncTableRule(
      tableName: 'posts',
      filter: (r) => r['is_public'] == true,
      priority: 10,
    ),
  ],
);

// Filter changeset based on rules
final filtered = syncRules.filterChangeset(changeset, isOutgoing: true);
```

## Notes

- CRDT is most complex adapter due to conflict resolution
- HLC (Hybrid Logical Clock) provides causal ordering
- Peer connectors enable various sync topologies (hub-spoke, mesh)
- sqlite_crdt handles HLC columns automatically
- All tests passing (403 total in package)
- 100% test coverage achieved

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | All phases completed - 384 tests passing |
| 2026-01-10 | 100% coverage achieved - 403 tests, fixed HLC serialization bug |
