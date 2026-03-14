# TRACKER: NexusStore Core Coverage Improvement

## Status: COMPLETE

## Summary

**Goal:** Bring `nexus_store` core package from failing coverage gate to 95%+ threshold.

**Finding:** The original plan estimated 61% coverage requiring ~78 new tests across 8 phases. Investigation revealed that the 61% figure included generated `.g.dart`/`.freezed.dart` files. The `check-coverage.py` script already filters these — hand-written code was at **98.01%** (4374/4463 lines).

**Root cause of gate failure:** Two flaky tests caused `dart test` to exit with code 1, which the coverage script treated as "tests failed" (0% coverage).

## Progress

### Overview
| Phase | Status | Description | Last Updated |
|-------|--------|-------------|--------------|
| 0. Baseline | ✅ Complete | Verified actual coverage: 98.01% (excl. generated) | 2026-03-15 |
| 1. Fix flaky tests | ✅ Complete | Fixed 2 tests causing gate failure | 2026-03-15 |

## Fixes Applied

### Fix 1: ConnectionPool tearDown LateInitializationError
- **File:** `test/src/pool/connection_pool_test.dart`
- **Problem:** `tearDown` accessed `late ConnectionPool pool` which was never assigned by the "should trim idle connections with real time wait" test (it used its own local `testPool`)
- **Fix:** Wrapped `tearDown` body in try-catch to handle `LateInitializationError`

### Fix 2: Transaction timeout test race condition
- **File:** `test/src/core/nexus_store_test.dart`
- **Problem:** `tx.save()` executed after transaction had already timed out and rolled back, causing "test failed after it had already completed" error
- **Fix:** Replaced `Future.delayed(200ms) + tx.save()` with `Completer<void>().future` (never completes, cleanly times out)

## Coverage Results

| Metric | Before Fix | After Fix |
|--------|-----------|-----------|
| Gate result | FAIL (0.0%) | PASS (98.01%) |
| Hand-written lines | 4374/4463 | 4374/4463 |
| Generated lines | 1187/4649 (25.5%) | unchanged |
| Overall (incl. generated) | 5561/9112 (61.0%) | unchanged |

### Files under 95% (9 remaining, 89 uncovered lines)
| File | Coverage | Uncovered |
|------|----------|-----------|
| `query/annotations.dart` | 0/1 (0%) | 1 |
| `sync/conflict_action.dart` | 11/28 (39.3%) | 17 |
| `interceptors/interceptor_context.dart` | 13/20 (65.0%) | 7 |
| `coordination/saga_result.dart` | 66/78 (84.6%) | 12 |
| `compliance/consent_record.dart` | 9/10 (90.0%) | 1 |
| `core/store_backend.dart` | 36/39 (92.3%) | 3 |
| `state/nexus_registry.dart` | 40/43 (93.0%) | 3 |
| `core/nexus_store.dart` | 395/421 (93.8%) | 26 |
| `interceptors/timing_interceptor.dart` | 32/34 (94.1%) | 2 |

## Conclusion

No new tests were needed. The coverage gate was failing due to flaky tests, not insufficient coverage. The 8-phase test-writing plan was based on misreading overall coverage (including generated files) as hand-written coverage.
