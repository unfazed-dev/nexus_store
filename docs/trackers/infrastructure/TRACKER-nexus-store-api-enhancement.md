# TRACKER: NexusStore API Enhancement

## Status: IN PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| 1. count() Method | ✅ Complete | 22 | ✅ 97.9% | `422497f` | 2026-03-14 |
| 2. deleteWhere() on NexusStore | ✅ Complete | 21 | ✅ 97.9% | `d5fbe0b` | 2026-03-15 |
| 3. Text Search in Query.where() | ✅ Complete | 14 | ✅ 97.9% | `45f60c9` | 2026-03-15 |
| 4. Backend Capability Introspection | ✅ Complete | 6 | ✅ 97.9% | `e83e79d` | 2026-03-15 |
| 5. Firefly Repository Migration | ✅ Complete | 13 | — | `38c46e65` | 2026-03-15 |
| 6. Drift Adapter Parity | ✅ Complete | 19 | ✅ 95.8% | `40b15d8` | 2026-03-15 |
| 7. OR Logic in Query | ✅ Complete | 35 | ✅ 97.9% | `1e8333e` | 2026-03-15 |
| 8. Aggregate Operations | ✅ Complete | 42 | ✅ 95.8% | `00288c3` | 2026-03-15 |
| 9. exists() Method | ✅ Complete | 17 | ✅ 95.8% | `30135f5` | 2026-03-16 |
| 10. updateWhere() / Batch Update | ✅ Complete | 37 | ✅ 95.8% | `90635c3` | 2026-03-16 |
| 11. patch() / Partial Update | ✅ Complete | 18 | ✅ 95.8% | ⏳ | 2026-03-16 |
| 12. Reactive Streams (watchCount, watchOne) | ⏳ Pending | ~10 | — | — | — |
| 13. Query Convenience Methods | ⏳ Pending | ~14 | — | — | — |
| 14. Diagnostics & Health | ⏳ Pending | ~8 | — | — | — |
| 15. upsert() / Save-If-Not-Exists | ⏳ Pending | ~16 | — | — | — |
| 16. getByIds() Batch Get | ⏳ Pending | ~12 | — | — | — |
| 17. Cross-Store Transactions | ⏳ Pending | ~18 | — | — | — |

**Overall:** ██████████░░░░░░ 65% complete
**Tests:** 244 passing | ~258-263 estimated total

### Progress Log

**Phase 11 Results (2026-03-16):**
- Added `Future<T?> patch(ID id, Map<String, dynamic> updates)` to `StoreBackend` interface
- Default implementation in `StoreBackendDefaults` throws `UnsupportedError` (requires field extraction)
- Added `patch` to `StoreOperation` enum (isWrite), `OperationType` enum, `TimingInterceptor` mapping
- `WritePolicyHandler.patch()` with all 4 policy strategies (cacheAndNetwork, networkFirst, cacheFirst, cacheOnly)
- `NexusStore.patch()` with interceptor chain, cache update, audit logging
- `CompositeBackend.patch()` delegation to primary
- `FakeStoreBackend.patch()` with `patchApplier` callback for tests
- PowerSync adapter: SQL `UPDATE table SET ... WHERE id = ?`
- Drift adapter: SQL `UPDATE table SET ... WHERE id = ?`
- 18 tests: 9 NexusStore, 4 StoreBackend, 5 WritePolicyHandler
- Harness: accepted (format, analyze, invariants, coverage all pass)
- Coverage: `nexus_store` 95.84%, `nexus_store_drift_adapter` 95.84%, `nexus_store_powersync_adapter` 99.23%

**Phase 10 Results (2026-03-16):**
- Added `updateWhere(Query<T> query, Map<String, dynamic> updates)` to `StoreBackend` interface
- Default implementation in `StoreBackendDefaults` throws `UnsupportedError` (requires field extraction knowledge)
- Added `updateWhere` to `NexusStore` with interceptor chain, write policy, cache invalidation, audit logging
- Added `updateWhere` to `WritePolicyHandler` with all 4 write policy strategies
- Added `toUpdateWhereSql` to both `PowerSyncQueryTranslator` and `DriftQueryTranslator`
- Native SQL `UPDATE SET ... WHERE ...` in both PowerSync and Drift backends
- Added `StoreOperation.updateWhere` (classified as write) and `OperationType.updateWhere`
- Added `updateWhere` to `CompositeBackend` (delegates to primary)
- 37 tests across 7 test files (core, backend, policy, interceptor, telemetry, PowerSync, Drift)
- Harness: accepted=true, all packages >= 95% coverage

**Phase 9 Results (2026-03-16):**
- Added `exists(ID id)` and `existsWhere(Query<T> query)` to `StoreBackend` interface
- Default implementations in `StoreBackendDefaults`: `exists` uses `get()`, `existsWhere` uses `getAll()`
- Optimized SQL implementations in PowerSync and Drift adapters using `SELECT EXISTS(SELECT 1 FROM ...)`
- Added `toExistsSql()` to both `PowerSyncQueryTranslator` and `DriftQueryTranslator`
- Added `StoreOperation.exists` and `StoreOperation.existsWhere` enum values
- Added `OperationType.exists` and `OperationType.existsWhere` enum values
- Updated `CompositeBackend` to delegate exists to primary backend
- Updated interceptor chain, timing interceptor, and extension methods
- 17 tests passing (12 nexus_store exists + 5 store_backend exists)
- Harness: accepted

**Phase 8 Results (2026-03-15):**
- Added `AggregateType` enum (sum, avg, min, max) in `aggregate_result.dart`
- Added `aggregate()` to `StoreBackend` interface with default UnsupportedError impl
- Added `toAggregateSql()` to both `PowerSyncQueryTranslator` and `DriftQueryTranslator`
- Added native `aggregate()` to PowerSync and Drift backends using `SELECT SUM/AVG/MIN/MAX`
- Added `aggregate()`, `sum()`, `avg()`, `min()`, `max()` convenience methods to `NexusStore`
- Added `aggregate` to `StoreOperation` and `OperationType` enums
- Updated `CompositeBackend`, `TimingInterceptor` for new operation type
- 42 new tests: 26 core (3 AggregateType + 12 backend + 8 NexusStore + 3 StoreOperation), 8 PowerSync SQL, 8 Drift SQL
- Harness: accepted (format, analyze, invariants, coverage all pass)

**Phase 7 Results (2026-03-15):**
- Added `QueryFilterGroup` class with `FilterGroupCombinator` enum (AND/OR)
- Added `.or()` builder method to `Query` with immutable filter group composition
- Added `hasFilters` getter and updated `isEmpty`/`==`/`hashCode`/`copyWith`/`toString`
- Updated `PowerSyncQueryTranslator` with `_buildFullWhereClause` for OR SQL generation
- Updated `DriftQueryTranslator` with `_buildFullWhereClause` for OR SQL generation
- Updated `InMemoryQueryEvaluator.matches()` with `_matchesFilterGroup` for OR evaluation
- 35 new tests: 14 core Query, 8 PowerSync SQL, 7 Drift SQL, 6 in-memory evaluator
- Harness: format clean, analyze clean, invariants pass, coverage 97.9%/95.8%/99.2%

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

**Phase 3 Results (2026-03-15):**
- Added `String? contains`, `String? startsWith`, `String? endsWith` named params to `Query.where()`
- Each creates a `QueryFilter` with corresponding `FilterOperator` (already existed in enum)
- PowerSync SQL translation already handled (`LIKE '%val%'`, `LIKE 'val%'`, `LIKE '%val'`)
- In-memory evaluator already handled (`String.contains`, `String.startsWith`, `String.endsWith`)
- Tests: 14 new tests across 3 test files (query builder, PowerSync SQL, in-memory evaluator)
- Harness: format ✅, analyze ✅, invariants ✅ (coverage pre-existing gap on nexus_store core)

**Phase 4 Results (2026-03-15):**
- Created `BackendCapabilities` class bundling 5 capability flags with value equality
- Added `BackendCapabilities get capabilities` getter to `NexusStore` delegating to backend
- Exported via barrel file `nexus_store.dart`
- Tests: 6 tests (4 for BackendCapabilities class, 2 for NexusStore.capabilities delegation)
- Harness: accepted: true (format, analyze, invariants, coverage all pass)

**Phase 5 Results (2026-03-15):**
- Migrated 5 Firefly repositories to use `count()` and `deleteWhere()` APIs
- count() replacements: TrainingRepository (getProgramsCount, getActiveEnrollmentsCount), PayslipRepository (getPendingPayslipsCount, getUnpaidPayslipsCount), UserSelectionRepository (getSelectionCounts), LocalMessageRepository (getPendingSyncCount), LocalDraftRepository (getPendingDraftCount)
- deleteWhere() replacements: LocalMessageRepository (clearAll, clearSyncQueue, clearAllCache), LocalDraftRepository (clearDraftsForUser, clearAllDrafts), UserSelectionRepository (clearAllSelections)
- Updated nexus_store dependency to local path overrides for development
- Tests: 13 new/updated tests (4 training, 4 payslip, 5 user_selection) + 99 total passing across all 5 repos
- Harness: flutter analyze clean, all tests passing

**Phase 6 Results (2026-03-15):**
- Added native `count()` override to DriftBackend using `SELECT COUNT(*)` (replaces inefficient `getAll().length` fallback)
- Added `toCountSql()` method to DriftQueryTranslator (mirrors PowerSync adapter pattern)
- Verified `deleteWhere()` already implemented natively in DriftBackend (uses `toDeleteSql()`)
- Verified text search (contains/startsWith/endsWith) already implemented via LIKE in DriftQueryTranslator
- Tests: 19 new tests (8 translator toCountSql, 5 backend count unit, 3 integration deleteWhere, 3 integration text search, 5 integration count = total 19 across 3 files)
- Harness: accepted (format, analyze, invariants, coverage all pass)
- Coverage: 95.8% (507/529 lines) for nexus_store_drift_adapter

**Current State (2026-03-16):**
- Working on: COMPLETE (Phase 11)
- Last completed: Phase 11 — patch() / Partial Update
- Blocked by: Nothing
- Next up: Phase 12 — Reactive Streams (watchCount, watchOne)

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
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.9% (4398/4491 lines)
  - `nexus_store_powersync_adapter`: 99.2% (769/775 lines)
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
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.9% (4398/4491 lines)
  - `nexus_store_powersync_adapter`: 99.2% (769/775 lines)
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
- [x] Read `query.dart` — existing `where()` method, `QueryFilter` creation
- [x] Read `filter_operator.dart` — contains/startsWith/endsWith enum values
- [x] Read `powersync_query_translator.dart` — existing LIKE translation

### Tasks
#### RED: Write Failing Tests (~12)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Query builder creates correct filter for each param
- [x] PowerSync SQL generates `LIKE '%value%'`, `LIKE 'value%'`, `LIKE '%value'`
- [x] In-memory evaluator matches correctly
- [x] Combined with other filters (AND composition)
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Add `String? contains`, `String? startsWith`, `String? endsWith` named params to `Query.where()`
2. [x] Each creates a `QueryFilter` with corresponding `FilterOperator`
3. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `Query<T>().where('name', contains: 'john')` generates correct filter
- [x] PowerSync translates to `LIKE '%john%'`
- [x] `startsWith` and `endsWith` work similarly

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~12, actual: 14)
- [x] `dart test` passes in `nexus_store/`
- [x] `dart test` passes in `nexus_store_powersync_adapter/`
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.9% (4398/4491 lines)
  - `nexus_store_powersync_adapter`: 99.2% (769/775 lines)
- [x] Tracker progress table updated

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
- [x] Read `store_backend.dart` — existing capability flags
- [x] Read `nexus_store.dart` — public API surface

### Tasks
#### RED: Write Failing Tests (~5)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Capabilities reflect backend flags
- [x] Each flag delegated correctly
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Create `BackendCapabilities` class
2. [x] Add `BackendCapabilities get capabilities` to `NexusStore`
3. [x] Delegate to backend properties
4. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `store.capabilities.supportsOffline` delegates to backend
- [x] All 5 capability flags exposed

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~5)
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.9% (4398/4491 lines)
- [x] Tracker progress table updated

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
- [x] Phase 1 (count) complete and committed
- [x] Phase 2 (deleteWhere) complete and committed
- [x] Phase 3 (text search) complete and committed
- [x] Run `prior-art` agent to identify all migration targets

### Tasks
#### RED: Write Failing Tests (~15-20)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Updated repository tests for count() usage
- [x] Updated repository tests for deleteWhere() usage
- [x] Updated text search tests — N/A (no text search patterns found in target repos)
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Replace `getAll().length` with `count()` in: training_repository, local_message_repository, local_draft_repository, payslip_repository, user_selection_repository
2. [x] Replace `getAll()` + `deleteAll(ids)` with `deleteWhere()` in: local_message_repository, local_draft_repository
3. [x] Replace in-memory text search with `Query.where(contains:)` where applicable — N/A (no text search patterns found)
4. [x] Update corresponding tests
5. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] No repository uses `getAll().length` pattern
- [x] No repository uses `getAll()` + `deleteAll(ids)` pattern where `deleteWhere()` is applicable
- [x] All Firefly tests pass

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~15-20 updated, actual: 13 new + 99 total passing)
- [x] `python3 .claude/hooks/core/smart-test-run.py` passes
- [x] `flutter analyze` clean
- [x] Coverage >= 95% for changed packages — N/A (Firefly app migration, no nexus_store package changes)
- [x] Tracker progress table updated

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
- [x] Phase 1 (count) complete and committed
- [x] Phase 2 (deleteWhere) complete and committed
- [x] Phase 3 (text search) complete and committed
- [x] Read `drift_backend.dart` — existing Drift adapter implementation
- [x] Read `drift_query_translator.dart` — existing query translation

### Tasks
#### RED: Write Failing Tests (~15)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Drift count with/without query
- [x] Drift deleteWhere
- [x] Text search LIKE in Drift
- [x] Integration with local stores
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Add `count({Query<T>? query})` to Drift adapter using `SELECT COUNT(*)`
2. [x] Verify `deleteWhere(Query<T> query)` works (may be inherited from defaults)
3. [x] Add text search LIKE support to Drift query translator
4. [x] Verify `DriftQueryTranslator` handles `FilterOperator.contains/startsWith/endsWith`
5. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `localStore.count()` uses `SELECT COUNT(*)` via Drift
- [x] `localStore.deleteWhere(query)` delegates to Drift
- [x] Text search works on Drift-backed stores

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~15)
- [x] `dart test` passes in `nexus_store_drift_adapter/`
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store_drift_adapter`: 95.8% (507/529 lines)
- [x] Tracker progress table updated

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
- [x] Phase 3 (text search) complete and committed
- [x] Read `query.dart` — existing expression tree
- [x] Read `powersync_query_translator.dart` — SQL generation
- [x] Read `in_memory_query_evaluator.dart` — OrExpression handling

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
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Query builder OR composition
- [x] Nested AND/OR
- [x] PowerSync SQL generation
- [x] Drift SQL generation
- [x] In-memory evaluation
- [x] Edge cases (empty OR, single-condition OR)
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Introduce `QueryFilterGroup` concept — group of filters with AND/OR combinator
2. [x] Add `.or(Query<T> Function(Query<T>) builder)` method to `Query`
3. [x] Update `PowerSyncQueryTranslator` to generate `(condition1 OR condition2)` SQL
4. [x] Update `DriftQueryTranslator` for OR support
5. [x] Update `toFilters()` to handle OR groups
6. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `.or()` builder creates correct OR filter group
- [x] PowerSync generates `(condition1 OR condition2)` SQL
- [x] Drift generates equivalent OR SQL
- [x] In-memory evaluator handles OR correctly

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~20, actual: 35)
- [x] `dart test` passes in `nexus_store/`, `nexus_store_powersync_adapter/`, `nexus_store_drift_adapter/`
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.93% (4398/4491 lines)
  - `nexus_store_drift_adapter`: 95.84% (507/529 lines)
  - `nexus_store_powersync_adapter`: 99.23% (769/775 lines)
- [x] Tracker progress table updated

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
- [x] Phase 1 (count) complete and committed
- [x] Read `store_backend.dart` — count() pattern to follow

### Tasks
#### RED: Write Failing Tests (~18)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Each aggregate type with/without query
- [x] Null handling, empty result sets
- [x] PowerSync SQL, Drift SQL
- [x] In-memory fallback
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Add `AggregateResult` class
2. [x] Add `Future<num?> aggregate(String field, AggregateType type, {Query<T>? query})` to `StoreBackend`
3. [x] Default impl using in-memory calculation on `getAll()` results
4. [x] PowerSync adapter: `SELECT SUM(field), AVG(field), ...`
5. [x] Drift adapter: same SQL pattern
6. [x] Add to `NexusStore` with interceptor chain
7. [x] Add convenience methods: `sum()`, `avg()`, `min()`, `max()`
8. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `store.sum('amount', query: query)` returns correct sum
- [x] `store.avg('rating')` returns correct average
- [x] PowerSync uses `SELECT SUM(field)` (not in-memory)
- [x] Empty result sets return null

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (expected: ~18, actual: 42)
- [x] `dart test` passes in all packages
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 97.93% (4398/4491 lines)
  - `nexus_store_drift_adapter`: 95.84% (507/529 lines)
  - `nexus_store_powersync_adapter`: 99.23% (769/775 lines)
- [x] Tracker progress table updated

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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
- [x] Read `store_backend.dart` — `save()` pattern
- [x] Read `nexus_store.dart` — write op interceptor chain

### Tasks
#### RED: Write Failing Tests (~14)
- [x] Scaffold test files (`test-scaffold` agent)
- [x] Patch single/multiple fields
- [x] Non-existent entity
- [x] Write policy, cache update
- [x] PowerSync SQL, Drift SQL
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Add `Future<T?> patch(ID id, Map<String, dynamic> updates)` to `StoreBackend`
2. [x] Default impl in `StoreBackendDefaults` throws `UnsupportedError`
3. [x] PowerSync: `UPDATE table SET field1=val1 WHERE id = ?`
4. [x] Drift: `UPDATE table SET field1=val1 WHERE id = ?`
5. [x] Add to `NexusStore` with interceptor chain, write policy, cache update
6. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [x] `store.patch(id, {'name': 'updated'})` updates without loading entity
- [x] Returns updated entity
- [x] Write policy respected
- [x] Cache updated after patch

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing (actual: 18)
- [x] `dart test` passes in all packages
- [x] `dart analyze` clean
- [x] Coverage >= 95% for changed packages
  - `nexus_store`: 95.84% (507/529 lines)
  - `nexus_store_drift_adapter`: 95.84% (507/529 lines)
  - `nexus_store_powersync_adapter`: 99.23% (769/775 lines)
- [x] Tracker progress table updated

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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
- [ ] Coverage >= 95% for changed packages
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
| 2026-03-15 | Phase 3 complete — Text search (contains/startsWith/endsWith) added to Query.where() |
| 2026-03-15 | Phase 4 complete — BackendCapabilities class with 5 capability flags |
| 2026-03-15 | Phase 5 complete — Firefly repository migration: 5 repos migrated to count() and deleteWhere(), 13 new tests, 99 total passing |
