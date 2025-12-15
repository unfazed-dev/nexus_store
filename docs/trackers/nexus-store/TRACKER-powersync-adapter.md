# TRACKER: PowerSync Backend Adapter

## Status: PENDING

## Overview

Implement the PowerSync backend adapter for nexus_store, providing offline-first sync capabilities with PostgreSQL backends and optional SQLCipher encryption.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-007
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Uncomment powersync dependencies in pubspec.yaml
- [ ] Add powersync_sqlcipher dependency for encryption
- [ ] Create lib/src/ directory structure
- [ ] Export public API from nexus_store_powersync_adapter.dart

### Core Implementation
- [ ] `powersync_backend.dart`
  - [ ] Implement StoreBackend<T, ID> interface
  - [ ] Constructor accepting PowerSyncDatabase, tableName, serializers
  - [ ] getId(T item) implementation
  - [ ] fromJson(Map<String, dynamic>) implementation
  - [ ] toJson(T item) implementation

### Lifecycle Management
- [ ] `initialize()` - Connect to PowerSync
- [ ] `close()` - Disconnect and cleanup
- [ ] Handle connection state changes

### Read Operations
- [ ] `get(ID id)` - Single row query
- [ ] `getAll({Query? query})` - Multi-row query with filters
- [ ] `watch(ID id)` - Watch single row changes
- [ ] `watchAll({Query? query})` - Watch table changes

### Write Operations
- [ ] `save(T item)` - Upsert row
- [ ] `saveAll(List<T> items)` - Batch upsert
- [ ] `delete(ID id)` - Delete row
- [ ] `deleteAll(List<ID> ids)` - Batch delete
- [ ] `deleteWhere(Query query)` - Conditional delete

### Sync Operations
- [ ] `syncStatus` getter - Current sync state
- [ ] `syncStatusStream` - Stream of sync state changes
- [ ] `sync()` - Trigger manual sync
- [ ] `pendingChangesCount` getter - Pending upload count
- [ ] Map PowerSync status to SyncStatus enum

### Query Translation
- [ ] `powersync_query_translator.dart`
  - [ ] Implement QueryTranslator interface
  - [ ] Translate Query.where() to SQL WHERE clause
  - [ ] Translate Query.orderBy() to SQL ORDER BY
  - [ ] Translate Query.limit() to SQL LIMIT
  - [ ] Translate Query.offset() to SQL OFFSET
  - [ ] Handle comparison operators (>, <, >=, <=, !=)
  - [ ] Handle IN, NOT IN operators
  - [ ] Handle IS NULL operator
  - [ ] Escape values to prevent SQL injection

### Backend Info
- [ ] `name` getter returns 'powersync'
- [ ] `supportsOffline` returns true
- [ ] `supportsRealtime` returns true (via sync)
- [ ] `supportsTransactions` returns true

### SQLCipher Integration
- [ ] `powersync_encrypted_backend.dart` (optional subclass)
  - [ ] Accept encryption key provider
  - [ ] Configure SQLCipher on database open
  - [ ] Handle key rotation

### Error Handling
- [ ] Map PowerSync exceptions to StoreError types
- [ ] Handle network errors as NetworkError
- [ ] Handle sync conflicts as ConflictError
- [ ] Handle auth errors as AuthenticationError

### Unit Tests
- [ ] `test/powersync_backend_test.dart`
  - [ ] Constructor validation
  - [ ] Lifecycle (initialize/close)
  - [ ] CRUD operations with mock database
  - [ ] Query translation correctness
  - [ ] Sync status mapping
  - [ ] Error mapping

### Integration Tests
- [ ] `test/integration/powersync_integration_test.dart`
  - [ ] Real PowerSync database operations
  - [ ] Sync with mock backend server
  - [ ] Offline/online transitions

## Files

**Package Structure:**
```
packages/nexus_store_powersync_adapter/
├── lib/
│   ├── nexus_store_powersync_adapter.dart    # Public exports
│   └── src/
│       ├── powersync_backend.dart            # Main backend class
│       ├── powersync_encrypted_backend.dart  # SQLCipher variant
│       └── powersync_query_translator.dart   # SQL query builder
├── test/
│   ├── powersync_backend_test.dart           # Unit tests
│   └── integration/
│       └── powersync_integration_test.dart   # Integration tests
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  powersync: ^1.17.0
  powersync_sqlcipher: ^1.0.0  # Optional for encryption
```

## Dependencies

- Core package tests must pass first
- PowerSync SDK documentation: https://docs.powersync.com/
- PowerSync Flutter SDK: https://github.com/powersync-ja/powersync.dart

## Notes

- PowerSync uses SQL internally, so query translation is straightforward
- PowerSync handles offline queue automatically - leverage this for sync status
- SQLCipher integration requires powersync_sqlcipher package
- Watch operations use PowerSync's `db.watch()` method
- Consider using PowerSync's `execute()` for batch operations
- Sync status maps: uploading->syncing, error->error, idle->synced
