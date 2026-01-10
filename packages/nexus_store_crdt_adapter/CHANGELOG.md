# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Type-safe configuration classes for reduced boilerplate
- `CrdtColumn` class with factory methods: `text()`, `integer()`, `real()`, `blob()`
- `CrdtTableConfig<T, ID>` class for bundling table configuration with merge strategies
- `CrdtTableDefinition` class for schema generation
- `CrdtIndex` class for index definitions
- `CrdtBackend.withDatabase()` factory method for automatic setup
- `CrdtManager` class for multi-table CRDT coordination with shared database
- `CrdtMergeStrategy` enum: `lww` (Last Writer Wins), `fww` (First Writer Wins), `custom`
- `CrdtMergeConfig<T>` class for per-field merge strategies
- `CrdtFieldMerger` and `CrdtMergeFunction` for custom merge logic
- `CrdtMergeResult<T>` and `CrdtConflictDetail` classes for merge outcomes
- `CrdtPeerConnector` abstract class for peer sync abstraction
- `CrdtPeerConnectionState` enum for connection lifecycle
- `CrdtChangesetMessage` class for changeset transport
- `CrdtMemoryConnector` and `CrdtPeerConnectorPair` for testing
- `CrdtSyncRules` class for sync filtering configuration
- `CrdtSyncTableRule` class for per-table sync behavior
- `CrdtSyncDirection` enum: `bidirectional`, `pushOnly`, `pullOnly`, `none`
- 403 unit tests with 100% coverage

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_crdt_adapter
- `CRDTBackend` implementation of `StoreBackend`
- Conflict-free replicated data type support
- Automatic merge conflict resolution
- Multi-device sync without conflicts
