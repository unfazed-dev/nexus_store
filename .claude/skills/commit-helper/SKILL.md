---
name: commit-helper
description: "Semantic commit workflow with pre-commit quality gates and attribution stripping"
metadata:
  scope: core
  status: active
  review_by: "2026-06-09"
  harness_compatible: true
  referenced_by:
    - verify-app
    - tracker-executor
  related_rules:
    - .claude/rules/git-commits.md
---

# Commit Helper
> Semantic commit generator with mandatory pre-commit quality gates — format, analyze, invariants.

## Harness Integration
- **Extends:** `.claude/rules/git-commits.md` (semantic commits, migration rules)
- **Agent:** `verify-app` references commit-helper for pre-commit validation
- **Orchestrator:** `.claude/orchestrators/pre-commit-check.sh` runs the 3 quality gates
- **Hook:** `.claude/hooks/core/strip-commit-attribution.py` auto-strips Claude attribution

## When to Use
- Before every commit — run pre-commit check
- Writing commit messages — follow semantic format
- Commits involving migrations — verify local SQL files exist

## Workflow

1. **Analyze changes:** Run `git status` and `git diff --staged` (and `git diff` for unstaged) to understand what changed
2. **Stage files:** Add relevant files to staging (prefer specific files over `git add -A`)
3. **Generate options:** Create 3 commit message options with different phrasings, all following semantic format
4. **Present to user:** Use `AskUserQuestion` to show the 3 options and let the user pick one, modify one, or provide their own
5. **Commit:** Run `git commit -m "chosen message"` with the user's selection

Example AskUserQuestion format:
```
Which commit message would you like to use?

1. `feat: add wallet top-up flow with MCQ confirmation`
2. `feat: implement prepaid credit top-up via Kinly Wallet`
3. `feat: add MCQ-based wallet funding with confirmation sheet`

Pick a number, edit one, or write your own.
```

## Pre-Commit Quality Gates

```bash
# Run the orchestrator:
bash .claude/orchestrators/pre-commit-check.sh

# It runs 3 sequential checks:
# 1. dart format --set-exit-if-changed .
# 2. flutter analyze (fail on errors)
# 3. All .dart invariants in .claude/invariants/
```

Output is JSON:
```json
{
  "status": "pass|fail",
  "accepted": true,
  "proof": ["format", "analyze", "invariants"],
  "details": []
}
```

## 8 Invariants (run by pre-commit)

| Invariant | Rule |
|-----------|------|
| `layer-deps.dart` | No service/repo imports in views |
| `import-paths.dart` | No cross-portal imports |
| `booking-model.dart` | No Appointment references |
| `interface-naming.dart` | `InterfaceXxx` not `IXxx` |
| `spacing-lint.dart` | No raw SizedBox for spacing |
| `subscription-ban.dart` | No Stripe/subscription code |
| `flow-route-sync.dart` | Flow docs match route config |
| `verification-frontmatter.dart` | Required frontmatter in docs |

## Commit Message Format

Commit messages MUST be single-line: `git commit -m "type: description"`
- DO NOT use HEREDOC format or multi-line body
- DO NOT add Co-Authored-By or extended descriptions
- The hook will strip any body text beyond the first line

```
# Format: git commit -m "type: description"
# Types: feat, fix, refactor, test, chore, docs
# Examples:
git commit -m "feat: add wallet top-up flow with MCQ confirmation"
git commit -m "fix: resolve PowerSync CRUD queue race condition in auth"
git commit -m "refactor: extract booking status transitions to dedicated service"
git commit --amend -m "chore: update rules with booking model naming convention"
```

## Rules
- Single-line messages ONLY — NO body, NO footer, NO HEREDOC
- NO `Co-Authored-By: Claude` — stripped automatically by hook
- NO generic messages (`fix bug`, `update code`)
- Migration commits MUST include local SQL file in `supabase/migrations/`
- PowerSync changes MUST update `powersync/sync-rules.yaml`

## Commit Message Hook
The `strip-commit-attribution.py` hook (PreToolUse on Bash) automatically:
- Collapses multi-line commit messages to the first line only
- Converts HEREDOC format to simple `-m "message"` format
- Strips `Co-Authored-By: Claude` attribution
- Strips `🤖 Generated with [Claude Code]` from PR bodies

## References
- Git rules: `.claude/rules/git-commits.md`
- Pre-commit orchestrator: `.claude/orchestrators/pre-commit-check.sh`
- Attribution hook: `.claude/hooks/core/strip-commit-attribution.py`
- Invariants: `.claude/invariants/`
