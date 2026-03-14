# Agents

Subagents invoked via the Agent tool for specialized analysis in the nexus_store monorepo.

## All Agents (14)

| Agent | Purpose | Invoke With |
|-------|---------|-------------|
| `arch-check` | Validate package dependency direction, public API surface, no circular deps | Agent tool |
| `verify-packages` | Melos-based package verification (analyze, test:dart, test:flutter, invariants) | Agent tool |
| `dead-code` | Find unused classes, exports, and dependencies across packages | Agent tool |
| `perf-scout` | Find performance issues (N+1 queries, memory leaks, collection inefficiencies) | Agent tool |
| `pr-reviewer` | Code review against nexus_store architecture and coding standards | Agent tool |
| `test-scaffold` | Generate test file scaffolding for packages | Agent tool |
| `deps-audit` | Audit multi-package dependencies for updates, security, and consistency | Agent tool |
| `doc-gardener` | Verify documentation freshness, frontmatter validity, accuracy grades | Agent tool |
| `drift-detector` | Detect contradictions between documentation and code via git-diff analysis | Agent tool |
| `gc-agent` | Find dead docs, orphaned files, and expired harness components | Agent tool |
| `code-simplifier` | Post-implementation cleanup, DRY, reduce complexity | Agent tool |
| `prior-art` | Find existing patterns and implementations before new work | Agent tool |
| `api-surface` | Validate public API consistency across packages | Agent tool |
| `cross-package-deps` | Validate dependency graph health and detect circular deps | Agent tool |

## Context Isolation Rules

All sub-agents MUST follow these isolation rules to prevent context window exhaustion:

1. **Isolated context** — Each agent operates in its own context window. It does NOT inherit the parent session's full context beyond what is explicitly passed via the prompt.
2. **Structured JSON output** — Agent output MUST be structured JSON <=2000 tokens (summary, not raw data).
3. **Minimal input** — Agents receive ONLY: root CLAUDE.md + relevant scoped CLAUDE.md + their specific instructions.
4. **No raw file pass-back** — Agents MUST NOT pass raw file contents back — only paths, line numbers, and summaries.
5. **Chain isolation** — When chaining agents (e.g., doc-gardener -> drift-detector -> gc-agent), each receives only the prior agent's JSON summary, not its full working context.
6. **Mandatory `tools:` allowlist** — Every agent `.md` MUST declare an explicit `tools:` field listing only the tools that agent needs. Read-only agents (doc-gardener, drift-detector) should NOT have Write/Edit.

### Output Contract

All agents MUST return JSON matching this schema:

```json
{
  "status": "pass|warn|fail",
  "summary": "One-line human-readable summary",
  "files_modified": [],
  "details": [],
  "timestamp": "ISO-8601"
}
```
