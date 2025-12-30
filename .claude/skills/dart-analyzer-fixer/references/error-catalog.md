# Dart Analyzer Error Catalog

Quick reference for analyzer issues with auto-fix status and resolution patterns.

## Auto-Fixable Issues

### Import Issues

| Issue | Severity | Auto-Fix | Fix Pattern |
|-------|----------|----------|-------------|
| `unused_import` | INFO | Yes | Remove import line |
| `duplicate_import` | INFO | Yes | Remove duplicate |
| `directives_ordering` | INFO | Yes | Reorder: dart → package → relative |
| `unnecessary_import` | INFO | Yes | Remove if unused |
| `unused_shown_name` | INFO | Yes | Remove from show clause |

**Auto-fix command:** `--fix-imports`

### Style Issues

| Issue | Severity | Auto-Fix | Fix Pattern |
|-------|----------|----------|-------------|
| `prefer_const_constructors` | INFO | Yes | Add `const` keyword |
| `prefer_const_declarations` | INFO | Yes | Add `const` to declaration |
| `prefer_const_literals_to_create_immutables` | INFO | Yes | Add `const` to literal |
| `cascade_invocations` | INFO | Yes | Convert to cascade `..` |
| `unnecessary_this` | INFO | Yes | Remove `this.` prefix |
| `prefer_final_locals` | INFO | Yes | Change `var` to `final` |
| `prefer_final_fields` | INFO | Yes | Add `final` to field |
| `unnecessary_late` | INFO | Yes | Remove `late` keyword |
| `unnecessary_new` | INFO | Yes | Remove `new` keyword |
| `unnecessary_null_aware_assignments` | INFO | Yes | Remove `??=` when unnecessary |

**Auto-fix command:** `--fix-style`

### String Issues

| Issue | Severity | Auto-Fix | Fix Pattern |
|-------|----------|----------|-------------|
| `prefer_single_quotes` | INFO | Yes | `"text"` → `'text'` |
| `unnecessary_brace_in_string_interps` | INFO | Yes | `'${x}'` → `'$x'` |
| `prefer_interpolation_to_compose_strings` | INFO | Yes | `a + b` → `'$a$b'` |
| `unnecessary_string_interpolations` | INFO | Yes | `'$x'` → `x` when possible |
| `unnecessary_string_escapes` | INFO | Yes | Remove unnecessary `\` |

**Auto-fix command:** `--fix-strings`

## Manual-Fix Issues

### Resource Management

| Issue | Severity | Fix Pattern |
|-------|----------|-------------|
| `close_sinks` | WARNING | Close in dispose/close method or add justified ignore |
| `cancel_subscriptions` | WARNING | Cancel in dispose/close method or add justified ignore |
| `unawaited_futures` | WARNING | Await, use `unawaited()`, or add ignore |

**Resolution Pattern:**

```dart
// Option 1: Proper cleanup
class MyClass {
  final _controller = StreamController<int>();
  StreamSubscription? _subscription;

  void init() {
    _subscription = stream.listen((_) {});
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

// Option 2: Justified ignore (when cleanup is handled elsewhere)
// ignore: close_sinks - closed by parent widget
final _controller = StreamController<int>();
```

### Type Safety

| Issue | Severity | Fix Pattern |
|-------|----------|-------------|
| `avoid_dynamic_calls` | WARNING | Add type cast or redesign with generics |
| `omit_local_variable_types` | INFO | Remove explicit type (style preference) |
| `always_specify_types` | INFO | Add explicit type (style preference) |
| `type_annotate_public_apis` | INFO | Add return type and parameter types |

**Resolution Pattern:**

```dart
// BEFORE: avoid_dynamic_calls
dynamic getData();
final result = getData();
result.process(); // Dynamic call warning

// AFTER: Type-safe
Object getData();
final result = getData();
if (result is Processable) {
  result.process();
}
```

### Exception Handling

| Issue | Severity | Fix Pattern |
|-------|----------|-------------|
| `avoid_catches_without_on_clauses` | INFO | Add specific exception type |
| `only_throw_errors` | WARNING | Throw Error subclass, not Exception |

**Resolution Pattern:**

```dart
// BEFORE: Generic catch
try {
  riskyOperation();
} catch (e) {
  print(e);
}

// AFTER: Specific exceptions
try {
  riskyOperation();
} on FormatException catch (e) {
  print('Format error: $e');
} on IOException catch (e) {
  print('IO error: $e');
}
```

### Documentation

| Issue | Severity | Fix Pattern |
|-------|----------|-------------|
| `public_member_api_docs` | INFO | Add `///` doc comment |
| `slash_for_doc_comments` | INFO | Change `/** */` to `///` |

**Resolution Pattern:**

```dart
// BEFORE: Missing docs
class UserService {
  User? getUser(String id) { ... }
}

// AFTER: With docs
/// Service for user operations.
class UserService {
  /// Retrieves user by [id], returns null if not found.
  User? getUser(String id) { ... }
}
```

## Issue Severity Reference

| Severity | Meaning | Action |
|----------|---------|--------|
| ERROR | Code will not compile | Must fix |
| WARNING | Potential bug or bad practice | Should fix |
| INFO | Style or best practice | Optional fix |

## When to Use Ignore Directives

**Acceptable:**
- Resource warnings when cleanup is handled by framework
- Dynamic calls in reflection/serialization code
- Style rules that conflict with project conventions

**Not Acceptable:**
- Ignoring actual bugs or errors
- Blanket file-level ignores without justification
- Hiding issues instead of fixing them

**Ignore Syntax:**

```dart
// Single line
// ignore: rule_name
final x = something();

// Next line only
// ignore: rule_name, another_rule

// File level (at top of file)
// ignore_for_file: rule_name

// With justification (recommended)
// ignore: close_sinks - closed in parent's dispose()
```

## Quick Decision Tree

```
Issue detected?
├── Error severity?
│   └── Must fix immediately
├── Auto-fixable?
│   └── Run `dart run fix_analyzer_issues.dart --all`
├── Resource warning?
│   ├── Can add cleanup? → Add dispose/close
│   └── Handled elsewhere? → Add justified ignore
├── Type warning?
│   ├── Can add types? → Add explicit types
│   └── Requires redesign? → Plan refactor
└── Style warning?
    ├── Team convention? → Follow convention
    └── Personal preference? → Use project standard
```
