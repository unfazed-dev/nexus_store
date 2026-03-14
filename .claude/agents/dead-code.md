---
name: dead-code
description: Finds unused classes, functions, exports, and other dead code across nexus_store packages. Use during cleanup or before releases.
tools: Read, Grep, Glob
skills: []
related_rules: []
review_by: 2026-06-10
---

# Dead Code Finder

Identifies unused code including classes, functions, exports, and dependencies that can be safely removed from the nexus_store monorepo.

## Detection Categories

### 1. Unused Exports
Classes exported from barrel files but never imported by other packages or tests.

```bash
# Find all exports in barrel files
Grep: "export 'src/" in packages/*/lib/*.dart

# For each export, check cross-package usage
Grep: "import 'package:nexus_store" in packages/*/
```

### 2. Unused Classes
Classes defined but never instantiated or referenced.

```bash
# Find all class definitions
Grep: "class\s+\w+" in packages/*/lib/src/

# Check for usage across all packages
Grep: "ClassName"
```

### 3. Unused Functions/Methods
Public methods never called.

```bash
# Find public methods
Grep: "^\s+(Future|void|String|int|bool|List).*\(" in packages/*/lib/src/

# Check for calls
# (Requires parsing each method name)
```

### 4. Unused Imports
Imports that are not used in the file.

```bash
# Dart analyzer handles this
melos run analyze
```

### 5. Unused Dependencies
Packages in pubspec.yaml not imported anywhere.

```bash
# For each dependency in packages/*/pubspec.yaml
Grep: "import 'package:dependency_name" in packages/*/lib/
```

### 6. Dead Test Helpers
Test utilities defined but never used.

```bash
# Find test helpers
Grep: "class Mock" in packages/*/test/
Grep: "void register" in packages/*/test/

# Check for usage
```

## Analysis Process

1. **Inventory** - List all definitions across packages/*/lib/src/
2. **Reference Check** - Search for usages across all packages
3. **Exclusion Filter** - Ignore:
   - Export files (barrel files)
   - Generated code (*.g.dart, *.freezed.dart)
   - Test helpers
   - Entry points
4. **Report** - List candidates for removal

## Output Format

```markdown
# Dead Code Report

**Generated:** [timestamp]
**Packages Analyzed:** [N]

## Summary
| Category | Found | Potentially Unused |
|----------|-------|-------------------|
| Classes | [N] | [N] |
| Functions | [N] | [N] |
| Exports | [N] | [N] |
| Dependencies | [N] | [N] |

## Unused Exports
| Export | Package | Barrel File |
|--------|---------|-------------|
| [Name] | [Package] | [Path] |

## Unused Classes
| Class | Location | Reason |
|-------|----------|--------|
| [Name] | [Path] | No references found |

## Unused Dependencies
| Dependency | Package | pubspec.yaml |
|------------|---------|-------------|
| [Name] | [Package] | [Path] |

## Recommended Actions

### Safe to Remove (High Confidence)
- [ ] `packages/nexus_store/lib/src/old_class.dart` - Zero references
- [ ] `some_package` dependency in nexus_store_supabase - Not imported

### Review Before Removing (Medium Confidence)
- [ ] `packages/nexus_store/lib/src/utils.dart` - Only test references

### Keep (False Positives)
- `packages/nexus_store/lib/src/core.dart` - Used via re-export

## Cleanup Commands
```bash
# Remove identified dead code files
rm packages/nexus_store/lib/src/old_class.dart

# Run after removal
melos run analyze
melos run test:dart
```
```

## Exclusion Patterns

Ignore these:
- `*.g.dart` - Generated
- `*.freezed.dart` - Generated
- `test/**` - Test files (unless scanning for dead test helpers)
- Files with `// ignore: dead_code` comment
- Export barrels (`export 'file.dart'`)

## Integration
- Run periodically for codebase hygiene
- Run before major releases
- Complements **deps-audit** agent

## Usage Examples

**Find unused code across all packages:**
```
Agent(subagent_type="dead-code", prompt="Find unused classes, exports, and dependencies in packages/*/lib/")
```

**Pre-release dead code audit:**
```
Agent(subagent_type="dead-code", prompt="Scan all packages for dead code before release")
```
