# TRACKER: Cursor-Based Pagination

## Status: COMPLETE

## Overview

Implement cursor-based pagination for efficient navigation through large datasets, avoiding the performance issues of offset-based pagination.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-018, Task 17
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `Cursor` class
  - [x] Opaque string representation
  - [x] encode() static method
  - [x] decode() static method
  - [x] Stores sort field values for cursor position

- [x] Create `PagedResult<T>` class
  - [x] `items: List<T>` - Current page items
  - [x] `nextCursor: Cursor?` - Cursor for next page
  - [x] `previousCursor: Cursor?` - Cursor for previous page
  - [x] `hasMore: bool` - More items available
  - [x] `totalCount: int?` - Optional total count

- [x] Create `PageInfo` class
  - [x] `startCursor: Cursor?`
  - [x] `endCursor: Cursor?`
  - [x] `hasNextPage: bool`
  - [x] `hasPreviousPage: bool`

### Query Builder Updates
- [x] Add `after(Cursor cursor)` to `Query<T>`
  - [x] Sets start position after cursor
  - [x] Works with orderBy fields

- [x] Add `before(Cursor cursor)` to `Query<T>`
  - [x] Sets end position before cursor
  - [x] Works with orderBy fields

- [x] Add `first(int count)` to `Query<T>`
  - [x] Alias for limit() with cursor semantics
  - [x] Returns first N items after cursor

- [x] Add `last(int count)` to `Query<T>`
  - [x] Returns last N items before cursor
  - [x] Requires reverse ordering

### Cursor Encoding
- [x] Implement cursor encoding strategy
  - [x] Base64 encode sort field values
  - [x] Include field names for validation
  - [x] Version prefix for future compatibility

- [x] Handle multi-field ordering
  - [x] Encode all orderBy field values
  - [x] Decode and apply all conditions

- [x] Handle edge cases
  - [x] Null values in sort fields
  - [x] Special characters in values
  - [x] Invalid/tampered cursors

### NexusStore Integration
- [x] Add `getAllPaged()` method
  - [x] Returns `Future<PagedResult<T>>`
  - [x] Accepts Query with cursor params

- [x] Add `watchAllPaged()` method
  - [x] Returns `Stream<PagedResult<T>>`
  - [x] Reactive cursor-based pagination

### Query Translation
- [x] Update `QueryTranslator` interface
  - [x] Add cursor condition translation
  - [x] Generate WHERE clause from cursor

- [x] Implement for SQL backends (PowerSync, Drift)
  - [x] `WHERE (col1, col2) > (val1, val2)` syntax
  - [x] Handle descending order correctly

- [x] Implement for Supabase backend
  - [x] Use .gt(), .lt() with cursor values

### Unit Tests
- [x] `test/src/query/cursor_test.dart`
  - [x] Cursor encode/decode roundtrip
  - [x] Multi-field cursor encoding
  - [x] Invalid cursor handling

- [x] `test/src/query/query_cursor_test.dart`
  - [x] after() applies correct filter
  - [x] before() applies correct filter
  - [x] first() with after() pagination
  - [x] last() with before() pagination

- [x] `test/src/core/nexus_store_paged_test.dart`
  - [x] getAllPaged() returns correct page
  - [x] Navigation through pages works
  - [x] Empty result handling

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

## Implementation Notes (Completed)

- **Test Count**: 120+ tests across pagination modules
  - cursor_test.dart: 32 tests
  - page_info_test.dart: 24 tests
  - paged_result_test.dart: 29 tests
  - query_cursor_test.dart: 34 tests
  - nexus_store_pagination_test.dart: 17 tests
- **Files Created**:
  - `lib/src/pagination/cursor.dart`
  - `lib/src/pagination/page_info.dart`
  - `lib/src/pagination/paged_result.dart`
- **Files Modified**:
  - `lib/src/query/query.dart` - Added after(), before(), first(), last()
  - `lib/src/core/store_backend.dart` - Added getAllPaged(), watchAllPaged()
  - `lib/src/core/nexus_store.dart` - Added pagination methods
  - `test/fixtures/mock_backend.dart` - Added pagination support
