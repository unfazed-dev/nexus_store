# TRACKER: nexus_store Package Implementation

## Status: IN_PROGRESS

## Overview

Main tracker for implementing the nexus_store package ecosystem - a unified reactive data store abstraction for Flutter/Dart with policy-based fetching, RxDart streams, and optional compliance features.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md)

## Milestones

### Phase 1: Core Foundation
- [x] Core package implementation (NexusStore, StoreBackend, CompositeBackend)
- [x] Configuration classes (StoreConfig, policies, RetryConfig)
- [x] Reactive layer (ReactiveStoreMixin, BehaviorSubject streams)
- [x] Query builder (fluent API with filters, ordering, pagination)
- [x] Policy engine (FetchPolicyHandler, WritePolicyHandler)
- [x] Encryption support (SQLCipher config, field-level AES-256-GCM)
- [x] Audit logging (HIPAA-compliant hash-chained logs)
- [x] GDPR service (erasure, portability)
- [ ] **Core package unit tests** - See [TRACKER-core-testing.md](./TRACKER-core-testing.md)

### Phase 2: Backend Adapters
- [ ] PowerSync adapter - See [TRACKER-powersync-adapter.md](./TRACKER-powersync-adapter.md)
- [ ] Drift adapter - See [TRACKER-drift-adapter.md](./TRACKER-drift-adapter.md)
- [ ] Supabase adapter - See [TRACKER-supabase-adapter.md](./TRACKER-supabase-adapter.md)
- [ ] Brick adapter - See [TRACKER-brick-adapter.md](./TRACKER-brick-adapter.md)
- [ ] CRDT adapter - See [TRACKER-crdt-adapter.md](./TRACKER-crdt-adapter.md)

### Phase 3: Flutter Extension
- [ ] Flutter widgets - See [TRACKER-flutter-extension.md](./TRACKER-flutter-extension.md)

### Phase 4: Documentation
- [ ] Documentation & examples - See [TRACKER-documentation.md](./TRACKER-documentation.md)

## Package Structure

```
nexus_store/
├── packages/
│   ├── nexus_store/                      # Core (✅ Complete, needs tests)
│   ├── nexus_store_flutter/              # Flutter extension (📦 Stub)
│   ├── nexus_store_powersync_adapter/    # PowerSync (📦 Stub)
│   ├── nexus_store_drift_adapter/        # Drift (📦 Stub)
│   ├── nexus_store_supabase_adapter/     # Supabase (📦 Stub)
│   ├── nexus_store_brick_adapter/        # Brick (📦 Stub)
│   └── nexus_store_crdt_adapter/         # CRDT (📦 Stub)
└── docs/
    ├── specs/SPEC-nexus-store.md
    └── trackers/nexus-store/             # This directory
```

## Dependencies Between Components

```
Core Package (nexus_store)
    │
    ├── Tests (must pass before adapters)
    │
    ├── Backend Adapters (can be parallel)
    │   ├── PowerSync (offline-first sync)
    │   ├── Drift (local-only)
    │   ├── Supabase (online realtime)
    │   ├── Brick (code-gen offline-first)
    │   └── CRDT (conflict-free)
    │
    └── Flutter Extension (depends on core)

Documentation (depends on all above)
```

## Requirements Coverage

| REQ | Description | Status | Tracker |
|-----|-------------|--------|---------|
| REQ-001 | Unified Backend Interface | ✅ Complete | core |
| REQ-002 | RxDart Reactive Streams | ✅ Complete | core |
| REQ-003 | Fetch Policies | ✅ Complete | core |
| REQ-004 | Write Policies | ✅ Complete | core |
| REQ-005 | Sync Status Observability | ✅ Complete | core |
| REQ-006 | Query Builder | ✅ Complete | core |
| REQ-007 | PowerSync Backend | 📦 Stub | [powersync](./TRACKER-powersync-adapter.md) |
| REQ-008 | Brick Backend | 📦 Stub | [brick](./TRACKER-brick-adapter.md) |
| REQ-009 | Supabase Backend | 📦 Stub | [supabase](./TRACKER-supabase-adapter.md) |
| REQ-010 | Drift Backend | 📦 Stub | [drift](./TRACKER-drift-adapter.md) |
| REQ-011 | CRDT Backend | 📦 Stub | [crdt](./TRACKER-crdt-adapter.md) |
| REQ-012 | SQLCipher Encryption | ✅ Complete | core |
| REQ-013 | Field-Level Encryption | ✅ Complete | core |
| REQ-014 | Audit Logging (HIPAA) | ✅ Complete | core |
| REQ-015 | GDPR Erasure | ✅ Complete | core |
| REQ-016 | GDPR Portability | ✅ Complete | core |

## Related Trackers

- [Core Testing](./TRACKER-core-testing.md) - Unit tests for core package
- [PowerSync Adapter](./TRACKER-powersync-adapter.md) - REQ-007
- [Drift Adapter](./TRACKER-drift-adapter.md) - REQ-010
- [Supabase Adapter](./TRACKER-supabase-adapter.md) - REQ-009
- [Brick Adapter](./TRACKER-brick-adapter.md) - REQ-008
- [CRDT Adapter](./TRACKER-crdt-adapter.md) - REQ-011
- [Flutter Extension](./TRACKER-flutter-extension.md) - Widgets
- [Documentation](./TRACKER-documentation.md) - README & examples

## Notes

- Core package is fully implemented but needs comprehensive unit tests
- All adapter packages exist as stubs with dependencies commented out
- Priority: Core tests > Adapters (parallel) > Flutter > Documentation
- Melos workspace configured with shared scripts for analyze, test, format
