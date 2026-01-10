# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Type-safe configuration classes for reduced boilerplate
- `BrickTableConfig<T, ID>` class for bundling table configuration
- `BrickSyncConfig` class for sync behavior configuration
- `BrickSyncPolicy` enum: `immediate`, `batch`, `manual`
- `BrickRetryPolicy` class for retry configuration with exponential backoff
- `BrickConflictResolution` enum: `serverWins`, `clientWins`, `lastWriteWins`
- `BrickBackend.withConfig()` factory method for streamlined setup
- `BrickManager` class for multi-entity coordination
- `BrickManager.withRepository()` factory for shared repository management
- `syncAll()` method for coordinated sync across all tables
- `totalPendingChanges` getter for aggregate pending count
- `syncStatusStream` for monitoring sync progress
- 90+ unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_brick_adapter
- `BrickBackend` implementation of `StoreBackend`
- Integration with Brick offline-first framework
- Automatic offline queue management
- SQLite local storage with Supabase sync
