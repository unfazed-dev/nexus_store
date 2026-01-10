# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Provider bundles for reduced boilerplate
- `StoreProviderBundle<T, ID>` class for all-in-one provider creation
- `StoreProviderBundle.forStore()` factory method
- Generated providers: `storeProvider`, `allProvider`, `byIdProvider`, `statusProvider`, `byIdStatusProvider`
- `keepAlive` option for preventing auto-dispose
- `RiverpodStoreConfig<T, ID>` class for manager configuration
- `RiverpodStoreManager` class for multi-store coordination
- `getBundle(name)` method for accessing store bundles
- `allStoreProviders` getter for provider access
- `createOverrides(mocks)` method for simplified test setup
- Store dependencies configuration support
- 103 unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_riverpod_binding
- Riverpod providers for NexusStore integration
- `nexusStoreProvider` family for store instances
- `nexusItemProvider` family for individual items
- `nexusListProvider` family for filtered lists
- Auto-dispose support for efficient memory management
- Async value handling with Riverpod's `AsyncValue`
- Extension methods for provider access
