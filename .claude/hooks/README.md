# Hooks

Claude Code hooks that run before/after tool invocations.

## core/
All hooks are generic Flutter/Dart tooling (no Firefly-specific logic).
Each script contains a `# Hook Contract:` block documenting its Event, Input, Output, Side effects, and Dependencies.

### PreToolUse (Bash)
| Hook | Purpose |
|------|---------|
| `inject-test-reporter.py` | Redirect full-suite `flutter test` → `smart-test-run.py`; passthrough targeted runs with `--file-reporter` |
| `strip-commit-attribution.py` | Remove Claude attribution from commit messages |

### PreToolUse (Edit / Write)
| Hook | Purpose |
|------|---------|
| `pre-edit-guard.py` | Validate edits against invariant rules before write |

### PostToolUse (Edit / Write)
| Hook | Purpose |
|------|---------|
| `dart-format-post-edit.py` | Auto-format Dart files after edits |
| `organize-imports-post-edit.py` | Sort and organize imports after edits |
| `lint-check-post-edit.py` | Run lint checks after edits |
| `invariant-check-post-edit.py` | Run relevant invariants after source edits |
| `doc-freshness-check.py` | Flag stale docs when mapped source files change |

### PostToolUse (Bash)
| Hook | Purpose |
|------|---------|
| `capture-test-results.py` | Parse test JSON reports → `test-runs.jsonl` |

### PreCompact
| Hook | Purpose |
|------|---------|
| `generate-handoff.py` | Extract decisions/blockers/changes from transcript, write session-handoff.json |

### SubagentStop
| Hook | Purpose |
|------|---------|
| `subagent-output-guard.py` | Validate sub-agent output is JSON, ≤2000 tokens, has required fields |

### StatusLine
| Script | Purpose |
|--------|---------|
| `context-budget.py` | Real-time context utilization monitor with graduated zone warnings |

### Supporting Scripts (Manual-Invoke Utilities)

These scripts are NOT registered as hooks in `settings.json`. They are invoked manually from the command line or called by other scripts:

| Script | Purpose | Invoked By |
|--------|---------|------------|
| `smart-test-run.py` | Git-diff analysis + content-hash caching test runner | `inject-test-reporter.py` / manual |
| `build-test-map.py` | Build test dependency map (`test-map.json`) | Manual |
| `test-cache.py` | SHA-256 composite hash test cache management | `smart-test-run.py` / manual |
| `test-dashboard.py` | One-liner test run summary | Manual |
| `rerun-failures.py` | Re-run previously failed tests | Manual |
| `update-route-hashes.py` | Update route_hash in all FLOWS.md files | Manual |
| `backfill-code-hashes.py` | Backfill `code_hash` in doc frontmatter | Manual (one-time/periodic) |
