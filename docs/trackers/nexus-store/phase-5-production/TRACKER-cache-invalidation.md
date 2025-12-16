# TRACKER: Tag-Based Cache Invalidation

## Status: PENDING

## Overview

Implement tag-based and query-based cache invalidation for selective cache clearing, providing more granular control than invalidate() and invalidateAll().

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-022, Task 21
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `CacheEntry<T>` wrapper class
  - [ ] `item: T` - The cached item
  - [ ] `tags: Set<String>` - Associated tags
  - [ ] `cachedAt: DateTime` - Cache timestamp
  - [ ] `staleAt: DateTime?` - When entry becomes stale

- [ ] Create `CacheTagIndex` class
  - [ ] Map tags to item IDs
  - [ ] Efficient lookup by tag
  - [ ] Add/remove tag associations

### Cache Storage Updates
- [ ] Update internal cache structure
  - [ ] Store CacheEntry instead of raw items
  - [ ] Maintain tag index

- [ ] Update `save()` method
  - [ ] Add optional `tags` parameter
  - [ ] `Future<T> save(T item, {Set<String>? tags})`
  - [ ] Store tags with cached item

- [ ] Update `saveAll()` method
  - [ ] Add optional `tags` parameter
  - [ ] Apply same tags to all items in batch

### Invalidation Methods
- [ ] Add `invalidateByTags(Set<String> tags)` method
  - [ ] Find all items with any matching tag
  - [ ] Mark them as stale
  - [ ] Trigger watch stream updates

- [ ] Add `invalidateWhere(Query<T> query)` method
  - [ ] Find items matching query
  - [ ] Mark them as stale
  - [ ] Efficient for simple queries

- [ ] Add `invalidateByIds(List<ID> ids)` method
  - [ ] Batch version of invalidate()
  - [ ] More efficient than calling invalidate() in loop

### Watch Stream Integration
- [ ] Update watch streams on invalidation
  - [ ] Emit updated list after invalidation
  - [ ] If policy is cacheAndNetwork, trigger refetch

- [ ] Add `onInvalidate` callback option
  - [ ] Called when items are invalidated
  - [ ] Allows custom refetch logic

### Tag Management
- [ ] Add `addTags(ID id, Set<String> tags)` method
  - [ ] Add tags to existing cached item
  - [ ] Useful for dynamic tagging

- [ ] Add `removeTags(ID id, Set<String> tags)` method
  - [ ] Remove tags from cached item

- [ ] Add `getTags(ID id)` method
  - [ ] Get current tags for item
  - [ ] Returns null if not cached

### Cache Statistics
- [ ] Add `getCacheStats()` method
  - [ ] Total items cached
  - [ ] Items per tag
  - [ ] Stale item count

### Unit Tests
- [ ] `test/src/cache/cache_tags_test.dart`
  - [ ] Save with tags stores tags
  - [ ] invalidateByTags marks correct items stale
  - [ ] invalidateWhere matches query correctly
  - [ ] Tag index updates on save/delete
  - [ ] Watch streams emit after invalidation

## Files

**Source Files:**
```
packages/nexus_store/lib/src/cache/
├── cache_entry.dart         # CacheEntry<T> wrapper
├── cache_tag_index.dart     # Tag to ID mapping
└── cache_manager.dart       # Cache operations with tags

packages/nexus_store/lib/src/core/
└── nexus_store.dart         # Update save(), add invalidation methods
```

**Test Files:**
```
packages/nexus_store/test/src/cache/
└── cache_tags_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Query builder (Task 4, complete)

## API Preview

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
store.invalidateWhere(
  Query<User>().where('teamId', teamId),
);
// All users in that team are now stale

// Invalidate multiple IDs
store.invalidateByIds(['user-1', 'user-2', 'user-3']);

// Dynamic tag management
await store.addTags('user-123', {'featured', 'promoted'});
await store.removeTags('user-123', {'promoted'});

// Get tags for item
final tags = store.getTags('user-123');
// {'user-data', 'profile', 'team-5', 'featured'}

// Cache statistics
final stats = store.getCacheStats();
print('Total cached: ${stats.totalItems}');
print('User-data tagged: ${stats.itemsPerTag['user-data']}');
print('Stale items: ${stats.staleCount}');

// Listen and invalidate pattern
userStore.watchAll().listen((users) {
  // When users change, invalidate related caches
  postStore.invalidateByTags({'posts-by-users'});
});
```

## Notes

- Tags are stored in memory; not persisted to backend
- Tag operations are O(1) lookup via index
- Consider tag namespacing for large apps (e.g., 'user:profile', 'user:settings')
- invalidateWhere is more expensive than invalidateByTags; prefer tags when possible
- Tags should be invalidated when related data changes (e.g., user updates → invalidate user's posts)
- Consider adding tag TTL for automatic expiration
