# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
