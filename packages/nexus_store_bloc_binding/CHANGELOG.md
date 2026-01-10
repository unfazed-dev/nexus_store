# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Bloc bundles and state helpers for reduced boilerplate
- `BlocStoreConfig<T, ID>` class for store configuration
- `LoadingStateConfig` class for customizable loading behavior
- `BlocStoreBundle<T, ID>` class for bundled bloc/cubit creation
- `BlocStoreBundle.create()` factory method
- `listBloc` and `itemCubit(id)` accessors
- `BlocManager` class for multi-store coordination
- `getBundle(name)`, `getListCubit(name)`, `getListBloc(name)` methods
- `refreshAll()` for coordinated refresh across all stores
- `isAnyLoading` and `isAnyLoadingStream` for aggregate loading state
- `firstError` and `errorStream` for error aggregation
- `NexusStoreStateX` extension with `mapData()`, `where()`, `firstOrNull`, `findById()`, `combineWith()`
- `CombinedState<T, R>` class for combined state handling
- `NexusStoreCubitX` extension with `loadDebounced()` and `loadWithRetry()`
- `NexusStoreBlocX` extension with `addDebounced()`
- `EventSequences` class for pre-built event patterns
- 65 unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_bloc_binding
- `NexusStoreCubit<T, ID>` for list data management
- `NexusItemCubit<T, ID>` for single item management
- `NexusStoreState` sealed class (Initial, Loading, Loaded, Error)
- `NexusItemState` sealed class (Initial, Loading, Loaded, NotFound, Error)
- `NexusStoreBlocObserver` for debugging and logging
- Automatic stream subscription management
- Policy support for save and delete operations
