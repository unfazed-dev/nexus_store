# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Type-safe configuration classes for reduced boilerplate
- `DriftColumn` class with factory methods: `text()`, `integer()`, `real()`, `boolean()`, `dateTime()`, `blob()`
- `DriftTableConfig<T, ID>` class for bundling table name, columns, and serialization functions
- `DriftTableDefinition` class for schema generation
- `DriftIndex` class for index definitions
- `DriftBackend.withDatabase()` factory method for automatic database setup
- `DriftManager` class for multi-table coordination with shared database connection
- 57 unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_drift_adapter
- `DriftBackend` implementation of `StoreBackend`
- `DriftQueryTranslator` for Drift query generation
- Full offline support with SQLite storage
- Transaction support
- Watch queries for reactive updates
- Integration with Drift ORM
