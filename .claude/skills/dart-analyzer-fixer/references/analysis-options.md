# Analysis Options Configuration

Recommended `analysis_options.yaml` configurations for Dart and Flutter projects.

## Base Configuration

### Pure Dart Package

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - 'build/**'

  errors:
    missing_return: error
    missing_required_param: error
    must_be_immutable: error

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_print
    - cancel_subscriptions
    - close_sinks
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - prefer_single_quotes
    - unawaited_futures
```

### Flutter Application

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true

  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - 'build/**'
    - '.dart_tool/**'

  errors:
    missing_return: error
    invalid_annotation_target: ignore

linter:
  rules:
    - avoid_print
    - cancel_subscriptions
    - close_sinks
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - prefer_single_quotes
    - sized_box_for_whitespace
    - use_build_context_synchronously
    - use_key_in_widget_constructors
```

## Strict Mode Settings

### Maximum Strictness (Recommended for new projects)

```yaml
analyzer:
  language:
    strict-casts: true       # No implicit casts from dynamic
    strict-inference: true   # Require explicit types when inference fails
    strict-raw-types: true   # No raw generic types
```

### Moderate Strictness (Legacy projects)

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: false  # Allow some inference
    strict-raw-types: false  # Allow raw types temporarily
```

## Generated Code Exclusions

```yaml
analyzer:
  exclude:
    # Code generation outputs
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/*.gr.dart'
    - '**/*.config.dart'

    # Build outputs
    - 'build/**'
    - '.dart_tool/**'

    # Test fixtures
    - 'test/fixtures/**'

    # Generated directories
    - '**/generated/**'
```

## Error Promotion

Promote warnings to errors for critical issues:

```yaml
analyzer:
  errors:
    # Type safety
    missing_return: error
    missing_required_param: error

    # Immutability
    must_be_immutable: error

    # Null safety
    null_check_on_nullable_type_parameter: error

    # Async
    unawaited_futures: warning  # Or error for strict
```

## Per-Category Rule Groups

### Import Rules

```yaml
linter:
  rules:
    - always_use_package_imports
    - avoid_relative_lib_imports
    - directives_ordering
    - library_prefixes
    - unnecessary_import
```

### Documentation Rules

```yaml
linter:
  rules:
    - package_api_docs
    - public_member_api_docs
    - slash_for_doc_comments
```

### Style Rules

```yaml
linter:
  rules:
    - cascade_invocations
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_single_quotes
    - unnecessary_this
```

### Resource Management Rules

```yaml
linter:
  rules:
    - cancel_subscriptions
    - close_sinks
    - unawaited_futures
```

### Type Safety Rules

```yaml
linter:
  rules:
    - avoid_dynamic_calls
    - avoid_returning_null_for_void
    - prefer_typing_uninitialized_variables
    - type_annotate_public_apis
```

## Monorepo Configuration

For monorepos, use a shared base configuration:

**Root analysis_options.yaml:**

```yaml
# Root configuration
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
```

**Package analysis_options.yaml:**

```yaml
# Inherits from root, adds package-specific rules
include: ../../analysis_options.yaml

analyzer:
  exclude:
    - '**/*.g.dart'

linter:
  rules:
    # Package-specific rules
    - public_member_api_docs  # For published packages
```

## Quick Reference

| Setting | Strictness | Use Case |
|---------|------------|----------|
| `strict-casts: true` | High | Prevent dynamic type issues |
| `strict-inference: true` | High | Require explicit types |
| `strict-raw-types: true` | High | No untyped generics |
| `missing_return: error` | High | Catch missing returns |
| `unawaited_futures: warning` | Medium | Catch unhandled futures |

## Validating Configuration

```bash
# Verify analysis_options.yaml is valid
dart analyze --fatal-infos

# Check for deprecated rules
dart pub upgrade
dart analyze
```
