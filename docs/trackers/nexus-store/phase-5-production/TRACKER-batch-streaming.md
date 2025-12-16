# TRACKER: Batch Streaming

## Status: PENDING

## Overview

Implement paginated streaming for efficiently watching large datasets without loading everything into memory, supporting infinite scroll patterns.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-025, Task 24
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `PagedResult<T>` class (if not done in Task 17)
  - [ ] `items: List<T>` - Items in current window
  - [ ] `hasMore: bool` - More items available
  - [ ] `isLoading: bool` - Currently loading next page
  - [ ] `error: Object?` - Last load error
  - [ ] `loadMore: Future<void> Function()` - Load next page

- [ ] Create `StreamingConfig` class
  - [ ] `pageSize: int` - Items per page (default 50)
  - [ ] `prefetchDistance: int` - Load next when N items from end
  - [ ] `maxPagesInMemory: int?` - Windowed loading limit
  - [ ] `debounce: Duration?` - Debounce rapid loads

### Core Implementation
- [ ] Add `watchAllPaginated()` to NexusStore
  - [ ] `Stream<PagedResult<T>> watchAllPaginated({...})`
  - [ ] Parameters: query, pageSize, prefetchDistance

- [ ] Implement pagination controller
  - [ ] Track current page/cursor
  - [ ] Manage loading state
  - [ ] Handle concurrent load requests

- [ ] Implement chunked loading
  - [ ] Load first page on subscribe
  - [ ] Load subsequent pages on demand
  - [ ] Emit updated PagedResult on each load

### Windowed Loading
- [ ] Implement page window management
  - [ ] Keep only N pages in memory
  - [ ] Release old pages when window moves
  - [ ] Re-fetch released pages if scrolled back

- [ ] Track visible range
  - [ ] Accept visibility hints from UI
  - [ ] Optimize which pages to keep

### Reactive Updates
- [ ] Handle data changes during streaming
  - [ ] New items appear in correct position
  - [ ] Deleted items removed from results
  - [ ] Updated items reflect changes

- [ ] Handle total count changes
  - [ ] New items added → hasMore may change
  - [ ] Items deleted → adjust counts

### Integration with Cursor Pagination
- [ ] Use cursor-based pagination internally
  - [ ] Leverage Task 17 cursor implementation
  - [ ] Maintain cursor per page boundary

- [ ] Handle sort order changes
  - [ ] Reset pagination on query change
  - [ ] Re-fetch from beginning

### Performance Optimization
- [ ] Implement request deduplication
  - [ ] Prevent duplicate page loads
  - [ ] Queue requests during active load

- [ ] Implement prefetching
  - [ ] Load next page before reaching end
  - [ ] Configurable prefetch distance

- [ ] Memory management
  - [ ] Estimate memory per item
  - [ ] Warn if exceeding recommended limit

### Flutter Integration (nexus_store_flutter)
- [ ] Create `NexusPaginatedListView<T>` widget
  - [ ] Wraps ListView.builder
  - [ ] Auto-triggers loadMore on scroll
  - [ ] Shows loading indicator

- [ ] Create `useNexusPaginated()` hook (optional)
  - [ ] For flutter_hooks users

### Unit Tests
- [ ] `test/src/core/paginated_stream_test.dart`
  - [ ] First page loads on subscribe
  - [ ] loadMore() loads next page
  - [ ] hasMore correctly reflects availability
  - [ ] Windowed loading releases old pages
  - [ ] Concurrent loads are deduplicated

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
