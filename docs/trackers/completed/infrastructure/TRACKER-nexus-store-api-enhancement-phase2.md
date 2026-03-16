# TRACKER: NexusStore API Enhancement Phase 2

## Status: COMPLETE

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| A1. `getOne()` / `findBy()` | ✅ Complete | 20 | ✅ 100.0% (15/15) | f547fdc | 2026-03-16 |
| A2. Query Scopes (Soft-Delete, Owner) | ✅ Complete | 22 | ✅ 100.0% (8/8) | d3c9198 | 2026-03-16 |
| A3. Case-Insensitive Search | ✅ Complete | 14 | ✅ 100.0% (25/25) | a57dc06 | 2026-03-16 |
| A4. Mutation Lifecycle Hooks | ✅ Complete | 22 | ✅ 100.0% (19/19) | 7f2f748 | 2026-03-16 |
| A5. Background Refetch Manager | ✅ Complete | 16 | ✅ 95.2% (40/42) | 03d4861 | 2026-03-16 |
| B1. Firefly Repo Migration (Phase 2) | ✅ Complete | — | — (no lib/ changes) | 904d904 | 2026-03-16 |
| C1. Cross-Adapter Composition Tests | ✅ Complete | 21 | — (no lib/ changes) | 88fbf2f | 2026-03-16 |
| C2. Brick Adapter Test Parity | ✅ Complete | 23 | — (no lib/ changes) | 5a3ccdd | 2026-03-16 |
| C3. Architecture Invariant Validators | ✅ Complete | 3 self-tests | — (no lib/ changes) | 352774f | 2026-03-16 |

**Overall:** ████████████████ 100% complete (9/9 phases done)
**Tests:** 138 passing + 3 invariant self-tests | 141 total (target: ~167)

### Progress Log

**Current State (2026-03-16):**
- Working on: COMPLETE (Phase B1)
- Last completed: Phase B1 — Firefly repository migration
- Next up: N/A — all 9 phases complete

**Phase B1 Results (2026-03-16):**
- Migrated 4 of 5 Firefly repositories to use Phase 2 NexusStore APIs
- `settings_repository.dart`: `getAll()+filter` → `findBy()`, `watchAll().map()` → `watchOne()`
- `app_settings_repository.dart`: `getAll()+filter` → `findBy()`, `watchAll().map()` → `watchOne()`
- `journal_repository.dart`: Created `ScopedStore` with `SoftDeleteScope` — eliminated 9x `.where('deleted_at', isNull: true)`. Replaced manual soft-delete with `softDelete()`. Replaced `getAll()` + in-memory search with `iContains` queries
- `complaint_repository.dart`: Replaced `getAll()` + in-memory search with `iContains` queries (subject + description OR logic via dual query + merge)
- `profile_repository.dart`: No migration needed — `getManagers()` uses role-based queries, not sequential `.get(id)` calls as originally estimated
- All 5 files pass `dart analyze` with no issues
- No lib/ changes in nexus_store packages (consumer-side migration only)

### Decisions
- A5: RefetchConfig passed as standalone class instead of embedding in freezed StoreConfig (avoids build_runner regeneration)
- A4: mutateDelete skips onSuccess callback since delete returns bool, not entity T
- C2: Skipped — brick adapter already has 2726 lines of tests across 6 files, well beyond the 11-test parity target

## Overview

Phase 1 (17 phases, 446 tests) completed all planned NexusStore API enhancements. Analysis of Firefly's 110 repositories reveals real consumer pain points — anti-patterns caused by (a) APIs added but repos not yet migrated, or (b) genuinely missing capabilities forcing workarounds. Web research on TanStack Query, WatermelonDB, and modern data layer patterns identifies ergonomic gaps in mutation lifecycle and query scoping.

**Package location:** `packages/` (Melos monorepo)

**Sub-packages affected:**
- `nexus_store` — Core library (primary target for A1-A5)
- `nexus_store_powersync_adapter` — PowerSync backend (A3: case-insensitive SQL)
- `nexus_store_drift_adapter` — Drift backend (A3: case-insensitive SQL)
- `nexus_store_brick_adapter` — Brick backend (C2: test parity)

## Dependency Graph

```
A1, A2, A3, A5, C1, C2, C3 — can start independently

A4 (mutation hooks)         depends on: A1
B1 (Firefly migration)      depends on: A1, A2, A3
```

## Priority Summary

| Priority | Phases | Est. Tests |
|----------|--------|------------|
| **Highest** | A1 (getOne/findBy), A3 (case-insensitive search) | ~33 |
| **High** | A2 (query scopes), A4 (mutation hooks) | ~47 |
| **Medium** | A5 (background refetch), B1 (Firefly migration) | ~30 |
| **Lower** | C1 (composition tests), C2 (brick tests), C3 (invariants) | ~57 |
| **Total** | 9 phases | ~167 |

## Skills & Agents by Phase

| Phase | Skills | Agents |
|-------|--------|--------|
| A1-A5 | `/nexus-store` | `arch-check`, `test-scaffold` |
| B1 | `/nexus-store` | `arch-check`, `prior-art` |
| C1-C2 | `/nexus-store` | `test-scaffold` |
| C3 | — | `arch-check` |
| **Every phase end** | `/commit-helper` | `verify-packages` |

## Verification

```bash
# Per-phase verification
cd packages/nexus_store && dart test
cd packages/nexus_store_powersync_adapter && dart test
cd packages/nexus_store_drift_adapter && dart test

# Pre-commit harness
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true

# Firefly tests (Phase B1 only)
python3 .claude/hooks/core/smart-test-run.py

# Full suite
melos run test:dart && melos run analyze
```

---

## Phase A1: `getOne()` / `findBy()` Convenience Methods (Highest Priority)

**Why:** 5+ Firefly repos do `getAll(query:).then((l) => l.first)` to find a single entity by a unique field. `watchOne()` exists (Phase 1, Phase 12) but there's no `getOne()` equivalent for one-shot reads.

**Dependencies:** None — can start immediately.

### Pre-Implementation Checklist
- [x] Read `nexus_store.dart` — existing `getAll()`, `watchOne()`, `count()` patterns
- [x] Read `store_operation.dart` — StoreOperation enum, extension methods
- [x] Read `operation_metric.dart` — OperationType enum
- [x] Read `timing_interceptor.dart` — operation mapping

### Tasks
#### RED: Write Failing Tests (~18)
- [x] getOne returns first match
- [x] getOne returns null when no match
- [x] getOne applies limitTo(1) optimization
- [x] getOne respects fetch policy
- [x] getOne fires interceptor chain
- [x] getOne throws before init (`StateError`)
- [x] getOne with query filters
- [x] getOne with empty store
- [x] findBy with string value
- [x] findBy with int value
- [x] findBy with bool value
- [x] findBy returns null when no match
- [x] findBy delegates to getOne internally
- [x] StoreOperation.getOne enum value exists
- [x] StoreOperation.getOne.isRead is true
- [x] OperationType.getOne exists
- [x] TimingInterceptor maps getOne
- [x] Verify all tests FAIL then PASS

#### GREEN: Implement
1. [x] Add `StoreOperation.getOne` enum value, update `isRead` extension
2. [x] Add `OperationType.getOne` for telemetry
3. [x] Add `Future<T?> getOne({Query<T>? query, FetchPolicy? policy})` to `NexusStore`
4. [x] Add `Future<T?> findBy(String field, Object value, {FetchPolicy? policy})` to `NexusStore`
5. [x] Wire through interceptor chain and `_trackOperation`
6. [x] Update `TimingInterceptor._mapOperation` switch
7. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, existing tests still pass

### Acceptance Criteria
- [x] `store.getOne(query: Query<T>().where('key', isEqualTo: 'theme'))` returns single entity
- [x] `store.findBy('email', 'user@example.com')` returns entity by unique field
- [x] Interceptor chain processes `StoreOperation.getOne`
- [x] Telemetry tracks `OperationType.getOne`
- [x] limitTo(1) optimization applied automatically

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 20
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage >= 95%: ✅ 100.0% (15/15 lines) — nexus_store.dart 15/15 100%
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/lib/src/core/nexus_store.dart` — added getOne, findBy methods
- `packages/nexus_store/lib/src/interceptors/store_operation.dart` — added getOne enum value
- `packages/nexus_store/lib/src/telemetry/operation_metric.dart` — added OperationType.getOne
- `packages/nexus_store/lib/src/interceptors/timing_interceptor.dart` — updated mapping
- `packages/nexus_store/test/src/core/get_one_find_by_test.dart` — new test file
- `packages/nexus_store/test/src/interceptors/store_operation_test.dart` — updated count

---

## Phase A2: Query Scopes — Soft-Delete, Owner Filtering (High Priority)

**Why:** `journal_repository.dart` has `.where('deleted_at', isNull: true)` repeated 11+ times. Every query method must remember to exclude soft-deleted records — error-prone and verbose.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `query.dart` — existing Query builder, filter composition
- [x] Read `nexus_store.dart` — public API, read/write method signatures

### Tasks
#### RED: Write Failing Tests (~25)
- [x] SoftDeleteScope appends filter to empty query
- [x] SoftDeleteScope preserves existing filters
- [x] SoftDeleteScope works with OR groups
- [x] SoftDeleteScope custom field name
- [x] OwnerScope appends owner filter
- [x] OwnerScope combines with SoftDeleteScope
- [x] ScopedStore getAll excludes soft-deleted
- [x] ScopedStore watchAll applies scope
- [x] ScopedStore count applies scope
- [x] ScopedStore getOne applies scope
- [x] ScopedStore existsWhere applies scope
- [x] ScopedStore deleteWhere applies scope
- [x] ScopedStore updateWhere applies scope
- [x] ScopedStore save passes through unmodified
- [x] ScopedStore delete passes through unmodified
- [x] ScopedStore upsert passes through unmodified
- [x] softDelete patches entity with timestamp
- [x] softDelete on non-existent entity returns null
- [x] Combined scopes applied in order
- [x] Scoped store with empty scope list behaves like original
- [x] QueryScope equality/hashCode
- [x] Verify all tests PASS

#### GREEN: Implement
1. [x] Create `QueryScope` abstract class with `Query<T> apply(Query<T> query)` method
2. [x] Create `SoftDeleteScope` — appends `.where(field, isNull: true)` to queries
3. [x] Create `OwnerScope` — appends `.where(field, isEqualTo: ownerId)` to queries
4. [x] Create `ScopedStore<T, ID>` proxy — delegates to underlying store with scope-applied queries
5. [x] Add `NexusStore.scoped(List<QueryScope> scopes)` factory returning ScopedStore
6. [x] Add `NexusStore.softDelete(ID id, {String field = 'deleted_at'})` — delegates to `patch()`
7. [x] Export via barrel file
8. [x] Verify all tests PASS

### Acceptance Criteria
- [x] `store.scoped([SoftDeleteScope()])` returns proxy that auto-filters deleted records
- [x] Write operations pass through without scope modification
- [x] `store.softDelete(id)` patches deleted_at field via existing `patch()` method
- [x] Multiple scopes compose correctly

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 22
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage >= 95%: ✅ 100.0% (8/8 lines) — nexus_store.dart 8/8 100%
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/lib/src/query/query_scope.dart` — new: QueryScope, SoftDeleteScope, OwnerScope
- `packages/nexus_store/lib/src/core/scoped_store.dart` — new: ScopedStore proxy
- `packages/nexus_store/lib/src/core/nexus_store.dart` — added `scoped()` and `softDelete()`
- `packages/nexus_store/lib/nexus_store.dart` — barrel exports
- `packages/nexus_store/test/src/query/query_scope_test.dart` — new test file

---

## Phase A3: Case-Insensitive Text Search (Highest Priority)

**Why:** `journal_repository.dart:185-218` and `complaint_repository.dart:216-241` do `getAll()` then `.toLowerCase().contains()` in-memory because `Query.where(contains:)` is case-sensitive.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `query.dart` — existing `where()` method, `QueryFilter` creation, `FilterOperator` enum
- [x] Read `query_evaluator.dart` — in-memory filter matching
- [x] Read `powersync_query_translator.dart` — existing LIKE translation
- [x] Read `drift_query_translator.dart` — same pattern

### Tasks
#### RED: Write Failing Tests (~15)
- [x] Query builder creates correct filter for `iContains`
- [x] Query builder creates correct filter for `iStartsWith`
- [x] Query builder creates correct filter for `iEndsWith`
- [x] In-memory evaluator: `iContains: 'hello'` matches "Hello World"
- [x] In-memory evaluator: `iStartsWith: 'HELLO'` matches "hello world"
- [x] In-memory evaluator: `iEndsWith: 'WORLD'` matches "hello World"
- [x] In-memory evaluator: no match returns false
- [x] Combined with case-sensitive filters (AND composition)
- [x] Query equality/hashCode with new operators
- [x] Query toString includes new operators
- [x] FilterOperator enum values exist (3 tests)
- [x] End-to-end with NexusStore
- [x] Verify all tests PASS

#### GREEN: Implement
1. [x] Add `FilterOperator.iContains`, `FilterOperator.iStartsWith`, `FilterOperator.iEndsWith` to enum
2. [x] Add `String? iContains`, `String? iStartsWith`, `String? iEndsWith` named params to `Query.where()`
3. [x] Update `InMemoryQueryEvaluator` to handle case-insensitive ops (`.toLowerCase()` on both sides)
4. [x] Update `PowerSyncQueryTranslator` — `LOWER(field) LIKE LOWER('%value%')` pattern
5. [x] Update `DriftQueryTranslator` — same LOWER() pattern
6. [x] Update `SqlQueryTranslatorMixin.operatorToSql` — new enum values
7. [x] Update `expression.dart` `_invertOperator` — throw UnsupportedError for new ops
8. [x] Update `FakeStoreBackend._matchesFilter` — case-insensitive matching
9. [x] Verify all tests PASS

### Acceptance Criteria
- [x] `Query<T>().where('title', iContains: 'hello')` matches "Hello World"
- [x] SQL uses `LOWER()` for case-insensitive matching
- [x] Existing case-sensitive operators unaffected

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 14
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean for `nexus_store`, `nexus_store_powersync_adapter`, `nexus_store_drift_adapter`
- [x] Delta coverage >= 95%: ✅ 100.0% (25/25 lines) — query_evaluator.dart 5/5 100%, expression.dart 4/4 100%, query.dart 16/16 100%
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/lib/src/query/query.dart` — added 3 named params + 3 FilterOperator values
- `packages/nexus_store/lib/src/cache/query_evaluator.dart` — in-memory case-insensitive evaluation
- `packages/nexus_store/lib/src/query/query_translator.dart` — updated operatorToSql mixin
- `packages/nexus_store/lib/src/query/expression.dart` — updated _invertOperator
- `packages/nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart` — LOWER() SQL helpers
- `packages/nexus_store_drift_adapter/lib/src/drift_query_translator.dart` — LOWER() SQL helpers
- `packages/nexus_store_brick_adapter/lib/src/brick_query_translator.dart` — iContains/iStartsWith/iEndsWith cases (fixed post-phase)
- `packages/nexus_store_crdt_adapter/lib/src/crdt_query_translator.dart` — LOWER() SQL helpers (fixed post-phase)
- `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart` — ilike() calls (fixed post-phase)
- `example/basic_usage/bin/main.dart` — case-insensitive filter cases (fixed post-phase)
- `example/flutter_widgets/lib/main.dart` — case-insensitive filter cases (fixed post-phase)
- `packages/nexus_store/test/fixtures/mock_backend.dart` — updated _matchesFilter
- `packages/nexus_store/test/src/query/case_insensitive_search_test.dart` — new test file
- `packages/nexus_store/test/src/query/query_test.dart` — updated FilterOperator count

---

## Phase A4: Mutation Lifecycle Hooks (High Priority)

**Why:** TanStack Query's `useMutation` pattern (onMutate/onSuccess/onError/onSettled) is the industry standard for structured mutations. Currently NexusStore has no way to coordinate pre-mutation setup, post-mutation cache invalidation, and error rollback in a single declaration.

**Dependencies:** Phase A1 (getOne for optimistic read-back). ✅ Complete.

### Pre-Implementation Checklist
- [x] Phase A1 complete and committed
- [x] Read `nexus_store.dart` — existing `save()`, `delete()`, tag invalidation patterns

### Tasks
#### RED: Write Failing Tests (~22)
- [x] mutate calls onMutate before save
- [x] mutate calls onSuccess after successful save
- [x] mutate calls onError on save failure
- [x] mutate calls onSettled after success
- [x] mutate calls onSettled after error
- [x] mutate invalidates tags on success
- [x] mutate does NOT invalidate tags on error
- [x] mutate rollback context flows from onMutate to onSuccess
- [x] mutate rollback context flows from onMutate to onError
- [x] mutate with onMutate returning null (no context)
- [x] mutate with no options falls through to plain save
- [x] mutate respects WritePolicy
- [x] mutateDelete calls onMutate before delete
- [x] mutateDelete calls onSettled after successful delete
- [x] mutateDelete calls onError on delete failure
- [x] mutateDelete calls onSettled after error
- [x] mutateDelete invalidates tags on success
- [x] mutateDelete with no options falls through to plain delete
- [x] MutationOptions equality/hashCode (all null)
- [x] MutationOptions equality with same invalidateTags
- [x] MutationOptions inequality with different invalidateTags
- [x] mutate throws before init
- [x] Verify all tests PASS

#### GREEN: Implement
1. [x] Create `MutationOptions<T>` class with onMutate/onSuccess/onError/onSettled/invalidateTags
2. [x] Add `Future<T> mutate(T item, {MutationOptions<T>? options, WritePolicy? policy})` to `NexusStore`
3. [x] Add `Future<bool> mutateDelete(ID id, {MutationOptions<T>? options, WritePolicy? policy})` to `NexusStore`
4. [x] Implement lifecycle: onMutate -> operation -> onSuccess/onError -> onSettled -> invalidateTags
5. [x] Export `MutationOptions` via barrel file
6. [x] Verify all tests PASS

**Design decision:** `mutateDelete` does NOT call `onSuccess` since delete returns `bool`, not `T`. Use `onSettled` for post-delete actions.

### Acceptance Criteria
- [x] Full lifecycle: onMutate -> save -> onSuccess -> onSettled
- [x] Error path: onMutate -> save fails -> onError -> onSettled
- [x] Tag invalidation fires on success only
- [x] No options = plain save/delete behavior

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 22
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage >= 95%: ✅ 100.0% (19/19 lines) — nexus_store.dart 19/19 100%
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/lib/src/core/mutation_options.dart` — new: MutationOptions class
- `packages/nexus_store/lib/src/core/nexus_store.dart` — added `mutate()`, `mutateDelete()`
- `packages/nexus_store/lib/nexus_store.dart` — barrel export
- `packages/nexus_store/test/src/core/mutation_test.dart` — new test file

---

## Phase A5: Background Refetch Manager (Medium Priority)

**Why:** `staleDuration` exists in StoreConfig but there's no automatic refetch — consumers must manually call `get()` again. Modern data layers auto-refetch on interval, reconnect, and app resume.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `store_config.dart` — existing freezed config, staleDuration field
- [x] Read `nexus_store.dart` — initialize/dispose lifecycle

### Tasks
#### RED: Write Failing Tests (~16)
- [x] RefetchConfig construction with defaults
- [x] RefetchConfig with interval only
- [x] RefetchConfig with reconnect only
- [x] RefetchConfig with resume only
- [x] RefetchConfig equality/hashCode
- [x] RefetchConfig toString
- [x] RefetchManager starts timer on start
- [x] RefetchManager triggers refetch at interval
- [x] RefetchManager cancels timer on dispose
- [x] RefetchManager fires on connectivity restored
- [x] RefetchManager does not fire on connectivity lost
- [x] RefetchManager fires on app resume
- [x] RefetchManager no-ops when config is not enabled
- [x] RefetchManager dispose cleans up subscriptions
- [x] RefetchManager silently ignores refetch errors
- [x] RefetchManager does not refetch after dispose
- [x] Verify all tests PASS

#### GREEN: Implement
1. [x] Create `RefetchConfig` class (refetchInterval, refetchOnReconnect, refetchOnResume)
2. [x] Create `RefetchManager` class with Timer and Stream subscriptions
3. [x] Export `RefetchConfig` and `RefetchManager` via barrel file
4. [x] Verify all tests PASS

**Design decision:** RefetchConfig is a standalone class, NOT embedded in freezed StoreConfig. Avoids build_runner regeneration. Consumers wire it into NexusStore externally.

### Acceptance Criteria
- [x] Timer-based refetch fires at configured interval
- [x] Refetch errors silently ignored (retried on next interval)
- [x] Clean dispose with no timer/subscription leaks
- [x] Connectivity and app resume triggers work

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 16
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage >= 95%: ✅ 95.2% (40/42 lines) — refetch_config.dart 14/16 87.5%, refetch_manager.dart 26/26 100%
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/lib/src/policy/refetch_config.dart` — new: RefetchConfig class
- `packages/nexus_store/lib/src/policy/refetch_manager.dart` — new: RefetchManager class
- `packages/nexus_store/lib/nexus_store.dart` — barrel exports
- `packages/nexus_store/test/src/policy/refetch_test.dart` — new test file

---

## Phase B1: Firefly Repository Migration — Phase 2 (Medium Priority)

**Why:** Several Firefly repos still use workarounds for features that now exist (watchOne, getByIds) or will exist after A1-A3 (getOne, findBy, scoped queries, iContains).

**Dependencies:** Phases A1, A2, A3 must be complete. ✅ All complete.

**Status:** ✅ Complete

### Pre-Implementation Checklist
- [x] Phase A1 (getOne/findBy) complete and committed
- [x] Phase A2 (query scopes) complete and committed
- [x] Phase A3 (case-insensitive search) complete and committed
- [x] Run `prior-art` agent to confirm all migration targets

### Tasks
- [x] `settings_repository.dart`: `getAll().where((s) => s.userId == userId).first` → `findBy('user_id', userId)`
- [x] `settings_repository.dart`: `watchAll().map(filter)` → `watchOne(Query().where('user_id', isEqualTo: userId))`
- [x] `app_settings_repository.dart`: `getAll().where((s) => s.key == key).first` → `findBy('key', key)`
- [x] `app_settings_repository.dart`: `watchAll().map(filter)` → `watchOne(Query().where('key', isEqualTo: key))`
- [x] `journal_repository.dart`: 9x `.where('deleted_at', isNull: true)` → `ScopedStore` with `SoftDeleteScope`
- [x] `journal_repository.dart`: manual soft-delete → `softDelete(entryId)`
- [x] `journal_repository.dart`: `getAll()` + in-memory search → `iContains` queries (title + content OR via dual query merge)
- [x] `complaint_repository.dart`: `getAll()` + in-memory search → `iContains` queries (subject + description OR via dual query merge)
- [x] `profile_repository.dart`: No migration needed — uses role-based queries, not sequential `.get(id)`

### Critical Files
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/settings/settings_repository.dart`
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/app_settings/app_settings_repository.dart`
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/journal/journal_repository.dart`
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/complaint/complaint_repository.dart`
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/profile/profile_repository.dart`

---

## Phase C1: Cross-Adapter Composition Tests (Lower Priority)

**Why:** CompositeBackend is tested in isolation but never with realistic adapter capability combinations. No cross-adapter composition tests exist.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `composite_backend.dart` — delegation patterns, read/write strategies
- [x] Read existing `composite_backend_test.dart` — current test coverage (1106 lines)

### Tasks
#### Tests Written (~21)
- [x] Primary failure — fallback serves reads
- [x] Fallback failure — primary still works
- [x] Cache miss — falls through to primary
- [x] All backends fail — returns null or throws
- [x] primaryFirst strategy returns from primary
- [x] cacheFirst strategy returns from cache
- [x] primaryOnly write strategy
- [x] all write strategy
- [x] primaryAndCache write strategy
- [x] Count through composite
- [x] Exists through composite
- [x] ExistsWhere through composite
- [x] DeleteWhere through composite
- [x] UpdateWhere through composite
- [x] Patch through composite
- [x] GetByIds through composite (found + missing + empty)
- [x] Upsert through composite
- [x] supportsTransactions flag
- [x] supportsPagination flag
- [x] Sync status aggregation
- [x] Verify all tests PASS

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 21
- [x] `dart test` passes in `nexus_store/`
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store/test/src/core/composite_backend_composition_test.dart` — new test file

---

## Phase C2: Brick Adapter Test Parity (Lower Priority)

**Status:** ✅ Complete

**Why:** While the brick adapter had 2726 lines / 49+ tests, gap analysis revealed 4 untested StoreBackend methods (exists, getByIds, patch, updateWhere) and no tests for Phase 2 case-insensitive operators (iContains, iStartsWith, iEndsWith).

### Tasks
- [x] Test `exists()` returns true/false correctly
- [x] Test `existsWhere()` with matching and non-matching queries
- [x] Test `getByIds()` — matching items, empty input, missing items, deduplication
- [x] Test `count()` — all items, with query, empty store
- [x] Test `patch()` throws UnsupportedError (default implementation)
- [x] Test `updateWhere()` returns 0 for empty updates
- [x] Test `iContains` translates to `brick.Compare.contains`
- [x] Test `iStartsWith` translates to `brick.Compare.contains`
- [x] Test `iEndsWith` translates to `brick.Compare.contains`
- [x] Test case-insensitive ops combined with other filters
- [x] Test case-insensitive ops with field mapping
- [x] Test `translateFilters` with iContains/iStartsWith/iEndsWith directly

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 23 new (207 total in brick adapter)
- [x] `dart test` passes in `nexus_store_brick_adapter/`
- [x] Tracker progress table updated

### Critical Files
- `packages/nexus_store_brick_adapter/test/brick_backend_parity_test.dart` — new: exists, getByIds, count, patch, updateWhere tests
- `packages/nexus_store_brick_adapter/test/brick_query_translator_case_insensitive_test.dart` — new: iContains/iStartsWith/iEndsWith tests

---

## Phase C3: Architecture Invariant Validators (Lower Priority)

**Why:** Rules exist in `.claude/rules/` but only 2 invariants are automated (`cross-package-src-import.dart`, `dependency-direction.dart`). Missing validators for barrel exports, interface naming, and no-envied.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read existing invariants in `.claude/invariants/`
- [x] Read `.claude/orchestrators/pre-commit-check.sh` — how invariants are integrated

### Tasks
- [x] Create `barrel-export-completeness.dart` — validates every public class in `lib/src/` is exported via barrel
- [x] Create `interface-naming.dart` — validates `InterfaceXxx` naming (not `IXxx`), updated with `--self-test` mode
- [x] Create `no-envied.dart` — validates no envied/`.env` usage in library packages
- [x] All 3 invariants have self-test modes (`--self-test` flag)
- [x] Orchestrator auto-discovers via glob — no changes needed to `pre-commit-check.sh`

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Self-tests passing for all 3 invariants
- [x] Pre-commit harness auto-discovers new invariants
- [x] Tracker progress table updated

### Critical Files
- `.claude/invariants/barrel-export-completeness.dart` — new
- `.claude/invariants/no-envied.dart` — new
- `.claude/invariants/interface-naming.dart` — updated with self-test

---

## Completion Checklist
- [x] 9/9 phases ✅ in progress table
- [x] B1 complete — Firefly migration done
- [x] C2 complete — 23 parity tests added
- [x] Status updated to `COMPLETE`
- [x] Move tracker to `docs/trackers/completed/infrastructure/`
- [x] Update `docs/trackers/index.md`
- [x] Final History entry added

## Files

### Files Created
| File | Phase | Purpose |
|------|-------|---------|
| `packages/nexus_store/lib/src/query/query_scope.dart` | A2 | QueryScope, SoftDeleteScope, OwnerScope |
| `packages/nexus_store/lib/src/core/scoped_store.dart` | A2 | ScopedStore proxy |
| `packages/nexus_store/lib/src/core/mutation_options.dart` | A4 | MutationOptions class |
| `packages/nexus_store/lib/src/policy/refetch_config.dart` | A5 | RefetchConfig class |
| `packages/nexus_store/lib/src/policy/refetch_manager.dart` | A5 | RefetchManager class |
| `.claude/invariants/barrel-export-completeness.dart` | C3 | Barrel export validator |
| `.claude/invariants/no-envied.dart` | C3 | No-envied validator |
| `packages/nexus_store/test/src/core/get_one_find_by_test.dart` | A1 | getOne/findBy tests |
| `packages/nexus_store/test/src/query/case_insensitive_search_test.dart` | A3 | Case-insensitive tests |
| `packages/nexus_store/test/src/query/query_scope_test.dart` | A2 | Query scope tests |
| `packages/nexus_store/test/src/core/mutation_test.dart` | A4 | Mutation lifecycle tests |
| `packages/nexus_store/test/src/policy/refetch_test.dart` | A5 | Refetch manager tests |
| `packages/nexus_store/test/src/core/composite_backend_composition_test.dart` | C1 | Composition tests |

### Files Modified
| File | Phases | Changes |
|------|--------|---------|
| `packages/nexus_store/lib/src/core/nexus_store.dart` | A1, A2, A4 | Added getOne, findBy, scoped, softDelete, mutate, mutateDelete |
| `packages/nexus_store/lib/src/query/query.dart` | A3 | Added iContains/iStartsWith/iEndsWith params + FilterOperator values |
| `packages/nexus_store/lib/src/cache/query_evaluator.dart` | A3 | Case-insensitive matching |
| `packages/nexus_store/lib/src/query/query_translator.dart` | A3 | Updated operatorToSql mixin |
| `packages/nexus_store/lib/src/query/expression.dart` | A3 | Updated _invertOperator |
| `packages/nexus_store/lib/src/interceptors/store_operation.dart` | A1 | Added getOne enum value + isRead |
| `packages/nexus_store/lib/src/telemetry/operation_metric.dart` | A1 | Added OperationType.getOne |
| `packages/nexus_store/lib/src/interceptors/timing_interceptor.dart` | A1 | Updated mapping |
| `packages/nexus_store/lib/nexus_store.dart` | A1-A5 | Barrel exports |
| `packages/nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart` | A3 | LOWER() SQL helpers |
| `packages/nexus_store_drift_adapter/lib/src/drift_query_translator.dart` | A3 | LOWER() SQL helpers |
| `packages/nexus_store_brick_adapter/lib/src/brick_query_translator.dart` | A3 | iContains/iStartsWith/iEndsWith Brick conditions |
| `packages/nexus_store_crdt_adapter/lib/src/crdt_query_translator.dart` | A3 | LOWER() SQL helpers for CRDT |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart` | A3 | ilike() calls for Supabase |
| `example/basic_usage/bin/main.dart` | A3 | Case-insensitive filter cases |
| `example/flutter_widgets/lib/main.dart` | A3 | Case-insensitive filter cases |
| `packages/nexus_store/test/fixtures/mock_backend.dart` | A3 | Case-insensitive filter matching |
| `packages/nexus_store/test/src/interceptors/store_operation_test.dart` | A1 | Updated enum count + switch |
| `packages/nexus_store/test/src/query/query_test.dart` | A3 | Updated FilterOperator count |
| `packages/nexus_store/test/src/telemetry/operation_metric_test.dart` | A1 | Updated OperationType enum count |
| `.claude/invariants/interface-naming.dart` | C3 | Added self-test mode |
| `.claude/orchestrators/pre-commit-check.sh` | fix | Fixed set -e bug silently killing analyzer check |

## History

| Date | Event |
|------|-------|
| 2026-03-16 | Tracker created — 9 phases, ~167 estimated tests |
| 2026-03-16 | Phase A1 complete — getOne/findBy, 20 tests, StoreOperation.getOne enum |
| 2026-03-16 | Phase A3 complete — iContains/iStartsWith/iEndsWith, 14 tests, 3 packages updated |
| 2026-03-16 | Phase A2 complete — QueryScope, SoftDeleteScope, OwnerScope, ScopedStore, 22 tests |
| 2026-03-16 | Phase A4 complete — MutationOptions with lifecycle hooks, 22 tests |
| 2026-03-16 | Phase A5 complete — RefetchConfig + RefetchManager, 16 tests |
| 2026-03-16 | Phase C1 complete — cross-adapter composition tests, 21 tests |
| 2026-03-16 | Phase C3 complete — 3 invariant validators (barrel-export, no-envied, interface-naming) |
| 2026-03-16 | Phase C2 skipped — brick adapter already exceeds parity target (2726 lines / 49 tests) |
| 2026-03-16 | Fix: OperationType enum count test (6c7b18c) — missed hasLength(20) → 21 |
| 2026-03-16 | Delta coverage retroactively computed — A1 100% (15/15), A2 100% (8/8), A3 100% (25/25), A4 100% (19/19), A5 LCOV gap |
| 2026-03-16 | Fix: 5 exhaustive switch errors in brick/crdt/supabase adapters + examples for new FilterOperator values (ba8ddd0) |
| 2026-03-16 | Fix: pre-commit-check.sh set -e bug — analyzer failure silently killed harness instead of reporting (ba8ddd0) |
| 2026-03-16 | Fix: check-coverage.py stale lcov.info bug — _try_format_coverage returned stale file instead of regenerating from VM JSON |
| 2026-03-16 | A5 delta coverage corrected: 95.2% (40/42) — was previously null due to stale lcov.info |
| 2026-03-16 | Phase B1 complete — migrated 4 Firefly repos: findBy, watchOne, ScopedStore+SoftDeleteScope, softDelete, iContains |
| 2026-03-16 | Phase C2 complete — 23 parity tests: exists, getByIds, count, patch, updateWhere, iContains/iStartsWith/iEndsWith |
