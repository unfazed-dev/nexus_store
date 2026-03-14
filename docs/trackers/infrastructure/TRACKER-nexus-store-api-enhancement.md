# TRACKER: NexusStore API Enhancement

## Status: IN PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Committed | Last Updated |
|-------|--------|-------|-----------|--------------|
| 1. count() Method | ✅ Complete | 22 | `422497f` | 2026-03-14 |
| 2. deleteWhere() on NexusStore | ✅ Complete | 21 | ⏳ | 2026-03-15 |
| 3. Text Search in Query.where() | ⏳ Pending | ~12 | — | — |
| 4. Backend Capability Introspection | ⏳ Pending | ~5 | — | — |
| 5. Firefly Repository Migration | ⏳ Pending | ~15-20 | — | — |
| 6. Drift Adapter Parity | ⏳ Pending | ~15 | — | — |
| 7. OR Logic in Query | ⏳ Pending | ~20 | — | — |
| 8. Aggregate Operations | ⏳ Pending | ~18 | — | — |
| 9. exists() Method | ⏳ Pending | ~12 | — | — |
| 10. updateWhere() / Batch Update | ⏳ Pending | ~16 | — | — |
| 11. patch() / Partial Update | ⏳ Pending | ~14 | — | — |
| 12. Reactive Streams (watchCount, watchOne) | ⏳ Pending | ~10 | — | — |
| 13. Query Convenience Methods | ⏳ Pending | ~14 | — | — |
| 14. Diagnostics & Health | ⏳ Pending | ~8 | — | — |
| 15. upsert() / Save-If-Not-Exists | ⏳ Pending | ~16 | — | — |
| 16. getByIds() Batch Get | ⏳ Pending | ~12 | — | — |
| 17. Cross-Store Transactions | ⏳ Pending | ~18 | — | — |

**Overall:** ██░░░░░░░░░░░░░░ 12% complete
**Tests:** 43 passing | ~246-251 estimated total

### Progress Log


**Phase 1 Results (2026-03-14):**
- Added `count()` method to StoreBackend interface, StoreBackendDefaults, CompositeBackend, PowerSyncBackend, and NexusStore
- Added `StoreOperation.count` enum value with `isRead` classification
- Added `OperationType.count` for telemetry tracking
- Added `toCountSql()` to PowerSyncQueryTranslator (SELECT COUNT(*))
- Wired through interceptor chain and `_trackOperation` in NexusStore
- Updated timing_interceptor switch for count mapping
- Tests: 22 count-related tests added/updated across 4 test files
- Harness: accepted: true (format, analyze, invariants all pass)

**Phase 2 Results (2026-03-15):**
- Added `StoreOperation.deleteWhere` enum value, updated `isDelete` extension
- Added `OperationType.deleteWhere` for telemetry tracking
- Added `deleteWhere(Query, {WritePolicy?})` to `WritePolicyHandler` with all 4 policy strategies
- Added `Future<int> deleteWhere(Query<T>, {WritePolicy?})` to `NexusStore`
- Wired through interceptor chain, `_trackOperation`, cache invalidation (`invalidateAll()`)
- Updated `TimingInterceptor._mapOperation` switch for deleteWhere mapping
- Updated existing tests: `store_operation_test.dart` (switch + count), `operation_metric_test.dart` (count)
- Tests: 21 new deleteWhere tests across 5 test files
- Harness: accepted: true (format, analyze, invariants all pass)

**Current State (2026-03-15):**
- Working on: COMPLETE (Phase 2)
- Last completed: Phase 2 — deleteWhere() on NexusStore
- Blocked by: Nothing
- Next up: Phase 3 — Text Search in Query.where()

---

## Overview

NexusStore is a unified reactive data store abstraction (git dependency) used across 55 PowerSync stores, 4 Drift stores, and 110+ repositories in Firefly. Several backend-level capabilities are not exposed through the NexusStore public API, forcing repositories into inefficient workarounds (fetching all records to count, fetching all to delete by filter, in-memory text search). This tracker covers closing those API gaps.

**Package location:** `~/.pub-cache/git/nexus_store-8fc701a2e3d7466be318bb9d6378601f41df3bf8/packages/`

**Sub-packages:**
- `nexus_store` — Core library (interface, NexusStore, Query, interceptors, telemetry)
- `nexus_store_powersync_adapter` — PowerSync backend (SQLite)
- `nexus_store_drift_adapter` — Drift backend (local SQLite)
- `nexus_store_flutter_widgets` — Flutter UI integration
- `nexus_store_entity_generator` — Code generation

## Dependency Graph

```
Phases 1, 2, 3, 4, 9, 11, 14, 15, 16 — can start independently

Phase 5  (repo migration)     depends on: 1, 2, 3
Phase 6  (Drift parity)       depends on: 1, 2, 3
Phase 7  (OR logic)           depends on: 3
Phase 8  (aggregates)         depends on: 1
Phase 10 (updateWhere)        depends on: 2
Phase 12 (reactive streams)   depends on: 1
Phase 13 (query convenience)  depends on: 3
Phase 17 (cross-store tx)     depends on: 11
```

## Priority Summary

| Priority | Phases | Est. Tests |
|----------|--------|------------|
| **Highest** | 1 (count) | ~22 |
| **High** | 2 (deleteWhere), 5 (repo migration) | ~34-39 |
| **Medium** | 3, 6, 7, 8, 9, 10, 11, 15, 16 | ~149 |
| **Lower** | 4, 12, 13, 14, 17 | ~55 |
| **Total** | 17 phases | ~246-251 |

## Skills & Agents by Phase

| Phase | Skills | Agents |
|-------|--------|--------|
| 1-4, 7-17 | `/nexus-store` | `arch-check`, `test-scaffold` |
| 5 | `/nexus-store`, `/stacked` | `arch-check`, `prior-art` |
| 6 | `/nexus-store` | `arch-check` |
| **Every phase end** | `/commit-helper` | `verify-app` |

## Verification

```bash
# NexusStore core tests
cd packages/nexus_store && dart test

# PowerSync adapter tests
cd packages/nexus_store_powersync_adapter && dart test

# Drift adapter tests
cd packages/nexus_store_drift_adapter && dart test

# Firefly tests (after Phase 5)
python3 .claude/hooks/core/smart-test-run.py

# Lint
flutter analyze
```

---

## Phase 1: `count()` Method (Highest Priority)

**Why:** 6+ repositories do `getAll().length` — fetches entire tables just to count rows.

**Dependencies:** None — can start immediately.

### Pre-Implementation Checklist
- [x] Read `store_backend.dart` — StoreBackend interface, StoreBackendDefaults mixin
- [x] Read `nexus_store.dart` — public API, `_trackOperation`, `_interceptorChain.execute` pattern
- [x] Read `composite_backend.dart` — delegation pattern
- [x] Read `store_operation.dart` — StoreOperation enum, extension methods
- [x] Read `operation_metric.dart` — OperationType enum
- [x] Read `powersync_backend.dart` — how other methods use `_queryTranslator`
- [x] Read `powersync_query_translator.dart` — `toSelectSql()`, `toDeleteSql()` patterns

### Tasks
1. [x] Add `Future<int> count({Query<T>? query})` to `StoreBackend` interface
2. [x] Add default impl in `StoreBackendDefaults`: `getAll(query:).then((l) => l.length)`
3. [x] Add `count()` to `CompositeBackend` (delegate to primary)
4. [x] Add `StoreOperation.count` enum value, update `isRead` extension
5. [x] Add `OperationType.count` for telemetry
6. [x] Add `toCountSql()` to `PowerSyncQueryTranslator`
7. [x] Add `count()` to `PowerSyncBackend` using `SELECT COUNT(*)`
8. [x] Add `Future<int> count({Query<T>? query, FetchPolicy? policy})` to `NexusStore`
9. [x] Wire through interceptor chain and `_trackOperation`

### Tests (~22)
- `store_backend_test.dart` — default count fallback
- `nexus_store_test.dart` — count with/without query, interceptor chain fires
- `store_operation_test.dart` — count enum value, isRead includes count
- `powersync_query_translator_test.dart` — toCountSql with/without filters
- `powersync_backend_test.dart` — count delegates to SQL
- `composite_backend_test.dart` — count delegates to primary
- `operation_metric_test.dart` — OperationType.count exists

### Acceptance Criteria
- [x] `store.count()` returns total count without fetching all entities
- [x] `store.count(query: Query<T>().where('status', isEqualTo: 'active'))` returns filtered count
- [x] PowerSync uses `SELECT COUNT(*)` (not in-memory)
- [x] Interceptor chain processes `StoreOperation.count`
- [x] Telemetry tracks `OperationType.count`

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~22)
- [x] `dart test` passes in `nexus_store/`
- [x] `dart test` passes in `nexus_store_powersync_adapter/`
- [x] `dart analyze` clean in both packages
- [x] Tracker progress table updated
- [x] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Critical Files
- `nexus_store/lib/src/core/store_backend.dart` — interface + defaults
- `nexus_store/lib/src/core/nexus_store.dart` — public method
- `nexus_store/lib/src/core/composite_backend.dart` — delegate
- `nexus_store/lib/src/interceptors/store_operation.dart` — enum
- `nexus_store/lib/src/telemetry/operation_metric.dart` — OperationType
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart` — SQL count
- `nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart` — toCountSql

---

## Phase 2: `deleteWhere()` on NexusStore (High Priority)

**Why:** Backend already has `deleteWhere(Query)` but NexusStore doesn't expose it. Repos do `getAll()` -> map IDs -> `deleteAll(ids)`.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `write_policy_handler.dart` — how `delete()` handles policy strategies
- [x] Read `nexus_store.dart` — `_interceptorChain.execute` pattern for write ops
- [x] Read `store_operation.dart` — existing delete enum, `isDelete` extension

### Tasks
#### RED: Write Failing Tests (~19)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Enum properties (isDelete includes deleteWhere, modifiesData true)
- [x] Write policy per strategy (cacheAndNetwork, networkFirst, cacheFirst, cacheOnly)
- [x] Interceptor chain fires for deleteWhere
- [x] Cache invalidation after deleteWhere
- [x] Telemetry tracks OperationType.deleteWhere
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Add `StoreOperation.deleteWhere` enum, update `isDelete` extension
2. [x] Add `OperationType.deleteWhere` for telemetry
3. [x] Add `deleteWhere()` to `WritePolicyHandler` (mirror `delete()` policy strategies)
4. [x] Add `Future<int> deleteWhere(Query<T> query, {WritePolicy? policy})` to `NexusStore`
5. [x] Wire through interceptor chain, telemetry, cache invalidation (`invalidateAll()`)
6. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `store.deleteWhere(Query<T>().where('status', isEqualTo: 'archived'))` works
- [x] Returns count of deleted entities
- [x] Write policy respected
- [x] Cache invalidated after delete

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~19, actual: 21)
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Tracker progress table updated
- [x] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/interceptors/store_operation.dart` — enum
- `nexus_store/lib/src/telemetry/operation_metric.dart` — OperationType
- `nexus_store/lib/src/policy/write_policy_handler.dart` — policy handling
- `nexus_store/lib/src/core/nexus_store.dart` — public method

---

## Phase 3: Text Search in `Query.where()` (Medium Priority)

**Why:** `FilterOperator` already has `contains`/`startsWith`/`endsWith` and PowerSync translates them to LIKE SQL. But `Query.where()` doesn't expose named parameters for these operators, forcing in-memory filtering.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `query.dart` — existing `where()` method, `QueryFilter` creation
- [ ] Read `filter_operator.dart` — contains/startsWith/endsWith enum values
- [ ] Read `powersync_query_translator.dart` — existing LIKE translation

### Tasks
#### RED: Write Failing Tests (~12)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Query builder creates correct filter for each param
- [ ] PowerSync SQL generates `LIKE '%value%'`, `LIKE 'value%'`, `LIKE '%value'`
- [ ] In-memory evaluator matches correctly
- [ ] Combined with other filters (AND composition)
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `String? contains`, `String? startsWith`, `String? endsWith` named params to `Query.where()`
2. [ ] Each creates a `QueryFilter` with corresponding `FilterOperator`
3. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `Query<T>().where('name', contains: 'john')` generates correct filter
- [ ] PowerSync translates to `LIKE '%john%'`
- [ ] `startsWith` and `endsWith` work similarly

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~12)
- [ ] `dart test` passes in `nexus_store/`
- [ ] `dart test` passes in `nexus_store_powersync_adapter/`
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/query/query.dart` — add 3 named params

---

## Phase 4: Backend Capability Introspection (Low Priority)

**Why:** Backend has `supportsOffline`, `supportsRealtime`, etc. but NexusStore doesn't expose them. Runtime capability checking would be useful.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `store_backend.dart` — existing capability flags
- [ ] Read `nexus_store.dart` — public API surface

### Tasks
#### RED: Write Failing Tests (~5)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Capabilities reflect backend flags
- [ ] Each flag delegated correctly
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Create `BackendCapabilities` class
2. [ ] Add `BackendCapabilities get capabilities` to `NexusStore`
3. [ ] Delegate to backend properties
4. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.capabilities.supportsOffline` delegates to backend
- [ ] All 5 capability flags exposed

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~5)
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- New: `nexus_store/lib/src/core/backend_capabilities.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store/lib/nexus_store.dart` — barrel export

---

## Phase 5: Firefly Repository Migration (After Phases 1-3)

**Why:** Once `count()`, `deleteWhere()`, and text search are available, update Firefly repositories to use them.

**Dependencies:** Phases 1, 2, 3 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 1 (count) complete and committed
- [ ] Phase 2 (deleteWhere) complete and committed
- [ ] Phase 3 (text search) complete and committed
- [ ] Run `prior-art` agent to identify all migration targets

### Tasks
#### RED: Write Failing Tests (~15-20)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Updated repository tests for count() usage
- [ ] Updated repository tests for deleteWhere() usage
- [ ] Updated text search tests
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Replace `getAll().length` with `count()` in: training_repository, local_message_repository, local_draft_repository, payslip_repository, user_selection_repository
2. [ ] Replace `getAll()` + `deleteAll(ids)` with `deleteWhere()` in: local_message_repository, local_draft_repository
3. [ ] Replace in-memory text search with `Query.where(contains:)` where applicable
4. [ ] Update corresponding tests
5. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] No repository uses `getAll().length` pattern
- [ ] No repository uses `getAll()` + `deleteAll(ids)` pattern where `deleteWhere()` is applicable
- [ ] All Firefly tests pass

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~15-20 updated)
- [ ] `python3 .claude/hooks/core/smart-test-run.py` passes
- [ ] `flutter analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
python3 .claude/hooks/core/smart-test-run.py
```

### Critical Files
- `lib/portals/services_hub/repositories/training/training_repository.dart` — `getAll().length` -> `count()`
- `lib/portals/shared/repositories/local_message/local_message_repository.dart` — `getAll().length` -> `count()`, `getAll()+deleteAll()` -> `deleteWhere()`
- `lib/portals/shared/repositories/local_draft/local_draft_repository.dart` — `getAll().length` -> `count()`, `getAll()+deleteAll()` -> `deleteWhere()`
- `lib/portals/shared/repositories/payslip/payslip_repository.dart` — `getAll().length` -> `count()`
- `lib/portals/shared/repositories/user_selection/user_selection_repository.dart` — `getAll().length` -> `count()`

---

## Phase 6: Drift Adapter Parity (Medium Priority, After Phases 1-3)

**Why:** LocalStoreRegistry uses 4 Drift-backed stores (device_settings, form_drafts, chat_messages, sync_operations). These need `count()`, `deleteWhere()`, and text search support.

**Dependencies:** Phases 1, 2, 3 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 1 (count) complete and committed
- [ ] Phase 2 (deleteWhere) complete and committed
- [ ] Phase 3 (text search) complete and committed
- [ ] Read `drift_backend.dart` — existing Drift adapter implementation
- [ ] Read `drift_query_translator.dart` — existing query translation

### Tasks
#### RED: Write Failing Tests (~15)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Drift count with/without query
- [ ] Drift deleteWhere
- [ ] Text search LIKE in Drift
- [ ] Integration with local stores
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `count({Query<T>? query})` to Drift adapter using `SELECT COUNT(*)`
2. [ ] Verify `deleteWhere(Query<T> query)` works (may be inherited from defaults)
3. [ ] Add text search LIKE support to Drift query translator
4. [ ] Verify `DriftQueryTranslator` handles `FilterOperator.contains/startsWith/endsWith`
5. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `localStore.count()` uses `SELECT COUNT(*)` via Drift
- [ ] `localStore.deleteWhere(query)` delegates to Drift
- [ ] Text search works on Drift-backed stores

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~15)
- [ ] `dart test` passes in `nexus_store_drift_adapter/`
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_query_translator.dart`
- Firefly: `lib/data/stores/local_store_registry.dart`

---

## Phase 7: OR Logic in Query (Medium Priority, After Phase 3)

**Why:** `OrExpression` exists in the expression tree and `InMemoryQueryEvaluator` supports it, but `toFilters()` throws `UnsupportedError` for OR — can't translate to SQL.

**Dependencies:** Phase 3 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 3 (text search) complete and committed
- [ ] Read `query.dart` — existing expression tree
- [ ] Read `powersync_query_translator.dart` — SQL generation
- [ ] Read `in_memory_query_evaluator.dart` — OrExpression handling

### Tasks

### API Design
```dart
Query<T>()
  .where('status', isEqualTo: 'active')
  .or((q) => q
    .where('role', isEqualTo: 'admin')
    .where('role', isEqualTo: 'superadmin')
  );
// Generates: status = 'active' AND (role = 'admin' OR role = 'superadmin')
```

#### RED: Write Failing Tests (~20)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Query builder OR composition
- [ ] Nested AND/OR
- [ ] PowerSync SQL generation
- [ ] Drift SQL generation
- [ ] In-memory evaluation
- [ ] Edge cases (empty OR, single-condition OR)
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Introduce `QueryFilterGroup` concept — group of filters with AND/OR combinator
2. [ ] Add `.or(Query<T> Function(Query<T>) builder)` method to `Query`
3. [ ] Update `PowerSyncQueryTranslator` to generate `(condition1 OR condition2)` SQL
4. [ ] Update `DriftQueryTranslator` for OR support
5. [ ] Update `toFilters()` to handle OR groups
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `.or()` builder creates correct OR filter group
- [ ] PowerSync generates `(condition1 OR condition2)` SQL
- [ ] Drift generates equivalent OR SQL
- [ ] In-memory evaluator handles OR correctly

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~20)
- [ ] `dart test` passes in `nexus_store/`, `nexus_store_powersync_adapter/`, `nexus_store_drift_adapter/`
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/query/query.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart`
- `nexus_store_drift_adapter/lib/src/drift_query_translator.dart`

---

## Phase 8: Aggregate Operations (Lower Priority, After Phase 1)

**Why:** No `sum()`, `avg()`, `min()`, `max()` methods. Training repo does dual `getAll()` calls for completion rate.

**Dependencies:** Phase 1 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 1 (count) complete and committed
- [ ] Read `store_backend.dart` — count() pattern to follow

### Tasks
#### RED: Write Failing Tests (~18)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Each aggregate type with/without query
- [ ] Null handling, empty result sets
- [ ] PowerSync SQL, Drift SQL
- [ ] In-memory fallback
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `AggregateResult` class
2. [ ] Add `Future<num?> aggregate(String field, AggregateType type, {Query<T>? query})` to `StoreBackend`
3. [ ] Default impl using in-memory calculation on `getAll()` results
4. [ ] PowerSync adapter: `SELECT SUM(field), AVG(field), ...`
5. [ ] Drift adapter: same SQL pattern
6. [ ] Add to `NexusStore` with interceptor chain
7. [ ] Add convenience methods: `sum()`, `avg()`, `min()`, `max()`
8. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.sum('amount', query: query)` returns correct sum
- [ ] `store.avg('rating')` returns correct average
- [ ] PowerSync uses `SELECT SUM(field)` (not in-memory)
- [ ] Empty result sets return null

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~18)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- New: `nexus_store/lib/src/core/aggregate_result.dart`
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Phase 9: `exists()` Method (Medium Priority)

**Why:** Repositories use `get(id) != null` to check existence — loads entire entity just to check a boolean.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `store_backend.dart` — `get()` pattern
- [ ] Read `nexus_store.dart` — interceptor chain for read ops

### Tasks
#### RED: Write Failing Tests (~12)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] exists by ID (found/not found)
- [ ] existsWhere with query
- [ ] PowerSync SQL, Drift SQL
- [ ] Interceptor chain
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `Future<bool> exists(ID id)` to `StoreBackend`
2. [ ] Add `Future<bool> existsWhere(Query<T> query)` to `StoreBackend`
3. [ ] Default impl: `get(id).then((v) => v != null)` and `getAll(query: query.limitTo(1)).then((l) => l.isNotEmpty)`
4. [ ] PowerSync: `SELECT EXISTS(SELECT 1 FROM table WHERE id = ?)`
5. [ ] Drift: same SQL pattern
6. [ ] Add to `NexusStore` with interceptor chain
7. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.exists(id)` returns bool without loading entity
- [ ] `store.existsWhere(query)` returns bool with query
- [ ] PowerSync uses `SELECT EXISTS(...)` (not in-memory)

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~12)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store/lib/src/interceptors/store_operation.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Phase 10: `updateWhere()` / Batch Update by Query (Medium Priority, After Phase 2)

**Why:** Repositories do `get(id)` -> `copyWith()` -> `save()` just to change one field. No way to update multiple records by query.

**Dependencies:** Phase 2 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 2 (deleteWhere) complete and committed
- [ ] Read `write_policy_handler.dart` — deleteWhere policy pattern

### Tasks
#### RED: Write Failing Tests (~16)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Update single/multiple records
- [ ] Empty result, write policy strategies
- [ ] Cache invalidation
- [ ] PowerSync SQL, Drift SQL
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `Future<int> updateWhere(Query<T> query, Map<String, dynamic> updates)` to `StoreBackend`
2. [ ] Default impl: `getAll(query:)` -> apply updates -> `saveAll()`
3. [ ] PowerSync: `UPDATE table SET field1=val1 WHERE ...`
4. [ ] Drift: Drift's update builder
5. [ ] Add to `NexusStore` with interceptor chain, write policy, cache invalidation
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.updateWhere(query, {'status': 'archived'})` updates matching records
- [ ] Returns count of updated entities
- [ ] Write policy respected
- [ ] Cache invalidated after update

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~16)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store/lib/src/policy/write_policy_handler.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Phase 11: `patch()` / Partial Update (Medium Priority)

**Why:** Single-entity partial update without loading the entire entity.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `store_backend.dart` — `save()` pattern
- [ ] Read `nexus_store.dart` — write op interceptor chain

### Tasks
#### RED: Write Failing Tests (~14)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Patch single/multiple fields
- [ ] Non-existent entity
- [ ] Write policy, cache update
- [ ] PowerSync SQL, Drift SQL
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `Future<T> patch(ID id, Map<String, dynamic> updates)` to `StoreBackend`
2. [ ] Default impl: `get(id)` -> apply updates via toJson/fromJson -> `save()`
3. [ ] PowerSync: `UPDATE table SET field1=val1 WHERE id = ?`
4. [ ] Drift: Drift's update builder with single-row filter
5. [ ] Add to `NexusStore` with interceptor chain, write policy, cache update
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.patch(id, {'name': 'updated'})` updates without loading entity
- [ ] Returns updated entity
- [ ] Write policy respected
- [ ] Cache updated after patch

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~14)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store/lib/src/policy/write_policy_handler.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Phase 12: Reactive Streams — `watchCount()` and `watchOne()` (Lower Priority, After Phase 1)

**Why:** No reactive count stream or single-item query stream. Repos use `watchAll().map((l) => l.length)` for count.

**Dependencies:** Phase 1 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 1 (count) complete and committed
- [ ] Read `nexus_store.dart` — existing `watchAll()` implementation

### Tasks
#### RED: Write Failing Tests (~10)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] watchCount empty/populated/changes
- [ ] watchOne found/not-found/changes
- [ ] Query filtering
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `Stream<int> watchCount({Query<T>? query})` to `NexusStore`
2. [ ] Add `Stream<T?> watchOne(Query<T> query)` to `NexusStore`
3. [ ] Default impl: `watchAll(query:).map((l) => l.length)` and `watchAll(query: query.limitTo(1)).map((l) => l.firstOrNull)`
4. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.watchCount()` emits count updates reactively
- [ ] `store.watchOne(query)` emits single entity or null reactively
- [ ] Both work with query filters

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~10)
- [ ] `dart test` passes in `nexus_store/`
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/core/nexus_store.dart`

---

## Phase 13: Query Convenience Methods (Lower Priority, After Phase 3)

**Why:** Common query patterns require verbose boilerplate.

**Dependencies:** Phase 3 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 3 (text search) complete and committed
- [ ] Read `query.dart` — existing builder methods

### Tasks
#### RED: Write Failing Tests (~14)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] whereBetween, whereNull/whereNotNull
- [ ] select projection, distinct
- [ ] SQL generation for each
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `.whereBetween(field, start, end)` — sugar for >= + <=
2. [ ] Add `.whereNull(field)` / `.whereNotNull(field)` — sugar for isNull
3. [ ] Add `.select(Set<String> fields)` for field projection
4. [ ] Add `.distinct()` for unique results
5. [ ] Update PowerSync and Drift query translators for `SELECT field1, field2`
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `Query<T>().whereBetween('age', 18, 65)` generates >= AND <= filters
- [ ] `.whereNull('field')` and `.whereNotNull('field')` work
- [ ] `.select({'name', 'email'})` generates `SELECT name, email`
- [ ] `.distinct()` generates `SELECT DISTINCT`

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~14)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/query/query.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart`
- `nexus_store_drift_adapter/lib/src/drift_query_translator.dart`

---

## Phase 14: Diagnostics & Health (Low Priority)

**Why:** No single method to get a snapshot of store health.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `nexus_store.dart` — existing stats/telemetry access
- [ ] Read `operation_metric.dart` — telemetry data available

### Tasks
#### RED: Write Failing Tests (~8)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Diagnostics accuracy
- [ ] Slow operation tracking
- [ ] Cache info per entity
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `StoreDiagnostics getDiagnostics()` to `NexusStore`
2. [ ] Include: entity count, pending changes, cache size, hit rate, avg latency
3. [ ] Add slow operations list from stats
4. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.getDiagnostics()` returns comprehensive health snapshot
- [ ] Slow operations identified above threshold
- [ ] Cache hit rate reported

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~8)
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- New: `nexus_store/lib/src/core/store_diagnostics.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store/lib/nexus_store.dart` — barrel export

---

## Phase 15: `upsert()` / Save-If-Not-Exists (Medium Priority)

**Why:** Repositories do `get(id)` then conditional `save()`. No atomic upsert with conflict strategy.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `store_backend.dart` — `save()` / `saveAll()` patterns
- [ ] Read `powersync_backend.dart` — SQL insert patterns

### Tasks
#### RED: Write Failing Tests (~16)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Upsert insert-new, update-existing
- [ ] Each conflict strategy
- [ ] Batch upsert
- [ ] PowerSync SQL, Drift SQL
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `ConflictStrategy` enum: `update`, `ignore`, `replace`, `error`
2. [ ] Add `Future<T> upsert(T item, {ConflictStrategy onConflict})` to `StoreBackend`
3. [ ] Default impl: `get(id)` -> if exists, apply strategy -> `save()`
4. [ ] PowerSync: `INSERT OR REPLACE INTO ...`
5. [ ] Drift: `insertOnConflictUpdate`
6. [ ] Add `upsertAll()` for batch
7. [ ] Add to `NexusStore` with interceptor chain
8. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.upsert(item)` inserts or updates atomically
- [ ] `ConflictStrategy.ignore` skips existing records
- [ ] `upsertAll()` handles batch upsert
- [ ] PowerSync uses `INSERT OR REPLACE`

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~16)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- New: `nexus_store/lib/src/core/conflict_strategy.dart`
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Phase 16: `getByIds(List<ID>)` — Batch Get (Medium Priority)

**Why:** No way to efficiently fetch multiple entities by IDs. Code uses sequential `get(id)` or `getAll()` + filter.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `store_backend.dart` — `get()` / `getAll()` patterns
- [ ] Read `nexus_store.dart` — read op interceptor chain

### Tasks
#### RED: Write Failing Tests (~12)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] getByIds all found, partial, none, empty list
- [ ] Cache hits, PowerSync SQL IN clause
- [ ] watchByIds reactivity
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `Future<List<T>> getByIds(List<ID> ids, {FetchPolicy? policy})` to `StoreBackend`
2. [ ] Default impl: `getAll(query: Query<T>().where('id', isIn: ids))`
3. [ ] PowerSync: `SELECT * FROM table WHERE id IN (?, ?, ...)`
4. [ ] Add `Stream<List<T>> watchByIds(List<ID> ids)` reactive variant
5. [ ] Add to `NexusStore` with interceptor chain
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.getByIds(['id1', 'id2'])` returns list efficiently
- [ ] PowerSync uses `WHERE id IN (...)` SQL
- [ ] `watchByIds()` emits updates reactively
- [ ] Empty list returns empty result

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~12)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- `nexus_store/lib/src/core/store_backend.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`

---

## Phase 17: Cross-Store Transactions (Lower Priority, After Phase 11)

**Why:** `runInTransaction()` only works within a single store. No atomic multi-store updates.

**Dependencies:** Phase 11 must be complete.

### Pre-Implementation Checklist
- [ ] Phase 11 (patch) complete and committed
- [ ] Read `nexus_store.dart` — existing `runInTransaction()` implementation
- [ ] Read `powersync_backend.dart` — transaction handling

### Tasks
#### RED: Write Failing Tests (~18)
- [ ] Scaffold test files (`test-scaffold` agent)
- [ ] Success commit, failure rollback
- [ ] Partial failure, nested cross-tx
- [ ] PowerSync shared DB tx
- [ ] Drift shared DB tx
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Create `TransactionCoordinator` class
2. [ ] Add `static Future<R> NexusStore.crossTransaction<R>(...)`
3. [ ] PowerSync: use shared `PowerSyncDatabase.writeTransaction()`
4. [ ] Drift: use shared Drift database transaction
5. [ ] Rollback: compensating actions for non-transactional backends
6. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `NexusStore.crossTransaction([store1, store2], (tx) => ...)` works atomically
- [ ] Failure in any store rolls back all changes
- [ ] PowerSync shares a single `writeTransaction()`
- [ ] Drift shares a single database transaction

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~18)
- [ ] `dart test` passes in all packages
- [ ] `dart analyze` clean
- [ ] Tracker progress table updated

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
- New: `nexus_store/lib/src/core/transaction_coordinator.dart`
- `nexus_store/lib/src/core/nexus_store.dart`
- `nexus_store_powersync_adapter/lib/src/powersync_backend.dart`
- `nexus_store_drift_adapter/lib/src/drift_backend.dart`

---

## Completion Checklist
- [ ] All 17 phases ✅ in progress table
- [ ] Status updated to `COMPLETE`
- [ ] Move tracker to `docs/trackers/completed/infrastructure/`
- [ ] Update `docs/trackers/index.md`
- [ ] Final History entry added
- [ ] Run `verify-app` agent for full verification

## Files

### NexusStore Core Package
| File | Phases |
|------|--------|
| `nexus_store/lib/src/core/store_backend.dart` | 1, 2, 8, 9, 10, 11, 15, 16 |
| `nexus_store/lib/src/core/nexus_store.dart` | 1, 2, 4, 8, 9, 10, 11, 12, 14, 15, 16, 17 |
| `nexus_store/lib/src/core/composite_backend.dart` | 1 |
| `nexus_store/lib/src/interceptors/store_operation.dart` | 1, 2, 8, 9, 10, 11, 12, 15, 16 |
| `nexus_store/lib/src/telemetry/operation_metric.dart` | 1, 2, 8, 9, 10, 11, 15, 16 |
| `nexus_store/lib/src/policy/write_policy_handler.dart` | 2, 10, 11, 15 |
| `nexus_store/lib/src/query/query.dart` | 3, 7, 13 |
| `nexus_store/lib/nexus_store.dart` | 4, 14 (new exports) |

### PowerSync Adapter
| File | Phases |
|------|--------|
| `nexus_store_powersync_adapter/lib/src/powersync_backend.dart` | 1, 8, 9, 10, 11, 15, 16 |
| `nexus_store_powersync_adapter/lib/src/powersync_query_translator.dart` | 1, 7, 13 |

### Drift Adapter
| File | Phases |
|------|--------|
| `nexus_store_drift_adapter/lib/src/drift_backend.dart` | 6, 8, 9, 10, 11, 15, 16 |
| `nexus_store_drift_adapter/lib/src/drift_query_translator.dart` | 6, 7, 13 |

### Files to Create
| File | Phase |
|------|-------|
| `nexus_store/lib/src/core/backend_capabilities.dart` | 4 |
| `nexus_store/lib/src/core/aggregate_result.dart` | 8 |
| `nexus_store/lib/src/core/conflict_strategy.dart` | 15 |
| `nexus_store/lib/src/core/store_diagnostics.dart` | 14 |
| `nexus_store/lib/src/core/transaction_coordinator.dart` | 17 |

### Firefly Repositories (Phase 5)
| File | Change |
|------|--------|
| `lib/portals/services_hub/repositories/training/training_repository.dart` | `getAll().length` -> `count()` |
| `lib/portals/shared/repositories/local_message/local_message_repository.dart` | `getAll().length` -> `count()`, `getAll()+deleteAll()` -> `deleteWhere()` |
| `lib/portals/shared/repositories/local_draft/local_draft_repository.dart` | `getAll().length` -> `count()`, `getAll()+deleteAll()` -> `deleteWhere()` |
| `lib/portals/shared/repositories/payslip/payslip_repository.dart` | `getAll().length` -> `count()` |
| `lib/portals/shared/repositories/user_selection/user_selection_repository.dart` | `getAll().length` -> `count()` |

## History

| Date | Event |
|------|-------|
| 2026-03-14 | Tracker created — 17 phases, ~246-251 estimated tests |
| 2026-03-14 | Tracker re-created with harness template format (pre/post checklists, verification checkpoints, completion checklist) |
| 2026-03-14 | Phase 1 complete — count() method added to StoreBackend, NexusStore, PowerSyncBackend, CompositeBackend |
| 2026-03-15 | Phase 2 complete — deleteWhere() added to WritePolicyHandler, NexusStore with interceptor chain, telemetry, cache invalidation |
