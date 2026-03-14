# TRACKER: CRDT Backend Adapter

## Status: COMPLETED ✅

## Overview

Implement the CRDT backend adapter for nexus_store, providing conflict-free replicated data types with Hybrid Logical Clock (HLC) timestamps for automatic merge resolution.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-011
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Implementation Summary

The CRDT adapter was implemented using **sqlite_crdt** (^3.0.4) which provides SQLite storage with built-in HLC timestamps and Last-Writer-Wins conflict resolution. The package handles all CRDT metadata columns (hlc, modified, is_deleted, node_id) automatically.

**Key Design Decisions:**
- sqlite_crdt handles HLC management internally via the crdt package
- No separate HlcManager or CrdtMergeHandler classes needed - sqlite_crdt provides this functionality
- Tombstone-based soft deletes (is_deleted column) for CRDT correctness
- BehaviorSubject streams (RxDart) consistent with other adapters
- Auto-tombstone filtering in queries (WHERE is_deleted = 0)
- Changeset-based sync via getChangeset/applyChangeset

**Test Coverage: 81 tests total**
- Query translator tests: 31 tests
- Backend unit tests: 35 tests
- Integration tests: 15 tests

## Tasks

### Package Setup
- [x] Uncomment sqlite_crdt and crdt dependencies in pubspec.yaml
- [x] Create lib/src/ directory structure
- [x] Create test/ directory
- [x] Export public API from nexus_store_crdt_adapter.dart

### Core Implementation
- [x] `crdt_backend.dart`
  - [x] Implement StoreBackend<T, ID> interface
  - [x] Constructor accepting tableName, getId, fromJson, toJson, primaryKeyField
  - [x] getId(T item) implementation
  - [x] fromJson(Map<String, dynamic>) implementation
  - [x] toJson(T item) implementation
  - [x] Handle CRDT metadata columns (hlc, modified, is_deleted) - auto-stripped from results

### Lifecycle Management
- [x] `initialize()` - Open CRDT database (SqliteCrdt.openInMemory)
- [x] `close()` - Close database connection and cleanup streams
- [x] Handle database migrations with CRDT columns (automatic via sqlite_crdt)

### Read Operations
- [x] `get(ID id)` - Query excluding tombstones (is_deleted = false)
- [x] `getAll({Query? query})` - Multi-row excluding tombstones
- [x] `watch(ID id)` - Watch single row changes (BehaviorSubject)
- [x] `watchAll({Query? query})` - Watch table changes (BehaviorSubject)

### Write Operations
- [x] `save(T item)` - Insert/update with HLC timestamp (automatic)
- [x] `saveAll(List<T> items)` - Batch operations
- [x] `delete(ID id)` - Soft delete (tombstone)
- [x] `deleteAll(List<ID> ids)` - Batch tombstone
- [x] `deleteWhere(Query query)` - Conditional tombstone

### CRDT-Specific Operations
- [x] Merge incoming changesets (via sqlite_crdt.merge())
- [x] Compare HLC timestamps (Last-Writer-Wins - automatic)
- [x] Preserve tombstones for conflict resolution
- [x] Handle concurrent edits (LWW automatic)
- [x] Generate changeset for outgoing sync (getChangeset)

### HLC (Hybrid Logical Clock) Integration
- [x] Generate HLC timestamps (automatic via sqlite_crdt)
- [x] Update local clock on receive (automatic via sqlite_crdt)
- [x] Ensure monotonically increasing timestamps (automatic)
- [x] Handle clock drift (automatic via Hlc class)

**Note:** Separate hlc_manager.dart and crdt_merge_handler.dart files were not needed - sqlite_crdt provides all HLC and merge functionality built-in.

### Sync Operations
- [x] `syncStatus` getter - Based on pending changesets
- [x] `syncStatusStream` - Emit on changeset state changes
- [x] `sync()` - Exchange changesets with peers (stub - no built-in transport)
- [x] `pendingChangesCount` getter - Pending outgoing changes
- [x] `nodeId` getter - Unique node identifier per instance

### Changeset Management
- [x] `getChangeset({Hlc? since})` - Get changes since timestamp
- [x] `applyChangeset(changeset)` - Apply incoming changes with LWW merge
- [x] Handle merge conflicts automatically (LWW via sqlite_crdt)

### Query Translation
- [x] `crdt_query_translator.dart`
  - [x] Implement QueryTranslator interface methods (translate, translateFilters, translateOrderBy)
  - [x] Translate to SQL (sqlite_crdt uses SQLite)
  - [x] Auto-filter tombstones (WHERE is_deleted = 0)
  - [x] Handle all filter operators (equals, notEquals, lessThan, greaterThan, etc.)
  - [x] Handle whereIn, whereNotIn, isNull, contains, startsWith, endsWith
  - [x] Handle ORDER BY, LIMIT, OFFSET
  - [x] Support field mapping

### Backend Info
- [x] `name` getter returns 'crdt'
- [x] `supportsOffline` returns true
- [x] `supportsRealtime` returns true (via changesets)
- [x] `supportsTransactions` returns true

### Tombstone Management
- [x] Tombstones preserved for sync
- [x] Handle tombstone revival (un-delete by saving again)

### Error Handling
- [x] Throw StateError when used before initialization
- [x] Handle merge conflicts (auto-resolve with LWW)

### Unit Tests
- [x] `test/crdt_backend_test.dart` (35 tests)
  - [x] Constructor validation
  - [x] Backend info properties (name, supportsOffline, supportsRealtime, supportsTransactions)
  - [x] Lifecycle (initialize idempotency, close cleanup, StateError before init)
  - [x] CRUD operations (get, getAll, save, saveAll, delete, deleteAll, deleteWhere)
  - [x] Tombstone behavior (soft delete, revival)
  - [x] Query with tombstone filtering (filters, orderBy, limit, offset)
  - [x] Watch operations (watch, watchAll)
  - [x] Sync operations (syncStatus, syncStatusStream, sync, pendingChangesCount)
  - [x] CRDT-specific (getChangeset, nodeId uniqueness)

- [x] `test/crdt_query_translator_test.dart` (31 tests)
  - [x] Tombstone auto-filtering (default WHERE is_deleted = 0)
  - [x] All filter operators (equals, notEquals, lessThan, lessThanOrEquals, greaterThan, greaterThanOrEquals)
  - [x] whereIn, whereNotIn, isNull filters
  - [x] contains, startsWith, endsWith via QueryFilter
  - [x] Multiple filters with AND
  - [x] ORDER BY (ascending, descending, multiple)
  - [x] LIMIT and OFFSET
  - [x] Field mapping
  - [x] DELETE SQL generation
  - [x] QueryTranslator interface methods

### Integration Tests
- [x] `test/integration/crdt_integration_test.dart` (15 tests)
  - [x] Full CRUD lifecycle (create-read-update-delete)
  - [x] Batch operations
  - [x] Query capabilities (filtering, ordering, pagination, combined filters)
  - [x] Tombstone behavior (soft delete, revival, deleteWhere)
  - [x] Watch operations
  - [x] Changeset operations
  - [x] nodeId consistency and uniqueness

## Files

**Package Structure:**
```
packages/nexus_store_crdt_adapter/
├── lib/
│   ├── nexus_store_crdt_adapter.dart    # Public exports
│   └── src/
│       ├── crdt_backend.dart            # Main backend class (~280 lines)
│       └── crdt_query_translator.dart   # SQL query builder (~180 lines)
├── test/
│   ├── crdt_backend_test.dart           # Unit tests (35 tests)
│   ├── crdt_query_translator_test.dart  # Query translator tests (31 tests)
│   └── integration/
│       └── crdt_integration_test.dart   # Integration tests (15 tests)
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  sqlite_crdt: ^3.0.4
  crdt: ^5.1.3
  rxdart: ^0.28.0

dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.4
  lints: ^5.1.0
```

## Dependencies

- Core package tests must pass first ✅
- sqlite_crdt documentation: https://pub.dev/packages/sqlite_crdt
- crdt package: https://pub.dev/packages/crdt

## Notes

- CRDT = Conflict-free Replicated Data Type
- HLC = Hybrid Logical Clock (combines physical + logical time)
- Last-Writer-Wins (LWW) based on HLC timestamps
- Tombstones are soft deletes - required for CRDT correctness
- sqlite_crdt adds metadata columns: hlc, modified, is_deleted, node_id
- CrdtChangeset is a typedef for `Map<String, List<Map<String, Object?>>>`
- Changesets contain all operations since a given HLC
- No merge conflicts - all conflicts auto-resolve via LWW
- Custom sync transport not included (use getChangeset/applyChangeset with your transport)
- CRDT metadata columns (hlc, modified, is_deleted, node_id) are automatically stripped from results

## Completion Date

2025-12-18
