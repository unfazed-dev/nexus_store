# TRACKER: NexusStore API Enhancement Phase 2

## Status: IN_PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| A1. `getOne()` / `findBy()` | ✅ Complete | 20 | — | f547fdc | 2026-03-16 |
| A2. Query Scopes (Soft-Delete, Owner) | ✅ Complete | 22 | — | d3c9198 | 2026-03-16 |
| A3. Case-Insensitive Search | ✅ Complete | 14 | — | a57dc06 | 2026-03-16 |
| A4. Mutation Lifecycle Hooks | ✅ Complete | 22 | — | 7f2f748 | 2026-03-16 |
| A5. Background Refetch Manager | ✅ Complete | 16 | — | 03d4861 | 2026-03-16 |
| B1. Firefly Repo Migration (Phase 2) | ⏳ Deferred | — | — | — | — |
| C1. Cross-Adapter Composition Tests | ✅ Complete | 21 | — | 88fbf2f | 2026-03-16 |
| C2. Brick Adapter Test Parity | ⏭️ Skipped | — | — | — | 2026-03-16 |
| C3. Architecture Invariant Validators | ✅ Complete | 3 self-tests | — | 352774f | 2026-03-16 |

**Overall:** ████████████████ 78% complete (7/9 phases done)
**Tests:** 115 passing + 3 invariant self-tests | 118 total (target: ~167)

### Progress Log

**Current State (2026-03-16):**
- Working on: Complete (7/9 phases)
- Deferred: B1 (Firefly migration — requires Firefly repo alignment)
- Skipped: C2 (Brick adapter already has 2726 lines / 49 tests — exceeds parity target)
- Next up: B1 when Firefly repos are updated

### Decisions
- A5: RefetchConfig passed as standalone class instead of embedding in freezed StoreConfig (avoids build_runner regeneration)
- A4: mutateDelete skips onSuccess callback since delete returns bool, not entity T
- C2: Skipped — brick adapter already has 2726 lines of tests across 6 files, well beyond the 11-test parity target

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
| 2026-03-16 | Phase C2 skipped — brick adapter already exceeds parity target |
