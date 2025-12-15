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

### Phase 5: Production Readiness Features (NEW)
- [ ] Transaction support - See [TRACKER-transactions.md](./TRACKER-transactions.md)
- [ ] Cursor-based pagination - See [TRACKER-cursor-pagination.md](./TRACKER-cursor-pagination.md)
- [ ] Type-safe query builder - See [TRACKER-type-safe-query.md](./TRACKER-type-safe-query.md)
- [ ] Conflict resolution & pending changes - See [TRACKER-conflict-resolution.md](./TRACKER-conflict-resolution.md)
- [ ] Tag-based cache invalidation - See [TRACKER-cache-invalidation.md](./TRACKER-cache-invalidation.md)
- [ ] Telemetry & metrics - See [TRACKER-telemetry.md](./TRACKER-telemetry.md)
- [ ] Key derivation (PBKDF2/Argon2) - See [TRACKER-key-derivation.md](./TRACKER-key-derivation.md)
- [ ] Batch streaming - See [TRACKER-batch-streaming.md](./TRACKER-batch-streaming.md)
- [ ] Enhanced GDPR compliance - See [TRACKER-gdpr-enhanced.md](./TRACKER-gdpr-enhanced.md)

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
| REQ-017 | Transaction Support | ⏳ Pending | [transactions](./TRACKER-transactions.md) |
| REQ-018 | Cursor-Based Pagination | ⏳ Pending | [pagination](./TRACKER-cursor-pagination.md) |
| REQ-019 | Type-Safe Query Builder | ⏳ Pending | [type-safe](./TRACKER-type-safe-query.md) |
| REQ-020 | Conflict Resolution Callbacks | ⏳ Pending | [conflict](./TRACKER-conflict-resolution.md) |
| REQ-021 | Pending Changes Visibility | ⏳ Pending | [conflict](./TRACKER-conflict-resolution.md) |
| REQ-022 | Tag-Based Cache Invalidation | ⏳ Pending | [cache](./TRACKER-cache-invalidation.md) |
| REQ-023 | Telemetry & Metrics | ⏳ Pending | [telemetry](./TRACKER-telemetry.md) |
| REQ-024 | Key Derivation | ⏳ Pending | [key-derivation](./TRACKER-key-derivation.md) |
| REQ-025 | Batch Streaming | ⏳ Pending | [streaming](./TRACKER-batch-streaming.md) |
| REQ-026 | Data Minimization (GDPR) | ⏳ Pending | [gdpr-enhanced](./TRACKER-gdpr-enhanced.md) |
| REQ-027 | Consent Tracking (GDPR) | ⏳ Pending | [gdpr-enhanced](./TRACKER-gdpr-enhanced.md) |
| REQ-028 | Breach Notification (GDPR) | ⏳ Pending | [gdpr-enhanced](./TRACKER-gdpr-enhanced.md) |

## Related Trackers

### Core & Testing
- [Core Testing](./TRACKER-core-testing.md) - Unit tests for core package

### Backend Adapters
- [PowerSync Adapter](./TRACKER-powersync-adapter.md) - REQ-007
- [Drift Adapter](./TRACKER-drift-adapter.md) - REQ-010
- [Supabase Adapter](./TRACKER-supabase-adapter.md) - REQ-009
- [Brick Adapter](./TRACKER-brick-adapter.md) - REQ-008
- [CRDT Adapter](./TRACKER-crdt-adapter.md) - REQ-011

### Flutter & Documentation
- [Flutter Extension](./TRACKER-flutter-extension.md) - Widgets
- [Documentation](./TRACKER-documentation.md) - README & examples

### Production Readiness (Phase 5)
- [Transactions](./TRACKER-transactions.md) - REQ-017: Atomic operations
- [Cursor Pagination](./TRACKER-cursor-pagination.md) - REQ-018: Efficient pagination
- [Type-Safe Query](./TRACKER-type-safe-query.md) - REQ-019: Compile-time validation
- [Conflict Resolution](./TRACKER-conflict-resolution.md) - REQ-020, REQ-021: Sync control
- [Cache Invalidation](./TRACKER-cache-invalidation.md) - REQ-022: Tag-based clearing
- [Telemetry](./TRACKER-telemetry.md) - REQ-023: Observability
- [Key Derivation](./TRACKER-key-derivation.md) - REQ-024: PBKDF2/Argon2
- [Batch Streaming](./TRACKER-batch-streaming.md) - REQ-025: Large datasets
- [Enhanced GDPR](./TRACKER-gdpr-enhanced.md) - REQ-026, REQ-027, REQ-028

## Notes

- Core package is fully implemented but needs comprehensive unit tests
- All adapter packages exist as stubs with dependencies commented out
- Priority: Core tests > Adapters (parallel) > Flutter > Documentation
- Melos workspace configured with shared scripts for analyze, test, format
