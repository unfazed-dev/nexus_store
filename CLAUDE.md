# CLAUDE.md - NexusStore

**NexusStore** is a reactive data layer package ecosystem for Dart/Flutter. 13 packages in a Melos monorepo providing offline-first sync, code generation, and state management bindings.

## Quick Start

```bash
melos bootstrap
melos run test:dart
melos run test:flutter
dart analyze
```

## Tech Stack

Dart 3.x | Melos monorepo | build_runner code gen | Drift | PowerSync | Supabase | Brick | CRDT | Bloc/Riverpod/Signals bindings

## Packages (13)

| Package | Purpose |
|---------|---------|
| `nexus_store` | Core reactive data layer |
| `nexus_store_drift_adapter` | Drift local storage adapter |
| `nexus_store_powersync_adapter` | PowerSync offline-first sync adapter |
| `nexus_store_supabase_adapter` | Supabase backend adapter |
| `nexus_store_brick_adapter` | Brick ORM adapter |
| `nexus_store_crdt_adapter` | CRDT conflict resolution adapter |
| `nexus_store_bloc_binding` | Bloc state management binding |
| `nexus_store_riverpod_binding` | Riverpod state management binding |
| `nexus_store_riverpod_generator` | Riverpod code generation |
| `nexus_store_signals_binding` | Signals state management binding |
| `nexus_store_flutter_widgets` | Flutter widget helpers |
| `nexus_store_generator` | Core code generator |
| `nexus_store_entity_generator` | Entity code generator |

## Where to Find Things

| What | Where |
|------|-------|
| **Coding rules** | `.claude/rules/*.md` |
| **Agent failure patterns** | `AGENTS.md` |
| **Agents** | `.claude/agents/` |
| **Hooks** | `.claude/hooks/` |
| **Progress** | `.claude/progress/` |

## Testing

- **Prefer narrow targets:** `dart test test/specific_test.dart` or `cd packages/nexus_store && dart test test/unit/store_test.dart`
- **Smart runner:** `python3 .claude/hooks/core/smart-test-run.py` (auto-detects changed files)
- **Full suite blocked** unless user explicitly requests
- Results auto-captured to `.claude/test-history/test-runs.jsonl`

## Melos CLI

```bash
melos bootstrap              # Install deps + link packages
melos run analyze             # Run dart analyze across all packages
melos run test:dart           # Run Dart-only tests
melos run test:flutter        # Run Flutter tests
melos run test:coverage       # Run tests with coverage
melos run build:runner        # Run build_runner across packages
melos run format              # Format all packages
melos run format:check        # Check formatting
melos run clean               # Clean all packages
```

## Session Lifecycle

**Start:** Read `.claude/progress/session-handoff.json` for prior context (decisions, blockers, file changes). Check `current-sprint.md` for active work.

**During:** StatusLine shows context utilization. Heed zone warnings (green/early/dumb/danger).

**End/Compaction:** `generate-handoff.py` (PreCompact hook) auto-captures decisions, blockers, and file changes. Previous handoff archived to `.claude/progress/sessions/`.

**Progress files:** `.claude/progress/` — `session-handoff.json`

## Update Protocol

When Claude makes a mistake:
1. Add DO NOT / DO line to `AGENTS.md`
2. Add detailed rule to relevant `.claude/rules/*.md` file
3. Commit: `chore: update rules with [learning]`

## Hierarchy

Scoped `CLAUDE.md` files throughout the repo provide directory-specific context. Precedence: **directory-level > root > AGENTS.md**. Packages may have their own `CLAUDE.md` for package-specific rules.
