# TRACKER: Riverpod Binding Package

## Status: ✅ COMPLETE (29 tests)

## Overview

Create `nexus_store_riverpod_binding` package that provides first-class Riverpod integration with code generation for auto-generated providers.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-046, Task 35
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [x] Create package skeleton
  - [x] `pubspec.yaml` with dependencies
  - [x] `analysis_options.yaml`
  - [x] Basic library structure

- [x] Add dependencies
  - [x] `flutter_riverpod: ^2.6.1`
  - [x] `riverpod_annotation: ^2.6.1`
  - [x] `nexus_store: (path)`
  - [x] `nexus_store_flutter: (path)`
  - [x] `flutter_hooks: ^0.20.5`
  - [x] `hooks_riverpod: ^2.6.1`

### Manual Providers (No Code Gen)
- [x] Create `createNexusStoreProvider<T, ID>` helper
  - [x] Wraps store in Provider
  - [x] Handles disposal with autoDispose option

- [x] Create `createAutoDisposeNexusStoreProvider<T, ID>` helper
  - [x] Auto-dispose variant for scoped stores

- [x] Create extension methods
  - [x] `store.bindToRef(ref)` → Auto-disposal on ref lifecycle
  - [x] `store.bindToAutoDisposeRef(ref)` → Auto-dispose variant
  - [x] `store.withKeepAlive(ref)` → Returns `NexusStoreKeepAlive` wrapper
  - [x] `ref.watchStoreAll(provider)` → `Stream<List<T>>`
  - [x] `ref.watchStoreItem(provider, id)` → `Stream<T?>`
  - [x] `ref.watchStoreAllWithStatus(provider)` → `Stream<StoreResult<List<T>>>`

### Stream Providers
- [x] Create `createWatchAllProvider<T, ID>` factory
  - [x] Wraps store.watchAll() as StreamProvider
  - [x] Optional query parameter

- [x] Create `createWatchByIdProvider<T, ID>` factory
  - [x] Wraps store.watch(id) as StreamProvider.family
  - [x] Supports different IDs independently

- [x] Create `createWatchWithStatusProvider<T, ID>` factory
  - [x] Wraps data in StoreResult for loading/error states

### Code Generation (Optional)
- [x] Create `@riverpodNexusStore` annotation
  - [x] Marks store factory for generation
  - [x] Options: keepAlive, name

- [x] Create `@RiverpodNexusStore(...)` configurable annotation
  - [x] `keepAlive: bool` - Prevent auto-dispose
  - [x] `name: String?` - Custom name prefix

- [x] Create `nexus_store_riverpod_generator` package
  - [x] Implements `Generator` from source_gen
  - [x] Builder configuration in build.yaml
  - [x] Generates provider code

### Disposal Integration
- [x] Implement `ref.onDispose` integration
  - [x] Close store on ref disposal
  - [x] Configurable via `StoreDisposalConfig`

- [x] Handle keepAlive stores
  - [x] `NexusStoreKeepAlive<T, ID>` wrapper
  - [x] Manual invalidation via `allowDispose()`

- [x] Create `StoreDisposalManager`
  - [x] Register multiple stores
  - [x] Dispose all on ref lifecycle
  - [x] Factory method `forRef(ref)`

### Widget Utilities
- [x] Create `NexusStoreListConsumer<T>` widget
  - [x] Wraps StreamProvider for list data
  - [x] Configurable loading/error widgets

- [x] Create `NexusStoreItemConsumer<T, ID>` widget
  - [x] Wraps family provider for single item
  - [x] Optional notFound callback

- [x] Create `NexusStoreRefreshableConsumer<T>` widget
  - [x] Pull-to-refresh support
  - [x] Refresh callback

- [x] Create `NexusStoreHookWidget` base class
  - [x] Base for hook-based widgets

### Hooks Integration
- [x] Create `useStoreCallback<T, ID, A, R>` hook
  - [x] Memoized callback for store operations

- [x] Create `useStoreOperation()` hook
  - [x] Returns (isLoading, execute) tuple
  - [x] Tracks async operation loading state

- [x] Create `useStoreDebouncedSearch()` hook
  - [x] Debounced search term with configurable duration
  - [x] Returns (debouncedValue, setValue) tuple

- [x] Create `useStoreDataWithPrevious<T>` hook
  - [x] Retains previous data while loading new
  - [x] Useful for skeleton loading patterns

- [x] Create WidgetRef extensions
  - [x] `watchStoreList<T>(provider)` → `AsyncValue<List<T>>`
  - [x] `watchStoreItem<T, ID>(provider, id)` → `AsyncValue<T?>`
  - [x] `readStore<T, ID>(provider)` → `NexusStore<T, ID>`
  - [x] `refreshStoreList<T>(provider)` → `Future<List<T>>`
  - [x] `refreshStoreItem<T, ID>(provider, id)` → `Future<T?>`

### Documentation & Examples
- [x] Write README.md
  - [x] Installation (with and without code generation)
  - [x] Basic usage with provider factories
  - [x] Extension methods documentation
  - [x] Widget utilities usage
  - [x] Hooks usage
  - [x] Code generation setup
  - [x] Disposal patterns
  - [x] Best practices
  - [x] API reference tables

### Unit Tests
- [x] `test/providers_test.dart` (17 tests)
  - [x] Provider creates store correctly
  - [x] Disposal called on container dispose when autoDispose=true
  - [x] Disposal NOT called when autoDispose=false
  - [x] StreamProvider emits watchAll() data
  - [x] Query parameter applied correctly
  - [x] Error propagation
  - [x] Multiple emissions from stream updates
  - [x] Family provider watches by ID
  - [x] Returns null for non-existent ID
  - [x] Different IDs create different providers
  - [x] Status provider wraps data in StoreResult.success

- [x] `test/extensions_test.dart` (12 tests)
  - [x] bindToRef disposes store on ref disposal
  - [x] Cascade chaining works
  - [x] bindToAutoDisposeRef works
  - [x] watchStoreAll returns stream
  - [x] Query parameter in watchStoreAll
  - [x] watchStoreItem returns stream
  - [x] watchStoreAllWithStatus wraps in StoreResult
  - [x] NexusStoreKeepAlive prevents auto-disposal
  - [x] allowDispose closes keepAlive link
  - [x] StoreDisposalManager disposes all stores
  - [x] forRef creates manager bound to lifecycle
  - [x] StoreDisposalConfig defaults

## Implementation Summary

### Packages Created

**nexus_store_riverpod_binding/**
```
lib/
├── nexus_store_riverpod_binding.dart    # Main export barrel
└── src/
    ├── annotations/
    │   └── riverpod_nexus_store.dart    # @riverpodNexusStore
    ├── extensions/
    │   ├── store_extensions.dart        # NexusStore.bindToRef
    │   └── ref_extensions.dart          # Ref/WidgetRef extensions
    ├── providers/
    │   ├── nexus_store_provider.dart    # createNexusStoreProvider
    │   ├── stream_providers.dart        # createWatchAllProvider
    │   └── family_providers.dart        # createWatchByIdProvider
    ├── widgets/
    │   ├── nexus_store_consumer.dart    # Consumer widgets
    │   └── nexus_store_hooks.dart       # Hooks utilities
    └── utils/
        └── disposal.dart                # Disposal utilities
test/
├── helpers/
│   ├── test_fixtures.dart              # TestUser, TestFixtures
│   └── mocks.dart                      # MockNexusStore, MockStoreHelper
├── providers_test.dart                 # 17 tests
└── extensions_test.dart                # 12 tests
```

**nexus_store_riverpod_generator/**
```
lib/
├── builder.dart                        # nexusStoreRiverpodBuilder
└── src/
    └── generator.dart                  # NexusStoreRiverpodGenerator
build.yaml                              # Builder configuration
pubspec.yaml
```

### Key Features

1. **Provider Factories**: `createNexusStoreProvider`, `createWatchAllProvider`, `createWatchByIdProvider`, `createWatchWithStatusProvider`

2. **Extensions**: `store.bindToRef(ref)`, `ref.watchStoreAll(provider)`, `ref.watchStoreItem(provider, id)`

3. **Disposal Utilities**: `NexusStoreKeepAlive`, `StoreDisposalManager`, `StoreDisposalConfig`

4. **Widget Utilities**: `NexusStoreListConsumer`, `NexusStoreItemConsumer`, `NexusStoreRefreshableConsumer`

5. **Hooks**: `useStoreCallback`, `useStoreOperation`, `useStoreDebouncedSearch`, `useStoreDataWithPrevious`

6. **Code Generation**: `@riverpodNexusStore` annotation with generator package

## Dependencies

- Core package (nexus_store) ✅
- Flutter extension (nexus_store_flutter) ✅
- `flutter_riverpod: ^2.6.1`
- `riverpod_annotation: ^2.6.1`
- `flutter_hooks: ^0.20.5`
- `hooks_riverpod: ^2.6.1`

## Notes

- Pattern matches bloc_binding package structure (183 tests reference)
- Uses mocktail for mocking
- All 29 tests passing
- Generator package creates skeleton for source_gen integration
- ConsumerWidget patterns for stateless, HookConsumerWidget for hooks
- Comprehensive README with usage examples and API reference
