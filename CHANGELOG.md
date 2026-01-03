# Changelog

All notable changes to nexus_store packages will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Integration tests for Supabase backend functionality
- Dart analyzer fixer skill with auto-fix scripts and TDD integration

### Fixed
- Resolved 49 dart analyzer issues in PowerSync integration tests
- Resolved all 173 dart analyzer issues across monorepo

### Changed
- Prepared packages for pub.dev publishing
- Removed generated files from version control
- Added gitignore and updated documentation

---

## [0.1.0] - 2024-12-31

### Initial Release

This is the first public release of nexus_store, a unified reactive data store abstraction for Dart and Flutter.

### Added

#### Core Package (`nexus_store`)

- **NexusStore<T, ID>** - Main store class with policy-based data management
- **StoreBackend<T, ID>** - Backend interface for implementing custom adapters
- **Query Builder** - Fluent API for building type-safe queries
  - `where()` with operators: isEqualTo, isNotEqualTo, isGreaterThan, isLessThan, whereIn, arrayContains
  - `orderBy()` with ascending/descending support
  - `limit()` and `offset()` for pagination
- **Fetch Policies** - Apollo GraphQL-style data fetching
  - `cacheFirst` - Use cache, fetch only if missing
  - `networkFirst` - Fetch from network, fall back to cache
  - `cacheOnly` - Only use cached data
  - `networkOnly` - Always fetch from network
  - `cacheAndNetwork` - Return cache immediately, update with network
- **Write Policies** - Control how writes are persisted
  - `cacheOnly` - Write to cache only
  - `networkOnly` - Write to network only
  - `cacheAndNetwork` - Write to both (default)
  - `networkFirst` - Network first, cache on success
- **Reactive Streams** - RxDart-powered observability
  - `watch()` - Observe single entity changes
  - `watchAll()` - Observe collection changes
  - `syncStatusStream` - Monitor sync state
  - `pendingChangesCount` - Track offline changes
- **Encryption** - Data protection features
  - SQLCipher database encryption (via backends)
  - Field-level encryption for sensitive fields
  - Key rotation support
- **HIPAA Audit Logging**
  - All CRUD operations logged
  - Hash chain integrity verification
  - Actor and session tracking
  - Configurable audit storage
- **GDPR Compliance**
  - `exportSubjectData()` - Article 20 data portability
  - `eraseSubjectData()` - Article 17 right to erasure
  - `accessSubjectData()` - Article 15 access reports
  - Pseudonymization support

#### Flutter Extension (`nexus_store_flutter_widgets`)

- **StoreResult<T>** - Sealed class for async states
  - `StoreResult.idle()` - Initial state
  - `StoreResult.pending()` - Loading with optional previous data
  - `StoreResult.success()` - Successful result with data
  - `StoreResult.failure()` - Error with optional previous data
- **StoreResultBuilder<T>** - Widget for rendering StoreResult states
- **NexusStoreBuilder<T, ID>** - Widget for watching store collections
- **NexusStoreItemBuilder<T, ID>** - Widget for watching single entities
- **NexusStoreProvider** - InheritedWidget for store access
- **BuildContext Extensions**
  - `context.nexusStore<T, ID>()` - Access store from context
  - `context.watchStore<T, ID>()` - Watch store with StreamBuilder

#### Backend Adapters

- **nexus_store_powersync_adapter**
  - Offline-first sync with PostgreSQL
  - SQLCipher encryption support
  - Conflict resolution via server
  - Real-time sync status

- **nexus_store_supabase_adapter**
  - Online realtime backend
  - Row-Level Security (RLS) compatible
  - Postgres Changes subscription
  - Schema and column mapping

- **nexus_store_drift_adapter**
  - Local-only SQLite storage
  - Integration with existing Drift databases
  - Full query translation
  - Watch query support

- **nexus_store_brick_adapter**
  - Code-generation offline-first
  - Brick model integration
  - Repository pattern support
  - SQLite + REST sync

- **nexus_store_crdt_adapter**
  - Conflict-free replicated data types
  - Hybrid Logical Clock (HLC) timestamps
  - Last-Write-Wins (LWW) conflict resolution
  - Tombstone-based deletions
  - Multi-device sync support

### Documentation

- Comprehensive README for all packages
- Architecture documentation
- Migration guides from raw backends
- Example applications

## Future Releases

### Planned Features

- Transaction support for batch operations
- Cursor-based pagination
- Type-safe query builder with code generation
- Custom conflict resolution callbacks
- Tag-based cache invalidation
- Telemetry and metrics
- Key derivation (PBKDF2/Argon2)
- Batch streaming for large datasets
- Enhanced GDPR consent management

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 0.1.0 | 2024-12-31 | Initial release |

## Links

- [GitHub Repository](https://github.com/unfazed-dev/nexus_store)
- [Documentation](https://github.com/unfazed-dev/nexus_store/tree/main/docs)
- [Issues](https://github.com/unfazed-dev/nexus_store/issues)
