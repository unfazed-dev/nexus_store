# Version Upgrade Guide

This document tracks breaking changes between nexus_store versions and how to upgrade.

## Version 0.1.0 (Initial Release)

This is the initial release. No migration needed.

### Included Features

- **Core Package**
  - NexusStore<T, ID> main class
  - StoreBackend<T, ID> interface
  - Query builder with fluent API
  - Fetch policies (cacheFirst, networkFirst, etc.)
  - Write policies (cacheAndNetwork, networkFirst, etc.)
  - Sync status observability
  - Field-level and database encryption
  - HIPAA audit logging
  - GDPR compliance (export, erasure)

- **Backend Adapters**
  - PowerSync (offline-first with PostgreSQL sync)
  - Supabase (online realtime)
  - Drift (local SQLite)
  - Brick (code-gen offline-first)
  - CRDT (conflict-free replication)

- **Flutter Extension**
  - StoreResult sealed class
  - NexusStoreBuilder widget
  - NexusStoreItemBuilder widget
  - StoreResultBuilder widget
  - NexusStoreProvider
  - BuildContext extensions

## Future Versions

This section will be updated as new versions are released.

### Planned for Future Releases

- Transaction support
- Cursor-based pagination
- Type-safe query builder with code generation
- Conflict resolution callbacks
- Tag-based cache invalidation
- Telemetry and metrics
- Key derivation (PBKDF2/Argon2)
- Batch streaming
- Enhanced GDPR features

## Upgrade Checklist

When upgrading to a new version:

1. **Read the changelog** - Review breaking changes
2. **Update pubspec.yaml** - Bump version numbers
3. **Run dart pub upgrade** - Update dependencies
4. **Run dart analyze** - Check for deprecation warnings
5. **Run tests** - Verify nothing broke
6. **Test critical paths** - Manually verify key features

## Deprecation Policy

- Deprecated APIs include `@deprecated` annotation
- Deprecated APIs are removed after 2 minor versions
- Migration instructions provided in deprecation message

## Getting Help

If you encounter issues during upgrade:

1. Check the [GitHub Issues](https://github.com/user/nexus_store/issues)
2. Search for existing migration discussions
3. Open a new issue with your upgrade scenario

## Changelog

See [CHANGELOG.md](../../CHANGELOG.md) for the complete version history.
