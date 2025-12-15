# TRACKER: Drift Backend Adapter

## Status: PENDING

## Overview

Implement the Drift backend adapter for nexus_store, providing local-only SQLite storage with type-safe queries and code generation.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-010
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Uncomment drift dependency in pubspec.yaml
- [ ] Add drift_dev and build_runner to dev_dependencies
- [ ] Create lib/src/ directory structure
- [ ] Export public API from nexus_store_drift_adapter.dart

### Core Implementation
- [ ] `drift_backend.dart`
  - [ ] Implement StoreBackend<T, ID> interface
  - [ ] Constructor accepting GeneratedDatabase, TableInfo, serializers
  - [ ] Generic approach that works with any Drift table
  - [ ] getId(T item) implementation
  - [ ] fromJson(Map<String, dynamic>) implementation
  - [ ] toJson(T item) implementation

### Lifecycle Management
- [ ] `initialize()` - Open database connection
- [ ] `close()` - Close database connection
- [ ] Handle database not initialized errors

### Read Operations
- [ ] `get(ID id)` - Single row select
- [ ] `getAll({Query? query})` - Multi-row select with filters
- [ ] `watch(ID id)` - Watch single row with watchSingle()
- [ ] `watchAll({Query? query})` - Watch table with watch()

### Write Operations
- [ ] `save(T item)` - Insert or replace
- [ ] `saveAll(List<T> items)` - Batch insert with transaction
- [ ] `delete(ID id)` - Delete by ID
- [ ] `deleteAll(List<ID> ids)` - Batch delete
- [ ] `deleteWhere(Query query)` - Conditional delete

### Sync Operations (Local-Only Stubs)
- [ ] `syncStatus` getter - Always returns SyncStatus.synced
- [ ] `syncStatusStream` - Emits single SyncStatus.synced
- [ ] `sync()` - No-op, completes immediately
- [ ] `pendingChangesCount` getter - Always returns 0
- [ ] `isConnected` stream - Always true (local)

### Query Translation
- [ ] `drift_query_translator.dart`
  - [ ] Implement QueryTranslator interface
  - [ ] Translate Query.where() to Drift Expression
  - [ ] Translate Query.orderBy() to OrderingTerm
  - [ ] Translate Query.limit() to limit()
  - [ ] Translate Query.offset() to offset()
  - [ ] Handle comparison operators
  - [ ] Handle IN operator with isIn()
  - [ ] Handle IS NULL with isNull()

### Backend Info
- [ ] `name` getter returns 'drift'
- [ ] `supportsOffline` returns true (local-only)
- [ ] `supportsRealtime` returns false (no remote sync)
- [ ] `supportsTransactions` returns true

### Generic Table Support
- [ ] Helper for mapping generic JSON to Drift Companions
- [ ] Helper for mapping Drift DataClass to JSON
- [ ] Consider TypeConverter usage

### Error Handling
- [ ] Map Drift/SQLite exceptions to StoreError types
- [ ] Handle constraint violations as ValidationError
- [ ] Handle database locked as TransactionError

### Unit Tests
- [ ] `test/drift_backend_test.dart`
  - [ ] Constructor validation
  - [ ] Lifecycle (initialize/close)
  - [ ] CRUD operations with in-memory database
  - [ ] Query translation correctness
  - [ ] Sync status (always synced)
  - [ ] Error mapping

### Integration Tests
- [ ] `test/integration/drift_integration_test.dart`
  - [ ] Real database operations
  - [ ] Watch stream emissions
  - [ ] Transaction behavior

## Files

**Package Structure:**
```
packages/nexus_store_drift_adapter/
├── lib/
│   ├── nexus_store_drift_adapter.dart    # Public exports
│   └── src/
│       ├── drift_backend.dart            # Main backend class
│       └── drift_query_translator.dart   # Query builder
├── test/
│   ├── drift_backend_test.dart           # Unit tests
│   ├── fixtures/
│   │   └── test_database.dart            # Test Drift database
│   └── integration/
│       └── drift_integration_test.dart   # Integration tests
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  drift: ^2.22.0

dev_dependencies:
  drift_dev: ^2.22.0
  build_runner: ^2.4.0
  test: ^1.25.0
  mocktail: ^1.0.4
```

## Dependencies

- Core package tests must pass first
- Drift documentation: https://drift.simonbinder.eu/
- Drift requires code generation (build_runner)

## Notes

- Drift is local-only - all sync operations are no-ops
- Use Drift's reactive queries with `.watch()` and `.watchSingle()`
- Consider using `.insertOnConflictUpdate()` for upserts
- Drift's type safety means query translation is more complex
- May need to accept table/column info at runtime for generic support
- Alternative: require users to provide specific table accessors
- In-memory database useful for testing: `NativeDatabase.memory()`
