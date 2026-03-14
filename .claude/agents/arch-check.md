---
name: arch-check
description: Validates package dependency direction, public API surface, and no circular deps in nexus_store monorepo.
tools: Read, Grep, Glob
skills:
  - nexus-store
related_rules:
  - .claude/rules/architecture.md
review_by: 2026-06-10
---

# Architecture Checker

Validates nexus_store monorepo packages follow proper dependency direction and public API conventions.

## Architecture Rules

### Package Dependency Direction (MUST follow)

```
ALLOWED                              FORBIDDEN
─────────────────────────────────────────────────
core ← adapters                      adapters → generators
core ← bindings                      bindings → generators
adapters ← bindings                  circular deps between packages
bindings ← generators               core → adapters/bindings
any ← example apps                   src/ imports across packages
```

### Violation Patterns to Detect

#### 1. Wrong dependency direction
```dart
// BAD: Core package imports adapter
// In packages/nexus_store/lib/src/...
import 'package:nexus_store_supabase/...'; // VIOLATION
```

#### 2. Cross-package src/ imports
```dart
// BAD: Importing src/ from another package
import 'package:nexus_store/src/internal_class.dart'; // VIOLATION

// GOOD: Import from barrel file
import 'package:nexus_store/nexus_store.dart';
```

#### 3. Circular dependencies
```yaml
# BAD: Package A depends on B, B depends on A
# packages/nexus_store_supabase/pubspec.yaml
dependencies:
  nexus_store_drift: ... # if drift also depends on supabase

# VIOLATION: circular dependency
```

#### 4. Unexported public types
```dart
// BAD: Public class in src/ not exported from barrel
// packages/nexus_store/lib/src/useful_class.dart
class UsefulClass {} // Public but not exported

// GOOD: Export from barrel
// packages/nexus_store/lib/nexus_store.dart
export 'src/useful_class.dart';
```

## Detection Queries

```bash
# Cross-package src/ imports
Grep: "import 'package:nexus_store.*/src/" in packages/*/lib/

# Circular dependency check
# Parse all pubspec.yaml files and build dependency graph

# Unexported public types
# Compare classes in src/ vs exports in barrel files

# Wrong direction imports
Grep: "import 'package:nexus_store" in packages/nexus_store/lib/
```

## Validation Checklist

### Core Package (nexus_store)
- [ ] No imports from adapter packages
- [ ] No imports from binding packages
- [ ] All public types exported from barrel file
- [ ] No circular dependencies

### Adapter Packages
- [ ] Only depend on core package
- [ ] No cross-adapter dependencies (unless explicit)
- [ ] Public API surface documented
- [ ] No src/ imports from core

### Binding Packages
- [ ] Depend on core and/or adapters only
- [ ] No generator dependencies
- [ ] Clean public API

### Generators
- [ ] Build-time only dependencies
- [ ] No runtime imports from other nexus_store packages

## Output Format

```markdown
# Architecture Validation Report

## Summary
| Layer | Packages Checked | Violations |
|-------|-----------------|------------|
| Core | [N] | [N] |
| Adapters | [N] | [N] |
| Bindings | [N] | [N] |
| Generators | [N] | [N] |

## Violations

### Critical (Must Fix)
1. **[Package:File:Line]**: [Violation type]
   ```dart
   [offending code]
   ```
   **Fix:** [How to fix]

### Warnings
1. **[Package]**: [Issue description]

## Recommendations
- [Architectural improvement suggestion]

## Compliant Packages
- [List of packages that pass all checks]
```

## Integration
- Run before PR merge
- Works with **cross-package-deps** agent for deeper graph analysis
- Complements **pr-reviewer** agent

## Usage Examples

**Validate all packages follow dependency direction:**
```
Agent(subagent_type="arch-check", prompt="Check all packages/ for architecture violations — dependency direction and public API surface")
```

**Review a PR for cross-package violations:**
```
Agent(subagent_type="arch-check", prompt="Validate architecture compliance for all changed files in the current branch")
```
