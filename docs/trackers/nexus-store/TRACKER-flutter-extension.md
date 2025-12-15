# TRACKER: Flutter Extension Package

## Status: PENDING

## Overview

Implement the Flutter extension package for nexus_store, providing StreamBuilder widgets, provider patterns, and Flutter-specific utilities.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - Task 14
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Verify Flutter SDK dependency in pubspec.yaml
- [ ] Create lib/src/ directory structure
- [ ] Export public API from nexus_store_flutter.dart

### StoreResult Widgets
- [ ] `store_result_builder.dart`
  - [ ] StoreResultBuilder<T> StatelessWidget
  - [ ] Required: result (StoreResult<T>)
  - [ ] Required: builder (BuildContext, T) -> Widget
  - [ ] Optional: idle (BuildContext) -> Widget
  - [ ] Optional: pending (BuildContext, T?) -> Widget
  - [ ] Optional: error (BuildContext, Object, T?) -> Widget
  - [ ] Default idle: empty Container
  - [ ] Default pending: CircularProgressIndicator
  - [ ] Default error: error Text widget
  - [ ] Handle stale-while-revalidate (show data + loading indicator)

- [ ] `store_result_stream_builder.dart`
  - [ ] StoreResultStreamBuilder<T> StatelessWidget
  - [ ] Required: stream (Stream<StoreResult<T>>)
  - [ ] Required: builder (BuildContext, T) -> Widget
  - [ ] Optional: idle, pending, error callbacks
  - [ ] Wrap StreamBuilder internally
  - [ ] Handle stream errors gracefully

### Watch Builders
- [ ] `nexus_store_builder.dart`
  - [ ] NexusStoreBuilder<T, ID> StatefulWidget
  - [ ] Required: store (NexusStore<T, ID>)
  - [ ] Required: builder (BuildContext, List<T>) -> Widget
  - [ ] Optional: query (Query<T>)
  - [ ] Optional: loading (Widget)
  - [ ] Optional: error (BuildContext, Object) -> Widget
  - [ ] Auto-subscribe to watchAll() in initState
  - [ ] Auto-dispose subscription in dispose

- [ ] `nexus_store_item_builder.dart`
  - [ ] NexusStoreItemBuilder<T, ID> StatefulWidget
  - [ ] Required: store (NexusStore<T, ID>)
  - [ ] Required: id (ID)
  - [ ] Required: builder (BuildContext, T?) -> Widget
  - [ ] Optional: loading, error callbacks
  - [ ] Subscribe to watch(id)

### Provider Pattern
- [ ] `nexus_store_provider.dart`
  - [ ] NexusStoreProvider<T, ID> InheritedWidget
  - [ ] Provide NexusStore instance to widget tree
  - [ ] Static of<T, ID>(BuildContext) accessor
  - [ ] Static maybeOf<T, ID>(BuildContext) accessor
  - [ ] Handle store not found with clear error message

- [ ] `multi_nexus_store_provider.dart`
  - [ ] MultiNexusStoreProvider StatelessWidget
  - [ ] Accept list of providers to nest
  - [ ] Reduce boilerplate for multiple stores

### Extension Methods
- [ ] `build_context_extensions.dart`
  - [ ] context.nexusStore<T, ID>() extension
  - [ ] context.watchNexusStore<T, ID>() returning Stream
  - [ ] Convenient access patterns

### Hooks (Optional - if flutter_hooks used)
- [ ] `nexus_store_hooks.dart` (optional)
  - [ ] useNexusStore<T, ID>(store) hook
  - [ ] useNexusStoreWatch<T, ID>(store, id) hook
  - [ ] useNexusStoreWatchAll<T, ID>(store, query) hook
  - [ ] Only if flutter_hooks is a dependency

### Utilities
- [ ] `store_lifecycle_observer.dart`
  - [ ] NexusStoreLifecycleObserver WidgetsBindingObserver
  - [ ] Pause sync on app background
  - [ ] Resume sync on app foreground
  - [ ] Optional - attach to WidgetsBinding

### Widget Tests
- [ ] `test/store_result_builder_test.dart`
  - [ ] Renders idle state
  - [ ] Renders pending state
  - [ ] Renders success state with data
  - [ ] Renders error state
  - [ ] Handles stale data during refresh

- [ ] `test/store_result_stream_builder_test.dart`
  - [ ] Subscribes to stream
  - [ ] Updates on new emissions
  - [ ] Handles stream errors

- [ ] `test/nexus_store_builder_test.dart`
  - [ ] Subscribes to watchAll
  - [ ] Rebuilds on data changes
  - [ ] Disposes subscription

- [ ] `test/nexus_store_provider_test.dart`
  - [ ] Provides store to descendants
  - [ ] of() finds ancestor provider
  - [ ] maybeOf() returns null when not found
  - [ ] of() throws when not found

## Files

**Package Structure:**
```
packages/nexus_store_flutter/
├── lib/
│   ├── nexus_store_flutter.dart           # Public exports
│   └── src/
│       ├── widgets/
│       │   ├── store_result_builder.dart
│       │   ├── store_result_stream_builder.dart
│       │   ├── nexus_store_builder.dart
│       │   └── nexus_store_item_builder.dart
│       ├── providers/
│       │   ├── nexus_store_provider.dart
│       │   └── multi_nexus_store_provider.dart
│       ├── extensions/
│       │   └── build_context_extensions.dart
│       └── utils/
│           └── store_lifecycle_observer.dart
├── test/
│   ├── widgets/
│   │   ├── store_result_builder_test.dart
│   │   ├── store_result_stream_builder_test.dart
│   │   └── nexus_store_builder_test.dart
│   └── providers/
│       └── nexus_store_provider_test.dart
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  nexus_store:
    path: ../nexus_store

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mocktail: ^1.0.4
```

## Dependencies

- Core package (nexus_store) must be complete
- Core tests should pass
- Flutter SDK

## Notes

- Keep widgets simple and focused
- Follow Flutter widget best practices
- Use const constructors where possible
- Consider performance with large lists (ListView.builder)
- StoreResultBuilder mirrors Riverpod's AsyncValue.when() pattern
- Provider pattern similar to Provider package but simpler
- Widget tests use flutter_test and WidgetTester
- Consider adding example/ directory with sample usage
- Document each widget with /// doc comments
