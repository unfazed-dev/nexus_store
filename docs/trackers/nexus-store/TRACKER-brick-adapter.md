# TRACKER: Brick Backend Adapter

## Status: PENDING

## Overview

Implement the Brick backend adapter for nexus_store, integrating with Brick's offline-first repository pattern and code generation capabilities.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-008
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Uncomment brick_offline_first_with_supabase dependency in pubspec.yaml
- [ ] Add brick_build to dev_dependencies
- [ ] Create lib/src/ directory structure
- [ ] Export public API from nexus_store_brick_adapter.dart

### Core Implementation
- [ ] `brick_backend.dart`
  - [ ] Implement StoreBackend<T, ID> interface
  - [ ] Constructor accepting Repository, Model type info
  - [ ] getId(T item) implementation (via Brick model primaryKey)
  - [ ] fromJson(Map<String, dynamic>) implementation
  - [ ] toJson(T item) implementation
  - [ ] Handle Brick's model-to-adapter mapping

### Lifecycle Management
- [ ] `initialize()` - Initialize repository if not already
- [ ] `close()` - Properly dispose repository
- [ ] Handle repository initialization state

### Read Operations
- [ ] `get(ID id)` - Repository.get() with Query.where primaryKey
- [ ] `getAll({Query? query})` - Repository.get() with translated query
- [ ] `watch(ID id)` - Stream from repository subscriptions
- [ ] `watchAll({Query? query})` - Repository.subscribe()

### Write Operations
- [ ] `save(T item)` - Repository.upsert()
- [ ] `saveAll(List<T> items)` - Batch upsert with transaction
- [ ] `delete(ID id)` - Repository.delete()
- [ ] `deleteAll(List<ID> ids)` - Batch delete
- [ ] `deleteWhere(Query query)` - Conditional delete

### Sync Operations
- [ ] `syncStatus` getter - Map from repository sync status
- [ ] `syncStatusStream` - Repository sync events
- [ ] `sync()` - Trigger repository sync
- [ ] `pendingChangesCount` getter - From offline queue
- [ ] `isConnected` stream - Network connectivity

### Query Translation
- [ ] `brick_query_translator.dart`
  - [ ] Implement QueryTranslator interface
  - [ ] Translate Query.where() to Brick Where clause
  - [ ] Where.exact() for equality
  - [ ] Compare.greaterThan for >
  - [ ] Compare.lessThan for <
  - [ ] Compare.greaterThanOrEqualTo for >=
  - [ ] Compare.lessThanOrEqualTo for <=
  - [ ] Where.contains() for IN
  - [ ] Translate Query.orderBy() to Brick orderBy
  - [ ] Translate Query.limit() to Brick limit
  - [ ] Translate Query.offset() to Brick offset

### Backend Info
- [ ] `name` getter returns 'brick'
- [ ] `supportsOffline` returns true
- [ ] `supportsRealtime` returns true (via subscriptions)
- [ ] `supportsTransactions` returns true

### Model Integration
- [ ] Helper for generic Brick model access
- [ ] Support for OfflineFirstWithSupabaseModel
- [ ] Support for OfflineFirstModel
- [ ] Consider adapter factory pattern

### Error Handling
- [ ] Map Brick exceptions to StoreError types
- [ ] Handle sync errors as SyncError
- [ ] Handle network errors as NetworkError
- [ ] Handle validation errors as ValidationError

### Unit Tests
- [ ] `test/brick_backend_test.dart`
  - [ ] Constructor validation
  - [ ] Lifecycle (initialize/close)
  - [ ] CRUD operations with mocked repository
  - [ ] Query translation correctness
  - [ ] Sync status mapping
  - [ ] Error mapping

### Integration Tests
- [ ] `test/integration/brick_integration_test.dart`
  - [ ] Real repository operations
  - [ ] Offline queue behavior
  - [ ] Sync with mock backend

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
│   ├── brick_backend_test.dart           # Unit tests
│   └── integration/
│       └── brick_integration_test.dart   # Integration tests
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  brick_offline_first_with_supabase: ^2.1.0

dev_dependencies:
  brick_build: ^3.0.0
  build_runner: ^2.4.0
  test: ^1.25.0
  mocktail: ^1.0.4
```

## Dependencies

- Core package tests must pass first
- Brick documentation: https://getdutchie.github.io/brick/
- Brick requires code generation for models

## Notes

- Brick uses its own Query class - translation needed
- Brick models extend OfflineFirstModel or OfflineFirstWithSupabaseModel
- Brick handles offline queue automatically
- Consider whether to expose Brick's Query directly or translate
- Brick's subscribe() provides stream updates
- Repository patterns: OfflineFirstWithSupabaseRepository
- May need to require Brick model type at construction time
- Consider using Brick's built-in JSON serialization
