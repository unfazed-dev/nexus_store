# TRACKER: Type-Safe Query Builder

## Status: ✅ COMPLETE

## Overview

Implement an optional type-safe query builder that provides compile-time validation of field names, reducing runtime errors from typos in string-based queries.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-019, Task 18
**Parent Tracker**: [TRACKER-nexus-store-main.md](../TRACKER-nexus-store-main.md)

## Implementation Summary

- **109 new tests** across 4 test files
- Dart 3 sealed classes for exhaustive pattern matching
- Extension methods on Query<T> for backward compatibility
- Type-safe field accessors with specialized operators
- Full OR expression support via `matchesExpression()` in evaluator

## Tasks

### Core Design
- [x] Design expression tree approach
  - [x] `Expression<T>` sealed base class
  - [x] `ComparisonExpression<T>` for field comparisons
  - [x] `AndExpression<T>` for logical AND
  - [x] `OrExpression<T>` for logical OR
  - [x] `NotExpression<T>` for logical NOT

- [x] Create `Query<T>` extension methods
  - [x] `whereExpression()` for type-safe filters
  - [x] `orderByTyped()` for type-safe ordering
  - [x] Backward compatible with string queries

### Field Accessor Pattern
- [x] Create `Fields<T>` abstract class
  - [x] Base class for entity field definitions
  - [x] Users define static Field instances

- [x] Create `Field<T, F>` class
  - [x] Represents a single field
  - [x] `equals(F value)` returns Expression
  - [x] `notEquals(F value)` returns Expression
  - [x] `isNull()` returns Expression
  - [x] `isNotNull()` returns Expression
  - [x] `isIn(List<F> values)` returns Expression
  - [x] `isNotIn(List<F> values)` returns Expression

- [x] Create `ComparableField<T, F>` class
  - [x] Extends Field for comparable types
  - [x] `greaterThan(F value)` returns Expression
  - [x] `lessThan(F value)` returns Expression
  - [x] `greaterThanOrEqualTo(F value)` returns Expression
  - [x] `lessThanOrEqualTo(F value)` returns Expression

- [x] Create `StringField<T>` class
  - [x] Extends ComparableField for strings
  - [x] `contains(String value)` returns Expression
  - [x] `startsWith(String value)` returns Expression
  - [x] `endsWith(String value)` returns Expression

- [x] Create `ListField<T, E>` class
  - [x] For array/list fields
  - [x] `arrayContains(E value)` returns Expression
  - [x] `arrayContainsAny(List<E> values)` returns Expression

### Expression Implementation
- [x] `ComparisonExpression<T>` implementation
  - [x] Stores fieldName, operator, value
  - [x] Converts to QueryFilter via `toFilters()`
  - [x] Implements equality and hashCode

- [x] `AndExpression<T>` implementation
  - [x] Stores left and right expressions
  - [x] `toFilters()` flattens to filter list

- [x] `OrExpression<T>` implementation
  - [x] Stores left and right expressions
  - [x] `toFilters()` throws UnsupportedError (use evaluator)

- [x] `NotExpression<T>` implementation
  - [x] Inverts operator in `toFilters()`
  - [x] Handles all invertible operators

### Query Builder Integration
- [x] Add `whereExpression(Expression<T>)` extension
  - [x] Convert expression to filter format
  - [x] Append to existing filters
  - [x] Maintain backward compatibility

- [x] Add `orderByTyped(Field<T, F>)` extension
  - [x] Type-safe field ordering
  - [x] Supports descending flag

### Evaluator Update
- [x] Update `InMemoryQueryEvaluator` for expressions
  - [x] `matchesExpression(T item, Expression<T>)` method
  - [x] Full support for AND/OR/NOT via pattern matching
  - [x] `evaluateWithExpression(List<T>, Expression<T>)` method

### Code Generation ✅
- [x] Create `nexus_store_entity_generator` package
  - [x] Annotation: `@NexusEntity()` in core package
  - [x] Generates `UserFields` from `User` class
  - [x] Uses build_runner with source_gen
  - [x] 13 comprehensive tests

### Manual Definition Support
- [x] Manual Fields definition works
  - [x] Pattern documented in tests
  - [x] Simple pattern to follow

### Unit Tests
- [x] `test/src/query/expression_test.dart` (25 tests)
  - [x] ComparisonExpression creation
  - [x] AndExpression combining
  - [x] OrExpression combining
  - [x] NotExpression negation
  - [x] toFilters() conversion
  - [x] OR expressions throw on toFilters()

- [x] `test/src/query/field_test.dart` (33 tests)
  - [x] Field.equals() creates correct expression
  - [x] ComparableField comparison operators
  - [x] StringField text operators
  - [x] ListField array operators
  - [x] Field equality and hashCode

- [x] `test/src/query/type_safe_query_test.dart` (21 tests)
  - [x] whereExpression() adds filter
  - [x] Multiple whereExpression() calls combine
  - [x] orderByTyped() works correctly
  - [x] Integration with existing Query methods
  - [x] Mixed string-based and type-safe usage
  - [x] Immutability verification

- [x] `test/src/cache/query_evaluator_expression_test.dart` (30 tests)
  - [x] matchesExpression() for all operators
  - [x] AND expression evaluation
  - [x] OR expression evaluation
  - [x] NOT expression evaluation
  - [x] Complex nested expressions
  - [x] evaluateWithExpression() list filtering

## Files

**Source Files:**
```
packages/nexus_store/lib/src/query/
├── annotations.dart             # ✅ @NexusEntity annotation
├── expression.dart              # ✅ Sealed expression class hierarchy
├── field.dart                   # ✅ Field, ComparableField, StringField, ListField
├── fields.dart                  # ✅ Fields<T> base class
└── query_expression_extension.dart  # ✅ Extension methods for Query<T>

packages/nexus_store/lib/src/cache/
└── query_evaluator.dart         # ✅ Updated with matchesExpression()

packages/nexus_store_entity_generator/
├── lib/
│   ├── builder.dart             # ✅ build_runner entry point
│   └── src/
│       └── entity_generator.dart # ✅ Main generator logic
├── test/
│   └── entity_generator_test.dart # ✅ 13 tests
└── build.yaml                    # ✅ Builder configuration
```

**Test Files:**
```
packages/nexus_store/test/src/query/
├── expression_test.dart         # ✅ 25 tests
├── field_test.dart              # ✅ 33 tests
└── type_safe_query_test.dart    # ✅ 21 tests

packages/nexus_store/test/src/cache/
└── query_evaluator_expression_test.dart  # ✅ 30 tests
```

## Dependencies

- Query builder (Task 4, complete)
- build_runner (for code generation, optional - deferred)

## API Usage

```dart
// 1. Manual field definition (no code generation needed)
class UserFields extends Fields<User> {
  static final id = StringField<User>('id');
  static final name = StringField<User>('name');
  static final age = ComparableField<User, int>('age');
  static final createdAt = ComparableField<User, DateTime>('createdAt');
  static final tags = ListField<User, String>('tags');
}

// 2. Type-safe query usage
final query = Query<User>()
  .whereExpression(UserFields.age.greaterThan(18))
  .whereExpression(UserFields.name.isNotNull())
  .orderByTyped(UserFields.createdAt, descending: true)
  .limitTo(10);

// 3. Compile-time type safety
UserFields.age.greaterThan(18);     // OK
UserFields.age.greaterThan('18');   // Compile error! int expected

// 4. Complex expressions with AND/OR
final query = Query<User>()
  .whereExpression(
    UserFields.age.greaterThan(18).and(
      UserFields.name.startsWith('A').or(
        UserFields.name.startsWith('B')
      )
    )
  );

// 5. Mix with string-based (backward compatible)
final query = Query<User>()
  .where('status', isEqualTo: 'active')          // String-based
  .whereExpression(UserFields.age.greaterThan(21)); // Type-safe

// 6. In-memory filtering with OR support
final evaluator = InMemoryQueryEvaluator<User>((u) => {...});
final matches = evaluator.evaluateWithExpression(
  users,
  UserFields.status.equals('active').or(UserFields.status.equals('pending')),
);
```

## Notes

- Type-safe queries are opt-in, string-based remains default
- Code generation package `nexus_store_entity_generator` is complete with 13 tests
- OR expressions require direct expression evaluation (not toFilters())
- All existing string-based queries remain fully functional
- Expression trees allow for powerful query composition
- ComparableField uses `Comparable<dynamic>` constraint because Dart's int/double implement `Comparable<num>` not `Comparable<int>`/`Comparable<double>`

## Completion Date

2025-12-26
