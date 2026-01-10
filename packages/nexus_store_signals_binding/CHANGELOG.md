# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Signal bundles for reduced boilerplate
- `SignalsStoreConfig<T, ID>` class for store configuration with computed signals
- `SignalsStoreBundle<T, ID>` class for bundled signals
- `SignalsStoreBundle.create()` factory method
- `listSignal` property for reactive list access
- `stateSignal` property for loading/error state tracking
- Named computed signals via `computedSignals` configuration
- `computed(name)` accessor for named computed signals
- `SignalsManager` class for multi-store coordination
- `getBundle(name)` method for accessing store bundles
- `getListSignal(name)` and `getStateSignal(name)` methods
- `createCrossStoreComputed<R>()` for derived state across stores
- 189 unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_signals_binding
- Signals integration for fine-grained reactivity
- `NexusStoreSignal<T, ID>` for reactive store access
- `NexusItemSignal<T, ID>` for individual item signals
- Computed signals for derived data
- Effect integration for side effects
- Automatic signal disposal
