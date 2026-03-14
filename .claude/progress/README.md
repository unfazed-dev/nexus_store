# Progress Directory

Session state and harness metrics for the nexus_store Claude harness.

## Files

| File | Purpose |
|------|---------|
| `session-handoff.json` | Last session context (decisions, blockers, file changes) |
| `session-handoff.schema.json` | JSON schema for handoff validation |
| `current-sprint.md` | Active work items and blockers |
| `harness-metrics.json` | Harness health: invariants, hooks, agents, rules |
| `sessions/` | Archived session handoffs |

## Session Lifecycle

**Start:** Read `session-handoff.json` + `current-sprint.md` to orient.

**During:** Work normally. Decisions and blockers accumulate in context.

**Compaction/End:** `generate-handoff.py` (PreCompact hook) extracts decisions/blockers/changes from transcript, writes `session-handoff.json`, archives previous handoff to `sessions/`.
