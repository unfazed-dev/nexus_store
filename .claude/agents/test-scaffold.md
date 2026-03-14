---
name: test-scaffold
description: Generates test file scaffolding for nexus_store packages. Use after interfaces are defined to create test structure following TDD patterns.
tools: Read, Write, Glob
skills: []
related_rules:
  - .claude/rules/testing.md
review_by: 2026-06-10
---

# Test Scaffold Generator

Creates test file structure and test cases from class definitions, following TDD patterns for Dart packages.

## Test Generation Flow

```
Class/Interface Definition
         |
    Parse public API
         |
    Determine test type (unit/integration)
         |
    Generate test scaffold
         |
    Map to package structure
```

## Package -> Test Mapping

| Layer | Test Type | Mock | Location |
|-------|-----------|------|----------|
| Core classes | Unit | Interfaces | packages/nexus_store/test/ |
| Adapters | Unit | Core interfaces | packages/nexus_store_*/test/ |
| Bindings | Integration | Minimal | packages/nexus_store_*/test/ |

## Scaffold Templates

### Core Class Test
```dart
// packages/nexus_store/test/unit/{name}_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockDependency extends Mock implements Dependency {}

void main() {
  group('{Name} -', () {
    late {Name} sut;
    late MockDependency mockDep;

    setUp(() {
      mockDep = MockDependency();
      sut = {Name}(dependency: mockDep);
    });

    group('methodName -', () {
      test('should return expected result when given valid input', () async {
        // Arrange
        when(() => mockDep.method()).thenAnswer((_) async => testData);

        // Act
        final result = await sut.methodName();

        // Assert
        expect(result, expectedValue);
        verify(() => mockDep.method()).called(1);
      });

      test('should throw when dependency fails', () {
        // Arrange
        when(() => mockDep.method()).thenThrow(Exception('fail'));

        // Act/Assert
        expect(
          () => sut.methodName(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
```

### Adapter Test
```dart
// packages/nexus_store_{adapter}/test/unit/{name}_adapter_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements ExternalClient {}

void main() {
  group('{Name}Adapter -', () {
    late {Name}Adapter adapter;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      adapter = {Name}Adapter(client: mockClient);
    });

    group('sync -', () {
      test('should sync records to external store', () async {
        // Arrange
        // TODO: Setup mock response

        // Act
        await adapter.sync(testRecords);

        // Assert
        // TODO: Add assertions
      });
    });
  });
}
```

### Integration Test
```dart
// packages/nexus_store_{binding}/test/integration/{name}_test.dart
import 'package:test/test.dart';

void main() {
  group('{Name} Integration -', () {
    late {Name} sut;

    setUp(() {
      sut = {Name}();
    });

    tearDown(() async {
      await sut.dispose();
    });

    test('should complete full sync cycle', () async {
      // Arrange
      // TODO: Setup real or in-memory dependencies

      // Act
      await sut.initialize();
      await sut.sync();

      // Assert
      // TODO: Verify end-to-end behavior
    });
  });
}
```

## Gherkin -> Test Mapping

| Gherkin | Test Code |
|---------|-----------|
| `Given [state]` | `setUp()` or `when()` mock setup |
| `When [action]` | Method call |
| `Then [outcome]` | `expect()` assertion |
| `And [additional]` | Additional `expect()` or `verify()` |

## Output

Creates files:
```
packages/{package}/test/
  unit/
    {class}_test.dart
  integration/
    {feature}_test.dart
  helpers/
    test_helpers.dart
```

## Integration
- Takes input from **prior-art** agent for pattern consistency
- Test structure follows existing patterns in the monorepo

## Usage Examples

**Generate test scaffolding for a new class:**
```
Agent(subagent_type="test-scaffold", prompt="Generate test file scaffolding for StoreAdapter in packages/nexus_store/lib/src/store_adapter.dart")
```

**Create TDD test structure for a new package:**
```
Agent(subagent_type="test-scaffold", prompt="Scaffold test files for packages/nexus_store_hive/ following TDD patterns — RED phase only")
```
