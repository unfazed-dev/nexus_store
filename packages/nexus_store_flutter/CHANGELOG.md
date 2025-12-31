# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_flutter package
- `NexusStoreProvider` widget for dependency injection
- `MultiNexusStoreProvider` for multiple store instances
- `NexusStoreBuilder` widget for reactive data display
- `NexusStoreItemBuilder` for single item watching
- `StoreResultBuilder` for handling async states (idle, pending, success, error)
- `StoreResultStreamBuilder` for stream-based results
- `PaginationStateBuilder` for paginated data display
- `StoreResult<T>` sealed class with pattern matching (`when`, `maybeWhen`, `map`)
- `LazyListView` for virtualized lazy loading
- `VisibilityLoader` for viewport-based loading
- `StoreLifecycleObserver` for app lifecycle integration
- `FlutterMemoryPressureHandler` for system memory pressure handling
- Background sync support with `BackgroundSyncService`
- `BackgroundSyncConfig` for sync configuration
- `PrioritySyncQueue` for prioritized sync operations
- BuildContext extensions for store access
