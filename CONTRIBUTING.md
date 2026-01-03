# Contributing to nexus_store

Thank you for your interest in contributing to nexus_store! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project follows a standard code of conduct. Please be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment
4. Create a feature branch
5. Make your changes
6. Submit a pull request

## Development Setup

### Prerequisites

- Dart SDK 3.0.0 or higher
- Flutter 3.10.0 or higher (for Flutter packages)
- Melos (for monorepo management)

### Installation

```bash
# Clone the repository
git clone https://github.com/unfazed-dev/nexus_store.git
cd nexus_store

# Install melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Verify setup
melos run analyze
melos run test
```

### Melos Commands

```bash
# Bootstrap all packages
melos bootstrap

# Run analyzer on all packages
melos run analyze

# Run tests on all packages
melos run test

# Run tests with coverage
melos run test:coverage

# Clean all packages
melos clean

# Publish packages (maintainers only)
melos publish
```

## Project Structure

```
nexus_store/
├── packages/
│   ├── nexus_store/                    # Core package
│   ├── nexus_store_flutter_widgets/            # Flutter widgets
│   ├── nexus_store_powersync_adapter/  # PowerSync backend
│   ├── nexus_store_supabase_adapter/   # Supabase backend
│   ├── nexus_store_drift_adapter/      # Drift backend
│   ├── nexus_store_brick_adapter/      # Brick backend
│   └── nexus_store_crdt_adapter/       # CRDT backend
├── example/
│   ├── basic_usage/                    # Dart console example
│   └── flutter_widgets/                # Flutter example
├── docs/
│   ├── architecture/                   # Architecture docs
│   └── migration/                      # Migration guides
└── melos.yaml                          # Monorepo config
```

## Making Changes

### Branching Strategy

- `main` - Stable release branch
- `develop` - Development branch
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches
- `docs/*` - Documentation branches

### Creating a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### Making Changes

1. Make your changes in the appropriate package
2. Add or update tests
3. Update documentation if needed
4. Run analyzer and tests locally
5. Commit your changes

## Testing

### Running Tests

```bash
# Run all tests
melos run test

# Run tests for specific package
cd packages/nexus_store
dart test

# Run tests with coverage
melos run test:coverage

# Run a specific test file
dart test test/specific_test.dart
```

### Writing Tests

- Place tests in the `test/` directory of each package
- Use descriptive test names
- Group related tests with `group()`
- Test both success and failure cases
- Mock external dependencies

```dart
import 'package:test/test.dart';
import 'package:nexus_store/nexus_store.dart';

void main() {
  group('NexusStore', () {
    late NexusStore<User, String> store;

    setUp(() {
      store = NexusStore<User, String>(
        backend: InMemoryBackend(),
        config: StoreConfig.defaults,
      );
    });

    tearDown(() async {
      await store.dispose();
    });

    test('should save and retrieve entity', () async {
      final user = User(id: '1', name: 'Test');
      await store.save(user);

      final retrieved = await store.get('1');
      expect(retrieved, equals(user));
    });

    test('should return null for non-existent entity', () async {
      final result = await store.get('non-existent');
      expect(result, isNull);
    });
  });
}
```

### Test Coverage

We aim for high test coverage. Please ensure your changes include appropriate tests:

- Unit tests for business logic
- Integration tests for backend adapters
- Widget tests for Flutter components

## Code Style

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- Use `lowerCamelCase` for variables, functions, and parameters
- Use `UpperCamelCase` for classes, enums, and type parameters
- Use `lowercase_with_underscores` for file names
- Prefer `final` for local variables
- Use `const` constructors where possible

### Formatting

```bash
# Format all Dart files
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .
```

### Analysis

```bash
# Run analyzer
dart analyze

# Run with strict mode
dart analyze --fatal-infos
```

### Linting Rules

The project uses `analysis_options.yaml` with strict linting. Common rules:

- `prefer_const_constructors`
- `prefer_final_locals`
- `avoid_print` (use proper logging)
- `always_declare_return_types`
- `prefer_single_quotes`

## Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

### Examples

```bash
feat(core): add transaction support for batch operations

fix(powersync): resolve sync status not updating on reconnect

docs(readme): add migration guide for Supabase users

test(drift): add integration tests for watch queries

chore: update dependencies to latest versions
```

## Pull Request Process

### Before Submitting

1. **Update from main**: Rebase your branch on the latest main
2. **Run tests**: Ensure all tests pass
3. **Run analyzer**: Fix any analysis issues
4. **Update docs**: Document any new features or changes
5. **Update CHANGELOG**: Add entry for your changes

### Submitting a PR

1. Push your branch to your fork
2. Create a pull request against `main`
3. Fill out the PR template
4. Link any related issues
5. Wait for review

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG updated
```

### Review Process

1. At least one maintainer approval required
2. All CI checks must pass
3. No unresolved conversations
4. Up-to-date with main branch

## Reporting Issues

### Bug Reports

Include:

- Package name and version
- Dart/Flutter version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages/stack traces

### Feature Requests

Include:

- Use case description
- Proposed solution
- Alternative approaches considered
- Impact on existing functionality

### Issue Template

```markdown
**Package**: nexus_store (v0.1.0)
**Dart Version**: 3.2.0
**Flutter Version**: 3.16.0 (if applicable)

**Description**
Clear description of the issue

**Steps to Reproduce**
1. Create store with...
2. Call method...
3. Observe error...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Code Sample**
```dart
// Minimal reproducible example
```

**Stack Trace**
```
Error message here
```
```

## Questions?

- Open a [GitHub Discussion](https://github.com/unfazed-dev/nexus_store/discussions)
- Check existing [Issues](https://github.com/unfazed-dev/nexus_store/issues)
- Review [Documentation](./docs/)

Thank you for contributing!
