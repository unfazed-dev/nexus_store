# TRACKER: Drift Backend Adapter

## Status: COMPLETE ✅

## Overview

Implement the Drift backend adapter for nexus_store, providing local-only SQLite storage with type-safe queries and code generation.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-010
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [x] Uncomment drift dependency in pubspec.yaml
- [x] Add drift_dev and build_runner to dev_dependencies
- [x] Create lib/src/ directory structure
- [x] Export public API from nexus_store_drift_adapter.dart

### Core Implementation
- [x] `drift_backend.dart`
  - [x] Implement StoreBackend<T, ID> interface
  - [x] Constructor accepting tableName, getId, fromJson, toJson, primaryKeyField
  - [x] Generic approach that works with any Drift table via raw SQL
  - [x] getId(T item) implementation
  - [x] fromJson(Map<String, dynamic>) implementation
  - [x] toJson(T item) implementation

### Lifecycle Management
- [x] `initialize()` - No-op (use initializeWithExecutor for database connection)
- [x] `initializeWithExecutor()` - Accept DatabaseConnectionUser for database operations
- [x] `close()` - Close database connection and clean up watchers
- [x] Handle database not initialized errors (throws StateError)

### Read Operations
- [x] `get(ID id)` - Single row select using customSelect
- [x] `getAll({Query? query})` - Multi-row select with filters
- [x] `watch(ID id)` - Watch single row with BehaviorSubject
- [x] `watchAll({Query? query})` - Watch table with BehaviorSubject

### Write Operations
- [x] `save(T item)` - INSERT OR REPLACE for upsert behavior
- [x] `saveAll(List<T> items)` - Batch insert with transaction
- [x] `delete(ID id)` - Delete by ID using customUpdate
- [x] `deleteAll(List<ID> ids)` - Batch delete with transaction
- [x] `deleteWhere(Query query)` - Conditional delete

### Sync Operations (Local-Only Stubs)
- [x] `syncStatus` getter - Always returns SyncStatus.synced
- [x] `syncStatusStream` - Emits single SyncStatus.synced via BehaviorSubject
- [x] `sync()` - No-op, completes immediately
- [x] `pendingChangesCount` getter - Always returns 0

### Query Translation
- [x] `drift_query_translator.dart`
  - [x] Implement QueryTranslator interface
  - [x] Translate Query.where() to SQL WHERE clauses
  - [x] Translate Query.orderBy() to ORDER BY clauses
  - [x] Translate Query.limit() to LIMIT clause
  - [x] Translate Query.offset() to OFFSET clause
  - [x] Handle comparison operators (=, !=, <, <=, >, >=)
  - [x] Handle IN operator with parameterized placeholders
  - [x] Handle IS NULL / IS NOT NULL
  - [x] Handle LIKE operators (contains, startsWith, endsWith)
  - [x] Handle arrayContainsAny with json_each()

### Backend Info
- [x] `name` getter returns 'drift'
- [x] `supportsOffline` returns true (local-only)
- [x] `supportsRealtime` returns false (no remote sync)
- [x] `supportsTransactions` returns true

### Generic Table Support
- [x] Generic JSON to row mapping via toJson/fromJson callbacks
- [x] Field mapping support for column name translation

### Error Handling
- [x] Map Drift/SQLite exceptions to StoreError types
- [x] Handle constraint violations as ValidationError
- [x] Handle database locked as TransactionError
- [x] Handle missing table as StateError

### Unit Tests
- [x] `test/drift_backend_test.dart` (18 tests)
  - [x] Constructor validation
  - [x] Lifecycle (initialize/close)
  - [x] Sync status (always synced)
  - [x] Error mapping (StateError before initialize)
- [x] `test/drift_query_translator_test.dart` (34 tests)
  - [x] Query translation correctness
  - [x] All filter operators
  - [x] OrderBy translation
  - [x] Pagination (limit/offset)
  - [x] Field mapping
  - [x] DELETE SQL generation

### Integration Tests
- [x] `test/integration/drift_integration_test.dart` (30 tests)
  - [x] Real database operations with in-memory SQLite
  - [x] Watch stream emissions
  - [x] Transaction behavior

## Files

**Package Structure:**
```
packages/nexus_store_drift_adapter/
├── lib/
│   ├── nexus_store_drift_adapter.dart      # Public exports
│   └── src/
│       ├── drift_backend.dart              # Main backend class
│       └── drift_query_translator.dart     # Query translator
├── test/
│   ├── drift_backend_test.dart             # Unit tests (18)
│   ├── drift_query_translator_test.dart    # Unit tests (34)
│   └── integration/
│       └── drift_integration_test.dart     # Integration tests (30)
└── pubspec.yaml
```

**Total Tests: 82** (52 unit + 30 integration)

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
