# TRACKER: Supabase Backend Adapter

## Status: PENDING

## Overview

Implement the Supabase backend adapter for nexus_store, providing direct Supabase API access with Realtime subscriptions for online-only applications.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-009
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Uncomment supabase dependency in pubspec.yaml
- [ ] Create lib/src/ directory structure
- [ ] Export public API from nexus_store_supabase_adapter.dart

### Core Implementation
- [ ] `supabase_backend.dart`
  - [ ] Implement StoreBackend<T, ID> interface
  - [ ] Constructor accepting SupabaseClient, tableName, serializers
  - [ ] getId(T item) implementation
  - [ ] fromJson(Map<String, dynamic>) implementation
  - [ ] toJson(T item) implementation
  - [ ] Configure primary key column name (default: 'id')

### Lifecycle Management
- [ ] `initialize()` - Verify Supabase connection
- [ ] `close()` - Unsubscribe from Realtime channels
- [ ] Handle connection state changes

### Read Operations
- [ ] `get(ID id)` - Single row with `.eq('id', id).single()`
- [ ] `getAll({Query? query})` - Multi-row with filters
- [ ] `watch(ID id)` - Realtime subscription for single row
- [ ] `watchAll({Query? query})` - Realtime subscription for table

### Write Operations
- [ ] `save(T item)` - Upsert with `.upsert()`
- [ ] `saveAll(List<T> items)` - Batch upsert
- [ ] `delete(ID id)` - Delete with `.delete().eq('id', id)`
- [ ] `deleteAll(List<ID> ids)` - Batch delete with `.in_('id', ids)`
- [ ] `deleteWhere(Query query)` - Conditional delete

### Sync Operations (Online-Only)
- [ ] `syncStatus` getter - Always returns SyncStatus.synced
- [ ] `syncStatusStream` - Emits single SyncStatus.synced
- [ ] `sync()` - No-op (always online)
- [ ] `pendingChangesCount` getter - Always returns 0
- [ ] `isConnected` stream - Based on Realtime connection state

### Realtime Subscriptions
- [ ] `supabase_realtime_manager.dart`
  - [ ] Manage channel subscriptions
  - [ ] Handle INSERT events
  - [ ] Handle UPDATE events
  - [ ] Handle DELETE events
  - [ ] Convert Realtime payloads to entity type
  - [ ] Broadcast to BehaviorSubject streams
  - [ ] Handle subscription errors
  - [ ] Cleanup on dispose

### Query Translation
- [ ] `supabase_query_translator.dart`
  - [ ] Implement QueryTranslator interface
  - [ ] Translate Query.where() to PostgREST filters
  - [ ] `.eq()` for equality
  - [ ] `.neq()` for not equals
  - [ ] `.gt()` for greater than
  - [ ] `.gte()` for greater than or equal
  - [ ] `.lt()` for less than
  - [ ] `.lte()` for less than or equal
  - [ ] `.in_()` for IN operator
  - [ ] `.is_()` for IS NULL
  - [ ] Translate Query.orderBy() to `.order()`
  - [ ] Translate Query.limit() to `.limit()`
  - [ ] Translate Query.offset() to `.range()`

### Backend Info
- [ ] `name` getter returns 'supabase'
- [ ] `supportsOffline` returns false (online-only)
- [ ] `supportsRealtime` returns true
- [ ] `supportsTransactions` returns false (via API)

### Error Handling
- [ ] Map Supabase exceptions to StoreError types
- [ ] Handle PostgrestException as appropriate type
- [ ] Handle network errors as NetworkError
- [ ] Handle auth errors as AuthenticationError
- [ ] Handle RLS errors as AuthorizationError
- [ ] Handle unique constraint as ValidationError

### Unit Tests
- [ ] `test/supabase_backend_test.dart`
  - [ ] Constructor validation
  - [ ] Lifecycle (initialize/close)
  - [ ] CRUD operations with mocked client
  - [ ] Query translation correctness
  - [ ] Realtime subscription management
  - [ ] Error mapping

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
│   ├── supabase_backend_test.dart           # Unit tests
│   └── integration/
│       └── supabase_integration_test.dart   # Integration tests
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  nexus_store:
    path: ../nexus_store
  supabase: ^2.8.0

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
- Consider connection pooling for high-frequency operations
- RLS (Row Level Security) errors map to AuthorizationError
- `.upsert()` handles both insert and update
- Realtime requires specific table configuration in Supabase
- Consider adding `.select()` optimization for partial fetches
