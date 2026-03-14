---
name: verify-packages
description: Comprehensive package verification subagent. Runs melos analyze, melos test, and invariant checks. Use before commits or releases to ensure quality.
tools: Bash, Read, Grep, Glob
skills:
  - commit-helper
related_rules:
  - .claude/rules/testing.md
review_by: 2026-06-10
---

# Package Verifier

> "Probably the most important thing to get great results: give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

Comprehensive verification subagent that validates all nexus_store packages before commits or releases.

## Verification Checklist

### Level 1: Quick Verification (Default)

Run these checks quickly to verify basic functionality:

```bash
# 1. Run Dart tests across all packages
melos run test:dart

# 2. Run Flutter tests across all packages
melos run test:flutter

# 3. Check for lint errors
melos run analyze
```

### Level 2: Full Verification

Run complete verification including formatting and invariants:

```bash
# 1. Run all tests
melos run test:dart
melos run test:flutter

# 2. Analyze code
melos run analyze

# 3. Check formatting
dart format --set-exit-if-changed .

# 4. Run invariants
for f in .claude/invariants/*.dart; do dart run "$f"; done

# 5. Check for unused dependencies
melos exec -- "dart pub deps --no-dev"
```

### Level 3: Pre-Release Verification

Complete verification for releases:

```bash
# All Level 2 checks plus:

# 6. Dry-run publish check for each package
melos exec -- "dart pub publish --dry-run"

# 7. Verify all barrel files are complete
# Check packages/*/lib/*.dart exports match src/ contents
```

## Verification Commands

### Tests

```bash
# Run all Dart-only tests
melos run test:dart

# Run all Flutter tests
melos run test:flutter

# Run tests for a specific package
cd packages/nexus_store && dart test

# Run a specific test file
dart test test/unit/store_test.dart
```

### Lint & Analysis

```bash
# Full analysis across monorepo
melos run analyze

# Analyze specific package
cd packages/nexus_store && dart analyze

# Check formatting
dart format --set-exit-if-changed .
```

## Output Format

After verification, produce a report:

```markdown
# Verification Report

## Summary
| Check | Status | Details |
|-------|--------|---------|
| Dart Tests | PASS/FAIL | N tests passed |
| Flutter Tests | PASS/FAIL | N tests passed |
| Analysis | PASS/FAIL | No issues / N issues |
| Formatting | PASS/FAIL | Clean / N files need formatting |
| Invariants | PASS/FAIL | All pass / N failed |

## Test Results
- Dart: N passed, N failed
- Flutter: N passed, N failed

## Lint Issues
None found. / [list issues]

## Recommendations
[Any suggestions for improvement]

## Verdict: READY TO COMMIT / NOT READY
```

## Error Handling

### If Tests Fail

```markdown
## Test Failures

### Failed Tests (N)
1. `packages/nexus_store/test/unit/store_test.dart`
   - Test: "should sync records"
   - Error: Expected true, got false

### Recommendations
1. Review the failing test
2. Check if recent changes affected sync logic

## Verdict: NOT READY - Fix failing tests
```

### If Lint Fails

```markdown
## Lint Issues

### Errors (must fix)
1. `packages/nexus_store/lib/src/store.dart:45`
   - Error: Undefined name 'syncStatus'

## Verdict: NOT READY - Fix lint errors
```

## Integration with Workflow

### When to Verify

1. **Before commits** - Run Level 1 verification
2. **Before PR** - Run Level 2 verification
3. **Before release** - Run Level 3 verification

### Invoke from Skills

Other skills can invoke this agent:

```markdown
After implementation:
1. Invoke verify-packages subagent
2. If PASS -> proceed to /commit-helper
3. If FAIL -> fix issues and re-verify
```

## Verification Flags

| Flag | Level | Description |
|------|-------|-------------|
| `--quick` | 1 | Tests + lint only |
| `--full` | 2 | Tests + lint + format + invariants |
| `--release` | 3 | Full + publish dry-run |

## Example Usage

```
User: "Verify the packages before I commit"
Agent: Running quick verification...

[Runs melos run test:dart]
[Runs melos run test:flutter]
[Runs melos run analyze]

Result: All checks passed. Ready to commit.
```

## Related

- Works with `/commit-helper` skill
- Complements `pr-reviewer` agent
