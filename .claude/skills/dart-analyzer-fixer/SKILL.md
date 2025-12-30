---
name: dart-analyzer-fixer
description: Auto-fix Dart/Flutter analyzer issues with automated scripts. Use when running dart analyze, fixing lint warnings, resolving type errors, or integrating analysis into TDD workflow.
---

# Dart Analyzer Fixer

Auto-fix toolkit for resolving Dart/Flutter analyzer issues with minimal manual intervention.

## Quick Start

```bash
# Run full analysis with categorized report
dart run .claude/skills/dart-analyzer-fixer/scripts/analyze_project.dart --summary

# Auto-fix all fixable issues
dart run .claude/skills/dart-analyzer-fixer/scripts/fix_analyzer_issues.dart --all

# Dry-run to preview changes
dart run .claude/skills/dart-analyzer-fixer/scripts/fix_analyzer_issues.dart --all --dry-run
```

## Auto-Fix Workflow

### 1. Analyze Project

```bash
dart run scripts/analyze_project.dart --path ./lib
```

Output shows issues by category with auto-fix indicators:
- `[auto]` - Can be fixed automatically
- `[manual]` - Requires human judgment

### 2. Apply Auto-Fixes

```bash
# Fix all auto-fixable issues
dart run scripts/fix_analyzer_issues.dart --all

# Fix specific categories
dart run scripts/fix_analyzer_issues.dart --fix-imports
dart run scripts/fix_analyzer_issues.dart --fix-style
dart run scripts/fix_analyzer_issues.dart --fix-strings
```

### 3. Review Manual Issues

After auto-fix, remaining issues require manual attention. See [error-catalog.md](references/error-catalog.md).

## TDD Integration

Integrate analysis into Red-Green-Refactor cycle:

```bash
# RED: Skip analysis (failing test expected)
dart run scripts/tdd_analysis_hook.dart red

# GREEN: Check for new issues
dart run scripts/tdd_analysis_hook.dart green --save-baseline

# REFACTOR: Auto-fix and check for regressions
dart run scripts/tdd_analysis_hook.dart refactor --strict
```

### TDD Workflow

| Phase | Analysis Action | Goal |
|-------|-----------------|------|
| RED | Skip | Focus on failing test |
| GREEN | Warn on new issues | Track regressions |
| REFACTOR | Auto-fix + strict check | Improve quality |

## Fix Categories

### Auto-Fixable (High Priority)

| Category | Command | Issues Fixed |
|----------|---------|--------------|
| **Imports** | `--fix-imports` | unused_import, directives_ordering |
| **Style** | `--fix-style` | prefer_const, cascade_invocations, unnecessary_this |
| **Strings** | `--fix-strings` | prefer_single_quotes, unnecessary_brace_in_string_interps |

### Manual Fix Required

| Category | Issues | Why Manual |
|----------|--------|------------|
| **Resources** | close_sinks, cancel_subscriptions | Lifecycle decisions |
| **Dynamic** | avoid_dynamic_calls | Type design choices |
| **Exceptions** | avoid_catches_without_on_clauses | Error strategy |

## Common Patterns

### Resource Warning with Justified Ignore

```dart
// BEFORE: close_sinks warning
final _controller = StreamController<int>();

// AFTER: With justification
// ignore: close_sinks - closed in dispose()
final _controller = StreamController<int>();

@override
void dispose() {
  _controller.close();
  super.dispose();
}
```

### Import Ordering Fix

```dart
// BEFORE: Unordered imports
import 'package:my_app/utils.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// AFTER: Ordered (dart, package, relative)
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:my_app/utils.dart';
```

### Cascade Invocations Fix

```dart
// BEFORE: cascade_invocations warning
final list = <int>[];
list.add(1);
list.add(2);
list.add(3);

// AFTER: Using cascades
final list = <int>[]
  ..add(1)
  ..add(2)
  ..add(3);
```

## Script Reference

| Script | Purpose |
|--------|---------|
| `fix_analyzer_issues.dart` | Main auto-fix tool |
| `analyze_project.dart` | Parse and categorize issues |
| `tdd_analysis_hook.dart` | TDD workflow integration |

### fix_analyzer_issues.dart Options

```
--all          Fix all auto-fixable issues
--fix-imports  Fix import issues only
--fix-style    Fix style issues only
--fix-strings  Fix string issues only
--dry-run      Preview changes without applying
--path <dir>   Target directory
--verbose      Show detailed output
```

### analyze_project.dart Options

```
--json         Output JSON format
--summary      Show summary only
--by-file      Group issues by file
--by-category  Group issues by category
--path <dir>   Target directory
```

### tdd_analysis_hook.dart Options

```
red            Skip analysis (RED phase)
green          Check for new issues (GREEN phase)
refactor       Auto-fix with regression check (REFACTOR phase)
--baseline     Path to baseline file
--save-baseline  Save current as baseline
--strict       Fail on any new issues
```

## Integration with Other Skills

- **dart-package**: See [analysis-options.md](references/analysis-options.md) for configuration
- **tdd-flutter**: Use `tdd_analysis_hook.dart` during refactor phase
- **dart-testing**: Run analysis after test passes

## Resources

- [Error Catalog](references/error-catalog.md) - Full issue reference
- [Analysis Options](references/analysis-options.md) - Configuration guide
