# TRACKER: Documentation & Examples

## Status: PENDING

## Overview

Create comprehensive documentation for the nexus_store package ecosystem including README files, API documentation, and example applications.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - Task 15
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Root README
- [ ] `README.md` at monorepo root
  - [ ] Package name and badges (pub.dev, CI, coverage)
  - [ ] One-line description
  - [ ] Feature highlights (5-7 bullet points)
  - [ ] Quick start code example
  - [ ] Installation instructions
  - [ ] Links to package READMEs
  - [ ] Requirements (Dart SDK, Flutter SDK)
  - [ ] License information
  - [ ] Contributing guidelines link

### Core Package README
- [ ] `packages/nexus_store/README.md`
  - [ ] Package description
  - [ ] Installation (pubspec.yaml snippet)
  - [ ] Basic usage example
  - [ ] Configuration options
  - [ ] Fetch policies explanation
  - [ ] Write policies explanation
  - [ ] Query builder examples
  - [ ] Reactive streams (watch/watchAll)
  - [ ] Encryption configuration
  - [ ] Audit logging setup
  - [ ] GDPR compliance usage
  - [ ] Error handling patterns
  - [ ] API reference link

### Adapter Package READMEs
- [ ] `packages/nexus_store_powersync_adapter/README.md`
  - [ ] PowerSync integration overview
  - [ ] Prerequisites (PowerSync account, schema)
  - [ ] Installation
  - [ ] Configuration example
  - [ ] SQLCipher encryption setup
  - [ ] Sync status handling
  - [ ] Migration guide from raw PowerSync

- [ ] `packages/nexus_store_drift_adapter/README.md`
  - [ ] Drift integration overview
  - [ ] Prerequisites (Drift setup, code generation)
  - [ ] Installation
  - [ ] Configuration example
  - [ ] Table mapping patterns
  - [ ] Local-only usage patterns

- [ ] `packages/nexus_store_supabase_adapter/README.md`
  - [ ] Supabase integration overview
  - [ ] Prerequisites (Supabase project, RLS)
  - [ ] Installation
  - [ ] Configuration example
  - [ ] Realtime setup requirements
  - [ ] Authentication handling

- [ ] `packages/nexus_store_brick_adapter/README.md`
  - [ ] Brick integration overview
  - [ ] Prerequisites (Brick models, repository)
  - [ ] Installation
  - [ ] Configuration example
  - [ ] Model requirements
  - [ ] Offline-first patterns

- [ ] `packages/nexus_store_crdt_adapter/README.md`
  - [ ] CRDT concepts explanation
  - [ ] Prerequisites (sqlite_crdt setup)
  - [ ] Installation
  - [ ] Configuration example
  - [ ] Conflict resolution (LWW)
  - [ ] Tombstone behavior
  - [ ] Sync transport options

### Flutter Extension README
- [ ] `packages/nexus_store_flutter/README.md`
  - [ ] Widget overview
  - [ ] Installation
  - [ ] StoreResultBuilder usage
  - [ ] NexusStoreBuilder usage
  - [ ] Provider pattern usage
  - [ ] Extension methods
  - [ ] Complete widget example

### Example Applications
- [ ] `example/` directory at monorepo root
  - [ ] `example/README.md` - Overview of examples

- [ ] `example/basic_usage/`
  - [ ] Simple CRUD operations
  - [ ] In-memory backend for demo
  - [ ] Query examples
  - [ ] Watch stream examples

- [ ] `example/powersync_todo/`
  - [ ] Todo app with PowerSync
  - [ ] Offline-first demonstration
  - [ ] Sync status UI
  - [ ] Full CRUD operations

- [ ] `example/drift_notes/`
  - [ ] Notes app with Drift
  - [ ] Local-only storage
  - [ ] Search and filtering

- [ ] `example/supabase_chat/`
  - [ ] Chat app with Supabase
  - [ ] Realtime subscriptions
  - [ ] Authentication integration

- [ ] `example/flutter_widgets/`
  - [ ] Flutter widget showcase
  - [ ] StoreResultBuilder demos
  - [ ] Provider pattern usage
  - [ ] Loading/error states

### API Documentation
- [ ] Add dartdoc comments to all public APIs
  - [ ] NexusStore class and methods
  - [ ] StoreBackend interface
  - [ ] StoreConfig and options
  - [ ] Query builder methods
  - [ ] All enum values
  - [ ] Error types
  - [ ] Widget classes

- [ ] Generate API docs
  - [ ] Configure dartdoc
  - [ ] Generate HTML documentation
  - [ ] Host on GitHub Pages (optional)

### Migration Guides
- [ ] `docs/migration/`
  - [ ] `from-raw-powersync.md` - Migrating from direct PowerSync usage
  - [ ] `from-drift.md` - Wrapping existing Drift database
  - [ ] `from-supabase.md` - Adding nexus_store to Supabase app
  - [ ] `version-upgrades.md` - Breaking changes between versions

### Architecture Documentation
- [ ] `docs/architecture/`
  - [ ] `overview.md` - High-level architecture
  - [ ] `policy-engine.md` - Fetch/write policy details
  - [ ] `reactive-layer.md` - RxDart integration
  - [ ] `backend-interface.md` - Implementing custom backends
  - [ ] `encryption.md` - Security implementation details
  - [ ] `compliance.md` - HIPAA/GDPR details

### CHANGELOG
- [ ] `CHANGELOG.md` at monorepo root
  - [ ] Follow Keep a Changelog format
  - [ ] Document all versions
  - [ ] Categorize: Added, Changed, Deprecated, Removed, Fixed, Security

### Contributing Guide
- [ ] `CONTRIBUTING.md`
  - [ ] Development setup
  - [ ] Running tests
  - [ ] Code style guidelines
  - [ ] PR process
  - [ ] Issue templates

## Files

**Documentation Structure:**
```
nexus_store/
├── README.md                              # Root README
├── CHANGELOG.md                           # Version history
├── CONTRIBUTING.md                        # Contributor guide
├── packages/
│   ├── nexus_store/README.md              # Core package docs
│   ├── nexus_store_flutter/README.md      # Flutter extension docs
│   ├── nexus_store_powersync_adapter/README.md
│   ├── nexus_store_drift_adapter/README.md
│   ├── nexus_store_supabase_adapter/README.md
│   ├── nexus_store_brick_adapter/README.md
│   └── nexus_store_crdt_adapter/README.md
├── example/
│   ├── README.md
│   ├── basic_usage/
│   ├── powersync_todo/
│   ├── drift_notes/
│   ├── supabase_chat/
│   └── flutter_widgets/
└── docs/
    ├── specs/SPEC-nexus-store.md          # (existing)
    ├── trackers/nexus-store/              # (this directory)
    ├── migration/
    │   ├── from-raw-powersync.md
    │   ├── from-drift.md
    │   ├── from-supabase.md
    │   └── version-upgrades.md
    └── architecture/
        ├── overview.md
        ├── policy-engine.md
        ├── reactive-layer.md
        ├── backend-interface.md
        ├── encryption.md
        └── compliance.md
```

## Dependencies

- All packages must be implemented and tested
- API must be stable before documenting
- Examples should use released versions when possible

## Notes

- Documentation should be written for developers new to the package
- Include copy-paste ready code examples
- Keep README files focused - link to detailed docs
- Use consistent formatting across all docs
- Include diagrams where helpful (architecture, data flow)
- Consider using mdBook or similar for comprehensive docs
- Test all code examples to ensure they compile
- Update docs when API changes
