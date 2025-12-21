# TRACKER: Tag-Based Cache Invalidation

## Status: COMPLETE

## Overview

Implement tag-based and query-based cache invalidation for selective cache clearing, providing more granular control than invalidate() and invalidateAll().

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-022, Task 21
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Completed Tasks

### Data Models
- [x] Create `CacheEntry<ID>` wrapper class (`lib/src/cache/cache_entry.dart`)
  - [x] `id: ID` - The cached item ID
  - [x] `tags: Set<String>` - Associated tags
  - [x] `cachedAt: DateTime` - Cache timestamp
  - [x] `staleAt: DateTime?` - When entry becomes stale
  - [x] `isStale()` - Check staleness
  - [x] `markStale()` - Mark as immediately stale
  - [x] `copyWith()` - Immutable updates
  - [x] Equality implementation

- [x] Create `CacheStats` class (`lib/src/cache/cache_stats.dart`)
  - [x] `totalCount` - Total items tracked
  - [x] `staleCount` - Number of stale items
  - [x] `tagCounts` - Items per tag
  - [x] `freshCount` - Computed non-stale count
  - [x] `stalePercentage` - Computed percentage

- [x] Create `CacheTagIndex<ID>` class (`lib/src/cache/cache_tag_index.dart`)
  - [x] Bidirectional mapping (tag→IDs and ID→tags)
  - [x] `addTags()` - Add tags to ID
  - [x] `removeTags()` - Remove tags from ID
  - [x] `removeId()` - Remove ID and its tags
  - [x] `getTagsForId()` - Get tags for ID
  - [x] `getIdsByTag()` - Get IDs by single tag
  - [x] `getIdsByAnyTag()` - Get IDs matching any tag
  - [x] `getIdsByAllTags()` - Get IDs matching all tags
  - [x] `clear()` - Clear all mappings
  - [x] `allTags`, `allIds`, `isEmpty` getters

- [x] Create `InMemoryQueryEvaluator<T>` class (`lib/src/cache/query_evaluator.dart`)
  - [x] `FieldAccessor<T>` typedef for field extraction
  - [x] `evaluate()` - Filter items by query
  - [x] `matches()` - Check single item match
  - [x] Support all FilterOperator types

### FetchPolicyHandler Updates
- [x] Update `FetchPolicyHandler` with tag tracking (`lib/src/policy/fetch_policy_handler.dart`)
  - [x] Add `CacheTagIndex<ID> _tagIndex` field
  - [x] Add `Set<ID> _trackedIds` field
  - [x] `recordCachedItem(id, {tags})` - Track item with optional tags
  - [x] `addTags(id, tags)` - Add tags to existing item
  - [x] `removeTags(id, tags)` - Remove tags from item
  - [x] `getTags(id)` - Get tags for item
  - [x] `invalidateByTags(tags)` - Invalidate by tags
  - [x] `invalidateByIds(ids)` - Batch invalidation
  - [x] `invalidateWhere(query, fieldAccessor)` - Query-based invalidation
  - [x] `isStale(id)` - Public staleness check
  - [x] `removeEntry(id)` - Remove cache entry
  - [x] `getCacheStats()` - Return cache statistics

### NexusStore API
- [x] Update `NexusStore` constructor
  - [x] Add optional `idExtractor` parameter for tag tracking

- [x] Update `save()` method
  - [x] Add optional `tags` parameter
  - [x] `Future<T> save(T item, {WritePolicy? policy, Set<String>? tags})`
  - [x] Record in cache with tags using idExtractor

- [x] Update `saveAll()` method
  - [x] Add optional `tags` parameter
  - [x] Apply same tags to all items in batch

- [x] Add invalidation methods to `NexusStore`
  - [x] `invalidateByTags(Set<String> tags)` - Tag-based invalidation
  - [x] `invalidateByIds(List<ID> ids)` - Batch ID invalidation
  - [x] `invalidateWhere(Query<T>, {fieldAccessor})` - Query-based invalidation

- [x] Add tag management methods to `NexusStore`
  - [x] `addTags(ID id, Set<String> tags)`
  - [x] `removeTags(ID id, Set<String> tags)`
  - [x] `getTags(ID id)` - Returns Set<String>

- [x] Add cache inspection methods to `NexusStore`
  - [x] `isStale(ID id)` - Check staleness
  - [x] `getCacheStats()` - Return CacheStats

### Unit Tests
- [x] `test/src/cache/cache_entry_test.dart` (14 tests)
- [x] `test/src/cache/cache_stats_test.dart` (10 tests)
- [x] `test/src/cache/cache_tag_index_test.dart` (28 tests)
- [x] `test/src/cache/query_evaluator_test.dart` (19 tests)
- [x] `test/src/policy/fetch_policy_handler_test.dart` - Cache tags group (18 tests)
- [x] `test/src/core/nexus_store_test.dart` - Cache tags group (8 tests)

### Integration Tests
- [x] `test/src/cache/cache_tags_integration_test.dart` (12 tests)
  - [x] Full workflow: save with tags, retrieve, invalidate
  - [x] Tag accumulation and removal
  - [x] Invalidation by tags with staleness verification
  - [x] Tags preserved after invalidation
  - [x] Query-based invalidation
  - [x] Cache statistics accuracy
  - [x] Cross-tag invalidation patterns
  - [x] Batch operations
  - [x] Works without idExtractor (no tracking)

### Exports
- [x] Update `lib/nexus_store.dart` with new exports:
  - [x] `cache_entry.dart`
  - [x] `cache_stats.dart`
  - [x] `cache_tag_index.dart`
  - [x] `query_evaluator.dart`

## Files Created/Modified

**Source Files Created:**
```
packages/nexus_store/lib/src/cache/
├── cache_entry.dart         # CacheEntry<ID> metadata wrapper
├── cache_stats.dart         # CacheStats data class
├── cache_tag_index.dart     # Bidirectional tag-to-ID mapping
└── query_evaluator.dart     # InMemoryQueryEvaluator for filtering
```

**Source Files Modified:**
```
packages/nexus_store/lib/src/policy/fetch_policy_handler.dart  # Tag tracking
packages/nexus_store/lib/src/core/nexus_store.dart            # Public API
packages/nexus_store/lib/nexus_store.dart                     # Exports
```

**Test Files Created:**
```
packages/nexus_store/test/src/cache/
├── cache_entry_test.dart            # 14 tests
├── cache_stats_test.dart            # 10 tests
├── cache_tag_index_test.dart        # 28 tests
├── query_evaluator_test.dart        # 19 tests
└── cache_tags_integration_test.dart # 12 tests
```

**Test Files Modified:**
```
packages/nexus_store/test/src/policy/fetch_policy_handler_test.dart  # 18 new tests
packages/nexus_store/test/src/core/nexus_store_test.dart             # 8 new tests
```

## Test Summary

Total new tests: **109 tests**
- Cache data models: 71 tests
- FetchPolicyHandler cache tags: 18 tests
- NexusStore cache tags: 8 tests
- Integration tests: 12 tests

All tests passing.

## API Usage

```dart
// Save with tags
await store.save(
  user,
  tags: {'user-data', 'profile', 'team-${user.teamId}'},
);

// Save batch with tags
await store.saveAll(
  users,
  tags: {'user-data', 'active-users'},
);

// Invalidate by tags
store.invalidateByTags({'user-data'});
// All items tagged 'user-data' are now stale

// Invalidate by query
await store.invalidateWhere(
  Query<User>().where('teamId', isEqualTo: teamId),
  fieldAccessor: (user, field) => switch (field) {
    'teamId' => user.teamId,
    _ => null,
  },
);
// All users in that team are now stale

// Invalidate multiple IDs
store.invalidateByIds(['user-1', 'user-2', 'user-3']);

// Dynamic tag management
store.addTags('user-123', {'featured', 'promoted'});
store.removeTags('user-123', {'promoted'});

// Get tags for item
final tags = store.getTags('user-123');
// {'user-data', 'profile', 'team-5', 'featured'}

// Check staleness
if (store.isStale('user-123')) {
  // Refetch from network
}

// Cache statistics
final stats = store.getCacheStats();
print('Total cached: ${stats.totalCount}');
print('User-data tagged: ${stats.tagCounts['user-data']}');
print('Stale items: ${stats.staleCount}');
print('Stale percentage: ${stats.stalePercentage}%');
```

## Notes

- Tags are stored in memory via FetchPolicyHandler; not persisted to backend
- Tag operations are O(1) lookup via bidirectional CacheTagIndex
- Tags survive invalidation (only fetch times are cleared)
- `idExtractor` is required in NexusStore constructor for tag tracking to work
- Consider tag namespacing for large apps (e.g., 'user:profile', 'user:settings')
- `invalidateWhere` is more expensive than `invalidateByTags`; prefer tags when possible
