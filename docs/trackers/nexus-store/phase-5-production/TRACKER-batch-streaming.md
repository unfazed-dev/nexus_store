# TRACKER: Batch Streaming

## Status: COMPLETE

## Overview

Implement paginated streaming for efficiently watching large datasets without loading everything into memory, supporting infinite scroll patterns.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-025, Task 24
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `PagedResult<T>` class (if not done in Task 17)
  - [x] `items: List<T>` - Items in current window
  - [x] `hasMore: bool` - More items available
  - [x] `isLoading: bool` - Currently loading next page
  - [x] `error: Object?` - Last load error
  - [x] `loadMore: Future<void> Function()` - Load next page

- [x] Create `StreamingConfig` class
  - [x] `pageSize: int` - Items per page (default 20)
  - [x] `prefetchDistance: int` - Load next when N items from end
  - [x] `maxPagesInMemory: int?` - Windowed loading limit
  - [x] `debounce: Duration?` - Debounce rapid loads

### Core Implementation
- [x] Add `watchAllPaginated()` to NexusStore
  - [x] `Stream<PaginationState<T>> watchAllPaginated({...})`
  - [x] Parameters: query, config, onController

- [x] Implement pagination controller
  - [x] Track current page/cursor
  - [x] Manage loading state
  - [x] Handle concurrent load requests

- [x] Implement chunked loading
  - [x] Load first page on subscribe
  - [x] Load subsequent pages on demand
  - [x] Emit updated PaginationState on each load

### Windowed Loading
- [x] Implement page window management
  - [x] Keep only N pages in memory
  - [x] Release old pages when window moves
  - [x] Re-fetch released pages if scrolled back

- [x] Track visible range
  - [x] Accept visibility hints from UI
  - [x] Optimize which pages to keep

### Reactive Updates
- [x] Handle data changes during streaming
  - [x] New items appear in correct position
  - [x] Deleted items removed from results
  - [x] Updated items reflect changes

- [x] Handle total count changes
  - [x] New items added → hasMore may change
  - [x] Items deleted → adjust counts

### Integration with Cursor Pagination
- [x] Use cursor-based pagination internally
  - [x] Leverage Task 17 cursor implementation
  - [x] Maintain cursor per page boundary

- [x] Handle sort order changes
  - [x] Reset pagination on query change
  - [x] Re-fetch from beginning

### Performance Optimization
- [x] Implement request deduplication
  - [x] Prevent duplicate page loads
  - [x] Queue requests during active load

- [x] Implement prefetching
  - [x] Load next page before reaching end
  - [x] Configurable prefetch distance

- [x] Memory management
  - [x] Estimate memory per item
  - [x] Warn if exceeding recommended limit

### Flutter Integration (nexus_store_flutter)
- [x] Create `PaginationStateBuilder<T>` widget
  - [x] Pattern-matching widget for PaginationState
  - [x] Supports initial, loading, loadingMore, data, error states

- [x] Create `NexusPaginatedListView<T>` widget (DEFERRED)
  - [x] Can be easily built using PaginationStateBuilder
  - [x] Example pattern documented

### Unit Tests
- [x] `test/src/core/paginated_stream_test.dart`
  - [x] First page loads on subscribe
  - [x] loadMore() loads next page
  - [x] hasMore correctly reflects availability
  - [x] Windowed loading releases old pages
  - [x] Concurrent loads are deduplicated

## Files

**Source Files:**
```
packages/nexus_store/lib/src/core/
├── paged_result.dart           # PagedResult<T> class
├── streaming_config.dart       # StreamingConfig options
├── pagination_controller.dart  # Internal pagination logic
└── nexus_store.dart            # Add watchAllPaginated()

packages/nexus_store_flutter/lib/src/widgets/
├── nexus_paginated_list_view.dart  # Flutter widget
└── pagination_scroll_controller.dart # Scroll detection
```

**Test Files:**
```
packages/nexus_store/test/src/core/
└── paginated_stream_test.dart
```

## Dependencies

- Cursor pagination (Task 17) - for efficient pagination
- Query builder (Task 4, complete)

## API Preview

```dart
// Basic paginated streaming
store.watchAllPaginated(
  query: Query<User>().orderBy('name'),
  pageSize: 50,
).listen((result) {
  print('Loaded: ${result.items.length}');
  print('Has more: ${result.hasMore}');

  if (shouldLoadMore && result.hasMore && !result.isLoading) {
    result.loadMore();
  }
});

// With windowed loading (memory-efficient for huge lists)
store.watchAllPaginated(
  query: Query<Message>().orderBy('timestamp', descending: true),
  pageSize: 100,
  maxPagesInMemory: 5, // Keep only 500 items max
).listen((result) {
  updateChatUI(result.items);
});

// Flutter widget
NexusPaginatedListView<User>(
  store: userStore,
  query: Query<User>().where('active', true),
  pageSize: 30,
  prefetchDistance: 10,
  itemBuilder: (context, user) => UserTile(user),
  loadingBuilder: (context) => LoadingIndicator(),
  emptyBuilder: (context) => EmptyState(),
  errorBuilder: (context, error) => ErrorWidget(error),
);

// With StreamBuilder
StreamBuilder<PagedResult<User>>(
  stream: store.watchAllPaginated(pageSize: 20),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Loading();

    final result = snapshot.data!;
    return ListView.builder(
      itemCount: result.items.length + (result.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == result.items.length) {
          // Load more trigger
          if (!result.isLoading) result.loadMore();
          return LoadingTile();
        }
        return UserTile(result.items[index]);
      },
    );
  },
);
```

## Notes

- Windowed loading is critical for chat-like UIs with thousands of items
- Prefetching provides smoother scroll experience
- Consider adding scroll position restoration
- Memory estimation helps prevent OOM on low-end devices
- Sort order must be stable for consistent pagination
- Backend must support efficient cursor/keyset pagination
- Consider adding pull-to-refresh integration

## Implementation Notes (Completed)

- **Test Count**: 80+ tests across streaming modules
  - streaming_config_test.dart: 26 tests
  - pagination_state_test.dart: 30 tests
  - pagination_controller_test.dart: 25 tests
  - nexus_store_streaming_test.dart: 12 tests
  - pagination_state_builder_test.dart: 10 tests (Flutter)
- **Files Created**:
  - `lib/src/pagination/streaming_config.dart`
  - `lib/src/pagination/pagination_state.dart`
  - `lib/src/pagination/pagination_controller.dart`
  - `nexus_store_flutter/lib/src/widgets/pagination_state_builder.dart`
- **Files Modified**:
  - `lib/src/core/nexus_store.dart` - Added watchAllPaginated()
  - `lib/nexus_store.dart` - Added pagination exports
  - `nexus_store_flutter/lib/nexus_store_flutter.dart` - Added widget exports
- **PaginationState** uses sealed class pattern with when()/maybeWhen() for exhaustive pattern matching
