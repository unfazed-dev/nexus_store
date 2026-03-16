# TRACKER: NexusStore API Enhancement Phase 3

## Status: IN_PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| A1. `deleteAll` WritePolicyHandler Fix | ✅ Complete | 15 | ✅ 100.0% | `d262a79` | 2026-03-16 |
| A2. `StoreJoin` — Reactive Cross-Store Joins | ✅ Complete | 14 | ✅ 95.8% | `8428416` | 2026-03-16 |
| A3. `mutateWithTransform` — Atomic Get+Transform+Save | ⏳ Pending | — | — | — | — |
| A4. `watchPaged` — Paginated Reactive Streams | ⏳ Pending | — | — | — | — |
| B1. Compliance Audit Migration | ⏳ Pending | — | — | — | — |
| B2. Incident Repository Migration | ⏳ Pending | — | — | — | — |
| B3. Journal Soft-Delete Redundancy | ⏳ Pending | — | — | — | — |

**Overall:** ████░░░░░░░░░░░░ 29% complete (2/7 phases done)
**Tests:** 29 passing | ~60 estimated

### Progress Log

**Phase A1 Results (2026-03-16):**
- Added `WritePolicyHandler.deleteAll` with all 4 policy strategies (cacheAndNetwork, networkFirst, cacheFirst, cacheOnly)
- Refactored `NexusStore.deleteAll` from per-ID iteration to batch delegation via `_writeHandler.deleteAll`
- 15 tests written (6 policy-level + 9 store-level), all passing
- Harness: accepted=true, delta coverage 100.0% (18/18 lines)
- 122 total tests passing, 0 regressions

**Phase A2 Results (2026-03-16):**
- Created `StoreJoin` class with `combine2`, `combine3`, `combine4`, and `withLatest2` static methods
- Uses `Rx.combineLatest2/3/4` and `withLatestFrom` from rxdart for reactive cross-store joins
- Dart 3 record types for type-safe tuple returns
- 14 tests written (5 combine2 + 2 combine3 + 2 combine4 + 3 withLatest2 + 1 error + 1 cancel), all passing
- Harness: accepted=true, delta coverage 95.8% (23/24 lines)
- 2057 total tests passing, 0 regressions

**Current State (2026-03-16):**
- Working on: COMPLETE (Phase A2)
- Last completed: Phase A2 — StoreJoin reactive cross-store joins
- Blocked by: Nothing
- Next up: Phase A3 — mutateWithTransform atomic get+transform+save

## Overview

Analysis of NexusStore's 40+ public API methods against 25+ Firefly production repositories revealed:
- **6 migration gaps** — Firefly repos using workarounds despite NexusStore already having the solution
- **4 genuine API gaps** — capabilities missing from NexusStore that production consumers need

This tracker covers implementing all 10 items across 7 phases: 4 NexusStore API additions (A1–A4) and 3 Firefly migration phases (B1–B3).

**Package location:** `packages/` (Melos monorepo)

**Sub-packages affected:**
- `nexus_store` — Core library (A1–A4)
- Firefly app — Consumer-side migrations (B1–B3)

## Dependency Graph

```
A1, A2, A3, A4 — independent (can parallel)
B1, B3 — independent, no NexusStore changes needed
B2 — independent, no NexusStore changes needed
```

## Priority Summary

| Priority | Phases | Est. Tests |
|----------|--------|------------|
| **Highest** | A1 (deleteAll fix), A3 (mutateWithTransform) | ~22 |
| **High** | A2 (StoreJoin) | ~14 |
| **Medium** | A4 (watchPaged), B2 (incident migration) | ~18 |
| **Lower** | B1 (compliance audit), B3 (journal) | ~6 |
| **Total** | 7 phases | ~60 |

## Skills & Agents by Phase

| Phase | Skills | Agents |
|-------|--------|--------|
| A1–A4 | `/nexus-store` | `arch-check`, `test-scaffold` |
| B1–B3 | `/nexus-store` | `prior-art` |
| **Every phase end** | `/commit-helper` | `verify-packages` |

## Verification

```bash
# NexusStore core tests (phases A1-A4)
cd packages/nexus_store && dart test

# Pre-commit harness
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true

# Firefly tests (phases B1-B3)
cd /Users/unfazed-mac/Developer/apps/firefly
dart analyze lib/core/repositories/
python3 .claude/hooks/core/smart-test-run.py
```

---

## Phase A1: `deleteAll` WritePolicyHandler Fix (Highest Priority)

**Why:** `deleteAll(List<ID>)` exists on `StoreBackend` but `NexusStore.deleteAll` iterates `_writeHandler.delete(id)` per-ID because `WritePolicyHandler` has no `deleteAll` method. This bypasses batch-optimized backend implementations.

**Dependencies:** None — can start immediately.

### Pre-Implementation Checklist
- [x] Read `write_policy_handler.dart` — existing `deleteWhere()` policy dispatch pattern
- [x] Read `nexus_store.dart` — current `deleteAll()` implementation (per-ID iteration)
- [x] Read `store_backend.dart` — `deleteAll()` interface method

### Tasks
#### RED: Write Failing Tests (~12)
- [x] WritePolicyHandler.deleteAll with cacheAndNetwork policy
- [x] WritePolicyHandler.deleteAll with networkFirst policy
- [x] WritePolicyHandler.deleteAll with cacheFirst policy
- [x] WritePolicyHandler.deleteAll with cacheOnly policy
- [x] NexusStore.deleteAll delegates to WritePolicyHandler.deleteAll
- [x] NexusStore.deleteAll with empty list returns 0
- [x] NexusStore.deleteAll with multiple items returns correct count
- [x] NexusStore.deleteAll with partial missing IDs returns partial count
- [x] NexusStore.deleteAll fires interceptor chain
- [x] NexusStore.deleteAll invalidates cache
- [x] NexusStore.deleteAll throws before init
- [x] NexusStore.deleteAll respects WritePolicy parameter
- [x] Verify all tests FAIL (policy tests fail; store tests pass on existing per-ID impl — regression guards)
- [x] WritePolicyHandler.deleteAll respects explicit policy override (bonus)
- [x] WritePolicyHandler.deleteAll rethrows StoreError when sync fails (bonus)
- [x] NexusStore.deleteAll tracks telemetry as OperationType.deleteAll (bonus)

#### GREEN: Implement
1. [x] Add `Future<int> deleteAll(List<ID> ids, {WritePolicy? policy})` to `WritePolicyHandler` — mirror `deleteWhere` policy dispatch with `_deleteAllCacheAndNetwork`, `_deleteAllNetworkFirst`, `_deleteAllCacheFirst` helpers
2. [x] Update `NexusStore.deleteAll` body to delegate to `_writeHandler.deleteAll(ids, policy: policy)` instead of per-ID iteration
3. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green (122 tests, 0 failures)

### Acceptance Criteria
- [x] `store.deleteAll(['id1', 'id2', 'id3'])` delegates to batch backend operation
- [x] Write policy respected (all 4 strategies)
- [x] Cache invalidated after batch delete
- [x] Interceptor chain processes `StoreOperation.deleteAll`
- [x] Returns count of deleted entities

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 15 (6 policy + 9 store)
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage: ✅ 100.0% (18/18 lines) — `nexus_store.dart` 2/2 100%, `write_policy_handler.dart` 16/16 100%
- [x] Tracker progress table updated
- [x] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Critical Files
- `packages/nexus_store/lib/src/policy/write_policy_handler.dart` — add `deleteAll` method
- `packages/nexus_store/lib/src/core/nexus_store.dart` — update `deleteAll` body

---

## Phase A2: `StoreJoin` — Reactive Cross-Store Joins (High Priority)

**Why:** 10 Firefly files use `Future.wait` / `CombineLatestStream` to combine data from multiple stores. No declarative cross-store reactive API exists.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [x] Read `nexus_store.dart` — `watchAll()` stream signature
- [x] Verify rxdart is a dependency (for `Rx.combineLatest2/3/4` and `withLatestFrom`)
- [x] Read `transaction_coordinator.dart` — cross-store static method precedent

### API Design
```dart
class StoreJoin {
  /// Combines two stores into a single stream of paired results.
  static Stream<(List<A>, List<B>)> combine2<A, B>({
    required NexusStore<A, dynamic> storeA,
    required NexusStore<B, dynamic> storeB,
    Query<A>? queryA,
    Query<B>? queryB,
  });

  /// Combines three stores.
  static Stream<(List<A>, List<B>, List<C>)> combine3<A, B, C>({
    required NexusStore<A, dynamic> storeA,
    required NexusStore<B, dynamic> storeB,
    required NexusStore<C, dynamic> storeC,
    Query<A>? queryA,
    Query<B>? queryB,
    Query<C>? queryC,
  });

  /// Combines four stores.
  static Stream<(List<A>, List<B>, List<C>, List<D>)> combine4<A, B, C, D>({...});

  /// Emits only when primary store changes; secondary provides latest value.
  static Stream<(List<A>, List<B>)> withLatest2<A, B>({
    required NexusStore<A, dynamic> primary,
    required NexusStore<B, dynamic> secondary,
    Query<A>? primaryQuery,
    Query<B>? secondaryQuery,
  });
}
```

### Tasks
#### RED: Write Failing Tests (~14)
- [x] combine2 emits initial combined state
- [x] combine2 re-emits when storeA changes
- [x] combine2 re-emits when storeB changes
- [x] combine2 handles empty stores
- [x] combine2 applies query filters
- [x] combine3 emits combined state of 3 stores
- [x] combine3 re-emits on any store change
- [x] combine4 emits combined state of 4 stores
- [x] combine4 re-emits on any store change
- [x] withLatest2 emits only when primary changes
- [x] withLatest2 uses latest secondary value
- [x] withLatest2 does NOT emit on secondary-only change
- [x] Error propagation from any store
- [x] Dispose/cancel handling
- [x] Verify all tests FAIL

#### GREEN: Implement
1. [x] Create `StoreJoin` class in `packages/nexus_store/lib/src/core/store_join.dart`
2. [x] Implement `combine2` using `Rx.combineLatest2` on `store.watchAll(query:)`
3. [x] Implement `combine3` using `Rx.combineLatest3`
4. [x] Implement `combine4` using `Rx.combineLatest4`
5. [x] Implement `withLatest2` using `primaryStream.withLatestFrom(secondaryStream, (a, b) => (a, b))`
6. [x] Export via barrel file `packages/nexus_store/lib/nexus_store.dart`
7. [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green (2057 tests, 0 failures)

### Acceptance Criteria
- [x] `StoreJoin.combine2(storeA: users, storeB: orders)` emits combined stream
- [x] Re-emits when any participating store changes
- [x] Dart 3 record types for type-safe tuple returns
- [x] `withLatest2` only emits on primary store changes
- [x] No new StoreOperation/OperationType needed — composes existing watch streams

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 14
- [x] `dart test` passes in `nexus_store/`
- [x] `dart analyze` clean
- [x] Delta coverage: ✅ 95.8% (23/24 lines) — `store_join.dart` 23/24 95.8%
- [x] Tracker progress table updated
- [x] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Critical Files
- **New:** `packages/nexus_store/lib/src/core/store_join.dart`
- `packages/nexus_store/lib/nexus_store.dart` — barrel export

---

## Phase A3: `mutateWithTransform` — Atomic Get+Transform+Save (Highest Priority)

**Why:** Repos do `get(id) → copyWith() → save()` for status transitions (submit, close, review). No atomic transform-based mutation exists.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `nexus_store.dart` — existing `mutate()` and `mutateDelete()` patterns
- [ ] Read `mutation_options.dart` — MutationOptions lifecycle hooks

### API Design
```dart
/// Atomic get → transform → save pattern.
///
/// Throws [StateError] if entity with [id] does not exist.
Future<T> mutateWithTransform(
  ID id,
  T Function(T current) transform, {
  MutationOptions<T>? options,
  WritePolicy? policy,
})
```

### Tasks
#### RED: Write Failing Tests (~10)
- [ ] Fetches current entity and applies transform
- [ ] Saves transformed entity via underlying `mutate()`
- [ ] Throws `StateError` when entity not found
- [ ] MutationOptions.onMutate called before transform
- [ ] MutationOptions.onSuccess called after successful save
- [ ] MutationOptions.onError called on transform/save failure
- [ ] MutationOptions.onSettled always called
- [ ] invalidateTags applied on success
- [ ] WritePolicy forwarded to underlying save
- [ ] Throws before init (`StateError`)
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `mutateWithTransform` method to `NexusStore` after `mutateDelete`
2. [ ] Implementation: `get(id)` → null check (throw `StateError('Entity $id not found')`) → `transform(current)` → `mutate(transformed, options: options, policy: policy)`
3. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.mutateWithTransform(id, (e) => e.copyWith(status: 'closed'))` works atomically
- [ ] Full MutationOptions lifecycle (onMutate/onSuccess/onError/onSettled) honored
- [ ] Throws on non-existent entity (not silent null)
- [ ] Reuses existing `mutate()` — no new StoreOperation needed

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~10)
- [ ] `dart test` passes in `nexus_store/`
- [ ] `dart analyze` clean
- [ ] Delta coverage >= 95% for changed files
- [ ] Tracker progress table updated
- [ ] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Critical Files
- `packages/nexus_store/lib/src/core/nexus_store.dart` — add `mutateWithTransform` method

---

## Phase A4: `watchPaged` — Paginated Reactive Streams (Medium Priority)

**Why:** `watchAllPaged` exists but requires manual query construction. A convenience wrapper with explicit `pageSize` improves DX.

**Dependencies:** None — can start independently.

### Pre-Implementation Checklist
- [ ] Read `nexus_store.dart` — existing `watchAllPaged()` implementation
- [ ] Read `store_backend.dart` — `watchAllPaged()` / `PagedResult` types

### API Design
```dart
/// Convenience wrapper for watchAllPaged with explicit pageSize.
Stream<PagedResult<T>> watchPaged({
  Query<T>? query,
  int pageSize = 20,
})
```

### Tasks
#### RED: Write Failing Tests (~6)
- [ ] Returns Stream of PagedResult
- [ ] Applies pageSize to query (limitTo)
- [ ] Re-emits when underlying data changes
- [ ] hasMore is true when more items exist than pageSize
- [ ] Works with additional query filters
- [ ] Handles empty data (hasMore = false)
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Add `watchPaged` method to `NexusStore` near `watchAllPaged`
2. [ ] Implementation: merge `pageSize` into query via `.limitTo(pageSize + 1)`, delegate to `watchAllPaged`, construct `PagedResult` with `hasMore = results.length > pageSize`
3. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- [ ] `store.watchPaged(pageSize: 10)` returns reactive paginated stream
- [ ] `hasMore` correctly indicates whether more items exist
- [ ] Query filters compose with pageSize
- [ ] No new StoreOperation or OperationType needed

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~6)
- [ ] `dart test` passes in `nexus_store/`
- [ ] `dart analyze` clean
- [ ] Delta coverage >= 95% for changed files
- [ ] Tracker progress table updated
- [ ] Harness verification checkpoint passed

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Critical Files
- `packages/nexus_store/lib/src/core/nexus_store.dart` — add `watchPaged` method

---

## Phase B1: Compliance Audit Migration (Lower Priority)

**Why:** `compliance_audit_repository.dart` has 2 anti-patterns: fetches ALL records for date range filtering and latest entry retrieval, despite NexusStore having `whereBetween()` and `getOne()`.

**Dependencies:** None — no NexusStore changes needed.

### Pre-Implementation Checklist
- [ ] Read `compliance_audit_repository.dart` — current `getByDateRange` and `getLatestEntry` implementations
- [ ] Read `compliance_audit_repository_test.dart` — existing test stubs to update

### Tasks
#### RED: Update Tests (~4)
- [ ] Update `getByDateRange` test stubs: `getAll()` → `getAll(query: any(named: 'query'))`
- [ ] Update `getLatestEntry` test stubs: `getAll()` → `getOne(query: any(named: 'query'))`
- [ ] Verify updated tests FAIL (old implementation doesn't match new stubs)

#### GREEN: Implement
1. [ ] Replace `getByDateRange` body (lines 54-63):
   ```dart
   return _stores.complianceAuditLog.getAll(
     query: const Query<ComplianceAuditEntry>().whereBetween(
       'created_at', start.toIso8601String(), end.toIso8601String(),
     ),
   );
   ```
2. [ ] Replace `getLatestEntry` body (lines 67-72):
   ```dart
   return _stores.complianceAuditLog.getOne(
     query: const Query<ComplianceAuditEntry>()
         .orderByField('created_at', descending: true),
   );
   ```
3. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run Firefly tests — all green

### Acceptance Criteria
- [ ] `getByDateRange` uses `whereBetween` (no in-memory filtering)
- [ ] `getLatestEntry` uses `getOne` + `orderByField` (no fetch-all + sort)
- [ ] Existing tests pass with updated stubs

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (4 updated)
- [ ] `dart analyze` clean for compliance_audit_repository
- [ ] Tracker progress table updated

### Critical Files
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/compliance_audit/compliance_audit_repository.dart`
- `/Users/unfazed-mac/Developer/apps/firefly/test/unit/repositories/compliance_audit/compliance_audit_repository_test.dart`

---

## Phase B2: Incident Repository Migration (Medium Priority)

**Why:** `incident_repository.dart` has 3 anti-patterns: in-memory text search (fetches ALL for `searchIncidents`), in-memory severity ordinal filtering (`getAllIncidents`/`watchAllIncidents`), and in-memory computed property filtering (`getReportableIncidents`).

**Dependencies:** None — no NexusStore changes needed.

### Pre-Implementation Checklist
- [ ] Read `incident_repository.dart` — all 3 anti-pattern methods
- [ ] Read `complaint_repository.dart` — reference dual-query iContains merge pattern (B1 Phase 2 migration)
- [ ] Identify `IncidentSeverity.value` and `IncidentType.value` field mappings
- [ ] Check which `IncidentType` values are `.isReportable`

### Tasks
#### RED: Write Failing Tests (~12)
- [ ] searchIncidents returns results matching description iContains
- [ ] searchIncidents returns results matching location iContains
- [ ] searchIncidents deduplicates across description + location matches
- [ ] searchIncidents applies status filter
- [ ] searchIncidents applies limit
- [ ] getAllIncidents filters by minSeverity using isIn
- [ ] getAllIncidents with minSeverity=low returns all (no filter)
- [ ] getAllIncidents with minSeverity=critical returns only critical
- [ ] watchAllIncidents filters by minSeverity using isIn
- [ ] getReportableIncidents uses isIn for reportable types
- [ ] getReportableIncidents filters unreported via query
- [ ] getReportableIncidents applies limit via query
- [ ] Verify all tests FAIL

#### GREEN: Implement
1. [ ] Replace `searchIncidents` (lines 245-272) with dual iContains query merge:
   - Two queries: `where('description', iContains: query)` and `where('location', iContains: query)`
   - Merge + deduplicate by ID (same pattern as `complaint_repository.dart`)
2. [ ] Replace `getAllIncidents` severity filter (lines 88-103) with `isIn`:
   ```dart
   final qualifyingValues = severityOrder.sublist(minIndex).map((s) => s.value).toList();
   query = query.where('severity', isIn: qualifyingValues);
   ```
   Remove post-fetch in-memory filter block
3. [ ] Replace `watchAllIncidents` severity filter (lines 163-182) with same `isIn` pattern:
   Remove `stream.map` in-memory filter block
4. [ ] Replace `getReportableIncidents` (lines 222-241) with query-based filtering:
   ```dart
   final reportableValues = IncidentType.values.where((t) => t.isReportable).map((t) => t.value).toList();
   query = query.where('incident_type', isIn: reportableValues);
   if (onlyUnreported) query = query.where('reported_to_ndis', isEqualTo: false);
   ```
5. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run Firefly tests — all green

### Acceptance Criteria
- [ ] `searchIncidents('fire')` uses `iContains` (no in-memory toLowerCase)
- [ ] `getAllIncidents(minSeverity: high)` uses `isIn: ['high', 'critical']` (no in-memory ordinal)
- [ ] `watchAllIncidents(minSeverity:)` uses query-level filter (no stream.map)
- [ ] `getReportableIncidents()` uses `isIn` for types + query for boolean (no fetch-all)

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~12)
- [ ] `dart analyze` clean for incident_repository
- [ ] Tracker progress table updated

### Critical Files
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/incident/incident_repository.dart`
- Reference: `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/complaint/complaint_repository.dart` — dual-query iContains pattern

---

## Phase B3: Journal Soft-Delete Redundancy (Lower Priority)

**Why:** `getEntry()` uses unscoped `_stores.journalEntries.get()` then manually checks `deletedAt != null`. The scoped store `_journalStore` (with `SoftDeleteScope`) already handles this filtering automatically.

**Dependencies:** None — no NexusStore changes needed.

### Pre-Implementation Checklist
- [ ] Read `journal_repository.dart` — `getEntry` method and `_journalStore` definition
- [ ] Verify `ScopedStore.get()` applies scope filtering

### Tasks
#### GREEN: Implement
1. [ ] Replace `getEntry` body (lines 50-55):
   ```dart
   Future<JournalEntry?> getEntry(String entryId) async {
     return _journalStore.get(entryId);
   }
   ```
   Changes: use `_journalStore` (scoped) instead of `_stores.journalEntries` (unscoped), remove redundant `deletedAt` null check
2. [ ] Add test verifying `getEntry` for soft-deleted entry returns null via scoped store
3. [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run Firefly tests — all green

### Acceptance Criteria
- [ ] `getEntry(id)` uses scoped store (no manual soft-delete check)
- [ ] Soft-deleted entries return `null` automatically

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (~2)
- [ ] `dart analyze` clean for journal_repository
- [ ] Tracker progress table updated

### Critical Files
- `/Users/unfazed-mac/Developer/apps/firefly/lib/core/repositories/journal/journal_repository.dart`

---

## Completion Checklist
- [ ] All 7 phases ✅ in progress table
- [ ] Status updated to `COMPLETE`
- [ ] Move tracker to `docs/trackers/completed/infrastructure/`
- [ ] Update `docs/trackers/index.md`
- [ ] Final History entry added
- [ ] Run `verify-packages` agent for full verification

## Files

### NexusStore Core Package
| File | Phases |
|------|--------|
| `packages/nexus_store/lib/src/core/nexus_store.dart` | A1, A3, A4 |
| `packages/nexus_store/lib/src/policy/write_policy_handler.dart` | A1 |
| `packages/nexus_store/lib/nexus_store.dart` | A2 (barrel export) |

### Files to Create
| File | Phase | Purpose |
|------|-------|---------|
| `packages/nexus_store/lib/src/core/store_join.dart` | A2 | StoreJoin reactive cross-store joins |

### Firefly Repositories (B1–B3)
| File | Phase | Change |
|------|-------|--------|
| `firefly/lib/core/repositories/compliance_audit/compliance_audit_repository.dart` | B1 | `getAll()+filter` → `whereBetween`, `getAll()+sort` → `getOne` |
| `firefly/lib/core/repositories/incident/incident_repository.dart` | B2 | In-memory search → `iContains`, severity → `isIn`, reportable → `isIn` |
| `firefly/lib/core/repositories/journal/journal_repository.dart` | B3 | Redundant soft-delete check → use scoped store |

## History

| Date | Event |
|------|-------|
| 2026-03-16 | Tracker created — 7 phases (4 NexusStore API + 3 Firefly migration), ~60 estimated tests |
| 2026-03-16 | Phase A1 complete — `WritePolicyHandler.deleteAll` added, `NexusStore.deleteAll` refactored to batch delegate, 15 tests, `d262a79` |
| 2026-03-16 | Phase A2 complete — `StoreJoin` class with `combine2/3/4` and `withLatest2`, 14 tests, delta 95.8%, `8428416` |
