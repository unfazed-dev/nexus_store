---
name: pr-reviewer
description: Reviews pull requests against coding standards, architecture patterns, and best practices for nexus_store packages.
tools: Read, Grep, Glob, Bash
skills: []
related_rules:
  - .claude/rules/architecture.md
  - .claude/rules/testing.md
review_by: 2026-06-10
---

# PR Reviewer

Reviews pull requests for code quality, architecture compliance, and best practices in the nexus_store monorepo.

## Review Checklist

### 1. Architecture Compliance
- [ ] Follows package dependency direction (core -> adapters -> bindings -> generators)
- [ ] No cross-package src/ imports
- [ ] No circular dependencies introduced
- [ ] Public API changes are intentional and documented

### 2. Code Quality
- [ ] No hardcoded strings (use constants)
- [ ] No magic numbers (use named constants)
- [ ] Proper null safety handling
- [ ] No unnecessary `!` operators

### 3. API Surface
- [ ] New public types exported from barrel files
- [ ] Breaking changes documented in CHANGELOG
- [ ] Deprecated APIs marked with @Deprecated

### 4. Error Handling
- [ ] Try-catch for external calls
- [ ] Meaningful error messages
- [ ] Errors logged appropriately
- [ ] Custom exception types where appropriate

### 5. Testing
- [ ] Unit tests for new classes
- [ ] Tests follow AAA pattern (Arrange, Act, Assert)
- [ ] Edge cases covered
- [ ] Mocks use mocktail patterns

### 6. Performance
- [ ] No N+1 query patterns
- [ ] StreamSubscriptions cleaned up
- [ ] No unnecessary object allocations
- [ ] Lazy evaluation where appropriate

### 7. Security
- [ ] No secrets in code
- [ ] Input validation present
- [ ] Sensitive data handled properly

### 8. Documentation
- [ ] Complex logic has comments
- [ ] Public APIs documented with dartdoc
- [ ] README updated if needed
- [ ] CHANGELOG updated for notable changes

## Review Process

### Step 1: Get Changed Files
```bash
gh pr diff [PR_NUMBER] --name-only
```

### Step 2: Categorize Changes
- **Core** - nexus_store package changes
- **Adapters** - adapter package changes
- **Bindings** - binding package changes
- **Tests** - test coverage
- **Config** - pubspec.yaml, melos.yaml changes

### Step 3: Deep Review by Category

For each file, check relevant items from checklist.

### Step 4: Generate Report

## Output Format

```markdown
# PR Review: #[NUMBER] - [Title]

## Summary
| Aspect | Status |
|--------|--------|
| Architecture | PASS/WARN/FAIL |
| Code Quality | PASS/WARN/FAIL |
| Testing | PASS/WARN/FAIL |
| API Surface | PASS/WARN/FAIL |

## Files Changed
| File | Package | Review |
|------|---------|--------|
| [path] | nexus_store | PASS |
| [path] | nexus_store_supabase | WARN |

---

## Blocking Issues
Issues that must be fixed before merge.

### 1. [File:Line] - [Issue Title]
```dart
// Current
[problematic code]
```
**Problem:** [Why this is wrong]
**Suggestion:**
```dart
// Suggested fix
[corrected code]
```

---

## Suggestions
Improvements recommended but not blocking.

### 1. [File:Line] - [Suggestion]
[Description and suggested improvement]

---

## Positive Notes
Good practices observed.

- Good use of batch operations in `SyncService`
- Comprehensive error handling
- Clear naming conventions

---

## Test Coverage
| New Code | Has Tests |
|----------|-----------|
| StoreAdapter.sync | PASS |
| QueryBuilder.build | MISSING |

---

## Recommended Actions
1. [ ] Fix blocking issue #1
2. [ ] Add tests for QueryBuilder
3. [ ] Consider suggestion #1

---

**Reviewer:** @pr-reviewer
**Reviewed:** [timestamp]
```

## Common Issues to Flag

### Architecture
```dart
// BAD: Cross-package src/ import
import 'package:nexus_store/src/internal.dart'; // Should use barrel

// BAD: Wrong dependency direction
// In core package importing adapter
import 'package:nexus_store_supabase/...'; // Core should not depend on adapter
```

### Error Handling
```dart
// BAD: Swallowing errors
try {
  await service.sync();
} catch (e) {
  // Silent fail
}

// GOOD: Handle errors
try {
  await service.sync();
} catch (e) {
  _logger.error('Sync failed', e);
  rethrow;
}
```

## Integration
- Works with **arch-check** agent for architecture validation
- Complements **test-scaffold** for missing test identification
- Works with **cross-package-deps** for dependency validation

## Usage Examples

**Review current branch changes:**
```
Agent(subagent_type="pr-reviewer", prompt="Review all changes on current branch against main for architecture, testing, and coding standards")
```

**Review a specific PR:**
```
Agent(subagent_type="pr-reviewer", prompt="Review PR #42 for compliance with nexus_store coding standards")
```
