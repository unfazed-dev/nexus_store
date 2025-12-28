# TRACKER: Lazy Field Loading

## Status: COMPLETE

## Overview

Implement on-demand loading for heavy fields (blobs, large text) to improve initial load performance and reduce memory usage.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-040, Task 32
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `LazyFieldState` enum
  - [x] `notLoaded` - Initial state
  - [x] `loading` - Currently loading
  - [x] `loaded` - Successfully loaded
  - [x] `error` - Load failed

- [x] Create `LazyField<T>` wrapper class
  - [x] `isLoaded: bool`
  - [x] `value: T?` - Null if not loaded
  - [x] `Future<T> load()` - Load the field
  - [x] `placeholder: T?` - Default value
  - [x] `reset()` - Reset to initial state
  - [x] `hasError: bool` - Check for error state
  - [x] `errorMessage: String?` - Error message if failed
  - [x] Concurrent load deduplication

- [x] Create `LazyLoadConfig` (@freezed)
  - [x] `lazyFields: Set<String>` - Fields to lazy load
  - [x] `batchSize: int` - Batch load limit
  - [x] `batchDelay: Duration` - Batching window
  - [x] `preloadOnWatch: bool` - Auto-load when watched
  - [x] `placeholders: Map<String, dynamic>` - Default values
  - [x] `isLazyField(String)` method
  - [x] `getPlaceholder(String)` method
  - [x] `hasLazyFields` getter
  - [x] Presets: `off`, `media`

### Field Loader
- [x] Create `FieldLoader<T, ID>` class
  - [x] `Future<dynamic> loadField(ID id, String fieldName)`
  - [x] `Future<Map<ID, dynamic>> loadFieldBatch(List<ID> ids, String fieldName)`
  - [x] `LazyFieldState getFieldState(ID id, String fieldName)`
  - [x] `Future<void> preloadFields(List<ID> ids, Set<String> fieldNames)`
  - [x] `void clearCache()`
  - [x] `void clearCacheForEntity(ID id)`
  - [x] `Future<void> dispose()`
  - [x] Concurrent request deduplication
  - [x] Caching of loaded values

- [x] Create `LazyFieldRegistry`
  - [x] Register lazy fields per entity type
  - [x] `register<T>(LazyLoadConfig config)`
  - [x] `getConfig<T>()` returns config or null
  - [x] `isLazy<T>(String fieldName)` check
  - [x] `clear()` method

### Backend Integration
- [x] Update `StoreBackend` interface
  - [x] `Future<dynamic> getField(ID id, String fieldName)`
  - [x] `Future<Map<ID, dynamic>> getFieldBatch(List<ID> ids, String fieldName)`
  - [x] `bool get supportsFieldOperations`

- [x] Add defaults in `StoreBackendDefaults` mixin
  - [x] Default implementations that throw UnsupportedError
  - [x] Fallback batch implementation using getField

- [x] Update `CompositeBackend`
  - [x] Implement new interface methods

- [x] Update test fixtures
  - [x] `FakeStoreBackend` with field storage support

### Entity Wrapper
- [x] Create `LazyEntity<T, ID>` wrapper
  - [x] Wraps entity with lazy field support
  - [x] `T get entity` - Access underlying entity
  - [x] `ID get id` - Entity identifier
  - [x] `dynamic getField(String fieldName)`
  - [x] `bool isFieldLoaded(String fieldName)`
  - [x] `Future<dynamic> loadField(String fieldName)`
  - [x] `Future<void> loadFields(Set<String> fieldNames)`
  - [x] `Future<void> loadAllLazyFields()`
  - [x] `Set<String> get unloadedFields`
  - [x] `Stream<String> get fieldLoadedStream`
  - [x] `Future<void> dispose()`

### NexusStore Integration
- [x] Add `lazyLoad` config to `StoreConfig`
- [x] Initialize `FieldLoader` when lazyLoad configured
- [x] Add `loadField(id, fieldName)` method
- [x] Add `loadFieldBatch(ids, fieldName)` method
- [x] Add `preloadFields(ids, fieldNames)` method
- [x] Add `getFieldState(id, fieldName)` method
- [x] Add `clearFieldCache()` method
- [x] Add `clearFieldCacheForEntity(id)` method
- [x] Dispose FieldLoader in store.dispose()

### Preloading Strategies
- [x] Implement `preload` query modifier
  - [x] `Query<T>().preload({'thumbnail'})`
  - [x] `Query<T>().preloadField('thumbnail')`
  - [x] Cumulative field addition
  - [x] `preloadFields` getter
  - [x] Preserved across all Query methods
  - [x] Included in equality/hashCode/toString

### Code Generation (Optional)
- [x] Create annotations for lazy field code generation
  - [x] `@Lazy` annotation for marking lazy fields
  - [x] `@NexusLazy` annotation for class-level code generation
  - [x] `@LazyAccessor` annotation for generated methods
- [x] Create `nexus_store_generator` package
  - [x] `LazyGenerator` using source_gen
  - [x] Generates accessor mixins with typed methods
  - [x] Generates wrapper classes extending `LazyEntity`
  - [x] build.yaml configuration for build_runner

### Visibility-based Loading (Optional)
- [x] Create `VisibilityLoader` widget
  - [x] On-demand loading when visible
  - [x] Placeholder while loading
  - [x] Error handling with retry
  - [x] Controller for manual control
  - [x] `loadOnce` parameter
- [x] Create `LazyListView` widget
  - [x] ListView with lazy field loading support
  - [x] `lazyFieldLoader` for item data
  - [x] `lazyPlaceholder` builder
  - [x] `lazyErrorBuilder` with retry
  - [x] `onItemVisible` callback
  - [x] Separator, padding, physics support
  - [x] Builder mode for index-based items

### Unit Tests
- [x] `test/src/lazy/lazy_field_state_test.dart` - 5 tests
- [x] `test/src/lazy/lazy_field_test.dart` - 23 tests
- [x] `test/src/lazy/lazy_load_config_test.dart` - 20 tests
- [x] `test/src/lazy/lazy_field_registry_test.dart` - 10 tests
- [x] `test/src/lazy/field_loader_test.dart` - 14 tests
- [x] `test/src/lazy/lazy_entity_test.dart` - 13 tests
- [x] `test/src/lazy/annotations_test.dart` - 11 tests
- [x] `test/src/core/nexus_store_lazy_loading_test.dart` - 22 tests
- [x] `test/src/query/query_preload_test.dart` - 11 tests

### Generator Tests (nexus_store_generator)
- [x] `test/lazy_generator_test.dart` - 4 tests

### Flutter Tests (nexus_store_flutter)
- [x] `test/src/lazy/visibility_loader_test.dart` - 14 tests
- [x] `test/src/lazy/lazy_list_view_test.dart` - 12 tests

**Total: 159 tests**

## Files

**Source Files:**
```
packages/nexus_store/lib/src/lazy/
├── annotations.dart            # @Lazy, @NexusLazy, @LazyAccessor
├── field_loader.dart           # FieldLoader<T, ID> service
├── lazy_entity.dart            # LazyEntity<T, ID> wrapper
├── lazy_field.dart             # LazyField<T> wrapper
├── lazy_field_registry.dart    # Per-type field configuration
├── lazy_field_state.dart       # LazyFieldState enum
└── lazy_load_config.dart       # LazyLoadConfig (@freezed)

packages/nexus_store/lib/src/config/
└── store_config.dart           # Updated with lazyLoad field

packages/nexus_store/lib/src/core/
├── nexus_store.dart            # Updated with lazy loading methods
└── store_backend.dart          # Updated with field operations

packages/nexus_store/lib/src/query/
└── query.dart                  # Updated with preload methods

packages/nexus_store_generator/
├── lib/
│   ├── builder.dart            # Builder entry point
│   └── src/
│       └── lazy_generator.dart # LazyGenerator implementation
├── build.yaml                  # Builder configuration
└── pubspec.yaml                # Package configuration

packages/nexus_store_flutter/lib/src/lazy/
├── visibility_loader.dart      # VisibilityLoader widget
└── lazy_list_view.dart         # LazyListView widget
```

**Test Files:**
```
packages/nexus_store/test/src/lazy/
├── annotations_test.dart
├── field_loader_test.dart
├── lazy_entity_test.dart
├── lazy_field_registry_test.dart
├── lazy_field_state_test.dart
├── lazy_field_test.dart
└── lazy_load_config_test.dart

packages/nexus_store/test/src/core/
└── nexus_store_lazy_loading_test.dart

packages/nexus_store/test/src/query/
└── query_preload_test.dart

packages/nexus_store_generator/test/
└── lazy_generator_test.dart

packages/nexus_store_flutter/test/src/lazy/
├── visibility_loader_test.dart
└── lazy_list_view_test.dart
```

## Dependencies

- Core package (Task 1, complete)

## API Example

```dart
// Configure store with lazy loading
final store = NexusStore<MediaItem, String>(
  backend: backend,
  config: StoreConfig(
    lazyLoad: LazyLoadConfig(
      lazyFields: {'thumbnail', 'fullDescription', 'fullResolutionImage'},
      batchSize: 10,
    ),
  ),
);

// Load specific field
final thumbnail = await store.loadField('item-123', 'thumbnail');

// Batch load for multiple items
final thumbnails = await store.loadFieldBatch(
  ['item-1', 'item-2', 'item-3'],
  'thumbnail',
);
// Returns Map<String, dynamic>

// Preload fields
await store.preloadFields(['item-1', 'item-2'], {'thumbnail', 'fullImage'});

// Check field state
final state = store.getFieldState('item-123', 'thumbnail');
if (state == LazyFieldState.loaded) {
  // Field is available
}

// Clear cache
store.clearFieldCache(); // All fields
store.clearFieldCacheForEntity('item-123'); // Specific entity

// Query with preloaded fields
final items = await store.getAll(
  query: Query<MediaItem>()
    .where('album', isEqualTo: albumId)
    .preload({'thumbnail', 'preview'}),
);

// Using LazyEntity wrapper
final lazyItem = LazyEntity<MediaItem, String>(
  item,
  idExtractor: (i) => i.id,
  fieldLoader: fieldLoader,
  config: LazyLoadConfig(lazyFields: {'thumbnail'}),
);

await lazyItem.loadField('thumbnail');
print(lazyItem.isFieldLoaded('thumbnail')); // true
```

## Notes

- Lazy loading trades latency for initial load speed
- Field caching prevents redundant backend calls
- Concurrent request deduplication prevents duplicate loads
- Backend must support field-level queries for optimal performance
- Consider preloading for predictable access patterns
- Query preload allows eager loading specific fields
- All components properly dispose resources
