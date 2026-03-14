# .claude/ Directory Structure

Claude Code configuration, skills, agents, hooks, and rules for the nexus_store monorepo.

## Structure

```
.claude/
├── settings.json          # Team-shared: hooks, permissions, MCP (committed to git)
├── settings.local.json    # Personal overrides (gitignored)
├── rules/                 # Path-scoped modular instructions
│   ├── architecture.md    # Package deps, public API, barrel files
│   ├── testing.md         # TDD, smart test runner, Melos
│   ├── git-commits.md     # Semantic commits
│   ├── data-layer.md      # NexusStore patterns, adapters, bindings
│   ├── diagrams.md        # Mermaid diagram styling
│   ├── environment.md     # Package env conventions
│   ├── code-generation.md # build_runner, .g.dart patterns
│   └── publishing.md      # pub.dev, versioning, changelog
├── skills/                # Flat: each skill is skills/<name>/SKILL.md
│   ├── nexus-store/       # NexusStore API reference
│   ├── mermaid-diagrams/  # Diagram generation
│   ├── commit-helper/     # Semantic commits
│   ├── implementation-tracker/
│   ├── tracker-executor/
│   └── README.md
├── agents/                # Flat: each agent is agents/<name>.md
│   ├── arch-check.md      # Package architecture compliance
│   ├── verify-packages.md # Melos-based verification
│   ├── dead-code.md       # Find unused code
│   ├── perf-scout.md      # Performance issues
│   ├── pr-reviewer.md     # Code review
│   ├── api-surface.md     # Public API consistency
│   ├── cross-package-deps.md # Dependency graph health
│   └── README.md
├── hooks/
│   └── core/              # Hook scripts (Python)
├── invariants/            # Dart invariant scripts
├── orchestrators/         # Pre-commit, test, verify scripts
├── progress/              # Session state and metrics
├── test-history/          # Auto-generated test data
├── doc-source-map.json    # Doc-to-source mappings for drift detection
└── plugins/               # Claude Code plugins
```

## Key Conventions

- **Skills:** `skills/<name>/SKILL.md` — flat, no nesting. YAML frontmatter with `name` and `description`
- **Agents:** `agents/<name>.md` — flat, no nesting. YAML frontmatter with `name`, `description`, and `tools`
- **Rules:** `rules/<topic>.md` — modular instructions auto-loaded by Claude Code based on path scope
- **Settings:** `settings.json` (team, git-tracked) + `settings.local.json` (personal, gitignored)
- **Hooks:** Use `$CLAUDE_PROJECT_DIR` in hook paths for portability
