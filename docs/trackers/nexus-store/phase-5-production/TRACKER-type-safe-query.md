# TRACKER: Type-Safe Query Builder

## Status: PENDING

## Overview

Implement an optional type-safe query builder that provides compile-time validation of field names, reducing runtime errors from typos in string-based queries.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-019, Task 18
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Core Design
- [ ] Design expression tree approach
  - [ ] `Expression<T>` base class
  - [ ] `FieldExpression<T, F>` for field access
  - [ ] `ComparisonExpression` for operators
  - [ ] `LogicalExpression` for AND/OR

- [ ] Create `TypeSafeQuery<T>` class
  - [ ] Extends or wraps existing `Query<T>`
  - [ ] Accepts expression-based filters
  - [ ] Backward compatible with string queries

### Field Accessor Pattern
- [ ] Create `Fields<T>` abstract class
  - [ ] Generated or manually defined per entity
  - [ ] Exposes typed field accessors

- [ ] Create `Field<T, F>` class
  - [ ] Represents a single field
  - [ ] Provides comparison operators
  - [ ] `greaterThan(F value)` returns Expression
  - [ ] `lessThan(F value)` returns Expression
  - [ ] `equals(F value)` returns Expression
  - [ ] `isIn(List<F> values)` returns Expression

### Expression Implementation
- [ ] `FieldExpression<T, F>` implementation
  - [ ] Stores field name
  - [ ] Stores field type for validation
  - [ ] Comparison methods return ComparisonExpression

- [ ] `ComparisonExpression` implementation
  - [ ] Stores operator (>, <, ==, !=, IN, etc.)
  - [ ] Stores field and value
  - [ ] Can be combined with AND/OR

- [ ] `LogicalExpression` implementation
  - [ ] `and(Expression a, Expression b)`
  - [ ] `or(Expression a, Expression b)`
  - [ ] `not(Expression e)`

### Query Builder Integration
- [ ] Add `where(Expression<T> expression)` overload
  - [ ] Convert expression to existing filter format
  - [ ] Maintain backward compatibility

- [ ] Add expression-based orderBy
  - [ ] `orderBy(Field<T, F> field, {bool descending})`

### Code Generation (Optional)
- [ ] Create `nexus_store_generator` package
  - [ ] Annotation: `@NexusEntity()`
  - [ ] Generates `UserFields` from `User` class
  - [ ] Uses build_runner

- [ ] Generator implementation
  - [ ] Read class fields via analyzer
  - [ ] Generate Field instances for each field
  - [ ] Generate static accessor class

### Manual Definition Support
- [ ] Document manual Fields definition
  - [ ] For users not using code generation
  - [ ] Simple pattern to follow

### Query Translation
- [ ] Update `QueryTranslator` for expressions
  - [ ] `translateExpression(Expression<T>)` method
  - [ ] Convert expression tree to backend query

### Unit Tests
- [ ] `test/src/query/type_safe_query_test.dart`
  - [ ] Field comparison creates correct expression
  - [ ] Logical combinations work
  - [ ] Expression translates to valid filter
  - [ ] Type safety catches mismatched types

## Files

**Source Files:**
```
packages/nexus_store/lib/src/query/
├── type_safe_query.dart     # TypeSafeQuery<T> class
├── expression.dart          # Expression base and implementations
├── field.dart               # Field<T, F> class
└── fields.dart              # Fields<T> base class

packages/nexus_store_generator/ (optional)
├── lib/
│   ├── nexus_store_generator.dart
│   └── src/
│       └── fields_generator.dart
└── pubspec.yaml
```

**Test Files:**
```
packages/nexus_store/test/src/query/
└── type_safe_query_test.dart
```

## Dependencies

- Query builder (Task 4, complete)
- build_runner (for code generation, optional)

## API Preview

```dart
// Manual field definition
class UserFields extends Fields<User> {
  static final id = Field<User, String>('id');
  static final name = Field<User, String>('name');
  static final age = Field<User, int>('age');
  static final createdAt = Field<User, DateTime>('createdAt');
}

// Type-safe query usage
final query = TypeSafeQuery<User>()
  .where(UserFields.age.greaterThan(18))
  .where(UserFields.name.isNotNull())
  .orderBy(UserFields.createdAt, descending: true)
  .limit(10);

// Compile-time error: int vs String mismatch
// UserFields.age.equals('not a number')  // Error!

// Complex expressions
final query = TypeSafeQuery<User>()
  .where(
    UserFields.age.greaterThan(18).and(
      UserFields.name.startsWith('A').or(
        UserFields.name.startsWith('B')
      )
    )
  );

// Generated fields (with code gen)
@NexusEntity()
class User {
  final String id;
  final String name;
  final int age;
}
// Generates: class $UserFields { ... }

// Mix with string-based (backward compatible)
final query = Query<User>()
  .where('status', 'active')  // String-based still works
  .where(UserFields.age.greaterThan(21));  // Type-safe
```

## Notes

- Type-safe queries are opt-in, string-based remains default
- Code generation is optional but recommended for large projects
- Expression trees allow for powerful query composition
- Consider integration with Dart 3 patterns for cleaner API
- Performance: Expression evaluation happens at query build time, not runtime
- Future: Could generate TypeScript types for full-stack type safety
