# TRACKER: Brick Backend Adapter

## Status: COMPLETE

## Overview

Implement the Brick backend adapter for nexus_store, integrating with Brick's offline-first repository pattern and code generation capabilities.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-008
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [x] Uncomment brick_offline_first_with_supabase dependency in pubspec.yaml
- [x] Add brick_offline_first to dependencies
- [x] Add brick_core to dependencies
- [x] Create lib/src/ directory structure
- [x] Export public API from nexus_store_brick_adapter.dart

### Core Implementation
- [x] `brick_backend.dart`
  - [x] Implement StoreBackend<T, ID> interface
  - [x] Constructor accepting Repository, getId callback, primaryKeyField
  - [x] Generic factory pattern for flexible model support
  - [x] Handle Brick's model-to-adapter mapping

### Lifecycle Management
- [x] `initialize()` - Initialize repository if not already
- [x] `close()` - Properly dispose repository and streams
- [x] Handle repository initialization state

### Read Operations
- [x] `get(ID id)` - Repository.get() with Query.where primaryKey
- [x] `getAll({Query? query})` - Repository.get() with translated query
- [x] `watch(ID id)` - BehaviorSubject with initial load
- [x] `watchAll({Query? query})` - BehaviorSubject with initial load

### Write Operations
- [x] `save(T item)` - Repository.upsert()
- [x] `saveAll(List<T> items)` - Batch upsert
- [x] `delete(ID id)` - Repository.delete()
- [x] `deleteAll(List<ID> ids)` - Batch delete
- [x] `deleteWhere(Query query)` - Conditional delete

### Sync Operations
- [x] `syncStatus` getter - Map from repository sync status
- [x] `syncStatusStream` - BehaviorSubject for sync events
- [x] `sync()` - Trigger repository sync
- [x] `pendingChangesCount` getter - Based on sync status

### Query Translation
- [x] `brick_query_translator.dart`
  - [x] Implement QueryTranslator interface
  - [x] Translate Query.where() to Brick Where clause
  - [x] Compare.exact for equality
  - [x] Compare.greaterThan for >
  - [x] Compare.lessThan for <
  - [x] Compare.greaterThanOrEqualTo for >=
  - [x] Compare.lessThanOrEqualTo for <=
  - [x] Compare.inIterable for IN
  - [x] Compare.contains for array/string contains
  - [x] Translate Query.orderBy() to Brick orderBy
  - [x] Translate Query.limit() to Brick limit
  - [x] Translate Query.offset() to Brick offset
  - [x] Field name mapping support

### Backend Info
- [x] `name` getter returns 'brick'
- [x] `supportsOffline` returns true
- [x] `supportsRealtime` returns true (via subscriptions)
- [x] `supportsTransactions` returns true

### Error Handling
- [x] Map Brick exceptions to StoreError types
- [x] Handle sync errors as SyncError
- [x] Handle network errors as NetworkError
- [x] Handle timeout errors as TimeoutError
- [x] Handle conflict errors as ConflictError
- [x] Handle state errors (not initialized)

### Unit Tests
- [x] `test/brick_backend_test.dart`
  - [x] Constructor validation
  - [x] Lifecycle (initialize/close)
  - [x] CRUD operations with mocked repository
  - [x] Sync status mapping
  - [x] Error mapping
- [x] `test/brick_query_translator_test.dart`
  - [x] Filter operator translation
  - [x] OrderBy translation
  - [x] Limit/offset translation
  - [x] Field mapping

## Files

**Package Structure:**
```
packages/nexus_store_brick_adapter/
├── lib/
│   ├── nexus_store_brick_adapter.dart    # Public exports
│   └── src/
│       ├── brick_backend.dart            # Main backend class
│       └── brick_query_translator.dart   # Brick Query builder
├── test/
│   ├── brick_backend_test.dart           # Unit tests (27 tests)
│   └── brick_query_translator_test.dart  # Query tests (24 tests)
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  brick_offline_first_with_supabase: ^2.1.0
  brick_offline_first: ^4.0.0
  brick_core: ^2.0.0
  rxdart: ^0.28.0

dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.4
  lints: ^5.1.0
```

## Test Results

- Total tests: 51
- All tests passing

## Completion Summary

The Brick backend adapter has been fully implemented with:

1. **BrickBackend<T, ID>** - Full StoreBackend implementation supporting:
   - Generic factory pattern (T extends OfflineFirstModel)
   - All CRUD operations via Brick repository
   - Watch streams using BehaviorSubject
   - Sync status tracking
   - Proper error mapping

2. **BrickQueryTranslator<T>** - Complete query translation:
   - All filter operators mapped to Brick Compare enum
   - OrderBy, limit, offset support
   - Optional field name mapping

3. **Comprehensive test coverage** - 51 unit tests covering:
   - Backend info, lifecycle, read/write/sync operations
   - Error handling and state management
   - Query translation for all operators

## Notes

- Brick uses its own Query class - translation layer handles conversion
- Brick models must extend OfflineFirstModel
- Brick handles offline queue automatically
- BehaviorSubject used for immediate value emission on watch streams
- Sync status managed via internal BehaviorSubject
