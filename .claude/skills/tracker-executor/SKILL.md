---
name: tracker-executor
description: "Universal phase executor — reads any tracker, executes one phase, runs harness gates, updates progress, stops"
metadata:
  scope: core
  status: active
  review_by: "2026-09-11"
  harness_compatible: true
  referenced_by: []
  related_rules:
    - .claude/rules/git-commits.md
    - .claude/rules/architecture.md
    - .claude/rules/testing.md
    - .claude/rules/diagrams.md
  related_skills:
    - implementation-tracker
    - commit-helper
---

# Tracker Executor
> Universal phase executor — reads any tracker, identifies a phase, executes all tasks, runs harness gates, updates progress, and stops.

## Harness Integration
- **Extends:** `.claude/rules/git-commits.md` (semantic commits at phase boundaries)
- **Depends on:** `implementation-tracker` (tracker format conventions), `commit-helper` (phase-end commit workflow)
- **Orchestrator:** `pre-commit-check.sh` runs quality gates before phase commit (code trackers)
- **Orchestrator:** `verify-feature.py` checks feature completeness for Tier 2 features
- **Invariants:** 8 checks in `.claude/invariants/` — selective based on tracker type

## When to Use
- Executing any phase of any tracker in `docs/trackers/`
- Resuming work on an in-progress tracker
- Advancing a tracker to its next pending phase

## Invocation

```
/tracker-executor <tracker-path> <phase>
```

**Arguments:**
- `<tracker-path>` — Path to the `TRACKER-*.md` file
- `<phase>` — Phase number (e.g., `1`, `3`) OR `next` to auto-detect the first pending phase

**Examples:**
```
/tracker-executor docs/trackers/in_progress/documentation/TRACKER-flow-documentation-redesign.md next
/tracker-executor docs/trackers/in_progress/onboarding/TRACKER-onboarding-submit-fix.md 1
/tracker-executor docs/trackers/backlog/kinly/TRACKER-kinly-wallet.md 0
```

If `<phase>` is omitted, ask the user: "Which phase? Provide a number or `next` for the first pending phase."

---

## Execution Workflow

### Step 0: Parse Tracker

1. Read the tracker file at `<tracker-path>`
2. Extract:
   - **Title** from `# TRACKER:` heading
   - **Status** from `## Status:`
   - **Progress table** from `### Overview` (or `## Progress` > `### Overview`)
   - **All phase sections** — heading-level tolerant: match `Phase N` at any heading level (`##`, `###`, `####`)
   - **Skills & Agents table** from `## Skills & Agents by Phase` (if present)
   - **Completion Checklist** from `## Completion Checklist` (if present)
3. **Detect tracker type** from progress table header:
   - `Tests` column → **Code tracker** (TDD mode, full invariant suite)
   - `Diagrams` column → **Doc tracker** (validation mode, selective invariants)
   - `Tasks` column → **Generic tracker** (task execution, selective invariants)

### Step 1: Resolve Target Phase

- If `<phase>` is a number: use that phase directly
- If `<phase>` is `next`: scan progress table for the first row with `⏳ Pending` or `🔄 In Progress`
- If no pending phases: report "All phases complete" and STOP

**Validation:**
- If previous phase is NOT `✅ Complete`: WARN user (do not block — some trackers allow parallel phases)
- If target phase is already `✅ Complete`: ASK user if they want to re-execute
- If tracker is in `backlog/` folder: move to `in_progress/`, update `docs/trackers/index.md`

### Step 2: Extract Phase Details

Parse the target phase section. Handle subsection name variants tolerantly:

| Look For | Accepted Variants |
|----------|-------------------|
| Pre-Implementation | `Pre-Implementation Checklist`, `Pre-Implementation` |
| Tasks | `Tasks`, `Diagrams to Create`, `Files to Create` |
| Files to Modify | `Files to Modify`, `Files Modified` |
| Post-Phase | `Post-Phase`, `Post-Implementation`, `Post-Implementation Checklist` |
| Harness Checkpoint | `Harness Verification Checkpoint` |

### Step 3: Invoke Listed Skills

1. Read the **Skills & Agents by Phase** table (if present)
2. Invoke all skills listed for the target phase AND the `ALL phases` / `Every phase end` row
3. Note listed agents for reference — do NOT auto-invoke agents (they are task-triggered)
4. ALWAYS load `/commit-helper` context (needed at phase end, even if not listed)

If no Skills & Agents table exists: skip skill invocations, still load `/commit-helper`.

### Step 4: Pre-Implementation Checklist

If a Pre-Implementation section exists:
1. Read referenced source code files
2. Invoke any additional skills listed in checklist items
3. Verify prior phase status in the progress table
4. Report pre-implementation status to user

If no Pre-Implementation section exists: skip to Step 5.

### Step 5: Execute Phase Tasks

Execute each task in the Tasks/Diagrams/Files section.

**By tracker type:**

| Type | Execution Mode | Hook Behavior |
|------|---------------|---------------|
| Code | TDD: write tests BEFORE implementation. Run `smart-test-run.py` after each task group | All PostToolUse hooks fire on .dart Edit/Write: dart-format, organize-imports, lint-check, invariant-check, doc-freshness |
| Doc | Create files sequentially. Follow `.claude/rules/diagrams.md` for diagram files | invariant-check + doc-freshness hooks fire on .md edits in `lib/` or scanned `docs/` subdirs |
| Generic | Execute tasks per checklist. Follow `.claude/rules/*.md` | Hooks fire based on file type edited |

**Frontmatter rules by directory** (enforced by `verification-frontmatter.dart`):

The invariant scans these `docRoots` directories ONLY:
- `docs/features/`, `docs/domain/`, `docs/architecture/`, `docs/design-system/`, `docs/guides/`, `docs/database_users/`, `docs/role-system/`, `lib/`
- Files in these dirs MUST have YAML frontmatter: `status`, `verified_date`, `verified_by`

Directories NOT in `docRoots` (no frontmatter required):
- `docs/diagrams/` — diagram files validated by `validate-mermaid.sh` instead
- `docs/trackers/` — explicitly skipped by the invariant

**For FLOWS.md modifications** (enforced by `flow-route-sync.dart`):
- Any modified `FLOWS.md` must have `route_hash` in frontmatter matching SHA-256 of route definition files
- Run `python3 .claude/hooks/core/update-route-hashes.py` to auto-update hashes before committing

**For diagram files** (enforced by `.claude/rules/diagrams.md`):
- Theme init block (`%%{init: ...}%%`) on supported types: flowchart, sequenceDiagram, stateDiagram-v2, block-beta
- 8-class classDef palette for flowchart/stateDiagram: `start`, `process`, `success`, `warning`, `error`, `info`, `neutral`, `critical`
- Accessibility metadata per diagram type:
  - flowchart, sequenceDiagram, stateDiagram-v2, gantt, C4: `accTitle` + `accDescr`
  - ER diagrams: YAML frontmatter `title:` (no accTitle/accDescr support)
  - journey, mindmap, pie, timeline: `title` directive
- Portal colors: Customer `#ede9fe`, Services Hub `#dbeafe`, Administration `#dcfce7`, Shared `#f1f5f9`
- Error/cancellation paths required in all state diagrams
- YES/NO labels required on all flowchart decision diamonds
- Cross-references between related diagrams must be bidirectional

### Step 6: Post-Implementation Checklist

If a Post-Phase/Post-Implementation section exists:
1. Walk through each checklist item
2. Verify all tasks are complete
3. Run any listed verification commands

### Step 7: Harness Verification Gate

**Decision tree:**

```
1. Tracker-specific harness checkpoint?
   ├── YES → Run those bash commands FIRST
   └── NO  → Skip to step 2

2. Tracker type?
   ├── Code → bash .claude/orchestrators/pre-commit-check.sh
   │          Must output: {"accepted": true}
   │          (runs: dart format + flutter analyze + all 8 invariants)
   │
   │          Tier 2 feature? → python3 .claude/orchestrators/verify-feature.py <portal>/<feature>
   │          Must output: {"accepted": true}
   │
   ├── Doc  → Selective checks based on what was modified:
   │          - FLOWS.md in lib/ modified?
   │            → dart run .claude/invariants/flow-route-sync.dart
   │          - Docs in docRoots dirs modified?
   │            → dart run .claude/invariants/verification-frontmatter.dart
   │          - Diagram files in docs/diagrams/ ONLY?
   │            → Tracker-specific harness only (no invariants apply to docs/diagrams/)
   │
   └── Generic → bash .claude/orchestrators/pre-commit-check.sh (if Dart files touched)
                 Otherwise: selective invariants based on files modified
```

**Orchestrator output contract** — verify this structure:
```json
{
  "status": "pass|fail|warn",
  "checks": {},
  "recommendation": "string",
  "action_needed": false,
  "details": [],
  "accepted": true
}
```

If any gate outputs `"accepted": false`: fix issues and re-run. Do NOT skip or bypass.

### Step 8: Register in Doc-Source-Map

For new files that document source code behavior, add entries to `.claude/doc-source-map.json`:
```json
{
  "docs/diagrams/flows/auth-login-flow.md": [
    "lib/portals/shared/features/auth/**/*.dart"
  ]
}
```

**Add when:** Diagram/doc files that describe code behavior (flows, sequences, architecture diagrams).
**Skip when:** Pure index files (README.md), style guides, mindmaps, treemaps with no code mapping.

### Step 9: Update Tracker

Update the tracker file with these changes:

1. **Progress table row** for this phase:
   - Status: `✅ Complete`
   - Tests/Tasks/Diagrams: actual count achieved
   - Committed: `⏳` (updated to commit hash in Step 10)
   - Last Updated: today's date (`YYYY-MM-DD`)

2. **Progress bar**: Recalculate `(completed phases / total phases) * 100%`
   - Use block characters: `█` (filled) and `░` (empty), 16 blocks total

3. **Aggregate counters**: If tracker has secondary counters (e.g., `**Diagrams:** 0 of 85 created`, `**Tests:** N passing`), update the running total

4. **Progress Log**: Add session entry:
   ```
   **Phase N Results (YYYY-MM-DD):**
   - [Summary of work done]
   - [Counts: tests/tasks/diagrams created]
   - [Harness result: accepted/issues]
   - [Key decisions or issues encountered]
   ```

5. **Current State block**: Update:
   - Working on: `COMPLETE (Phase N)`
   - Last completed: `Phase N — [description]`
   - Next up: `Phase N+1 — [description]` (or `N/A` if last phase)

6. **Checkboxes**: All `- [ ]` → `- [x]` for completed items in the phase

7. **History table**: Add row with date, action, and details

### Step 10: Commit

1. Stage specific files — NEVER use `git add -A` or `git add .`
2. Semantic commit message (single-line, no HEREDOC, no Co-Authored-By):
   - Code phases: `feat: phase N — [tracker name] [description]`
   - Doc phases: `docs: phase N — [tracker name] [description]`
   - Mixed/audit: `chore: phase N — [tracker name] [description]`
3. `strip-commit-attribution.py` hook fires automatically
4. Update tracker: set Committed column to short commit hash
5. If commit fails due to pre-commit hook: fix issues and create a NEW commit (never amend)

### Step 11: HARD STOP

Report to user:
- Phase N completed (or with issues)
- Task/test/diagram counts (estimated vs actual if available)
- Harness verification result
- Next phase summary (name + count of items)
- Instruction: "Run `/tracker-executor <path> next` to continue with Phase N+1"

**NEVER auto-advance to the next phase. NEVER start Phase N+1 work.**

---

## Edge Cases

| Scenario | Action |
|----------|--------|
| No Skills & Agents table | Skip Step 3 skill invocations (still load `/commit-helper`) |
| No Pre-Implementation section | Skip Step 4, proceed to tasks |
| No Harness Verification section | Use type-specific defaults from Step 7 decision tree |
| Tracker in `backlog/` folder | Move to `in_progress/`, update `docs/trackers/index.md` |
| Phase already `✅ Complete` | Ask user: "Phase N is already complete. Re-execute?" |
| Last phase completing | Run Completion Checklist, set status `COMPLETE`, move to `docs/trackers/completed/[category]/`, update index |
| New doc files created | Register source-mapped ones in `.claude/doc-source-map.json` (Step 8) |
| PostToolUse hooks fire during edits | Expected — dart-format, lint-check, invariant-check fire automatically. Do NOT duplicate their work manually |
| Phase has no checkboxes | Some older trackers use prose tasks. Execute the work, add completion note to progress log |

## Anti-Patterns
- Auto-advancing to the next phase without user instruction
- Skipping harness verification when the tracker specifies it
- Using `git add -A` or `git add .` instead of staging specific files
- Running `dart format` / `flutter analyze` manually (hooks + orchestrator handle this)
- Creating docs in `docRoots` dirs without YAML frontmatter
- Modifying phases other than the target phase
- Amending commits after hook failure (create NEW commit instead)
- Invoking agents listed in Skills & Agents table automatically (agents are task-triggered, not phase-triggered)

## References
- Tracker template: `.claude/skills/implementation-tracker/SKILL.md`
- Commit workflow: `.claude/skills/commit-helper/SKILL.md`
- Pre-commit gate: `.claude/orchestrators/pre-commit-check.sh`
- Feature verify: `.claude/orchestrators/verify-feature.py`
- Mermaid validate: `.claude/skills/mermaid-diagrams/scripts/validate-mermaid.sh`
- All trackers: `docs/trackers/`
- Tracker index: `docs/trackers/index.md`
- Doc-source-map: `.claude/doc-source-map.json`
- Project rules: `.claude/rules/` (12 rule files)
- Invariants: `.claude/invariants/` (8 invariant files)
