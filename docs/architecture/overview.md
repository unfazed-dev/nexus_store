# Architecture Overview

This document provides a high-level overview of the nexus_store architecture.

## Core Design Principles

1. **Unified API** - Single interface across all storage backends
2. **Policy-Driven** - Configurable fetch and write policies
3. **Reactive First** - RxDart streams with BehaviorSubject for immediate values
4. **Backend Agnostic** - Abstract interface allows swapping backends
5. **Compliance Ready** - Built-in GDPR and HIPAA support

## Package Structure

```
nexus_store/
├── packages/
│   ├── nexus_store/                    # Core package
│   │   ├── lib/src/
│   │   │   ├── core/                   # NexusStore, StoreBackend
│   │   │   ├── config/                 # StoreConfig, policies
│   │   │   ├── query/                  # Query builder
│   │   │   ├── policy/                 # Policy handlers
│   │   │   ├── reactive/               # RxDart integration
│   │   │   ├── security/               # Encryption
│   │   │   ├── compliance/             # Audit, GDPR
│   │   │   ├── lazy/                   # Lazy field loading
│   │   │   ├── interceptors/           # Middleware API
│   │   │   ├── transactions/           # Saga support
│   │   │   ├── sync/                   # Delta sync
│   │   │   ├── pool/                   # Connection pooling
│   │   │   └── errors/                 # Error types
│   │   └── test/
│   │
│   ├── nexus_store_flutter_widgets/            # Flutter widgets
│   │   └── lib/src/
│   │       ├── widgets/                # Builder widgets
│   │       ├── providers/              # DI providers
│   │       ├── types/                  # StoreResult
│   │       └── extensions/             # BuildContext extensions
│   │
│   ├── nexus_store_*_adapter/          # Backend adapters
│   │   └── lib/src/
│   │       ├── *_backend.dart          # Backend implementation
│   │       └── *_query_translator.dart # Query translation
│   │
│   ├── nexus_store_*_binding/          # State management bindings
│   │   ├── nexus_store_riverpod_binding/   # Riverpod integration
│   │   ├── nexus_store_bloc_binding/       # Bloc/Cubit integration
│   │   └── nexus_store_signals_binding/    # Signals integration
│   │
│   └── nexus_store_*_generator/        # Code generators
│       ├── nexus_store_generator/          # Lazy field accessors
│       ├── nexus_store_entity_generator/   # Type-safe field accessors
│       └── nexus_store_riverpod_generator/ # Riverpod providers
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   Flutter Widgets                        │ │
│  │  NexusStoreBuilder  StoreResultBuilder  NexusStoreProvider│
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 State Management Bindings                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Riverpod   │  │     Bloc     │  │   Signals    │       │
│  │  - Providers │  │  - Cubits    │  │  - Signals   │       │
│  │  - Hooks     │  │  - Events    │  │  - Computed  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       NexusStore<T, ID>                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  StoreConfig   │  │ PolicyEngine   │  │ ReactiveState  │ │
│  │  - FetchPolicy │  │ - FetchHandler │  │ - BehaviorSubj │ │
│  │  - WritePolicy │  │ - WriteHandler │  │ - RxDart       │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  AuditService  │  │  GdprService   │  │ EncryptService │ │
│  │  - Hash chain  │  │  - Erasure     │  │ - Field-level  │ │
│  │  - Query       │  │  - Export      │  │ - SQLCipher    │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  Interceptors  │  │   Lazy Load    │  │  Transactions  │ │
│  │  - Pre/Post    │  │  - On-demand   │  │  - Sagas       │ │
│  │  - Middleware  │  │  - Caching     │  │  - Rollback    │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   StoreBackend<T, ID>                        │
│                    (Abstract Interface)                       │
└─────────────────────────────────────────────────────────────┘
                              │
    ┌───────────┬─────────────┼─────────────┬───────────┐
    │           │             │             │           │
    ▼           ▼             ▼             ▼           ▼
┌────────┐ ┌────────┐   ┌────────┐   ┌────────┐ ┌────────┐
│PowerSync│ │Supabase│   │ Drift  │   │ Brick  │ │  CRDT  │
│Backend │ │Backend │   │Backend │   │Backend │ │Backend │
│-Offline│ │-Realtime│  │-Local  │   │-Multi  │ │-P2P    │
│-Sync   │ │-RLS    │   │-SQLite │   │-Sources│ │-LWW    │
└────────┘ └────────┘   └────────┘   └────────┘ └────────┘
```

## Data Flow

### Read Operation Flow

```
1. App calls store.get(id)
           │
           ▼
2. FetchPolicyHandler determines data source
   ┌─────────────────────────────────────────┐
   │ cacheFirst:  Cache → Network (fallback) │
   │ networkFirst: Network → Cache (fallback)│
   │ cacheAndNetwork: Cache + Network        │
   │ cacheOnly: Cache only                   │
   │ networkOnly: Network only               │
   └─────────────────────────────────────────┘
           │
           ▼
3. Backend.get(id) called
           │
           ▼
4. QueryTranslator converts Query to backend format
           │
           ▼
5. Backend returns data
           │
           ▼
6. EncryptionService decrypts if needed
           │
           ▼
7. AuditService logs access if enabled
           │
           ▼
8. Data returned to app
```

### Write Operation Flow

```
1. App calls store.save(item)
           │
           ▼
2. WritePolicyHandler determines write strategy
   ┌─────────────────────────────────────────┐
   │ cacheAndNetwork: Cache → Network (sync) │
   │ networkFirst: Network → Cache (update)  │
   │ cacheFirst: Cache → Network (background)│
   │ cacheOnly: Cache only                   │
   └─────────────────────────────────────────┘
           │
           ▼
3. EncryptionService encrypts if needed
           │
           ▼
4. Backend.save(item) called
           │
           ▼
5. AuditService logs modification if enabled
           │
           ▼
6. ReactiveState updated (streams emit)
           │
           ▼
7. Sync triggered based on SyncMode
```

## Key Components

### NexusStore

The main entry point providing a unified API for all operations:

- CRUD operations (get, getAll, save, saveAll, delete)
- Reactive streams (watch, watchAll)
- Sync management (sync, syncStatus)
- Cache control (invalidate, invalidateAll)

### StoreBackend

Abstract interface implemented by all adapters:

- Defines read/write/sync contract
- Declares backend capabilities (offline, realtime, transactions)
- Provides lifecycle methods (initialize, close)

### StoreConfig

Immutable configuration for store behavior:

- Fetch and write policies
- Sync mode and interval
- Encryption settings
- Compliance toggles

### Query Builder

Fluent API for constructing queries:

- Filter operators (equals, greater than, contains, etc.)
- Ordering (ascending, descending)
- Pagination (limit, offset)
- Translates to backend-specific format

## Backend Adapter Pattern

Each adapter follows a consistent pattern:

1. **Backend Class** - Implements `StoreBackend<T, ID>`
2. **Query Translator** - Converts `Query<T>` to backend format
3. **Capabilities** - Declares supported features

```dart
class MyBackend<T, ID> implements StoreBackend<T, ID> {
  @override
  String get name => 'MyBackend';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => false;

  // Implement read/write/sync methods...
}
```

## Thread Safety

- All operations are asynchronous (Future/Stream)
- State is managed via RxDart BehaviorSubjects
- Backend implementations handle their own concurrency
- Encryption operations are stateless and thread-safe

## Error Handling

Errors are categorized into typed exceptions:

- `NotFoundError` - Entity not found
- `NetworkError` - Network failure (may be retryable)
- `ValidationError` - Invalid data
- `SyncError` - Synchronization failure
- `StoreError` - Base type for all errors

## See Also

- [Policy Engine](policy-engine.md)
- [Reactive Layer](reactive-layer.md)
- [Backend Interface](backend-interface.md)
- [Encryption](encryption.md)
- [Compliance](compliance.md)
