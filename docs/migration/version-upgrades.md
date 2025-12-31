# Version Upgrade Guide

This document tracks breaking changes between nexus_store versions and how to upgrade.

## Version 0.1.0 (Initial Release)

This is the initial release. No migration needed.

### Included Features

- **Core Package**
  - NexusStore<T, ID> main class
  - StoreBackend<T, ID> interface
  - Query builder with fluent API and type-safe expressions
  - Fetch policies (cacheFirst, networkFirst, etc.)
  - Write policies (cacheAndNetwork, networkFirst, etc.)
  - Sync status observability
  - Field-level and database encryption
  - HIPAA audit logging
  - GDPR compliance (export, erasure)
  - Transaction and saga support with nested transactions
  - Interceptor/middleware API with pre/post operation hooks
  - Delta sync with field-level change tracking
  - Connection pooling with health checks and telemetry
  - Background sync service with priority queues
  - Memory management with eviction and pressure handling
  - Circuit breaker, health checks, schema validation, and degradation patterns
  - Lazy field loading with on-demand loading and caching
  - Telemetry and metrics integration

- **Backend Adapters**
  - PowerSync (offline-first with PostgreSQL sync)
  - Supabase (online realtime with integration tests)
  - Drift (local SQLite)
  - Brick (code-gen offline-first)
  - CRDT (conflict-free replication)

- **Flutter Extension**
  - StoreResult sealed class with pattern matching
  - NexusStoreBuilder widget
  - NexusStoreItemBuilder widget
  - StoreResultBuilder widget
  - NexusStoreProvider
  - BuildContext extensions
  - Lazy loading widgets with visibility detection

- **State Management Bindings**
  - Riverpod providers and hooks (nexus_store_riverpod_binding)
  - Bloc/Cubit integration (nexus_store_bloc_binding)
  - Signals fine-grained reactivity (nexus_store_signals_binding)

- **Code Generators**
  - Entity generator for type-safe field accessors (nexus_store_entity_generator)
  - Lazy field accessor generator (nexus_store_generator)
  - Riverpod provider generator (nexus_store_riverpod_generator)

## Future Versions

This section will be updated as new versions are released.

### Planned for Future Releases

- Cursor-based pagination (in progress)
- Custom conflict resolution callbacks
- Tag-based cache invalidation
- Enhanced key rotation workflows
- Advanced GDPR consent management
- GraphQL backend adapter

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

1. Check the [GitHub Issues](https://github.com/unfazed-dev/nexus_store/issues)
2. Search for existing migration discussions
3. Open a new issue with your upgrade scenario

## Changelog

See [CHANGELOG.md](../../CHANGELOG.md) for the complete version history.
