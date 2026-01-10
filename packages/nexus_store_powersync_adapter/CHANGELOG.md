# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

#### Multi-Table Support
- `PowerSyncManager` for multi-table app support with shared database connection
- `PowerSyncManager.withSupabase()` factory for batteries-included multi-table setup
- `PSTableConfig<T, ID>` for individual table configuration in multi-table apps

#### Sync Rules Generation
- `PSSyncRules`, `PSBucket`, `PSQuery` for programmatic sync rules YAML generation
- Three bucket types: `PSBucket.global()`, `PSBucket.userScoped()`, `PSBucket.parameterized()`
- `syncRules.saveToFile()` for saving generated YAML to disk

#### Factory Methods
- `PowerSyncBackend.withSupabase()` factory for batteries-included single-table setup
- Automatic schema, database, and connector configuration

#### Database Abstraction Layer
- `PowerSyncDatabaseAdapter` abstraction layer for improved testability
- `DefaultPowerSyncDatabaseAdapter` production implementation
- `PowerSyncDatabaseWrapper` for testing abstraction
- `PowerSyncDatabaseAdapterFactory` type for dependency injection

#### Supabase Integration
- `SupabasePowerSyncConnector` for Supabase authentication and data sync
- `SupabaseAuthProvider` interface with `DefaultSupabaseAuthProvider` implementation
- `SupabaseDataProvider` interface with `DefaultSupabaseDataProvider` implementation
- Fatal vs transient error handling for upload operations

#### Lifecycle Management
- Proper lifecycle management with `dispose()` methods on backends and manager
- Automatic resource cleanup on dispose

#### Test Utilities
- `TestPowerSyncOpenFactory` for desktop integration tests
- `createTestPowerSyncDatabase()` helper function
- `checkPowerSyncLibraryAvailable()` and `isHomebrewSqliteAvailable()` for test setup validation
- Download script for PowerSync native binaries (`scripts/download_powersync_binary.sh`)

### Fixed
- SQL syntax error when using `offsetBy()` without `limitTo()` - SQLite requires LIMIT before OFFSET, now correctly generates `LIMIT -1 OFFSET n`

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_powersync_adapter
- `PowerSyncBackend` implementation of `StoreBackend`
- `PowerSyncEncryptedBackend` for SQLCipher encryption support
- `PowerSyncQueryTranslator` for SQL query generation
- Full offline-first support with automatic sync
- Real-time sync status tracking
- Pending changes management
- Encryption key rotation support
- Integration with PowerSync SDK
