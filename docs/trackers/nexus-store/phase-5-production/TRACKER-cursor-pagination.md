# TRACKER: Cursor-Based Pagination

## Status: PENDING

## Overview

Implement cursor-based pagination for efficient navigation through large datasets, avoiding the performance issues of offset-based pagination.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-018, Task 17
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `Cursor` class
  - [ ] Opaque string representation
  - [ ] encode() static method
  - [ ] decode() static method
  - [ ] Stores sort field values for cursor position

- [ ] Create `PagedResult<T>` class
  - [ ] `items: List<T>` - Current page items
  - [ ] `nextCursor: Cursor?` - Cursor for next page
  - [ ] `previousCursor: Cursor?` - Cursor for previous page
  - [ ] `hasMore: bool` - More items available
  - [ ] `totalCount: int?` - Optional total count

- [ ] Create `PageInfo` class
  - [ ] `startCursor: Cursor?`
  - [ ] `endCursor: Cursor?`
  - [ ] `hasNextPage: bool`
  - [ ] `hasPreviousPage: bool`

### Query Builder Updates
- [ ] Add `after(Cursor cursor)` to `Query<T>`
  - [ ] Sets start position after cursor
  - [ ] Works with orderBy fields

- [ ] Add `before(Cursor cursor)` to `Query<T>`
  - [ ] Sets end position before cursor
  - [ ] Works with orderBy fields

- [ ] Add `first(int count)` to `Query<T>`
  - [ ] Alias for limit() with cursor semantics
  - [ ] Returns first N items after cursor

- [ ] Add `last(int count)` to `Query<T>`
  - [ ] Returns last N items before cursor
  - [ ] Requires reverse ordering

### Cursor Encoding
- [ ] Implement cursor encoding strategy
  - [ ] Base64 encode sort field values
  - [ ] Include field names for validation
  - [ ] Version prefix for future compatibility

- [ ] Handle multi-field ordering
  - [ ] Encode all orderBy field values
  - [ ] Decode and apply all conditions

- [ ] Handle edge cases
  - [ ] Null values in sort fields
  - [ ] Special characters in values
  - [ ] Invalid/tampered cursors

### NexusStore Integration
- [ ] Add `getAllPaged()` method
  - [ ] Returns `Future<PagedResult<T>>`
  - [ ] Accepts Query with cursor params

- [ ] Add `watchAllPaged()` method
  - [ ] Returns `Stream<PagedResult<T>>`
  - [ ] Reactive cursor-based pagination

### Query Translation
- [ ] Update `QueryTranslator` interface
  - [ ] Add cursor condition translation
  - [ ] Generate WHERE clause from cursor

- [ ] Implement for SQL backends (PowerSync, Drift)
  - [ ] `WHERE (col1, col2) > (val1, val2)` syntax
  - [ ] Handle descending order correctly

- [ ] Implement for Supabase backend
  - [ ] Use .gt(), .lt() with cursor values

### Unit Tests
- [ ] `test/src/query/cursor_test.dart`
  - [ ] Cursor encode/decode roundtrip
  - [ ] Multi-field cursor encoding
  - [ ] Invalid cursor handling

- [ ] `test/src/query/query_cursor_test.dart`
  - [ ] after() applies correct filter
  - [ ] before() applies correct filter
  - [ ] first() with after() pagination
  - [ ] last() with before() pagination

- [ ] `test/src/core/nexus_store_paged_test.dart`
  - [ ] getAllPaged() returns correct page
  - [ ] Navigation through pages works
  - [ ] Empty result handling

## Files

**Source Files:**
```
packages/nexus_store/lib/src/query/
├── cursor.dart           # Cursor class
├── paged_result.dart     # PagedResult<T> and PageInfo
└── query.dart            # Update with after/before/first/last
```

**Test Files:**
```
packages/nexus_store/test/src/query/
├── cursor_test.dart
└── query_cursor_test.dart
```

## Dependencies

- Query builder (Task 4, complete)
- QueryTranslator interface (complete)

## API Preview

```dart
// Basic cursor pagination
final firstPage = await store.getAllPaged(
  query: Query<User>()
    .orderBy('createdAt', descending: true)
    .first(20),
);

print('Users: ${firstPage.items.length}');
print('Has more: ${firstPage.hasMore}');

// Get next page
if (firstPage.nextCursor != null) {
  final secondPage = await store.getAllPaged(
    query: Query<User>()
      .orderBy('createdAt', descending: true)
      .after(firstPage.nextCursor!)
      .first(20),
  );
}

// Reactive pagination
store.watchAllPaged(
  query: Query<User>()
    .orderBy('name')
    .first(50),
).listen((page) {
  updateUI(page.items);
});

// Relay-style connection
final connection = await store.getAllPaged(
  query: Query<User>()
    .where('status', 'active')
    .orderBy('score', descending: true)
    .first(10)
    .after(cursor),
);
// connection.pageInfo.hasNextPage
// connection.pageInfo.endCursor
```

## Notes

- Cursor pagination is more efficient than offset for large datasets
- Cursors should be opaque to clients (no assumptions about format)
- Consider caching cursor positions for fast backward navigation
- Cursor must include all orderBy fields to maintain consistency
- Integration with GraphQL Relay spec is a future consideration
