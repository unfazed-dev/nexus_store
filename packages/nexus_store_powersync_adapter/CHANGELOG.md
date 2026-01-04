# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Test utilities for desktop integration tests (`TestPowerSyncOpenFactory`, `createTestPowerSyncDatabase()`)
- Helper functions `checkPowerSyncLibraryAvailable()` and `isHomebrewSqliteAvailable()` for test setup validation
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
