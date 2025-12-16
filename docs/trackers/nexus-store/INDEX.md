# nexus_store Trackers Index

Quick navigation and status dashboard for all implementation trackers.

## Status Dashboard

| Phase | Name | Trackers | Status |
|-------|------|----------|--------|
| 1 | Foundation | 1 | PENDING |
| 2 | Adapters | 5 | PENDING |
| 3 | Flutter | 1 | PENDING |
| 4 | Documentation | 1 | PENDING |
| 5 | Production | 9 | PENDING |
| 6 | Enterprise | 8 | PENDING |
| 7 | State Layer | 1 | PENDING |
| 8 | Bindings | 3 | PENDING |
| **Total** | | **29** | **1 IN_PROGRESS** |

## Quick Links

- [Main Tracker](./TRACKER-nexus-store-main.md) - Master orchestrator (IN_PROGRESS)
- [Specification](../../specs/SPEC-nexus-store.md) - Full requirements spec

---

## Phase 1: Foundation

Core package testing and validation.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Core Testing](./phase-1-foundation/TRACKER-core-testing.md) | Tests for REQ-001 to REQ-016 | PENDING |

---

## Phase 2: Backend Adapters

Database backend implementations.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [PowerSync](./phase-2-adapters/TRACKER-powersync-adapter.md) | REQ-007 | PENDING |
| [Drift](./phase-2-adapters/TRACKER-drift-adapter.md) | REQ-010 | PENDING |
| [Supabase](./phase-2-adapters/TRACKER-supabase-adapter.md) | REQ-009 | PENDING |
| [Brick](./phase-2-adapters/TRACKER-brick-adapter.md) | REQ-008 | PENDING |
| [CRDT](./phase-2-adapters/TRACKER-crdt-adapter.md) | REQ-011 | PENDING |

---

## Phase 3: Flutter Extension

Flutter-specific widgets and integrations.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Flutter Extension](./phase-3-flutter/TRACKER-flutter-extension.md) | Widgets, platform channels | PENDING |

---

## Phase 4: Documentation

README, API docs, and examples.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Documentation](./phase-4-docs/TRACKER-documentation.md) | Docs, examples, guides | PENDING |

---

## Phase 5: Production Readiness

Features needed for production deployment.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Transactions](./phase-5-production/TRACKER-transactions.md) | REQ-017 | PENDING |
| [Cursor Pagination](./phase-5-production/TRACKER-cursor-pagination.md) | REQ-018 | PENDING |
| [Type-Safe Query](./phase-5-production/TRACKER-type-safe-query.md) | REQ-019, REQ-034 | PENDING |
| [Conflict Resolution](./phase-5-production/TRACKER-conflict-resolution.md) | REQ-020, REQ-021 | PENDING |
| [Cache Invalidation](./phase-5-production/TRACKER-cache-invalidation.md) | REQ-022 | PENDING |
| [Telemetry](./phase-5-production/TRACKER-telemetry.md) | REQ-023 | PENDING |
| [Key Derivation](./phase-5-production/TRACKER-key-derivation.md) | REQ-024 | PENDING |
| [Batch Streaming](./phase-5-production/TRACKER-batch-streaming.md) | REQ-025 | PENDING |
| [Enhanced GDPR](./phase-5-production/TRACKER-gdpr-enhanced.md) | REQ-026, REQ-027, REQ-028 | PENDING |

---

## Phase 6: Enterprise & Performance

Enterprise features and performance optimizations.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Saga Transactions](./phase-6-enterprise/TRACKER-saga-transactions.md) | REQ-029 | PENDING |
| [Interceptors](./phase-6-enterprise/TRACKER-interceptors.md) | REQ-030 | PENDING |
| [Delta Sync](./phase-6-enterprise/TRACKER-delta-sync.md) | REQ-031 | PENDING |
| [Background Sync](./phase-6-enterprise/TRACKER-background-sync.md) | REQ-032, REQ-033 | PENDING |
| [Reliability](./phase-6-enterprise/TRACKER-reliability.md) | REQ-035, REQ-036, REQ-037, REQ-038 | PENDING |
| [Memory Management](./phase-6-enterprise/TRACKER-memory-management.md) | REQ-039 | PENDING |
| [Lazy Loading](./phase-6-enterprise/TRACKER-lazy-loading.md) | REQ-040 | PENDING |
| [Connection Pool](./phase-6-enterprise/TRACKER-connection-pool.md) | REQ-041 | PENDING |

---

## Phase 7: Built-in State Layer

Self-sufficient state management.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [State Layer](./phase-7-state/TRACKER-state-layer.md) | REQ-042, REQ-043, REQ-044, REQ-045 | PENDING |

---

## Phase 8: State Management Bindings

Optional integrations with popular state management libraries.

| Tracker | Requirements | Status |
|---------|--------------|--------|
| [Riverpod Binding](./phase-8-bindings/TRACKER-riverpod-binding.md) | REQ-046 | PENDING |
| [Bloc Binding](./phase-8-bindings/TRACKER-bloc-binding.md) | REQ-047 | PENDING |
| [Signals Binding](./phase-8-bindings/TRACKER-signals-binding.md) | REQ-048 | PENDING |

---

## Directory Structure

```
docs/trackers/nexus-store/
├── TRACKER-nexus-store-main.md    # Master tracker
├── INDEX.md                        # This file
│
├── phase-1-foundation/
│   └── TRACKER-core-testing.md
│
├── phase-2-adapters/
│   ├── TRACKER-powersync-adapter.md
│   ├── TRACKER-drift-adapter.md
│   ├── TRACKER-supabase-adapter.md
│   ├── TRACKER-brick-adapter.md
│   └── TRACKER-crdt-adapter.md
│
├── phase-3-flutter/
│   └── TRACKER-flutter-extension.md
│
├── phase-4-docs/
│   └── TRACKER-documentation.md
│
├── phase-5-production/
│   ├── TRACKER-transactions.md
│   ├── TRACKER-cursor-pagination.md
│   ├── TRACKER-type-safe-query.md
│   ├── TRACKER-conflict-resolution.md
│   ├── TRACKER-cache-invalidation.md
│   ├── TRACKER-telemetry.md
│   ├── TRACKER-key-derivation.md
│   ├── TRACKER-batch-streaming.md
│   └── TRACKER-gdpr-enhanced.md
│
├── phase-6-enterprise/
│   ├── TRACKER-saga-transactions.md
│   ├── TRACKER-interceptors.md
│   ├── TRACKER-delta-sync.md
│   ├── TRACKER-background-sync.md
│   ├── TRACKER-reliability.md
│   ├── TRACKER-memory-management.md
│   ├── TRACKER-lazy-loading.md
│   └── TRACKER-connection-pool.md
│
├── phase-7-state/
│   └── TRACKER-state-layer.md
│
└── phase-8-bindings/
    ├── TRACKER-riverpod-binding.md
    ├── TRACKER-bloc-binding.md
    └── TRACKER-signals-binding.md
```

## Categories by Domain

### Data Layer
- [Core Testing](./phase-1-foundation/TRACKER-core-testing.md)
- [Transactions](./phase-5-production/TRACKER-transactions.md)
- [Cursor Pagination](./phase-5-production/TRACKER-cursor-pagination.md)
- [Type-Safe Query](./phase-5-production/TRACKER-type-safe-query.md)
- [Batch Streaming](./phase-5-production/TRACKER-batch-streaming.md)

### Sync & Offline
- All [Phase 2 Adapters](./phase-2-adapters/)
- [Conflict Resolution](./phase-5-production/TRACKER-conflict-resolution.md)
- [Delta Sync](./phase-6-enterprise/TRACKER-delta-sync.md)
- [Background Sync](./phase-6-enterprise/TRACKER-background-sync.md)

### Security & Compliance
- [Key Derivation](./phase-5-production/TRACKER-key-derivation.md)
- [Enhanced GDPR](./phase-5-production/TRACKER-gdpr-enhanced.md)

### Performance
- [Cache Invalidation](./phase-5-production/TRACKER-cache-invalidation.md)
- [Memory Management](./phase-6-enterprise/TRACKER-memory-management.md)
- [Lazy Loading](./phase-6-enterprise/TRACKER-lazy-loading.md)
- [Connection Pool](./phase-6-enterprise/TRACKER-connection-pool.md)

### Observability & Reliability
- [Telemetry](./phase-5-production/TRACKER-telemetry.md)
- [Reliability](./phase-6-enterprise/TRACKER-reliability.md)

### State Management
- [State Layer](./phase-7-state/TRACKER-state-layer.md)
- All [Phase 8 Bindings](./phase-8-bindings/)

### Integration
- [Flutter Extension](./phase-3-flutter/TRACKER-flutter-extension.md)
- [Interceptors](./phase-6-enterprise/TRACKER-interceptors.md)
- [Saga Transactions](./phase-6-enterprise/TRACKER-saga-transactions.md)
