# TRACKER: Flutter Extension Package

## Status: COMPLETE

## Overview

Implement the Flutter extension package for nexus_store, providing StreamBuilder widgets, provider patterns, and Flutter-specific utilities.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - Task 14
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [x] Verify Flutter SDK dependency in pubspec.yaml
- [x] Create lib/src/ directory structure
- [x] Export public API from nexus_store_flutter_widgets.dart

### StoreResult Type
- [x] `store_result.dart` - StoreResult<T> sealed class
  - [x] StoreResultIdle<T> - idle state
  - [x] StoreResultPending<T> - loading with optional previous data
  - [x] StoreResultSuccess<T> - success with data
  - [x] StoreResultError<T> - error with optional previous data
  - [x] when() pattern matching method
  - [x] maybeWhen() partial pattern matching
  - [x] map() transformation
  - [x] Extension methods (dataOr, requireData, isIdle, isSuccess, isRefreshing)

### StoreResult Widgets
- [x] `store_result_builder.dart`
  - [x] StoreResultBuilder<T> StatelessWidget
  - [x] Required: result (StoreResult<T>)
  - [x] Required: builder (BuildContext, T) -> Widget
  - [x] Optional: idle (BuildContext) -> Widget
  - [x] Optional: pending (BuildContext, T?) -> Widget
  - [x] Optional: error (BuildContext, Object, T?) -> Widget
  - [x] Default idle: empty SizedBox.shrink
  - [x] Default pending: CircularProgressIndicator
  - [x] Default error: error Text widget
  - [x] Handle stale-while-revalidate (show data + loading indicator)

- [x] `store_result_stream_builder.dart`
  - [x] StoreResultStreamBuilder<T> StatelessWidget
  - [x] Required: stream (Stream<StoreResult<T>>)
  - [x] Required: builder (BuildContext, T) -> Widget
  - [x] Optional: idle, pending, error callbacks
  - [x] Wrap StreamBuilder internally
  - [x] Handle stream errors gracefully
  - [x] DataStreamBuilder<T> for raw data streams

### Watch Builders
- [x] `nexus_store_builder.dart`
  - [x] NexusStoreBuilder<T, ID> StatefulWidget
  - [x] Required: store (NexusStore<T, ID>)
  - [x] Required: builder (BuildContext, List<T>) -> Widget
  - [x] Optional: query (Query<T>)
  - [x] Optional: loading (Widget)
  - [x] Optional: error (BuildContext, Object) -> Widget
  - [x] Auto-subscribe to watchAll() in initState
  - [x] Auto-dispose subscription in dispose
  - [x] Re-subscribe on store/query change

- [x] `nexus_store_item_builder.dart`
  - [x] NexusStoreItemBuilder<T, ID> StatefulWidget
  - [x] Required: store (NexusStore<T, ID>)
  - [x] Required: id (ID)
  - [x] Required: builder (BuildContext, T?) -> Widget
  - [x] Optional: loading, error callbacks
  - [x] Subscribe to watch(id)
  - [x] Re-subscribe on store/id change

### Provider Pattern
- [x] `nexus_store_provider.dart`
  - [x] NexusStoreProvider<T, ID> InheritedWidget
  - [x] Provide NexusStore instance to widget tree
  - [x] Static of<T, ID>(BuildContext) accessor
  - [x] Static maybeOf<T, ID>(BuildContext) accessor
  - [x] Handle store not found with clear error message

- [x] `multi_nexus_store_provider.dart`
  - [x] MultiNexusStoreProvider StatelessWidget
  - [x] Accept list of providers to nest
  - [x] Reduce boilerplate for multiple stores

### Extension Methods
- [x] `build_context_extensions.dart`
  - [x] context.nexusStore<T, ID>() extension
  - [x] context.maybeNexusStore<T, ID>() extension
  - [x] context.watchNexusStore<T, ID>() returning Stream
  - [x] context.watchNexusStoreItem<T, ID>(id) returning Stream

### Hooks (Optional - if flutter_hooks used)
- [x] Skipped - flutter_hooks not a dependency

### Utilities
- [x] `store_lifecycle_observer.dart`
  - [x] NexusStoreLifecycleObserver WidgetsBindingObserver
  - [x] Pause sync on app background
  - [x] Resume sync on app foreground
  - [x] attach()/detach() methods
  - [x] NexusStoreLifecycleObserverWidget wrapper

### Widget Tests (67 tests passing)
- [x] `test/types/store_result_test.dart`
  - [x] StoreResultIdle tests
  - [x] StoreResultPending tests
  - [x] StoreResultSuccess tests
  - [x] StoreResultError tests
  - [x] Extension methods tests

- [x] `test/widgets/store_result_builder_test.dart`
  - [x] Renders idle state
  - [x] Renders pending state
  - [x] Renders success state with data
  - [x] Renders error state
  - [x] Handles stale data during refresh

- [x] `test/widgets/nexus_store_builder_test.dart`
  - [x] Shows loading indicator initially
  - [x] Renders items when stream emits
  - [x] Shows error when stream errors
  - [x] Updates on new data
  - [x] Disposes subscription
  - [x] Resubscribes when store changes
  - [x] Passes query to watchAll

- [x] `test/providers/nexus_store_provider_test.dart`
  - [x] Provides store to descendants
  - [x] of() finds ancestor provider
  - [x] maybeOf() returns null when not found
  - [x] of() throws when not found
  - [x] Nested providers work correctly
  - [x] MultiNexusStoreProvider tests
  - [x] BuildContext extensions tests

## Files

**Package Structure:**
```
packages/nexus_store_flutter_widgets/
├── lib/
│   ├── nexus_store_flutter_widgets.dart           # Public exports
│   └── src/
│       ├── types/
│       │   └── store_result.dart          # StoreResult<T> sealed class
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
│   ├── types/
│   │   └── store_result_test.dart
│   ├── widgets/
│   │   ├── store_result_builder_test.dart
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
- **StoreResult<T>** created as sealed class since core package uses direct values/exceptions
