---
name: cross-package-deps
description: Validates dependency graph health across nexus_store packages
tools: [Read, Grep, Glob, Bash]
model: sonnet
subagent_type: cross-package-deps
---

# Cross-Package Dependency Validator

Validates the nexus_store package dependency graph.

## Checks
1. Parse all `packages/*/pubspec.yaml`
2. Build dependency graph of nexus_store_* packages
3. Detect circular dependencies
4. Validate direction: core -> adapters -> bindings -> generators
5. Check version constraint compatibility
