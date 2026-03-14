# Git Commit Rules

## Message Format
- Single-line only: `git commit -m "type: description"` — NO body, NO footer, NO HEREDOC
- Use semantic commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`
- NO "Co-Authored-By: Claude" (hook strips this automatically)
- NO generic messages like "fix bug" or "update code"
- Hook enforces single-line: multi-line messages are collapsed to first line

## Scope Convention
- Use package name as scope when change is package-specific: `feat(nexus_store): add batch upsert`
- Omit scope for cross-cutting changes: `chore: update melos config`

## Enforcement
- **Hook:** `.claude/hooks/core/strip-commit-attribution.py` — strips Co-Authored-By lines, collapses multi-line messages
- **Orchestrator:** `.claude/orchestrators/pre-commit-check.sh` — format + analyze + invariants gate before commit
- **Manual only:** Semantic prefix choice is not automatically enforced
