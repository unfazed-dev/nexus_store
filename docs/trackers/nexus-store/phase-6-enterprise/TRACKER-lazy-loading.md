# TRACKER: Lazy Field Loading

## Status: PENDING

## Overview

Implement on-demand loading for heavy fields (blobs, large text) to improve initial load performance and reduce memory usage.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-040, Task 32
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `@LazyLoad()` annotation
  - [ ] `placeholder: dynamic` - Value before loading
  - [ ] `eager: bool` - Load immediately in getAll (default false)

- [ ] Create `LazyField<T>` wrapper class
  - [ ] `isLoaded: bool`
  - [ ] `value: T?` - Null if not loaded
  - [ ] `Future<T> load()` - Load the field
  - [ ] `placeholder: T?` - Default value

- [ ] Create `LazyLoadConfig` class
  - [ ] `lazyFields: Set<String>` - Fields to lazy load
  - [ ] `batchSize: int` - Batch load limit
  - [ ] `preloadOnWatch: bool` - Auto-load when watched

### Field Loader
- [ ] Create `FieldLoader<T, ID>` class
  - [ ] `Future<T> loadField(ID id, String fieldName)`
  - [ ] `Future<Map<ID, T>> loadFieldBatch(List<ID> ids, String fieldName)`
  - [ ] Track loading state per field

- [ ] Implement batch loading
  - [ ] Collect pending field requests
  - [ ] Execute in single backend call
  - [ ] Distribute results to waiters

- [ ] Create `LazyFieldRegistry`
  - [ ] Register lazy fields per entity type
  - [ ] Configure per-field loading behavior

### Backend Integration
- [ ] Update `StoreBackend` interface
  - [ ] `Future<dynamic> getField(ID id, String fieldName)`
  - [ ] `Future<Map<ID, dynamic>> getFieldBatch(List<ID> ids, String fieldName)`

- [ ] Implement in adapters
  - [ ] SQL: SELECT specific column
  - [ ] Document support requirements

### Entity Wrapper
- [ ] Create `LazyEntity<T>` wrapper
  - [ ] Wraps entity with lazy field support
  - [ ] Proxies field access
  - [ ] Tracks loaded state

- [ ] Implement lazy property access
  - [ ] Return placeholder if not loaded
  - [ ] Track which fields accessed
  - [ ] Provide `loadAll()` method

### Code Generation (Optional)
- [ ] Create `@NexusEntity` annotation enhancements
  - [ ] Recognize `@LazyLoad()` on fields
  - [ ] Generate lazy wrapper class

- [ ] Generate accessor methods
  - [ ] Async getter for lazy fields
  - [ ] Sync getter returns placeholder

### NexusStore Integration
- [ ] Add `lazyLoad` config to `StoreConfig`
- [ ] Modify `get()` to respect lazy config
- [ ] Add `loadField(id, fieldName)` method
- [ ] Add `loadFields(id, fieldNames)` method

### Preloading Strategies
- [ ] Implement `preload` query modifier
  - [ ] `Query<T>().preload(['thumbnail'])`
  - [ ] Load specified lazy fields with query

- [ ] Implement visibility-based loading
  - [ ] Load when item becomes visible
  - [ ] For Flutter ListView integration

### Unit Tests
- [ ] `test/src/core/lazy_field_test.dart`
  - [ ] Lazy fields not loaded initially
  - [ ] Load on demand works
  - [ ] Batch loading works
  - [ ] Placeholder values correct

## Files

**Source Files:**
```
packages/nexus_store/lib/src/core/
├── lazy_field.dart           # LazyField<T> wrapper
├── lazy_load_annotation.dart # @LazyLoad() annotation
├── field_loader.dart         # FieldLoader service
├── lazy_entity.dart          # LazyEntity<T> wrapper
└── lazy_field_registry.dart  # Field configuration

packages/nexus_store/lib/src/config/
└── lazy_load_config.dart     # LazyLoadConfig
```

**Test Files:**
```
packages/nexus_store/test/src/core/
├── lazy_field_test.dart
├── field_loader_test.dart
└── lazy_entity_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Code generation (Task 18, optional) - for annotations

## API Preview

```dart
// Define model with lazy fields
@freezed
class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required String name,
    required String thumbnailUrl, // Always loaded

    @LazyLoad(placeholder: null)
    Uint8List? thumbnail, // Lazy - loaded on demand

    @LazyLoad(placeholder: '')
    String? fullDescription, // Lazy

    @LazyLoad(placeholder: null)
    Uint8List? fullResolutionImage, // Lazy - large blob
  }) = _MediaItem;
}

// Configure store
final store = NexusStore<MediaItem, String>(
  backend: backend,
  config: StoreConfig(
    lazyLoad: LazyLoadConfig(
      lazyFields: {'thumbnail', 'fullDescription', 'fullResolutionImage'},
      batchSize: 10,
    ),
  ),
);

// Get item - lazy fields not loaded
final item = await store.get('item-123');
print(item!.name); // "My Photo"
print(item.thumbnail); // null (placeholder)
print(item.fullDescription); // "" (placeholder)

// Load specific field
final thumbnail = await store.loadField<Uint8List>('item-123', 'thumbnail');
// OR
final thumbnailLoaded = await item.loadField('thumbnail');

// Load multiple fields at once
final loaded = await store.loadFields('item-123', ['thumbnail', 'fullDescription']);

// Batch load for multiple items
final items = await store.getAll();
final thumbnails = await store.loadFieldBatch(
  items.map((i) => i.id).toList(),
  'thumbnail',
);
// Returns Map<String, Uint8List>

// Preload in query
final itemsWithThumbnails = await store.getAll(
  query: Query<MediaItem>()
    .where('album', albumId)
    .preload(['thumbnail']), // Load thumbnails with items
);

// Flutter integration - load on visibility
NexusLazyImage(
  store: mediaStore,
  itemId: item.id,
  field: 'thumbnail',
  placeholder: ShimmerPlaceholder(),
  builder: (context, bytes) => Image.memory(bytes),
);

// Using LazyField wrapper directly
class DetailScreen extends StatefulWidget {
  final MediaItem item;

  @override
  void initState() {
    super.initState();
    // Load lazy fields when screen opens
    mediaStore.loadFields(item.id, ['fullDescription', 'fullResolutionImage']);
  }
}
```

## Notes

- Lazy loading trades latency for initial load speed
- Consider preloading for predictable access patterns
- Batch loading significantly reduces network calls
- Backend must support field-level queries
- Not all backends support efficient partial loading
- Consider caching loaded fields separately
- Document memory implications of loading large blobs
- Placeholder values should be type-appropriate
