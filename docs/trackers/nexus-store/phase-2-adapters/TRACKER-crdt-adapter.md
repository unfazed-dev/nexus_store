# TRACKER: CRDT Backend Adapter

## Status: PENDING

## Overview

Implement the CRDT backend adapter for nexus_store, providing conflict-free replicated data types with Hybrid Logical Clock (HLC) timestamps for automatic merge resolution.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-011
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Uncomment sqlite_crdt and crdt dependencies in pubspec.yaml
- [ ] Create lib/src/ directory structure
- [ ] Create test/ directory
- [ ] Export public API from nexus_store_crdt_adapter.dart

### Core Implementation
- [ ] `crdt_backend.dart`
  - [ ] Implement StoreBackend<T, ID> interface
  - [ ] Constructor accepting CrdtDatabase, tableName, serializers
  - [ ] getId(T item) implementation
  - [ ] fromJson(Map<String, dynamic>) implementation
  - [ ] toJson(T item) implementation
  - [ ] Handle CRDT metadata columns (hlc, modified, is_deleted)

### Lifecycle Management
- [ ] `initialize()` - Open CRDT database
- [ ] `close()` - Close database connection
- [ ] Handle database migrations with CRDT columns

### Read Operations
- [ ] `get(ID id)` - Query excluding tombstones (is_deleted = false)
- [ ] `getAll({Query? query})` - Multi-row excluding tombstones
- [ ] `watch(ID id)` - Watch single row changes
- [ ] `watchAll({Query? query})` - Watch table changes

### Write Operations
- [ ] `save(T item)` - Insert/update with HLC timestamp
- [ ] `saveAll(List<T> items)` - Batch operations
- [ ] `delete(ID id)` - Soft delete (tombstone)
- [ ] `deleteAll(List<ID> ids)` - Batch tombstone
- [ ] `deleteWhere(Query query)` - Conditional tombstone

### CRDT-Specific Operations
- [ ] `crdt_merge_handler.dart`
  - [ ] Merge incoming changesets
  - [ ] Compare HLC timestamps (Last-Writer-Wins)
  - [ ] Preserve tombstones for conflict resolution
  - [ ] Handle concurrent edits
  - [ ] Generate changeset for outgoing sync

### HLC (Hybrid Logical Clock) Integration
- [ ] `hlc_manager.dart`
  - [ ] Generate HLC timestamps
  - [ ] Update local clock on receive
  - [ ] Ensure monotonically increasing timestamps
  - [ ] Handle clock drift

### Sync Operations
- [ ] `syncStatus` getter - Based on pending changesets
- [ ] `syncStatusStream` - Emit on changeset state changes
- [ ] `sync()` - Exchange changesets with peers
- [ ] `pendingChangesCount` getter - Pending outgoing changes
- [ ] `isConnected` stream - Peer connectivity

### Changeset Management
- [ ] `getChangeset(Hlc since)` - Get changes since timestamp
- [ ] `applyChangeset(changeset)` - Apply incoming changes
- [ ] Handle merge conflicts automatically

### Query Translation
- [ ] `crdt_query_translator.dart`
  - [ ] Implement QueryTranslator interface
  - [ ] Translate to SQL (sqlite_crdt uses SQLite)
  - [ ] Auto-filter tombstones (WHERE is_deleted = 0)
  - [ ] Handle CRDT metadata columns in projections

### Backend Info
- [ ] `name` getter returns 'crdt'
- [ ] `supportsOffline` returns true
- [ ] `supportsRealtime` returns true (via changesets)
- [ ] `supportsTransactions` returns true

### Tombstone Management
- [ ] Tombstones preserved for sync
- [ ] Optional tombstone cleanup after TTL
- [ ] Handle tombstone revival (un-delete)

### Error Handling
- [ ] Map sqlite_crdt exceptions to StoreError types
- [ ] Handle merge conflicts (should auto-resolve with LWW)
- [ ] Handle database errors

### Unit Tests
- [ ] `test/crdt_backend_test.dart`
  - [ ] Constructor validation
  - [ ] Lifecycle (initialize/close)
  - [ ] CRUD operations
  - [ ] Tombstone behavior
  - [ ] HLC timestamp generation
  - [ ] Query with tombstone filtering

- [ ] `test/crdt_merge_handler_test.dart`
  - [ ] Merge with newer timestamp wins
  - [ ] Merge with concurrent edits
  - [ ] Tombstone preservation
  - [ ] Changeset generation

- [ ] `test/hlc_manager_test.dart`
  - [ ] Monotonic timestamp generation
  - [ ] Clock update on receive
  - [ ] Drift handling

### Integration Tests
- [ ] `test/integration/crdt_integration_test.dart`
  - [ ] Multi-instance conflict resolution
  - [ ] Offline edits merge correctly
  - [ ] Tombstone sync between instances

## Files

**Package Structure:**
```
packages/nexus_store_crdt_adapter/
├── lib/
│   ├── nexus_store_crdt_adapter.dart    # Public exports
│   └── src/
│       ├── crdt_backend.dart            # Main backend class
│       ├── crdt_query_translator.dart   # SQL query builder
│       ├── crdt_merge_handler.dart      # Changeset merging
│       └── hlc_manager.dart             # HLC timestamp management
├── test/
│   ├── crdt_backend_test.dart           # Unit tests
│   ├── crdt_merge_handler_test.dart     # Merge logic tests
│   ├── hlc_manager_test.dart            # HLC tests
│   └── integration/
│       └── crdt_integration_test.dart   # Integration tests
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  sqlite_crdt: ^2.1.0
  crdt: ^5.2.0

dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.4
```

## Dependencies

- Core package tests must pass first
- sqlite_crdt documentation: https://pub.dev/packages/sqlite_crdt
- crdt package: https://pub.dev/packages/crdt
- Understanding of CRDTs and HLC

## Notes

- CRDT = Conflict-free Replicated Data Type
- HLC = Hybrid Logical Clock (combines physical + logical time)
- Last-Writer-Wins (LWW) based on HLC timestamps
- Tombstones are soft deletes - required for CRDT correctness
- sqlite_crdt adds metadata columns: hlc, modified, is_deleted
- Changesets contain all operations since a given HLC
- No merge conflicts - all conflicts auto-resolve via LWW
- Consider eventual consistency implications in documentation
- May need custom sync transport (not included in sqlite_crdt)
