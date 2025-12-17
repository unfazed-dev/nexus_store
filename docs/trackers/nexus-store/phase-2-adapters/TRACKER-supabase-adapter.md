# TRACKER: Supabase Backend Adapter

## Status: COMPLETED

## Overview

Implement the Supabase backend adapter for nexus_store, providing direct Supabase API access with Realtime subscriptions for online-only applications.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-009
**Parent Tracker**: [TRACKER-nexus-store-main.md](../TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [x] Uncomment supabase dependency in pubspec.yaml
- [x] Create lib/src/ directory structure
- [x] Export public API from nexus_store_supabase_adapter.dart

### Core Implementation
- [x] `supabase_backend.dart`
  - [x] Implement StoreBackend<T, ID> interface
  - [x] Constructor accepting SupabaseClient, tableName, serializers
  - [x] getId(T item) implementation
  - [x] fromJson(Map<String, dynamic>) implementation
  - [x] toJson(T item) implementation
  - [x] Configure primary key column name (default: 'id')

### Lifecycle Management
- [x] `initialize()` - Verify Supabase connection
- [x] `close()` - Unsubscribe from Realtime channels
- [x] Handle connection state changes

### Read Operations
- [x] `get(ID id)` - Single row with `.eq('id', id).maybeSingle()`
- [x] `getAll({Query? query})` - Multi-row with filters
- [x] `watch(ID id)` - Realtime subscription for single row
- [x] `watchAll({Query? query})` - Realtime subscription for table

### Write Operations
- [x] `save(T item)` - Upsert with `.upsert()`
- [x] `saveAll(List<T> items)` - Batch upsert
- [x] `delete(ID id)` - Delete with `.delete().eq('id', id)`
- [x] `deleteAll(List<ID> ids)` - Batch delete with `.inFilter('id', ids)`
- [x] `deleteWhere(Query query)` - Conditional delete

### Sync Operations (Online-Only)
- [x] `syncStatus` getter - Always returns SyncStatus.synced
- [x] `syncStatusStream` - Emits single SyncStatus.synced
- [x] `sync()` - No-op (always online)
- [x] `pendingChangesCount` getter - Always returns 0

### Realtime Subscriptions
- [x] `supabase_realtime_manager.dart`
  - [x] Manage channel subscriptions
  - [x] Handle INSERT events
  - [x] Handle UPDATE events
  - [x] Handle DELETE events
  - [x] Convert Realtime payloads to entity type
  - [x] Broadcast to BehaviorSubject streams
  - [x] Handle subscription errors
  - [x] Cleanup on dispose

### Query Translation
- [x] `supabase_query_translator.dart`
  - [x] Implement QueryTranslator interface
  - [x] Translate Query.where() to PostgREST filters
  - [x] `.eq()` for equality
  - [x] `.neq()` for not equals
  - [x] `.gt()` for greater than
  - [x] `.gte()` for greater than or equal
  - [x] `.lt()` for less than
  - [x] `.lte()` for less than or equal
  - [x] `.inFilter()` for IN operator
  - [x] `.isFilter()` for IS NULL
  - [x] Translate Query.orderBy() to `.order()`
  - [x] Translate Query.limit() to `.range()`
  - [x] Translate Query.offset() to `.range()`

### Backend Info
- [x] `name` getter returns 'supabase'
- [x] `supportsOffline` returns false (online-only)
- [x] `supportsRealtime` returns true
- [x] `supportsTransactions` returns false (via API)

### Error Handling
- [x] Map Supabase exceptions to StoreError types
- [x] Handle PostgrestException as appropriate type
- [x] Handle network errors as NetworkError
- [x] Handle auth errors as AuthenticationError
- [x] Handle RLS errors as AuthorizationError
- [x] Handle unique constraint as ValidationError

### Unit Tests
- [x] `test/supabase_backend_test.dart`
  - [x] Constructor validation
  - [x] Lifecycle (initialize/close)
  - [x] State checks for uninitialized backend
  - [x] Query translation correctness
  - [x] Error mapping verification
- [x] `test/supabase_query_translator_test.dart`
  - [x] All filter operators coverage
  - [x] Query building verification
  - [x] Field mapping support

### Integration Tests
- [ ] `test/integration/supabase_integration_test.dart`
  - [ ] Real Supabase operations (requires test project)
  - [ ] Realtime event handling
  - [ ] Query filter combinations

## Files

**Package Structure:**
```
packages/nexus_store_supabase_adapter/
├── lib/
│   ├── nexus_store_supabase_adapter.dart    # Public exports
│   └── src/
│       ├── supabase_backend.dart            # Main backend class
│       ├── supabase_query_translator.dart   # PostgREST query builder
│       └── supabase_realtime_manager.dart   # Realtime subscriptions
├── test/
│   ├── supabase_backend_test.dart           # Unit tests (30 tests)
│   └── supabase_query_translator_test.dart  # Translator tests (29 tests)
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  supabase: ^2.8.0
  rxdart: ^0.28.0

dev_dependencies:
  test: ^1.25.0
  mocktail: ^1.0.4
```

## Dependencies

- Core package tests must pass first
- Supabase documentation: https://supabase.com/docs
- Supabase Dart client: https://github.com/supabase/supabase-dart

## Notes

- Supabase is online-only - no offline queue
- Use Supabase Realtime for watch operations
- PostgREST query syntax differs from SQL
- RLS (Row Level Security) errors map to AuthorizationError
- `.upsert()` handles both insert and update
- Realtime requires specific table configuration in Supabase
- 59 total unit tests passing

## Completion Summary

The Supabase backend adapter is fully implemented with:
- Complete `StoreBackend<T, ID>` interface implementation
- PostgREST query translation for all filter operators
- Realtime subscription management via `SupabaseRealtimeManager`
- Comprehensive error mapping from Supabase exceptions to `StoreError` types
- 59 unit tests covering translator and backend functionality
