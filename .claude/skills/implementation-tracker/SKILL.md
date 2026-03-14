---
name: implementation-tracker
description: "Phase-gated implementation tracking with harness verification checkpoints"
metadata:
  scope: core
  status: active
  review_by: "2026-06-09"
  harness_compatible: true
  referenced_by:
    - flow-checker
    - tracker-executor
  related_rules:
    - .claude/rules/git-commits.md
    - .claude/rules/architecture.md
    - .claude/rules/testing.md
    - .claude/rules/diagrams.md
---

# Implementation Tracker
> Phase-gated feature implementation workflow — tracker templates, harness verification checkpoints, orchestrator integration.

## Harness Integration
- **Extends:** `.claude/rules/git-commits.md` (semantic commits required at phase boundaries)
- **Agent:** `flow-checker` validates tracker phases against code implementation and flow docs
- **Orchestrator:** `verify-feature.py` checks feature completeness (code, docs, tests, invariants)
- **Orchestrator:** `pre-commit-check.sh` runs quality gates at each phase commit
- **Invariants:** 8 checks in `.claude/invariants/` — layer-deps, import-paths, booking-model, subscription-ban, interface-naming, spacing-lint, flow-route-sync, verification-frontmatter

## When to Use
- Starting a new feature implementation
- Tracking multi-phase work (design → implement → test → verify)
- Running harness verification at phase boundaries
- Documenting implementation decisions and file changes

## Tracker Template

```markdown
# TRACKER: [Feature Name]

## Status: IN_PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Committed | Last Updated |
|-------|--------|-------|-----------|--------------|
| 0. Documentation | ✅ Complete | 0 | ✅ | YYYY-MM-DD |
| 1. Data Layer | 🔄 In Progress | 12 | ⏳ | YYYY-MM-DD |
| 2. Service Layer | ⏳ Pending | — | — | — |
| 3. UI Layer | ⏳ Pending | — | — | — |
| 4. GenUI Integration | ⏳ Pending | — | — | — |

**Overall:** ░░░░░░░░░░░░░░░░ 0% complete
**Tests:** 0 passing | 0 failing

### Progress Log

**Current State (YYYY-MM-DD):**
- Working on: [current task or COMPLETE]
- Last completed: [phase/action]
- Blocked by: [blocker or Nothing]
- Next up: [next action or N/A]

**Session N (YYYY-MM-DD):**
- [What was done, test counts, key decisions]

## Overview

Brief description of the feature and its scope.

## Skills & Agents by Phase

| Phase | Skills | Agents |
|-------|--------|--------|
| 0. Documentation | `/flutter-app-blueprint`, `/mermaid-diagrams` | `prior-art`, `flow-checker` |
| 1. Data Layer | `/supabase-flutter-stacked`, `/nexus-store` | `migration-planner`, `arch-check`, `test-scaffold` |
| 2. Service Layer | `/stacked` | `arch-check`, `test-scaffold` |
| 3. UI Layer | `/stacked`, `/flutter-ui-patterns` | `widget-finder`, `arch-check`, `test-scaffold` |
| 4. GenUI Integration | `/genui` | `test-scaffold` |
| **Every phase end** | `/commit-helper` | `verify-app` |

---

## Phase 0: Documentation

### Pre-Implementation Checklist
- [ ] Read existing code/docs for the area
- [ ] Identify reusable patterns (run `prior-art` agent)
- [ ] Load `/flutter-app-blueprint` for scoped CLAUDE.md and FLOWS.md patterns

### Tasks
- [ ] Create scoped `CLAUDE.md` (route card)
- [ ] Create `FLOWS.md` with Mermaid diagrams (use `/mermaid-diagrams`)
- [ ] Update `doc-source-map.json`
- [ ] Create `README.md` for Tier 2 features

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tracker progress table updated
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `chore: phase 0 — [feature] documentation`

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
```

### Files Modified
- `lib/portals/.../CLAUDE.md` (new)
- `docs/features/.../FLOWS.md` (new)

---

## Phase 1: Data Layer

### Pre-Implementation Checklist
- [ ] Phase 0 complete and committed

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for repository test scaffolding
- [ ] Write unit tests for model serialization
- [ ] Write unit tests for repository interface methods
- [ ] Verify tests FAIL

#### GREEN: Implement
- [ ] Create migration: `supabase/migrations/YYYYMMDD_feature.sql`
- [ ] Update sync rules: `powersync/sync-rules.yaml`
- [ ] Create model: `lib/core/models/feature.dart`
- [ ] Create repository interface + implementation (use `InterfaceXxxRepository` naming)
- [ ] Register in DI locator
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~N)
- [ ] Tracker progress table updated
- [ ] Coverage >= 95% for changed packages
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 1 — [feature] data layer`

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
python3 .claude/orchestrators/verify-feature.py portal/feature
# Must pass: code_exists, claude_md_exists, has_tests
```

### Files Modified
- `supabase/migrations/YYYYMMDD_feature.sql`
- `lib/core/models/feature.dart`
- `lib/core/repositories/feature/`
- ...

---

## Phase 2: Service Layer

### Pre-Implementation Checklist
- [ ] Phase 1 complete and committed

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for service test scaffolding
- [ ] Write unit tests for service methods (mock repository)
- [ ] Verify tests FAIL

#### GREEN: Implement
- [ ] Create service with `ListenableServiceMixin` + `BehaviorSubject`
- [ ] Inject repository via `locator<InterfaceXxxRepository>()`
- [ ] Register service in DI locator
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~N)
- [ ] Tracker progress table updated
- [ ] Coverage >= 95% for changed packages
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 2 — [feature] service layer`

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
python3 .claude/orchestrators/verify-feature.py portal/feature
# Must pass: code_exists, claude_md_exists, has_tests
```

### Files Modified
- `lib/portals/.../services/feature_service.dart`
- ...

---

## Phase 3: UI Layer

### Pre-Implementation Checklist
- [ ] Phase 2 complete and committed
- [ ] Run `widget-finder` agent to identify reusable widgets

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for widget test scaffolding
- [ ] Write widget tests for view rendering and interactions
- [ ] Verify tests FAIL

#### GREEN: Implement
- [ ] Create view + viewmodel: `stacked create view feature_name`
- [ ] Wire viewmodel to service via `locator<FeatureService>()`
- [ ] Use `KinlySpacing` tokens for all spacing (no raw `SizedBox`)
- [ ] Use `setBusy()` / `setBusyForObject()` for loading states
- [ ] Use `RouterService` for navigation
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~N)
- [ ] Tracker progress table updated
- [ ] Coverage >= 95% for changed packages
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 3 — [feature] UI layer`

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
python3 .claude/orchestrators/verify-feature.py portal/feature
# Must pass: code_exists, claude_md_exists, has_tests
```

### Files Modified
- `lib/portals/.../views/feature/feature_view.dart`
- `lib/portals/.../views/feature/feature_viewmodel.dart`
- ...

---

## Phase 4: GenUI Integration

### Pre-Implementation Checklist
- [ ] Phase 3 complete and committed

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for provider test scaffolding
- [ ] Write provider unit tests for data provider methods
- [ ] Verify tests FAIL

#### GREEN: Implement
- [ ] Create `EntityDataProvider` (use `/genui` skill)
- [ ] Register provider in `EntityDataRegistry`
- [ ] Create MCQ catalog entries
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~N)
- [ ] Tracker progress table updated
- [ ] Coverage >= 95% for changed packages
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 4 — [feature] GenUI integration`

### Harness Verification Checkpoint
```bash
bash .claude/orchestrators/pre-commit-check.sh
# Must output: "accepted": true
python3 .claude/orchestrators/verify-feature.py portal/feature
# Must pass: code_exists, claude_md_exists, has_tests
```

### Files Modified
- `lib/genui/data/providers/feature_data_provider.dart`
- `lib/genui/data/entity_data_registry.dart`
- ...

---

## Completion Checklist
- [ ] All phases ✅ in progress table
- [ ] Status updated to `COMPLETE`
- [ ] Move tracker to `docs/trackers/completed/[category]/`
- [ ] Update `docs/trackers/index.md`
- [ ] Final History entry added
- [ ] Run `verify-app` agent for full verification

## Files

### Files to Create
| File | Purpose |
|------|---------|
| `lib/core/models/feature.dart` | Feature model |
| `lib/core/repositories/feature/` | Repository + interface |
| `lib/portals/.../services/feature_service.dart` | Service layer |
| `lib/portals/.../views/feature/` | View + ViewModel |
| `lib/genui/data/providers/feature_data_provider.dart` | GenUI provider |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/app/app.dart` | Register in DI locator |
| `lib/genui/data/entity_data_registry.dart` | Register provider |

## History

| Date | Action | Details |
|------|--------|---------|
| YYYY-MM-DD | Created | Initial tracker |
```

## Template Variants

The default template uses "Tests" as the metric column. Substitute based on work type:

| Variant | Metric Column | When to Use |
|---------|---------------|-------------|
| **Standard** | Tests | Code features, UI, services |
| **Task-based** | Tasks | Documentation, harness audits, refactoring |

## TDD Task Structure (Code Trackers)

Code trackers (with a `Tests` column) MUST use RED-GREEN-REFACTOR substep structure in every phase:

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for test file scaffolding
- [ ] Write test cases for [behavior 1]
- [ ] Write test cases for [behavior 2]
- [ ] Verify all new tests FAIL (`dart test` — expect failures)

#### GREEN: Implement Minimum Code
- [ ] Implement [component 1] to pass tests
- [ ] Implement [component 2] to pass tests
- [ ] Verify all tests PASS (`dart test`)

#### REFACTOR: Clean Up
- [ ] Refactor while keeping tests green
- [ ] Run `smart-test-run.py` — no regressions

## Tracker Lifecycle

| Status | Folder |
|--------|--------|
| PLANNING, BLOCKED | `docs/trackers/backlog/[category]/` |
| IN_PROGRESS, REVIEW | `docs/trackers/in_progress/[category]/` |
| COMPLETE, DONE | `docs/trackers/completed/[category]/` |

Always update `docs/trackers/index.md` when creating or moving trackers.

### Handling Blocked State
When a phase is blocked:
1. Update Progress Log with blocker description
2. Set phase status to `⏳ Blocked` in progress table
3. Move tracker to `docs/trackers/backlog/[category]/` if blocked long-term
4. Update `docs/trackers/index.md`
5. When unblocked: resume from the blocked phase, update Progress Log

## Harness Verification at Phase Boundaries

Every phase commit MUST:
1. Run `pre-commit-check.sh` → `"accepted": true`
2. Pass all 8 invariants
3. Have tests for the phase's implementation
4. Update tracker progress table

### Phase Gate Criteria (Definition of Done)
Each phase boundary should have explicit gate criteria:
- **Code gate:** All tasks checked, files listed in "Files Modified"
- **Test gate:** Estimated vs actual test count tracked (e.g., "Tests: 12 estimated / 15 actual")
- **Coverage gate:** Changed packages meet 95% line coverage
- **Quality gate:** Pre-commit check passes, no regressions
- **Doc gate:** Tracker progress table updated, History row added

For Tier 2 features (complex, multi-portal):
- Run `verify-feature.py portal/feature` at each phase end
- Ensure scoped `CLAUDE.md` exists with valid frontmatter
- `README.md` required for Tier 2 features

### Tier 2 Features
Bookings, wallet, funds, invoices, managed_participants, onboarding, trust_fund, clm_portfolio, compliance, contracts — across customer, services_hub, and administration portals.

## Anti-Patterns
- Skipping harness verification between phases
- Committing phase work without running pre-commit check
- Not updating tracker progress table after phase completion
- Creating trackers without adding to `docs/trackers/index.md`
- Using PRD/TECH-SPEC documents (use scoped CLAUDE.md instead)
- Omitting Progress Log section (critical for session resumption context)
- Omitting Skills & Agents by Phase table for multi-phase features
- Missing Pre/Post-Implementation Checklists on gate-critical phases
- Missing combined Files section (Files to Create / Files to Modify) at bottom
- Missing Completion Checklist (trackers stall at "done but not closed")
- Listing implementation tasks before test tasks in Code trackers (violates TDD)
- Omitting RED/GREEN/REFACTOR substep structure in Code tracker phases
- Committing without 95% coverage for changed packages
- Excluding files to inflate coverage numbers

## References
- Verify feature: `.claude/orchestrators/verify-feature.py`
- Pre-commit: `.claude/orchestrators/pre-commit-check.sh`
- Flow checker agent: `.claude/agents/flow-checker.md`
- Invariants: `.claude/invariants/` (8 checks)
- Tracker index: `docs/trackers/index.md`
- All trackers: `docs/trackers/`
