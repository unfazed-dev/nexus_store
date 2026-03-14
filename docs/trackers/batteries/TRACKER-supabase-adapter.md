# TRACKER: Supabase Adapter Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_supabase_adapter` including type-safe column definitions, auth provider abstraction, table configuration, factory methods, multi-table manager, and RLS policy DSL.

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
- [x] Create `SupabaseColumn` class with factory methods
  - [x] `SupabaseColumn.text()`
  - [x] `SupabaseColumn.integer()`
  - [x] `SupabaseColumn.float8()`
  - [x] `SupabaseColumn.boolean()`
  - [x] `SupabaseColumn.timestamptz()`
  - [x] `SupabaseColumn.uuid()`
  - [x] `SupabaseColumn.jsonb()`
- [x] Create `SupabaseTableDefinition` class

### Phase 2: Auth Provider Pattern
- [x] Create abstract `SupabaseAuthProvider` interface
- [x] Create `DefaultSupabaseAuthProvider` implementation
- [x] Add `SupabaseAuthState` enum
- [x] Implement auth state stream

### Phase 3: Table Configuration
- [x] Create `SupabaseTableConfig<T, ID>` class
- [x] Add schema support (default: 'public')
- [x] Add realtime enable/disable flag
- [x] Add field mapping support

### Phase 4: Factory Method
- [x] Add `SupabaseBackend.withConfig()` factory
- [x] Auto-configure realtime subscriptions
- [x] Wire up auth provider
- [x] Handle lifecycle management

### Phase 5: Manager Class
- [x] Create `SupabaseManager` class
- [x] Implement `SupabaseManager.withClient()` factory
- [x] Implement `initialize()` method
- [x] Implement `getBackend<T, ID>(tableName)` method
- [x] Implement `subscribeAll()` / `unsubscribeAll()` methods
- [x] Implement `dispose()` method
- [x] Add shared realtime channel management

### Phase 6: RLS Policy DSL
- [x] Create `SupabaseRLSPolicy` class
  - [x] `SupabaseRLSPolicy.select()`
  - [x] `SupabaseRLSPolicy.insert()`
  - [x] `SupabaseRLSPolicy.update()`
  - [x] `SupabaseRLSPolicy.delete()`
- [x] Create `SupabaseRLSRules` class
- [x] Implement `toSql(tableName)` method

### Phase 7: Integration
- [x] Update barrel export
- [x] Add unit tests for column definitions (42 tests)
- [x] Add unit tests for auth provider (7 tests)
- [x] Add unit tests for RLS DSL (21 tests)
- [x] Add unit tests for manager (7 tests)
- [x] Update README with examples

## Files

### New Files
| File | Description |
|------|-------------|
| `lib/src/supabase_column.dart` | Type-safe column definitions |
| `lib/src/supabase_table_config.dart` | Table configuration bundling |
| `lib/src/supabase_auth_provider.dart` | Auth abstraction |
| `lib/src/supabase_manager.dart` | Multi-table coordination |
| `lib/src/supabase_rls.dart` | RLS policy DSL |

### Modified Files
| File | Changes |
|------|---------|
| `lib/src/supabase_backend.dart` | Add `withClient()` factory |
| `lib/nexus_store_supabase_adapter.dart` | Export new classes |
| `README.md` | Document batteries-included usage |

### Test Files
| File | Description |
|------|-------------|
| `test/unit/supabase_column_test.dart` | Column tests |
| `test/unit/supabase_auth_provider_test.dart` | Auth provider tests |
| `test/unit/supabase_rls_test.dart` | RLS DSL tests |
| `test/integration/supabase_manager_test.dart` | Manager tests |

## Dependencies

- supabase: ^2.0.0 (existing)

## API Design

```dart
// Column definitions
final columns = [
  SupabaseColumn.uuid('id'),
  SupabaseColumn.text('name'),
  SupabaseColumn.timestamptz('created_at'),
  SupabaseColumn.jsonb('metadata', nullable: true),
];

// Single table factory
final backend = SupabaseBackend<User, String>.withClient(
  client: Supabase.instance.client,
  tableName: 'users',
  columns: columns,
  getId: (u) => u.id,
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  enableRealtime: true,
);

// Multi-table manager
final manager = SupabaseManager.withClient(
  client: Supabase.instance.client,
  tables: [
    SupabaseTableConfig<User, String>(...),
    SupabaseTableConfig<Post, String>(...),
  ],
);

// RLS policy DSL
final rlsRules = SupabaseRLSRules([
  SupabaseRLSPolicy.select(
    name: 'users_select_own',
    using: 'auth.uid() = id',
  ),
  SupabaseRLSPolicy.insert(
    name: 'users_insert_own',
    withCheck: 'auth.uid() = id',
  ),
]);
print(rlsRules.toSql('users'));
```

## Notes

- Supabase has existing realtime infrastructure
- Auth provider pattern enables custom auth (e.g., custom JWT)
- RLS DSL generates PostgreSQL policy SQL

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Completed all 7 phases with 94 unit tests passing |
