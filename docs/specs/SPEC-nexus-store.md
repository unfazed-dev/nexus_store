# SPEC: nexus-store

## Metadata

| Field | Value |
|-------|-------|
| **Version** | 0.2.0 |
| **Status** | In Progress |
| **Author** | Claude |
| **Date** | 2025-12-16 |
| **Package Type** | Pure Dart (with optional Flutter extensions) |
| **Repository** | `/Users/unfazed-mac/Developer/packages/nexus_store` |

---

## Implementation Progress

> **Last Updated**: 2025-12-31 (Audit completed - see [AUDIT-REPORT.md](../AUDIT-REPORT.md))

| Component | Status | Notes |
|-----------|--------|-------|
| **Core Package** | ✅ Complete | `nexus_store` - all core features implemented |
| **Configuration** | ✅ Complete | StoreConfig, policies, retry config |
| **Reactive Layer** | ✅ Complete | RxDart BehaviorSubject-based streams |
| **Query Builder** | ✅ Complete | Fluent API with filters, ordering, pagination |
| **Policy Engine** | ✅ Complete | Fetch and write policy handlers |
| **Encryption** | ✅ Complete | SQLCipher + field-level AES-256-GCM |
| **Audit Logging** | ✅ Complete | Hash-chained immutable audit logs |
| **GDPR Service** | ✅ Complete | Erasure (Art. 17) and portability (Art. 20) |
| **PowerSync Adapter** | ✅ Complete | 1,257 LOC, full CRUD, sync lifecycle, SQLCipher |
| **Drift Adapter** | ✅ Complete | 931 LOC, local SQLite via Drift ORM |
| **Supabase Adapter** | ✅ Complete | 1,179 LOC, Realtime, RLS auth, PostgreSQL errors |
| **Brick Adapter** | ✅ Complete | 711 LOC, offline-first repository pattern |
| **CRDT Adapter** | ✅ Complete | 1,049 LOC, HLC timestamps, LWW merge |
| **Flutter Extension** | ✅ Complete | 3,174 LOC, widgets, background sync, lazy loading |
| **Unit Tests** | ✅ Complete | 500+ tests across monorepo |
| **Documentation** | ✅ Complete | README with backend guide, compliance docs, state mgmt examples |
| **Transaction Support** | ✅ Complete | REQ-017 - Atomic multi-entity operations |
| **Cursor Pagination** | ✅ Complete | REQ-018 - Efficient large dataset pagination |
| **Type-Safe Query** | ⏳ Pending | REQ-019 - Compile-time validated queries |
| **Conflict Resolution** | ✅ Complete | REQ-020 - Custom conflict callbacks |
| **Pending Changes API** | ✅ Complete | REQ-021 - Visibility into sync queue |
| **Tag-Based Invalidation** | ✅ Complete | REQ-022 - Selective cache clearing |
| **Telemetry & Metrics** | ✅ Complete | REQ-023 - Store observability |
| **Key Derivation** | ✅ Complete | REQ-024 - PBKDF2 support |
| **Batch Streaming** | ✅ Complete | REQ-025 - Paginated streaming for large datasets |
| **Data Minimization** | ✅ Complete | REQ-026 - DataMinimizationService with RetentionPolicy |
| **Consent Tracking** | ✅ Complete | REQ-027 - ConsentService with granular purpose tracking |
| **Breach Notification** | ✅ Complete | REQ-028 - BreachService with report generation |
| **Cross-Store Transactions** | ✅ Complete | REQ-029 - Saga pattern implemented |
| **Middleware/Interceptors** | ✅ Complete | REQ-030 - Pre/post hooks |
| **Delta Sync** | ✅ Complete | REQ-031 - Field-level sync |
| **Background Sync** | ⏳ Partial | REQ-032 - Framework exists, platform-specific pending |
| **Sync Priority Queues** | ⏳ Pending | REQ-033 - Prioritized sync |
| **Code Generation** | ⏳ Pending | REQ-034 - Type-safe query codegen |
| **Schema Validation** | ⏳ Pending | REQ-035 - Runtime schema checks |
| **Circuit Breaker** | ✅ Complete | REQ-036 - Backend failover |
| **Health Check API** | ✅ Complete | REQ-037 - Monitoring integration |
| **Graceful Degradation** | ✅ Complete | REQ-038 - Offline fallbacks |
| **Memory Pressure Handling** | ✅ Complete | REQ-039 - Auto cache eviction |
| **Lazy Field Loading** | ✅ Complete | REQ-040 - On-demand blob loading |
| **Connection Pooling** | ✅ Complete | REQ-041 - Backend connection management |
| **Store Registry** | ✅ Complete | REQ-042 - Built-in DI for stores |
| **Computed Stores** | ✅ Complete | REQ-043 - Derived state from multiple stores |
| **UI State Containers** | ⏳ Pending | REQ-044 - Non-data reactive state |
| **Selectors** | ✅ Complete | REQ-045 - Efficient derived values |
| **Riverpod Integration** | ✅ Complete | REQ-046 - nexus_store_riverpod_binding (44 tests) + generator (23 tests) |
| **Bloc Integration** | ✅ Complete | REQ-047 - nexus_store_bloc_binding (244 tests) |
| **Signals Integration** | ✅ Complete | REQ-048 - nexus_store_signals_binding (87 tests) |

---

## Package Overview

**Name**: `nexus_store`

**Description**: A unified reactive data store abstraction that provides a single consistent API across multiple storage backends (PowerSync, Brick, Supabase, Drift, sqlite_crdt) with policy-based fetching, RxDart streams, and optional compliance features.

**Problem Statement**: Flutter developers must learn and maintain different APIs for each storage backend. Switching backends requires significant code changes. There's no unified way to apply fetch policies (cache-first, network-first), reactive streams, or compliance features (audit logging, GDPR) across backends.

**Target Users**:
- Flutter/Dart developers building offline-first applications
- Teams who want backend-agnostic data layers
- Enterprise developers requiring HIPAA/GDPR compliance
- Developers migrating between storage solutions

**Package Type**: Pure Dart library with optional Flutter extension package

---

## Requirements

### REQ-001: Unified Backend Interface

**User Story**:
As a Flutter developer
I want a single interface for all storage backends
So that I can swap backends without changing application code

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>` configured with `PowerSyncBackend`
  WHEN I call `store.get(id)`
  THEN it returns the item from PowerSync

- GIVEN a `NexusStore<T, ID>` configured with `DriftBackend`
  WHEN I call `store.get(id)` with the same code
  THEN it returns the item from Drift

- GIVEN any supported backend
  WHEN I use `store.save()`, `store.delete()`, `store.getAll()`
  THEN the operations work identically across backends

**Priority**: Must Have

---

### REQ-002: RxDart Reactive Streams

**User Story**:
As a Flutter developer
I want reactive streams that emit updates automatically
So that my UI stays in sync with data changes

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>`
  WHEN I call `store.watch(id)`
  THEN it returns a `Stream<T?>` that emits on every change

- GIVEN a `NexusStore<T, ID>`
  WHEN I call `store.watchAll()`
  THEN it returns a `Stream<List<T>>` (BehaviorSubject-backed)

- GIVEN multiple listeners on `watchAll()`
  WHEN a new listener subscribes
  THEN it immediately receives the current value (BehaviorSubject behavior)

- GIVEN an active watch stream
  WHEN an item is saved/deleted via the store
  THEN the stream emits the updated data within 100ms

**Priority**: Must Have

---

### REQ-003: Fetch Policies

**User Story**:
As a developer
I want to control how data is fetched (cache vs network)
So that I can optimize for different use cases

**Acceptance Criteria**:
- GIVEN `FetchPolicy.cacheFirst` (default)
  WHEN data exists in cache
  THEN return cached data without network call

- GIVEN `FetchPolicy.cacheFirst`
  WHEN data does NOT exist in cache
  THEN fetch from network and cache the result

- GIVEN `FetchPolicy.networkFirst`
  WHEN network is available
  THEN fetch from network, cache result, return data

- GIVEN `FetchPolicy.networkFirst`
  WHEN network is unavailable
  THEN fall back to cached data

- GIVEN `FetchPolicy.cacheAndNetwork`
  WHEN called
  THEN immediately return cached data AND trigger background network fetch

- GIVEN `FetchPolicy.cacheOnly`
  WHEN called
  THEN return only cached data, never make network calls

- GIVEN `FetchPolicy.networkOnly`
  WHEN called
  THEN always fetch from network, never use cache

**Priority**: Must Have

---

### REQ-004: Write Policies

**User Story**:
As a developer
I want to control how data is written (optimistic vs confirmed)
So that I can balance UX responsiveness with data consistency

**Acceptance Criteria**:
- GIVEN `WritePolicy.cacheAndNetwork` (default)
  WHEN `store.save(item)` is called
  THEN write to cache immediately AND queue for network sync

- GIVEN `WritePolicy.networkFirst`
  WHEN `store.save(item)` is called
  THEN write to network first, only cache on success

- GIVEN `WritePolicy.cacheOnly`
  WHEN `store.save(item)` is called
  THEN write to cache only, never sync to network

**Priority**: Must Have

---

### REQ-005: Sync Status Observability

**User Story**:
As a developer
I want to know the sync status of my store
So that I can show appropriate UI indicators

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>`
  WHEN I subscribe to `store.syncStatus`
  THEN I receive `SyncStatus` enum values (`synced`, `pending`, `syncing`, `error`, `paused`, `conflict`)

- GIVEN pending changes in the queue
  WHEN I call `store.pendingChangesCount`
  THEN it returns the number of unsynced items

- GIVEN a sync error occurs
  WHEN I subscribe to `store.errors`
  THEN I receive `StoreError` with details

**Priority**: Must Have

---

### REQ-006: Query Builder

**User Story**:
As a developer
I want to query data with filters, sorting, and pagination
So that I can efficiently retrieve subsets of data

**Acceptance Criteria**:
- GIVEN a `Query<T>` builder
  WHEN I call `Query<T>().where('field', value)`
  THEN it filters results where field equals value

- GIVEN a `Query<T>` builder
  WHEN I call `.where('field', greaterThan: 10)`
  THEN it filters results where field > 10

- GIVEN a `Query<T>` builder
  WHEN I call `.orderBy('field', descending: true)`
  THEN results are sorted by field descending

- GIVEN a `Query<T>` builder
  WHEN I call `.limit(10).offset(20)`
  THEN it returns 10 items starting from index 20

- GIVEN a complex query
  WHEN I call `store.getAll(query: query)`
  THEN the query is translated to the backend's native query format

**Priority**: Must Have

---

### REQ-007: PowerSync Backend Adapter

**User Story**:
As a developer using PowerSync
I want to use NexusStore with my PowerSync database
So that I get unified API benefits with PowerSync's offline-first sync

**Acceptance Criteria**:
- GIVEN a `PowerSyncDatabase` instance
  WHEN I create `PowerSyncBackend(db, tableName, ...)`
  THEN it implements `StoreBackend<T, ID>` interface

- GIVEN a PowerSync backend
  WHEN `watchAll()` is called
  THEN it uses PowerSync's `db.watch()` internally

- GIVEN a PowerSync backend with SQLCipher
  WHEN initialized with encryption key
  THEN data is encrypted at rest using AES-256

**Priority**: Must Have

---

### REQ-008: Brick Backend Adapter

**User Story**:
As a developer using Brick
I want to use NexusStore with my Brick repository
So that I get unified API benefits with Brick's code generation

**Acceptance Criteria**:
- GIVEN an `OfflineFirstWithSupabaseRepository` instance
  WHEN I create `BrickBackend(repository)`
  THEN it implements `StoreBackend<T, ID>` interface

- GIVEN a Brick backend
  WHEN `getAll()` is called with a query
  THEN it translates to Brick's `Query.where()` format

**Priority**: Should Have

---

### REQ-009: Supabase Direct Backend Adapter

**User Story**:
As a developer using Supabase without offline-first
I want to use NexusStore with direct Supabase calls
So that I get unified API for simpler online-only apps

**Acceptance Criteria**:
- GIVEN a `SupabaseClient` instance
  WHEN I create `SupabaseBackend(client, tableName, ...)`
  THEN it implements `StoreBackend<T, ID>` interface

- GIVEN a Supabase backend
  WHEN `watchAll()` is called
  THEN it uses Supabase Realtime subscriptions

- GIVEN a Supabase backend
  WHEN `syncStatus` is observed
  THEN it always returns `SyncStatus.synced` (no offline queue)

**Priority**: Should Have

---

### REQ-010: Drift Backend Adapter (Local-Only)

**User Story**:
As a developer who only needs local storage
I want to use NexusStore with Drift
So that I can migrate to sync-enabled backends later

**Acceptance Criteria**:
- GIVEN a `GeneratedDatabase` instance
  WHEN I create `DriftBackend(db, table, ...)`
  THEN it implements `StoreBackend<T, ID>` interface

- GIVEN a Drift backend
  WHEN sync-related methods are called
  THEN they complete immediately (no-op)

- GIVEN a Drift backend
  WHEN `syncStatus` is observed
  THEN it always returns `SyncStatus.synced` (no remote sync needed)

**Priority**: Should Have

---

### REQ-011: CRDT Backend Adapter

**User Story**:
As a developer building collaborative apps
I want CRDT-based conflict resolution
So that concurrent edits merge automatically

**Acceptance Criteria**:
- GIVEN a `sqlite_crdt` database
  WHEN I create `CrdtBackend(db, ...)`
  THEN it implements `StoreBackend<T, ID>` with CRDT semantics

- GIVEN two devices with conflicting edits
  WHEN they sync
  THEN changes merge using Last-Writer-Wins with HLC timestamps

- GIVEN a deleted record
  WHEN synced
  THEN tombstone is preserved for conflict resolution

**Priority**: Nice to Have

---

### REQ-012: SQLCipher Encryption Support

**User Story**:
As a developer handling sensitive data
I want database-level encryption
So that data at rest is protected

**Acceptance Criteria**:
- GIVEN PowerSync backend with `EncryptionConfig.sqlCipher(keyProvider: ...)`
  WHEN database is created
  THEN it uses `powersync_sqlcipher` with AES-256

- GIVEN an encrypted database
  WHEN accessed without correct key
  THEN operations throw `EncryptionException`

**Priority**: Should Have

---

### REQ-013: Field-Level Encryption

**User Story**:
As a developer handling PHI/PII
I want to encrypt specific fields
So that sensitive data has extra protection

**Acceptance Criteria**:
- GIVEN `EncryptionConfig.fieldLevel(fields: {'ssn', 'diagnosis'})`
  WHEN an item with those fields is saved
  THEN only those fields are encrypted before storage

- GIVEN encrypted fields
  WHEN item is retrieved
  THEN fields are decrypted transparently

- GIVEN an encryption key rotation
  WHEN `store.rotateEncryptionKey(newKey)` is called
  THEN all encrypted fields are re-encrypted

**Priority**: Nice to Have

---

### REQ-014: Audit Logging (HIPAA)

**User Story**:
As a healthcare developer
I want immutable audit logs of all data access
So that I meet HIPAA audit trail requirements

**Acceptance Criteria**:
- GIVEN `AuditConfig.hipaaCompliant(backend: ...)`
  WHEN any read/write operation occurs
  THEN an `AuditLogEntry` is recorded

- GIVEN an audit log entry
  WHEN created
  THEN it includes: userId, timestamp (UTC), action, resourceType, resourceId, success, ipAddress

- GIVEN audit logging enabled
  WHEN logs are queried
  THEN they are retrievable for 6+ years

- GIVEN an audit log
  WHEN `signLogs: true`
  THEN each entry is cryptographically signed with hash chain

**Priority**: Nice to Have

---

### REQ-015: GDPR Right to Erasure

**User Story**:
As a developer serving EU users
I want to process data deletion requests
So that I comply with GDPR Article 17

**Acceptance Criteria**:
- GIVEN `GdprConfig` enabled
  WHEN `store.gdpr.processErasureRequest(userId: ...)` is called
  THEN all user data is deleted or anonymized

- GIVEN data that cannot be fully deleted (legal retention)
  WHEN erasure is requested
  THEN data is anonymized with PII removed

- GIVEN erasure processing
  WHEN complete
  THEN an audit log entry is created

**Priority**: Nice to Have

---

### REQ-016: GDPR Data Portability

**User Story**:
As a developer serving EU users
I want to export user data in portable format
So that I comply with GDPR Article 20

**Acceptance Criteria**:
- GIVEN `GdprConfig` enabled
  WHEN `store.gdpr.exportUserData(userId: ..., format: ExportFormat.json)` is called
  THEN returns JSON containing all user's data

- GIVEN export request
  WHEN format is `ExportFormat.csv`
  THEN returns CSV-formatted data

- GIVEN export complete
  WHEN returned
  THEN includes checksum for integrity verification

**Priority**: Nice to Have

---

### REQ-017: Transaction Support

**User Story**:
As a developer
I want atomic multi-entity operations
So that data integrity is maintained when saving related entities

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>`
  WHEN I call `store.transaction((tx) => ...)`
  THEN all operations within the callback are atomic

- GIVEN a transaction with multiple saves
  WHEN one operation fails
  THEN all operations are rolled back

- GIVEN nested transactions
  WHEN the inner transaction fails
  THEN only the inner transaction is rolled back (savepoint behavior)

- GIVEN a transaction
  WHEN `tx.save()`, `tx.delete()`, `tx.saveAll()` are called
  THEN they participate in the transaction context

**Priority**: Must Have

---

### REQ-018: Cursor-Based Pagination

**User Story**:
As a developer with large datasets
I want cursor-based pagination
So that I can efficiently paginate without offset performance issues

**Acceptance Criteria**:
- GIVEN a `Query<T>` builder
  WHEN I call `.after(cursor)`
  THEN results start after the cursor position

- GIVEN a `Query<T>` builder
  WHEN I call `.before(cursor)`
  THEN results end before the cursor position

- GIVEN a paginated result
  WHEN returned
  THEN includes `nextCursor` and `previousCursor` for navigation

- GIVEN cursor pagination
  WHEN used with `orderBy()`
  THEN cursor is encoded based on sort fields

**Priority**: Should Have

---

### REQ-019: Type-Safe Query Builder (Optional)

**User Story**:
As a developer
I want compile-time validated queries
So that field name typos are caught at build time

**Acceptance Criteria**:
- GIVEN a type-safe query builder
  WHEN I call `Query<User>().where((u) => u.age > 18)`
  THEN field access is validated at compile time

- GIVEN a type-safe query
  WHEN a non-existent field is referenced
  THEN compilation fails

- GIVEN the type-safe builder
  WHEN used alongside string-based queries
  THEN both approaches work (opt-in type safety)

**Priority**: Nice to Have

---

### REQ-020: Conflict Resolution Callbacks

**User Story**:
As a developer
I want control over conflict resolution
So that users can decide how to merge conflicting changes

**Acceptance Criteria**:
- GIVEN `StoreConfig` with `onConflict` callback
  WHEN a sync conflict occurs
  THEN the callback receives `ConflictDetails<T>` with local and remote values

- GIVEN a conflict callback
  WHEN it returns `ConflictAction.keepLocal`
  THEN local version is preserved

- GIVEN a conflict callback
  WHEN it returns `ConflictAction.keepRemote`
  THEN remote version is accepted

- GIVEN a conflict callback
  WHEN it returns `ConflictAction.merge(T merged)`
  THEN the custom merged value is saved

- GIVEN no conflict callback
  WHEN conflict occurs
  THEN default `ConflictResolution` strategy is applied

**Priority**: Should Have

---

### REQ-021: Pending Changes Visibility

**User Story**:
As a developer
I want to see and manage pending changes
So that users can track and retry/cancel individual sync operations

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>`
  WHEN I subscribe to `store.pendingChanges`
  THEN I receive `Stream<List<PendingChange<T>>>` with details

- GIVEN a `PendingChange<T>`
  WHEN accessed
  THEN it includes: item, operation (create/update/delete), retryCount, lastError

- GIVEN a pending change
  WHEN I call `store.retryPendingChange(changeId)`
  THEN that specific change is retried immediately

- GIVEN a pending change
  WHEN I call `store.cancelPendingChange(changeId)`
  THEN the change is removed from queue (local state reverted)

**Priority**: Should Have

---

### REQ-022: Tag-Based Cache Invalidation

**User Story**:
As a developer
I want to invalidate cache by tags or queries
So that I can selectively clear related data

**Acceptance Criteria**:
- GIVEN items saved with tags via `store.save(item, tags: {'user-data', 'profile'})`
  WHEN I call `store.invalidateByTags({'user-data'})`
  THEN all items with that tag are marked stale

- GIVEN a query
  WHEN I call `store.invalidateWhere(query)`
  THEN all items matching the query are invalidated

- GIVEN tag-based invalidation
  WHEN performed
  THEN affected watch streams emit updated data

**Priority**: Should Have

---

### REQ-023: Telemetry & Metrics

**User Story**:
As a developer
I want observability into store performance
So that I can monitor and optimize data layer behavior

**Acceptance Criteria**:
- GIVEN `StoreConfig` with `metricsReporter`
  WHEN any operation completes
  THEN metrics are reported: operation type, duration, success/failure

- GIVEN metrics enabled
  WHEN cache operations occur
  THEN hit/miss rates are tracked

- GIVEN metrics enabled
  WHEN sync operations occur
  THEN success/failure/retry counts are tracked

- GIVEN a custom `MetricsReporter` implementation
  WHEN provided
  THEN it receives all metric events (pluggable: Firebase, DataDog, custom)

**Priority**: Should Have

---

### REQ-024: Key Derivation Specification

**User Story**:
As a security-conscious developer
I want proper key derivation from passwords/passphrases
So that encryption keys are cryptographically strong

**Acceptance Criteria**:
- GIVEN `KeyDerivationConfig.pbkdf2(password, salt, iterations)`
  WHEN key is derived
  THEN PBKDF2-HMAC-SHA256 is used with configurable iterations (min 100,000)

- GIVEN `KeyDerivationConfig.argon2id(password, salt, ...)`
  WHEN key is derived
  THEN Argon2id is used with configurable memory/time cost

- GIVEN key derivation
  WHEN salt is not provided
  THEN a secure random salt is generated and stored

- GIVEN derived keys
  WHEN stored
  THEN only the salt is persisted, never the password or derived key

**Priority**: Must Have

---

### REQ-025: Batch Streaming

**User Story**:
As a developer with large datasets
I want paginated streaming
So that I can load large lists without OOM errors

**Acceptance Criteria**:
- GIVEN a `NexusStore<T, ID>`
  WHEN I call `store.watchAllPaginated(pageSize: 50)`
  THEN it returns `Stream<PagedResult<T>>` loading in chunks

- GIVEN paginated streaming
  WHEN scrolled
  THEN next page is loaded automatically (infinite scroll support)

- GIVEN `PagedResult<T>`
  WHEN accessed
  THEN it includes: items, hasMore, loadMore() callback

- GIVEN memory pressure
  WHEN earlier pages are no longer visible
  THEN they can be released (windowed loading)

**Priority**: Should Have

---

### REQ-026: Data Minimization (GDPR)

**User Story**:
As a developer handling EU user data
I want automatic data retention policies
So that I comply with GDPR data minimization principle

**Acceptance Criteria**:
- GIVEN `GdprConfig` with `retentionPolicies`
  WHEN a retention period expires for a field
  THEN that field is automatically nullified or the record deleted

- GIVEN retention policy `RetentionPolicy(field: 'ipAddress', duration: Duration(days: 30))`
  WHEN 30 days pass since record creation
  THEN `ipAddress` field is set to null

- GIVEN retention processing
  WHEN fields are cleared
  THEN an audit log entry is created

**Priority**: Should Have

---

### REQ-027: Consent Tracking (GDPR)

**User Story**:
As a developer handling EU user data
I want to track user consent
So that I only process data for consented purposes

**Acceptance Criteria**:
- GIVEN `GdprConfig` with `consentTracking: true`
  WHEN `store.gdpr.recordConsent(userId, purposes: {'marketing', 'analytics'})` is called
  THEN consent is recorded with timestamp

- GIVEN recorded consent
  WHEN `store.gdpr.getConsent(userId)` is called
  THEN returns `ConsentRecord` with all consented purposes and timestamps

- GIVEN consent
  WHEN `store.gdpr.withdrawConsent(userId, purposes: {'marketing'})` is called
  THEN consent is withdrawn and audit logged

- GIVEN consent records
  WHEN accessed
  THEN full history with timestamps is available for compliance audits

**Priority**: Should Have

---

### REQ-028: Breach Notification Support (GDPR)

**User Story**:
As a developer handling EU user data
I want to identify affected users in a data breach
So that I can comply with GDPR breach notification requirements

**Acceptance Criteria**:
- GIVEN `GdprConfig` with breach support enabled
  WHEN `store.gdpr.identifyAffectedUsers(query, timeRange)` is called
  THEN returns list of user IDs whose data matches criteria in time range

- GIVEN breach identification
  WHEN `store.gdpr.generateBreachReport(affectedUsers)` is called
  THEN generates report with: affected users, data categories, timeline

- GIVEN breach processing
  WHEN performed
  THEN all actions are audit logged with breach reference ID

**Priority**: Nice to Have

---

### REQ-029: Cross-Store Transactions (Saga Pattern)

**User Story**:
As a developer
I want to coordinate transactions across multiple stores
So that complex operations involving different entity types remain consistent

**Acceptance Criteria**:
- GIVEN multiple `NexusStore` instances
  WHEN I call `NexusStoreCoordinator.transaction([store1, store2], ...)`
  THEN all operations across stores are coordinated

- GIVEN a saga transaction
  WHEN one store operation fails
  THEN compensating actions are executed on successful stores

- GIVEN a saga transaction with `Order` and `Inventory` stores
  WHEN `inventory.decrement()` succeeds but `order.create()` fails
  THEN `inventory.increment()` compensation is executed

**Priority**: Should Have

---

### REQ-030: Middleware/Interceptor API

**User Story**:
As a developer
I want pre/post hooks for all store operations
So that I can add logging, transformation, or validation globally

**Acceptance Criteria**:
- GIVEN `StoreConfig` with `interceptors`
  WHEN any operation is called
  THEN interceptors run in order before and after

- GIVEN an interceptor
  WHEN it modifies the request
  THEN the modified request is passed to the next interceptor

- GIVEN an interceptor
  WHEN it returns early (e.g., from cache)
  THEN subsequent interceptors and the actual operation are skipped

- GIVEN a response interceptor
  WHEN the operation completes
  THEN it can transform the response

**Priority**: Should Have

---

### REQ-031: Delta Sync Support

**User Story**:
As a developer with bandwidth-constrained users
I want to sync only changed fields
So that sync operations are efficient

**Acceptance Criteria**:
- GIVEN `StoreConfig` with `deltaSync: true`
  WHEN an item is updated locally
  THEN only changed fields are tracked

- GIVEN pending changes with delta sync
  WHEN sync occurs
  THEN only changed fields are sent to remote

- GIVEN remote delta updates
  WHEN received
  THEN only specified fields are merged into local state

**Priority**: Should Have

---

### REQ-032: Background Sync Service

**User Story**:
As a developer building mobile apps
I want sync to continue when the app is backgrounded
So that data stays fresh for users

**Acceptance Criteria**:
- GIVEN `BackgroundSyncConfig` enabled
  WHEN app goes to background
  THEN sync continues using platform background APIs

- GIVEN Android platform
  WHEN background sync is configured
  THEN WorkManager is used for reliable background execution

- GIVEN iOS platform
  WHEN background sync is configured
  THEN BGTaskScheduler is used

- GIVEN configurable intervals
  WHEN set
  THEN background sync runs at specified intervals

**Priority**: Nice to Have

---

### REQ-033: Sync Priority Queues

**User Story**:
As a developer
I want critical changes to sync before less important ones
So that important data has lower latency

**Acceptance Criteria**:
- GIVEN `save(item, priority: SyncPriority.critical)`
  WHEN sync occurs
  THEN critical items sync before normal priority

- GIVEN multiple priority levels (critical, high, normal, low)
  WHEN queue is processed
  THEN items are processed in priority order, then FIFO within priority

- GIVEN network bandwidth constraints
  WHEN available
  THEN critical items get priority access

**Priority**: Nice to Have

---

### REQ-034: Code Generation Tooling

**User Story**:
As a developer
I want generated type-safe query fields
So that I get compile-time validation without manual boilerplate

**Acceptance Criteria**:
- GIVEN a `@NexusEntity()` annotated model
  WHEN `build_runner` runs
  THEN `$ModelFields` class is generated with typed field accessors

- GIVEN generated fields
  WHEN used in queries like `Query<User>().where(User$.age > 18)`
  THEN compilation succeeds with type safety

- GIVEN a non-existent field reference
  WHEN using generated fields
  THEN compilation fails

**Priority**: Nice to Have

---

### REQ-035: Schema Validation

**User Story**:
As a developer
I want runtime validation against expected schema
So that data integrity issues are caught early

**Acceptance Criteria**:
- GIVEN `SchemaConfig` with field definitions
  WHEN an item is saved with invalid type
  THEN `SchemaValidationError` is thrown

- GIVEN schema validation enabled
  WHEN data is loaded from backend
  THEN schema compliance is verified

- GIVEN schema mismatches
  WHEN detected
  THEN detailed error with field name and expected vs actual type is provided

**Priority**: Nice to Have

---

### REQ-036: Circuit Breaker Pattern

**User Story**:
As a developer
I want automatic backend failover
So that temporary backend issues don't cascade failures

**Acceptance Criteria**:
- GIVEN `CircuitBreakerConfig` with failure threshold
  WHEN consecutive failures exceed threshold
  THEN circuit opens and operations fail fast

- GIVEN an open circuit
  WHEN cooldown period elapses
  THEN circuit moves to half-open, allowing test requests

- GIVEN a half-open circuit
  WHEN test request succeeds
  THEN circuit closes and normal operation resumes

- GIVEN circuit state changes
  WHEN monitored
  THEN events are emitted for observability

**Priority**: Should Have

---

### REQ-037: Health Check API

**User Story**:
As a DevOps engineer
I want to query store health status
So that I can integrate with monitoring systems

**Acceptance Criteria**:
- GIVEN a `NexusStore`
  WHEN `store.healthCheck()` is called
  THEN returns `HealthStatus` with component health

- GIVEN `HealthStatus`
  WHEN accessed
  THEN includes: overall status, backend connectivity, cache status, sync status

- GIVEN multiple components
  WHEN any is unhealthy
  THEN overall status reflects degraded/unhealthy

- GIVEN health check
  WHEN called
  THEN response includes latency metrics

**Priority**: Should Have

---

### REQ-038: Graceful Degradation Modes

**User Story**:
As a developer
I want configurable behavior when backends are unavailable
So that the app remains usable offline

**Acceptance Criteria**:
- GIVEN `DegradationConfig` with mode `readOnlyCache`
  WHEN backend is unavailable
  THEN reads work from cache, writes are queued

- GIVEN degradation mode `failFast`
  WHEN backend is unavailable
  THEN operations throw immediately with clear error

- GIVEN degradation mode `staleData`
  WHEN backend is unavailable
  THEN expired cache data is returned with warning

- GIVEN degradation state changes
  WHEN detected
  THEN `store.degradationStatus` stream emits new state

**Priority**: Should Have

---

### REQ-039: Memory Pressure Handling

**User Story**:
As a developer targeting low-end devices
I want automatic cache eviction under memory pressure
So that my app doesn't crash on memory-constrained devices

**Acceptance Criteria**:
- GIVEN `MemoryConfig` with pressure thresholds
  WHEN system memory pressure is detected
  THEN LRU cache entries are evicted

- GIVEN memory pressure levels (moderate, critical)
  WHEN moderate pressure occurs
  THEN aggressive eviction begins

- GIVEN critical memory pressure
  WHEN detected
  THEN cache is cleared except pinned items

- GIVEN memory events
  WHEN they occur
  THEN metrics are reported for monitoring

**Priority**: Should Have

---

### REQ-040: Lazy Field Loading

**User Story**:
As a developer with large blob fields
I want to load heavy fields on demand
So that initial load is fast

**Acceptance Criteria**:
- GIVEN `@LazyLoad()` annotation on a field
  WHEN item is fetched
  THEN that field is not loaded initially

- GIVEN a lazy field
  WHEN `item.loadField('thumbnail')` is called
  THEN the field is fetched and populated

- GIVEN a lazy field
  WHEN accessed before loading
  THEN returns null or placeholder

- GIVEN batch loading
  WHEN multiple items need same lazy field
  THEN fields are loaded in single request

**Priority**: Nice to Have

---

### REQ-041: Connection Pooling Abstraction

**User Story**:
As a developer with high-throughput apps
I want managed backend connections
So that connection overhead is minimized

**Acceptance Criteria**:
- GIVEN `ConnectionPoolConfig` with pool size
  WHEN multiple concurrent operations occur
  THEN connections are reused from pool

- GIVEN connection pool
  WHEN pool is exhausted
  THEN operations wait or fail based on config

- GIVEN idle connections
  WHEN timeout elapses
  THEN connections are closed

- GIVEN connection health
  WHEN checked periodically
  THEN unhealthy connections are replaced

**Priority**: Nice to Have

---

### REQ-042: Store Registry (Built-in DI)

**User Story**:
As a developer
I want a simple way to register and access store instances
So that I don't need an external DI package for basic use cases

**Acceptance Criteria**:
- GIVEN `NexusRegistry.register<User>(store)`
  WHEN I call `NexusRegistry.get<User>()` anywhere
  THEN I receive the registered store instance

- GIVEN a registered store
  WHEN I call `NexusRegistry.dispose<User>()`
  THEN the store is disposed and removed from registry

- GIVEN scoped registration with `NexusRegistry.registerScoped<User>(store, scope: 'tenant-123')`
  WHEN I call `NexusRegistry.get<User>(scope: 'tenant-123')`
  THEN I receive the scoped instance

- GIVEN the registry
  WHEN I call `NexusRegistry.reset()`
  THEN all stores are disposed and registry is cleared

**Priority**: Should Have

---

### REQ-043: Computed Stores

**User Story**:
As a developer
I want to derive state from multiple stores
So that I can create aggregate views without manual stream combining

**Acceptance Criteria**:
- GIVEN multiple stores
  WHEN I create `ComputedStore([userStore, orderStore], (user, orders) => ...)`
  THEN it combines streams and computes derived state

- GIVEN a computed store
  WHEN any source store emits
  THEN the computed store recalculates and emits

- GIVEN a compute function
  WHEN it returns the same value (by equality)
  THEN the computed store does not emit (distinctUntilChanged)

- GIVEN a computed store
  WHEN watched
  THEN it emits immediately with current computed value (BehaviorSubject)

**Priority**: Should Have

---

### REQ-044: UI State Containers

**User Story**:
As a developer
I want reactive containers for non-data UI state
So that I can manage form state, filters, etc. with the same patterns as data

**Acceptance Criteria**:
- GIVEN `NexusState<T>(initialValue)`
  WHEN I call `state.value = newValue`
  THEN the stream emits the new value

- GIVEN a NexusState
  WHEN I call `state.update((current) => current.copyWith(...))`
  THEN it applies the transform and emits

- GIVEN a NexusState
  WHEN I subscribe to `state.stream`
  THEN I immediately receive the current value (BehaviorSubject)

- GIVEN a NexusState
  WHEN I call `state.reset()`
  THEN it reverts to initial value and emits

**Priority**: Should Have

---

### REQ-045: Selectors

**User Story**:
As a developer
I want to efficiently select/transform subsets of store data
So that widgets only rebuild when their specific data changes

**Acceptance Criteria**:
- GIVEN a store and `store.select((items) => items.where((i) => i.isActive))`
  WHEN the selector is watched
  THEN it emits only when the selected subset changes

- GIVEN a selector with custom equality
  WHEN `store.select(..., equals: listEquals)`
  THEN it uses the custom equality for change detection

- GIVEN a selector
  WHEN source data changes but selected result is equal
  THEN the selector does not emit

- GIVEN multiple selectors on same store
  WHEN store updates
  THEN each selector computes independently

**Priority**: Should Have

---

### REQ-046: Riverpod Integration

**User Story**:
As a developer using Riverpod
I want first-class NexusStore integration
So that I get auto-generated providers and seamless DI

**Acceptance Criteria**:
- GIVEN `nexus_store_riverpod_binding` package
  WHEN I annotate with `@riverpodNexusStore`
  THEN providers are generated for the store

- GIVEN generated providers
  WHEN I use `ref.watch(usersProvider)`
  THEN I get a `Stream<List<User>>` from `watchAll()`

- GIVEN generated providers
  WHEN I use `ref.watch(userProvider(id))`
  THEN I get a `Stream<User?>` from `watch(id)`

- GIVEN store disposal
  WHEN Riverpod disposes the provider
  THEN the store is properly disposed

**Priority**: Nice to Have

---

### REQ-047: Bloc Integration

**User Story**:
As a developer using Bloc
I want pre-built Bloc/Cubit wrappers for NexusStore
So that I can use familiar Bloc patterns with NexusStore data

**Acceptance Criteria**:
- GIVEN `nexus_store_bloc_binding` package
  WHEN I extend `NexusStoreCubit<User>`
  THEN I get a Cubit that wraps store operations

- GIVEN a NexusStoreCubit
  WHEN store data changes
  THEN Cubit state updates accordingly

- GIVEN a NexusStoreCubit
  WHEN I call `cubit.save(user)`
  THEN it delegates to the underlying store

- GIVEN Bloc disposal
  WHEN `close()` is called
  THEN store subscriptions are cancelled

**Priority**: Nice to Have

---

### REQ-048: Signals Integration

**User Story**:
As a developer using Signals
I want NexusStore data exposed as Signals
So that I can use fine-grained reactivity with NexusStore

**Acceptance Criteria**:
- GIVEN `nexus_store_signals_binding` package
  WHEN I call `store.toSignal()`
  THEN I get a `Signal<List<T>>` that tracks store data

- GIVEN a store signal
  WHEN store emits new data
  THEN the signal updates and dependents rebuild

- GIVEN `store.toSignal(id)`
  WHEN watching a single item
  THEN I get a `Signal<T?>` for that item

- GIVEN computed signals
  WHEN combining store signals
  THEN they work with standard Signals computed()

**Priority**: Nice to Have

---

## Technical Constraints

### Project Configuration (nexus_store monorepo)

| Constraint | Value | Source |
|------------|-------|--------|
| Dart SDK | `^3.5.0` | `melos.yaml` |
| Strict casts | `true` | `analysis_options.yaml` |
| Strict inference | `true` | `analysis_options.yaml` |
| Strict raw types | `true` | `analysis_options.yaml` |
| Code generation | freezed, json_serializable | Core package |
| Logging | `logging: ^1.2.0` | Core package |
| Testing | `test: ^1.24.0`, `mocktail` | Core package |

### Explicit Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| No Flutter dependency | Core package is pure Dart | Usable in CLI, server, edge functions |
| Optional Flutter extension | `nexus_store_flutter` | For Flutter-specific widgets |
| Minimum dependencies | Only essential deps in core | Keep package lightweight |
| Backend adapters optional | Separate packages or peer deps | Users only import what they need |

---

## Public API Contract

### Core Classes

#### NexusStore<T, ID>

```dart
/// A unified reactive data store with policy-based fetching.
///
/// Example:
/// ```dart
/// final store = NexusStore<User, String>(
///   backend: PowerSyncBackend(db, 'users'),
///   config: StoreConfig(
///     fetchPolicy: FetchPolicy.cacheAndNetwork,
///     encryption: EncryptionConfig.fieldLevel(
///       encryptedFields: {'ssn', 'email'},
///       keyProvider: () => secureStorage.getKey(),
///     ),
///   ),
/// );
///
/// await store.initialize();
///
/// // Reactive watch (BehaviorSubject - immediate value)
/// store.watchAll().listen((users) => print('Users: $users'));
///
/// // CRUD operations
/// await store.save(user);
/// final user = await store.get('user_123');
/// await store.delete('user_123');
///
/// await store.dispose();
/// ```
class NexusStore<T, ID> {
  /// Creates a store with the given backend and configuration.
  NexusStore({
    required StoreBackend<T, ID> backend,
    StoreConfig? config,
    AuditService? auditService,
    String? subjectIdField,  // Field name for GDPR subject ID
  });

  // === CONFIGURATION ===

  /// The store configuration.
  StoreConfig get config;

  /// The underlying backend.
  StoreBackend<T, ID> get backend;

  /// Whether this store has been initialized.
  bool get isInitialized;

  /// Whether this store has been disposed.
  bool get isDisposed;

  // === LIFECYCLE ===

  /// Initializes the store and backend.
  /// Must be called before any data operations.
  Future<void> initialize();

  /// Disposes resources and closes streams.
  Future<void> dispose();

  // === READ OPERATIONS ===

  /// Gets a single item by ID.
  /// Returns `null` if not found.
  /// Uses [policy] or falls back to [config.fetchPolicy].
  Future<T?> get(ID id, {FetchPolicy? policy});

  /// Gets all items matching the optional query.
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy});

  /// Watches a single item reactively.
  /// Returns BehaviorSubject stream - emits current value immediately.
  /// Emits `null` if item doesn't exist or is deleted.
  Stream<T?> watch(ID id);

  /// Watches all items matching the optional query.
  /// Returns BehaviorSubject stream - emits current list immediately.
  Stream<List<T>> watchAll({Query<T>? query});

  // === WRITE OPERATIONS ===

  /// Saves (creates or updates) an item.
  /// Returns the saved item (may include server-generated fields).
  Future<T> save(T item, {WritePolicy? policy});

  /// Saves multiple items in a batch.
  Future<List<T>> saveAll(List<T> items, {WritePolicy? policy});

  /// Deletes an item by ID.
  /// Returns `true` if deleted, `false` if not found.
  Future<bool> delete(ID id, {WritePolicy? policy});

  /// Deletes multiple items by IDs.
  /// Returns the count of items actually deleted.
  Future<int> deleteAll(List<ID> ids, {WritePolicy? policy});

  // === SYNC ===

  /// Forces a sync with the remote backend.
  Future<void> sync();

  /// Current sync status.
  SyncStatus get syncStatus;

  /// Stream of sync status changes.
  Stream<SyncStatus> get syncStatusStream;

  /// Number of pending changes waiting to sync.
  Future<int> get pendingChangesCount;

  // === CACHE MANAGEMENT ===

  /// Marks an entity as stale, forcing next fetch to hit network.
  void invalidate(ID id);

  /// Marks all entities as stale.
  void invalidateAll();

  // === COMPLIANCE (optional) ===

  /// GDPR service (available if enableGdpr is true).
  GdprService<T, ID>? get gdpr;

  /// Audit service (if provided in constructor).
  AuditService? get audit;
}
```

**Input/Output Contract**:

| Method | Input | Output | Throws |
|--------|-------|--------|--------|
| `get(id)` | `ID`, `FetchPolicy?` | `Future<T?>` | `StateError` |
| `getAll(query)` | `Query<T>?`, `FetchPolicy?` | `Future<List<T>>` | `StateError` |
| `watch(id)` | `ID` | `Stream<T?>` | `StateError` |
| `watchAll(query)` | `Query<T>?` | `Stream<List<T>>` | `StateError` |
| `save(item)` | `T`, `WritePolicy?` | `Future<T>` | `StateError` |
| `delete(id)` | `ID`, `WritePolicy?` | `Future<bool>` | `StateError` |
| `deleteAll(ids)` | `List<ID>`, `WritePolicy?` | `Future<int>` | `StateError` |
| `sync()` | - | `Future<void>` | Backend errors |
| `initialize()` | - | `Future<void>` | `StateError` |
| `dispose()` | - | `Future<void>` | - |

**Lifecycle Requirements**:
- Must call `initialize()` before any operations
- Operations throw `StateError` if called before initialization or after disposal

---

#### StoreBackend<T, ID>

```dart
/// Abstract interface for storage backends.
///
/// Implement this to add support for a new storage system.
abstract class StoreBackend<T, ID> {
  // === LIFECYCLE ===

  /// Initializes the backend (open connections, etc.).
  Future<void> initialize();

  /// Disposes resources.
  Future<void> dispose();

  // === LOCAL OPERATIONS ===

  /// Gets item from local cache/database.
  Future<T?> getLocal(ID id);

  /// Gets all items from local cache/database.
  Future<List<T>> getAllLocal({Query<T>? query});

  /// Saves item to local cache/database.
  Future<T> saveLocal(T item);

  /// Deletes item from local cache/database.
  Future<void> deleteLocal(ID id);

  /// Watches local changes.
  Stream<List<T>> watchLocal({Query<T>? query});

  // === REMOTE OPERATIONS ===

  /// Gets item from remote source.
  Future<T?> getRemote(ID id);

  /// Gets all items from remote source.
  Future<List<T>> getAllRemote({Query<T>? query});

  /// Saves item to remote source.
  Future<T> saveRemote(T item);

  /// Deletes item from remote source.
  Future<void> deleteRemote(ID id);

  // === SYNC ===

  /// Synchronizes local and remote data.
  Future<void> sync();

  /// Number of pending changes.
  Future<int> get pendingChangesCount;

  /// Stream of sync status.
  Stream<SyncStatus> get syncStatus;

  // === CONNECTIVITY ===

  /// Stream indicating if remote is reachable.
  Stream<bool> get isConnected;

  // === HELPERS ===

  /// Extracts ID from an item.
  ID getId(T item);

  /// Converts JSON to item.
  T fromJson(Map<String, dynamic> json);

  /// Converts item to JSON.
  Map<String, dynamic> toJson(T item);
}
```

---

#### StoreConfig<T>

```dart
/// Configuration for a NexusStore.
@freezed
class StoreConfig<T> with _$StoreConfig<T> {
  const factory StoreConfig({
    /// Default policy for read operations.
    @Default(FetchPolicy.cacheFirst) FetchPolicy defaultFetchPolicy,

    /// Default policy for write operations.
    @Default(WritePolicy.cacheAndNetwork) WritePolicy defaultWritePolicy,

    /// Cache time-to-live. Null means no expiration.
    Duration? cacheTtl,

    /// Maximum items to cache (LRU eviction).
    int? maxCacheSize,

    /// Enable optimistic updates for better UX.
    @Default(true) bool optimisticUpdates,

    /// Retry configuration for failed operations.
    @Default(RetryConfig.defaults()) RetryConfig retryConfig,

    /// Encryption configuration.
    EncryptionConfig? encryption,

    /// Audit logging configuration.
    AuditConfig? audit,

    /// GDPR compliance configuration.
    GdprConfig? gdpr,
  }) = _StoreConfig<T>;
}
```

---

#### Query<T>

```dart
/// Fluent query builder for filtering and sorting.
///
/// Example:
/// ```dart
/// final query = Query<User>()
///   .where('age', greaterThan: 18)
///   .where('status', 'active')
///   .orderBy('createdAt', descending: true)
///   .limit(10);
///
/// final users = await store.getAll(query: query);
/// ```
class Query<T> {
  /// Filters where field equals value.
  Query<T> where(String field, dynamic value);

  /// Filters with comparison operators.
  Query<T> where(
    String field, {
    dynamic equals,
    dynamic notEquals,
    dynamic greaterThan,
    dynamic greaterThanOrEqual,
    dynamic lessThan,
    dynamic lessThanOrEqual,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
  });

  /// Orders results by field.
  Query<T> orderBy(String field, {bool descending = false});

  /// Limits number of results.
  Query<T> limit(int count);

  /// Skips first N results.
  Query<T> offset(int count);
}
```

---

### Enums

```dart
/// Policy for read operations.
/// Inspired by Apollo GraphQL fetch policies.
enum FetchPolicy {
  /// Return cache if available, otherwise fetch from network.
  /// Best for: Read-heavy data that doesn't change frequently.
  cacheFirst,

  /// Always fetch from network, update cache with result.
  /// Best for: Data that must be fresh (e.g., account balance).
  networkFirst,

  /// Return cache immediately, then fetch and emit network result.
  /// Best for: UX optimization where showing stale data is better than loading.
  cacheAndNetwork,

  /// Return only cached data, never fetch from network.
  /// Best for: Offline-only scenarios or when network is unavailable.
  cacheOnly,

  /// Always fetch from network, ignore cache entirely.
  /// Best for: Data that should never be cached (e.g., OTP, real-time prices).
  networkOnly,

  /// Return stale cache immediately while revalidating in background.
  /// Best for: Content that benefits from instant display with eventual consistency.
  staleWhileRevalidate,
}

/// Policy for write operations.
enum WritePolicy {
  /// Write to cache and network simultaneously.
  /// Behavior: Optimistic update to cache, rollback on network failure.
  cacheAndNetwork,

  /// Write to network first, then update cache on success.
  /// Behavior: No optimistic update, UI waits for network confirmation.
  networkFirst,

  /// Write to cache first, sync to network later.
  /// Best for: Offline-first applications.
  cacheFirst,

  /// Write only to cache, never sync to network.
  /// Best for: Local-only data (settings, drafts).
  cacheOnly,
}

/// Current sync status.
enum SyncStatus {
  /// Fully synchronized with remote.
  synced,

  /// Local changes pending sync.
  pending,

  /// Currently syncing with remote.
  syncing,

  /// Sync failed, will retry.
  error,

  /// Sync paused (e.g., offline).
  paused,

  /// Conflict detected, needs resolution.
  conflict,
}

/// Conflict resolution strategies.
enum ConflictResolution {
  /// Server version always wins.
  serverWins,

  /// Client version always wins.
  clientWins,

  /// Most recent timestamp wins.
  latestWins,

  /// Attempt to merge changes.
  merge,

  /// Use CRDT for automatic conflict resolution.
  crdt,

  /// Delegate to custom handler.
  custom,
}

/// Sync modes for different synchronization patterns.
enum SyncMode {
  /// Real-time sync via WebSocket/SSE.
  realtime,

  /// Periodic sync at configured intervals.
  periodic,

  /// Manual sync only when explicitly triggered.
  manual,

  /// Sync triggered by specific events.
  eventDriven,

  /// Sync disabled entirely.
  disabled,
}
```

---

### Error Types

```dart
/// Base class for store errors.
sealed class StoreError implements Exception {
  String get message;
  StackTrace? get stackTrace;
}

/// Error during fetch operations.
class FetchError extends StoreError { ... }

/// Error during save operations.
class SaveError extends StoreError { ... }

/// Error during delete operations.
class DeleteError extends StoreError { ... }

/// Error during sync operations.
class SyncError extends StoreError { ... }

/// Error due to encryption/decryption failure.
class EncryptionError extends StoreError { ... }

/// Error due to validation failure.
class ValidationError extends StoreError { ... }
```

---

## Dependencies

### Core Package (`nexus_store`)

| Package | Version | Rationale |
|---------|---------|-----------|
| `rxdart` | `^0.28.0` | BehaviorSubject for reactive streams |
| `freezed_annotation` | `^3.1.0` | Immutable config classes |
| `json_annotation` | `^4.9.0` | JSON serialization |
| `meta` | `^1.9.0` | `@immutable` annotation |
| `logging` | `^1.2.0` | Consistent logging |
| `collection` | `^1.18.0` | Collection utilities |
| `cryptography` | `^2.7.0` | AES-256-GCM field encryption |
| `crypto` | `^3.0.5` | SHA-256 for audit log hash chains |

### Adapter Packages (Separate Packages)

| Adapter Package | Dependencies | Purpose |
|-----------------|-------------|---------|
| `nexus_store_powersync_adapter` | `powersync: ^1.17.0`, `powersync_sqlcipher: ^1.0.0` | PowerSync offline-first sync with optional SQLCipher |
| `nexus_store_drift_adapter` | `drift: ^2.22.0` | Local-only Drift database |
| `nexus_store_supabase_adapter` | `supabase: ^2.8.0` | Supabase direct + Realtime subscriptions |
| `nexus_store_brick_adapter` | `brick_offline_first_with_supabase: ^2.1.0` | Brick offline-first with code generation |
| `nexus_store_crdt_adapter` | `sqlite_crdt: ^2.1.0`, `crdt: ^5.2.0` | CRDT with HLC timestamps |
| `nexus_store_flutter` | `flutter: sdk` | Flutter widgets (NexusStoreBuilder, NexusStoreProvider) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Application Code                                │
│                                                                              │
│   store.get(id)    store.watchAll()    store.save(item)    store.sync()    │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                            NexusStore<T, ID>                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Policy Engine                                                       │    │
│  │  - FetchPolicy routing (cacheFirst, networkFirst, etc.)              │    │
│  │  - WritePolicy routing (optimistic, confirmed)                       │    │
│  │  - Cache TTL management                                              │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Reactive Layer (RxDart)                                             │    │
│  │  - BehaviorSubject<Map<ID, T>> for items                             │    │
│  │  - BehaviorSubject<SyncStatus> for sync status                       │    │
│  │  - PublishSubject<StoreError> for errors                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Compliance Layer (Optional)                                         │    │
│  │  - AuditService (logging all operations)                             │    │
│  │  - GdprService (erasure, portability)                                │    │
│  │  - FieldEncryptor (PHI/PII protection)                               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                          StoreBackend<T, ID>                                 │
│                         (Abstract Interface)                                 │
└───────┬─────────────┬─────────────┬─────────────┬─────────────┬─────────────┘
        │             │             │             │             │
   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
   │PowerSync│   │  Brick  │   │Supabase │   │  Drift  │   │  CRDT   │
   │ Backend │   │ Backend │   │ Backend │   │ Backend │   │ Backend │
   └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘
        │             │             │             │             │
   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
   │powersync│   │  brick  │   │supabase │   │  drift  │   │sqlite   │
   │ package │   │ package │   │ package │   │ package │   │  _crdt  │
   └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

---

## Monorepo Structure

```
nexus_store/
├── melos.yaml
├── pubspec.yaml (workspace)
├── analysis_options.yaml
├── README.md
├── packages/
│   ├── nexus_store/                      # Core package (Pure Dart)
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── nexus_store.dart
│   │   │   └── src/
│   │   │       ├── core/
│   │   │       │   ├── nexus_store.dart
│   │   │       │   ├── store_backend.dart
│   │   │       │   └── composite_backend.dart
│   │   │       ├── config/
│   │   │       │   ├── store_config.dart
│   │   │       │   ├── policies.dart
│   │   │       │   └── retry_config.dart
│   │   │       ├── reactive/
│   │   │       │   └── reactive_store_mixin.dart
│   │   │       ├── query/
│   │   │       │   ├── query.dart
│   │   │       │   └── query_translator.dart
│   │   │       ├── policy/
│   │   │       │   ├── fetch_policy_handler.dart
│   │   │       │   └── write_policy_handler.dart
│   │   │       ├── security/
│   │   │       │   ├── encryption_config.dart
│   │   │       │   ├── encryption_algorithm.dart
│   │   │       │   ├── field_encryptor.dart
│   │   │       │   └── encryption_service.dart
│   │   │       ├── compliance/
│   │   │       │   ├── audit_service.dart
│   │   │       │   ├── audit_log_entry.dart
│   │   │       │   └── gdpr_service.dart
│   │   │       └── errors/
│   │   │           └── store_errors.dart
│   │   └── test/
│   │
│   ├── nexus_store_flutter/              # Flutter extension
│   ├── nexus_store_powersync_adapter/    # PowerSync adapter
│   ├── nexus_store_drift_adapter/        # Drift adapter
│   ├── nexus_store_supabase_adapter/     # Supabase adapter
│   ├── nexus_store_brick_adapter/        # Brick adapter
│   └── nexus_store_crdt_adapter/         # CRDT adapter
│
└── docs/
    └── specs/
        └── SPEC-nexus-store.md
```

---

## Multiple Adapters Usage

### Single Store = Single Backend (Default)

By design, each `NexusStore<T, ID>` instance takes exactly one `StoreBackend`:

```dart
// One store, one backend
final userStore = NexusStore<User, String>(
  backend: PowerSyncBackend(...),
);
```

### Multiple Stores with Different Backends (Recommended)

Create separate store instances for different entity types:

```dart
// Users synced via PowerSync (offline-first)
final userStore = NexusStore<User, String>(
  backend: PowerSyncBackend(powerSync),
);

// Analytics stored in Supabase only (online)
final analyticsStore = NexusStore<AnalyticsEvent, String>(
  backend: SupabaseBackend(supabase, 'analytics'),
);

// Local settings in Drift (never synced)
final settingsStore = NexusStore<Setting, String>(
  backend: DriftBackend(database),
);
```

### CompositeBackend for Advanced Scenarios

For primary/fallback or caching patterns:

```dart
/// Wraps multiple backends with fallback behavior
class CompositeBackend<T, ID> implements StoreBackend<T, ID> {
  CompositeBackend({
    required this.primary,
    this.fallback,
    this.cache,
    this.readStrategy = CompositeReadStrategy.primaryFirst,
    this.writeStrategy = CompositeWriteStrategy.primaryOnly,
  });

  final StoreBackend<T, ID> primary;
  final StoreBackend<T, ID>? fallback;
  final StoreBackend<T, ID>? cache;
}

// Usage: Primary PowerSync, fallback to Supabase if offline fails
final backend = CompositeBackend<User, String>(
  primary: PowerSyncBackend(...),
  fallback: SupabaseBackend(...),
);
```

---

## RxDart Integration

nexus_store uses RxDart's `BehaviorSubject` for reactive streams that emit the current value immediately upon subscription.

### Why BehaviorSubject?

Unlike standard Dart `Stream`:
- **Regular Stream**: New subscribers get nothing until next emit
- **BehaviorSubject**: New subscribers immediately receive the current value

```dart
// With regular Stream: subscriber sees nothing initially
final stream = StreamController<List<User>>.broadcast();
stream.stream.listen((users) => print(users)); // Nothing printed yet

// With BehaviorSubject: subscriber immediately gets current value
final subject = BehaviorSubject.seeded(<User>[]);
subject.stream.listen((users) => print(users)); // Prints [] immediately!
```

### ReactiveState<T>

Core reactive container wrapping `BehaviorSubject`:

```dart
/// A reactive state container using BehaviorSubject.
class ReactiveState<T> {
  ReactiveState(T initialValue) : _subject = BehaviorSubject.seeded(initialValue);

  /// The current value (synchronous access).
  T get value => _subject.value;

  /// Updates the current value.
  set value(T newValue) => _subject.add(newValue);

  /// Stream of value changes.
  /// Emits the current value immediately upon subscription.
  Stream<T> get stream => _subject.stream;

  /// Updates the value using a transform function.
  void update(T Function(T current) transform) {
    value = transform(value);
  }

  /// Disposes this reactive state.
  Future<void> dispose() => _subject.close();
}
```

### ReactiveList<T> and ReactiveMap<K, V>

Specialized reactive containers for collections:

```dart
// ReactiveList - reactive list with add/remove operations
final users = ReactiveList<User>();
users.add(user);           // Emits [..., user]
users.remove(user);        // Emits list without user
users.clear();             // Emits []

// Stream updates automatically
users.stream.listen((list) => print('Count: ${list.length}'));

// ReactiveMap - reactive map with set/remove operations
final cache = ReactiveMap<String, User>();
cache.set('user-123', user);  // Emits {user-123: user}
cache.remove('user-123');     // Emits {}

// Stream updates automatically
cache.stream.listen((map) => print('Keys: ${map.keys}'));
```

### ReactiveStoreMixin

Helper mixin for managing multiple reactive states:

```dart
class MyService with ReactiveStoreMixin {
  late final _users = createReactiveState<List<User>>([]);
  late final _loading = createReactiveState<bool>(false);

  Stream<List<User>> get users => _users.stream;
  Stream<bool> get loading => _loading.stream;

  Future<void> loadUsers() async {
    _loading.value = true;
    _users.value = await api.getUsers();
    _loading.value = false;
  }

  Future<void> dispose() => disposeReactiveStates();
}
```

### Watch Streams in NexusStore

The `watch()` and `watchAll()` methods return `BehaviorSubject`-backed streams:

```dart
final userStore = NexusStore<User, String>(backend: ...);
await userStore.initialize();

// Watch single item - immediate value, then updates
userStore.watch('user-123').listen((user) {
  // Called immediately with current value (or null)
  // Called again on every change
  if (user != null) {
    print('User: ${user.name}');
  }
});

// Watch all - immediate list, then updates
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) {
  // Called immediately with current matching users
  // Called again when any active user changes
  print('Active users: ${users.length}');
});

// Combine with RxDart operators
userStore.watchAll()
  .debounceTime(Duration(milliseconds: 300))
  .distinctUntilChanged((a, b) => a.length == b.length)
  .listen((users) => updateUI(users));
```

---

## StoreResult<T> - Loading/Error State Management

### Rationale

Following industry standards (Apollo Client, TanStack Query, Riverpod AsyncValue, Elf), loading and error states are intrinsic to async operations, not separate concerns. This does NOT violate the Single Responsibility Principle.

| Library | Approach |
|---------|----------|
| Apollo Client | `{ loading, error, data }` |
| TanStack Query | `{ isPending, isError, isSuccess, data, error }` |
| Riverpod | `AsyncValue<T>` sealed class with `.when()` |
| Elf (ngneat) | Status: `idle`, `pending`, `success`, `error` |

**NexusStore approach**: Elf-inspired status naming + Riverpod ergonomics.

### RequestStatus Enum

```dart
/// Status of a store operation (Elf-inspired naming convention).
enum RequestStatus {
  /// No request made yet (initial state).
  idle,

  /// Request in progress.
  pending,

  /// Request completed successfully.
  success,

  /// Request failed with error.
  error,
}
```

### StoreResult<T> Sealed Class

```dart
@freezed
sealed class StoreResult<T> with _$StoreResult<T> {
  /// Initial state - no data loaded yet.
  const factory StoreResult.idle() = StoreIdle<T>;

  /// Loading/refreshing - optionally with previous data for stale-while-revalidate.
  const factory StoreResult.pending([T? previousValue]) = StorePending<T>;

  /// Successfully loaded data.
  const factory StoreResult.success(T value) = StoreSuccess<T>;

  /// Failed with error - optionally with stale data.
  const factory StoreResult.error(
    Object error, [
    StackTrace? stackTrace,
    T? previousValue,
  ]) = StoreFailure<T>;
}
```

### Convenience Getters and Methods

```dart
extension StoreResultX<T> on StoreResult<T> {
  // === Status getters (Elf-style) ===
  RequestStatus get status;
  bool get isIdle;
  bool get isPending;
  bool get isSuccess;
  bool get isError;
  bool get isRefreshing => isPending && hasValue;

  // === Data getters (Riverpod-style) ===
  T? get valueOrNull;
  T valueOr(T defaultValue);
  bool get hasValue;
  Object? get errorOrNull;
  StackTrace? get stackTraceOrNull;

  // === Callbacks (Riverpod .when() style) ===
  R when<R>({
    required R Function() idle,
    required R Function(T? previousValue) pending,
    required R Function(T value) success,
    required R Function(Object error, StackTrace? stack, T? previousValue) error,
  });

  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousValue)? pending,
    R Function(T value)? success,
    R Function(Object error, StackTrace? stack, T? previousValue)? error,
    required R Function() orElse,
  });

  // === Transforms ===
  StoreResult<R> map<R>(R Function(T value) transform);
  StoreResult<T> mapError(Object Function(Object error) transform);
}
```

### Stream Extensions

```dart
extension StoreResultStreamX<T> on Stream<StoreResult<T>> {
  /// Only emit successful data values, skip idle/pending/error.
  Stream<T> whereSuccess();

  /// Skip loading emissions when we already have data (stale-while-revalidate UX).
  Stream<StoreResult<T>> skipPendingWhenHasValue();

  /// Map only the data values, pass through other states.
  Stream<StoreResult<R>> mapData<R>(R Function(T value) transform);

  /// Convert to raw data stream (throws on error).
  Stream<T?> toDataStream();
}
```

### NexusStore API Additions

```dart
class NexusStore<T, ID> {
  // === Existing API (unchanged) ===
  Future<T?> get(ID id, {FetchPolicy? policy});
  Stream<T?> watch(ID id);
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy});
  Stream<List<T>> watchAll({Query<T>? query});

  // === New stateful API ===
  /// Watch with full loading/error state.
  Stream<StoreResult<T?>> watchWithStatus(ID id);

  /// Watch all with full loading/error state.
  Stream<StoreResult<List<T>>> watchAllWithStatus({Query<T>? query});

  /// Get status for a specific entity.
  RequestStatus getStatus(ID id);

  /// Stream of status changes for a specific entity.
  Stream<RequestStatus> watchStatus(ID id);

  /// Check if entity is currently loading.
  bool isPending(ID id);
}
```

### Flutter Widget Builders (nexus_store_flutter)

```dart
/// Builds UI based on StoreResult state with sensible defaults.
class StoreResultBuilder<T> extends StatelessWidget {
  const StoreResultBuilder({
    required this.result,
    required this.builder,
    this.idle,
    this.pending,
    this.error,
  });

  final StoreResult<T> result;
  final Widget Function(BuildContext context, T value) builder;
  final Widget Function(BuildContext context)? idle;
  final Widget Function(BuildContext context, T? previousValue)? pending;
  final Widget Function(BuildContext context, Object error, T? previousValue)? error;
}

/// StreamBuilder wrapper for StoreResult streams.
class StoreResultStreamBuilder<T> extends StatelessWidget {
  const StoreResultStreamBuilder({
    required this.stream,
    required this.builder,
    this.idle,
    this.pending,
    this.error,
  });

  final Stream<StoreResult<T>> stream;
  final Widget Function(BuildContext context, T value) builder;
  final Widget Function(BuildContext context)? idle;
  final Widget Function(BuildContext context, T? previousValue)? pending;
  final Widget Function(BuildContext context, Object error, T? previousValue)? error;
}
```

### Usage Examples

```dart
// === Quick status checks (Elf-style) ===
if (result.isIdle) return Text('Pull to refresh');
if (result.isPending) return CircularProgressIndicator();
if (result.isError) return ErrorWidget(result.errorOrNull!);
return UserCard(result.valueOrNull!);

// === Callback style (Riverpod .when()) ===
result.when(
  idle: () => Text('Pull to refresh'),
  pending: (prev) => prev != null
    ? UserCard(prev, refreshing: true)
    : CircularProgressIndicator(),
  success: (user) => UserCard(user),
  error: (e, stack, prev) => ErrorWidget(e),
);

// === Quick data access ===
final user = result.valueOrNull;
final users = result.valueOr([]);

// === Stream with status ===
userStore.watchWithStatus('user-123').listen((result) {
  // result is StoreResult<User?> with full state
});

// === Flutter widget ===
StoreResultStreamBuilder<User>(
  stream: userStore.watchWithStatus('user-123'),
  builder: (context, user) => UserCard(user),
  // loading and error have sensible defaults
);

// === Stream operators ===
userStore.watchAllWithStatus()
  .skipPendingWhenHasValue()  // Show stale data during refresh
  .mapData((users) => users.where((u) => u.isActive).toList())
  .whereSuccess()
  .listen((activeUsers) => updateUI(activeUsers));
```

---

## Encryption Layer

### EncryptionConfig (Sealed Class)

```dart
@freezed
sealed class EncryptionConfig with _$EncryptionConfig {
  /// No encryption (default)
  const factory EncryptionConfig.none() = EncryptionNone;

  /// SQLCipher database-level encryption (AES-256)
  const factory EncryptionConfig.sqlCipher({
    required Future<String> Function() keyProvider,
    @Default(256000) int kdfIterations,
  }) = EncryptionSqlCipher;

  /// Field-level encryption for specific sensitive fields
  const factory EncryptionConfig.fieldLevel({
    required Set<String> encryptedFields,
    required Future<String> Function() keyProvider,
    @Default(EncryptionAlgorithm.aes256Gcm) EncryptionAlgorithm algorithm,
    @Default('v1') String version,
  }) = EncryptionFieldLevel;
}
```

### EncryptionAlgorithm Enum

```dart
enum EncryptionAlgorithm {
  /// AES-256-GCM (recommended - authenticated encryption)
  aes256Gcm,

  /// AES-256-CBC (legacy compatibility)
  aes256Cbc,

  /// ChaCha20-Poly1305 (mobile-optimized)
  chaCha20Poly1305,
}
```

### Usage Examples

```dart
// No encryption (default)
final store = NexusStore<User, String>(
  backend: PowerSyncBackend(...),
  config: StoreConfig(encryption: EncryptionConfig.none()),
);

// SQLCipher encryption at rest
final store = NexusStore<User, String>(
  backend: PowerSyncBackend(...),
  config: StoreConfig(
    encryption: EncryptionConfig.sqlCipher(
      keyProvider: () => secureStorage.read('db_key'),
      kdfIterations: 256000,
    ),
  ),
);

// Field-level encryption for PII/PHI
final store = NexusStore<Patient, String>(
  backend: DriftBackend(...),
  config: StoreConfig(
    encryption: EncryptionConfig.fieldLevel(
      encryptedFields: {'ssn', 'medicalRecordNumber', 'diagnosis'},
      keyProvider: () => keyVault.getFieldEncryptionKey(),
      algorithm: EncryptionAlgorithm.aes256Gcm,
    ),
  ),
);
// Data stored: {"name": "John", "ssn": "enc:v1:aGVsbG8gd29ybGQ=..."}
```

---

## Testing Requirements

### Unit Tests

| Requirement | Test Scenarios |
|-------------|----------------|
| REQ-001 | Backend interface compliance for each adapter |
| REQ-002 | BehaviorSubject emission timing, multiple listeners |
| REQ-003 | Each FetchPolicy with cache hit/miss combinations |
| REQ-004 | Each WritePolicy with online/offline states |
| REQ-005 | SyncStatus transitions, pendingChangesCount accuracy |
| REQ-006 | Query builder SQL/filter generation |

### Integration Tests

| Scenario | Description |
|----------|-------------|
| PowerSync E2E | Full CRUD cycle with PowerSync backend |
| Offline/Online | Operations while offline, sync when back online |
| Policy switching | Same store, different policies per operation |
| Multi-listener | Multiple widgets watching same store |

### Compliance Tests

| Scenario | Description |
|----------|-------------|
| Audit immutability | Verify logs cannot be modified |
| GDPR erasure | Verify all user data is deleted/anonymized |
| Encryption roundtrip | Encrypt → store → retrieve → decrypt |

---

## Implementation Tasks

### Task 1: Core Interfaces [P] ✅ COMPLETE
**Files**: `lib/src/core/store_backend.dart`, `lib/src/core/nexus_store.dart`, `lib/src/core/composite_backend.dart`
**Implements**: REQ-001
**Complexity**: Medium

**Deliverables**:
- [x] Define `StoreBackend<T, ID>` abstract class
- [x] Define `NexusStore<T, ID>` class skeleton
- [x] Define `CompositeBackend<T, ID>` for multi-backend scenarios
- [ ] Add unit tests for interface contracts

### Task 2: Configuration Classes [P] ✅ COMPLETE
**Files**: `lib/src/config/store_config.dart`, `lib/src/config/policies.dart`
**Implements**: REQ-003, REQ-004
**Complexity**: Low

**Deliverables**:
- [x] Create `StoreConfig` freezed class
- [x] Create `FetchPolicy`, `WritePolicy`, `SyncStatus`, `SyncMode`, `ConflictResolution` enums
- [x] Create `RetryConfig` class with exponential backoff
- [ ] Add unit tests

### Task 3: RxDart Reactive Layer [P] ✅ COMPLETE
**Files**: `lib/src/reactive/reactive_store_mixin.dart`
**Implements**: REQ-002
**Complexity**: Medium

**Deliverables**:
- [x] Implement BehaviorSubject-based `ReactiveState<T>`
- [x] Implement `watch()` and `watchAll()` methods
- [x] Add stream lifecycle management (dispose)
- [ ] Add unit tests for emission timing

### Task 4: Query Builder [P] ✅ COMPLETE
**Files**: `lib/src/query/query.dart`, `lib/src/query/query_translator.dart`
**Implements**: REQ-006
**Complexity**: Medium

**Deliverables**:
- [x] Implement fluent `Query<T>` builder with `where`, `orderBy`, `limit`, `offset`
- [x] Create abstract `QueryTranslator<T>` interface
- [ ] Add unit tests

### Task 5: Policy Engine ✅ COMPLETE
**Files**: `lib/src/policy/fetch_policy_handler.dart`, `lib/src/policy/write_policy_handler.dart`
**Implements**: REQ-003, REQ-004
**Depends On**: Task 1, Task 2
**Complexity**: Medium

**Deliverables**:
- [x] Implement `FetchPolicyHandler` with all policies (cacheFirst, networkFirst, cacheAndNetwork, etc.)
- [x] Implement `WritePolicyHandler` with all policies (cacheAndNetwork, networkFirst, cacheFirst, cacheOnly)
- [ ] Add integration tests

### Task 6: PowerSync Backend Adapter 📦 STUB
**Package**: `nexus_store_powersync_adapter`
**Implements**: REQ-007
**Depends On**: Task 1, Task 4
**Complexity**: Medium

**Deliverables**:
- [x] Create adapter package skeleton
- [ ] Implement `PowerSyncBackend` class
- [ ] Implement query translation for SQL
- [ ] Add integration tests with PowerSync

### Task 7: Drift Backend Adapter [P] 📦 STUB
**Package**: `nexus_store_drift_adapter`
**Implements**: REQ-010
**Depends On**: Task 1, Task 4
**Complexity**: Low

**Deliverables**:
- [x] Create adapter package skeleton
- [ ] Implement `DriftBackend` class
- [ ] Implement query translation for Drift
- [ ] Add integration tests

### Task 8: Supabase Backend Adapter [P] 📦 STUB
**Package**: `nexus_store_supabase_adapter`
**Implements**: REQ-009
**Depends On**: Task 1, Task 4
**Complexity**: Low

**Deliverables**:
- [x] Create adapter package skeleton
- [ ] Implement `SupabaseBackend` class
- [ ] Implement Realtime subscription for `watchAll()`
- [ ] Add integration tests

### Task 9: Brick Backend Adapter 📦 STUB
**Package**: `nexus_store_brick_adapter`
**Implements**: REQ-008
**Depends On**: Task 1, Task 4
**Complexity**: Medium

**Deliverables**:
- [x] Create adapter package skeleton
- [ ] Implement `BrickBackend` class
- [ ] Implement query translation for Brick Query
- [ ] Add integration tests

### Task 10: CRDT Backend Adapter 📦 STUB
**Package**: `nexus_store_crdt_adapter`
**Implements**: REQ-011
**Depends On**: Task 1, Task 4
**Complexity**: High

**Deliverables**:
- [x] Create adapter package skeleton
- [ ] Implement `CrdtBackend` class with HLC
- [ ] Implement merge logic
- [ ] Add integration tests

### Task 11: Encryption Support ✅ COMPLETE
**Files**: `lib/src/security/encryption_config.dart`, `lib/src/security/field_encryptor.dart`, `lib/src/security/encryption_service.dart`, `lib/src/security/encryption_algorithm.dart`
**Implements**: REQ-012, REQ-013
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [x] Create `EncryptionConfig` sealed class (none, sqlCipher, fieldLevel)
- [x] Create `EncryptionAlgorithm` enum (aes256Gcm, aes256Cbc, chaCha20Poly1305)
- [x] Implement `FieldEncryptor` interface and `DefaultFieldEncryptor` with AES-256-GCM
- [x] Implement `EncryptionService` coordinator
- [ ] Add encryption roundtrip tests

### Task 12: Audit Logging ✅ COMPLETE
**Files**: `lib/src/compliance/audit_service.dart`, `lib/src/compliance/audit_log_entry.dart`
**Implements**: REQ-014
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [x] Create `AuditLogEntry` freezed model with action, entityType, actorId, etc.
- [x] Create `AuditAction` enum (create, read, update, delete, list, export, accessDenied, etc.)
- [x] Create `ActorType` enum (user, service, system, apiClient, anonymous)
- [x] Implement `AuditService` with SHA-256 hash chain for integrity
- [ ] Add immutability tests

### Task 13: GDPR Service ✅ COMPLETE
**Files**: `lib/src/compliance/gdpr_service.dart`
**Implements**: REQ-015, REQ-016
**Depends On**: Task 1, Task 12
**Complexity**: Medium

**Deliverables**:
- [x] Implement erasure request processing (Article 17)
- [x] Implement data portability export (Article 20) with JSON/CSV
- [x] Create `ExportFormat` enum and `ExportResult` model
- [ ] Add compliance tests

### Task 14: Flutter Extension 📦 STUB
**Package**: `nexus_store_flutter`
**Implements**: Flutter widgets
**Depends On**: Task 1, Task 3
**Complexity**: Low

**Deliverables**:
- [x] Create Flutter extension package skeleton
- [ ] Implement `NexusStoreBuilder` widget (StreamBuilder wrapper)
- [ ] Implement `NexusStoreProvider` widget (InheritedWidget for DI)
- [ ] Add widget tests

### Task 15: Documentation & Examples
**Files**: `README.md`, `example/`
**Implements**: All
**Depends On**: All
**Complexity**: Low

**Deliverables**:
- [ ] Write comprehensive README
- [ ] Create example app for each backend
- [ ] Add API documentation

### Task 16: Transaction Support ⏳ PENDING
**Files**: `lib/src/core/transaction.dart`, `lib/src/core/nexus_store.dart`
**Implements**: REQ-017
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `Transaction<T, ID>` class with save/delete/saveAll methods
- [ ] Create `TransactionContext` for tracking transaction state
- [ ] Add `transaction()` method to `NexusStore`
- [ ] Implement rollback on failure
- [ ] Implement savepoint support for nested transactions
- [ ] Add unit tests

### Task 17: Cursor-Based Pagination ⏳ PENDING
**Files**: `lib/src/query/cursor.dart`, `lib/src/query/query.dart`
**Implements**: REQ-018
**Depends On**: Task 4
**Complexity**: Medium

**Deliverables**:
- [ ] Create `Cursor` class with encode/decode methods
- [ ] Create `PagedResult<T>` with items, nextCursor, previousCursor
- [ ] Add `after(cursor)` and `before(cursor)` to `Query<T>`
- [ ] Implement cursor encoding based on orderBy fields
- [ ] Add `getAllPaged()` method to `NexusStore`
- [ ] Add unit tests

### Task 18: Type-Safe Query Builder ⏳ PENDING
**Files**: `lib/src/query/type_safe_query.dart`
**Implements**: REQ-019
**Depends On**: Task 4
**Complexity**: High

**Deliverables**:
- [ ] Create `TypeSafeQuery<T>` builder using expression trees
- [ ] Implement `where((item) => item.field > value)` syntax
- [ ] Create `FieldAccessor<T, F>` for compile-time field validation
- [ ] Add code generation support (optional build_runner integration)
- [ ] Ensure backward compatibility with string-based queries
- [ ] Add unit tests

### Task 19: Conflict Resolution Callbacks ⏳ PENDING
**Files**: `lib/src/sync/conflict_resolver.dart`, `lib/src/sync/conflict_details.dart`
**Implements**: REQ-020
**Depends On**: Task 1, Task 5
**Complexity**: Medium

**Deliverables**:
- [ ] Create `ConflictDetails<T>` with localValue, remoteValue, timestamp info
- [ ] Create `ConflictAction` enum (keepLocal, keepRemote, merge)
- [ ] Create `ConflictResolver<T>` callback typedef
- [ ] Add `onConflict` to `StoreConfig`
- [ ] Integrate with sync flow in `NexusStore`
- [ ] Add unit tests

### Task 20: Pending Changes Visibility ⏳ PENDING
**Files**: `lib/src/sync/pending_change.dart`, `lib/src/core/nexus_store.dart`
**Implements**: REQ-021
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `PendingChange<T>` model with item, operation, retryCount, lastError
- [ ] Create `PendingChangeOperation` enum (create, update, delete)
- [ ] Add `pendingChanges` stream to `NexusStore`
- [ ] Add `retryPendingChange(changeId)` method
- [ ] Add `cancelPendingChange(changeId)` method
- [ ] Add unit tests

### Task 21: Tag-Based Cache Invalidation ⏳ PENDING
**Files**: `lib/src/cache/cache_tags.dart`, `lib/src/core/nexus_store.dart`
**Implements**: REQ-022
**Depends On**: Task 1
**Complexity**: Low

**Deliverables**:
- [ ] Create tag storage alongside cached items
- [ ] Add `tags` parameter to `save()` method
- [ ] Add `invalidateByTags(Set<String> tags)` method
- [ ] Add `invalidateWhere(Query<T> query)` method
- [ ] Emit updates on affected watch streams
- [ ] Add unit tests

### Task 22: Telemetry & Metrics ⏳ PENDING
**Files**: `lib/src/telemetry/metrics_reporter.dart`, `lib/src/telemetry/store_metrics.dart`
**Implements**: REQ-023
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `MetricsReporter` abstract interface
- [ ] Create `StoreMetric` model with operation, duration, success
- [ ] Create `CacheMetrics` with hitCount, missCount, hitRate
- [ ] Create `SyncMetrics` with successCount, failureCount, retryCount
- [ ] Add `metricsReporter` to `StoreConfig`
- [ ] Instrument all store operations
- [ ] Create `NoOpMetricsReporter` default implementation
- [ ] Add unit tests

### Task 23: Key Derivation ⏳ PENDING
**Files**: `lib/src/security/key_derivation.dart`
**Implements**: REQ-024
**Depends On**: Task 11
**Complexity**: Medium

**Deliverables**:
- [ ] Create `KeyDerivationConfig` sealed class (pbkdf2, argon2id)
- [ ] Implement PBKDF2-HMAC-SHA256 with configurable iterations
- [ ] Implement Argon2id with configurable memory/time cost
- [ ] Create `DerivedKey` model with key bytes and salt
- [ ] Add secure random salt generation
- [ ] Integrate with `EncryptionConfig`
- [ ] Add unit tests

### Task 24: Batch Streaming ⏳ PENDING
**Files**: `lib/src/core/nexus_store.dart`, `lib/src/query/paged_result.dart`
**Implements**: REQ-025
**Depends On**: Task 1, Task 17
**Complexity**: Medium

**Deliverables**:
- [ ] Create `PagedResult<T>` with items, hasMore, loadMore callback
- [ ] Add `watchAllPaginated(pageSize)` method to `NexusStore`
- [ ] Implement chunked loading with BehaviorSubject
- [ ] Add windowed loading support (release old pages)
- [ ] Integrate with Flutter ListView.builder patterns
- [ ] Add unit tests

### Task 25: Enhanced GDPR Compliance ⏳ PENDING
**Files**: `lib/src/compliance/data_minimization.dart`, `lib/src/compliance/consent_service.dart`, `lib/src/compliance/breach_service.dart`
**Implements**: REQ-026, REQ-027, REQ-028
**Depends On**: Task 12, Task 13
**Complexity**: High

**Deliverables**:
- [ ] Create `RetentionPolicy` model with field, duration, action
- [ ] Create `DataMinimizationService` with auto-purge logic
- [ ] Create `ConsentRecord` model with purposes, timestamps
- [ ] Create `ConsentService` with record/get/withdraw methods
- [ ] Create `BreachReport` model
- [ ] Create `BreachService` with identifyAffectedUsers, generateReport
- [ ] Integrate with audit logging
- [ ] Add unit tests

### Task 26: Cross-Store Transactions (Saga) ⏳ PENDING
**Files**: `lib/src/coordination/saga_coordinator.dart`, `lib/src/coordination/compensating_action.dart`
**Implements**: REQ-029
**Depends On**: Task 16
**Complexity**: High

**Deliverables**:
- [ ] Create `SagaCoordinator` class for multi-store transactions
- [ ] Create `CompensatingAction<T>` for rollback operations
- [ ] Create `SagaStep` model with action and compensation
- [ ] Implement execute-or-compensate logic
- [ ] Add timeout handling for long-running sagas
- [ ] Add unit tests

### Task 27: Middleware/Interceptor API ⏳ PENDING
**Files**: `lib/src/interceptors/store_interceptor.dart`, `lib/src/interceptors/interceptor_chain.dart`
**Implements**: REQ-030
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `StoreInterceptor` abstract class
- [ ] Create `InterceptorChain` for ordered execution
- [ ] Create `InterceptorContext` with request/response data
- [ ] Implement request interception (pre-operation)
- [ ] Implement response interception (post-operation)
- [ ] Add `interceptors` to `StoreConfig`
- [ ] Create `LoggingInterceptor` example
- [ ] Add unit tests

### Task 28: Delta Sync Support ⏳ PENDING
**Files**: `lib/src/sync/delta_tracker.dart`, `lib/src/sync/field_change.dart`
**Implements**: REQ-031
**Depends On**: Task 1
**Complexity**: High

**Deliverables**:
- [ ] Create `DeltaTracker<T>` for field-level change tracking
- [ ] Create `FieldChange` model with field name, old value, new value
- [ ] Implement dirty field detection
- [ ] Modify sync flow to send only changed fields
- [ ] Implement merge logic for incoming deltas
- [ ] Add `deltaSync` option to `StoreConfig`
- [ ] Add unit tests

### Task 29: Background Sync Service ⏳ PENDING
**Package**: `nexus_store_flutter`
**Files**: `lib/src/background/background_sync_service.dart`
**Implements**: REQ-032
**Depends On**: Task 14
**Complexity**: High

**Deliverables**:
- [ ] Create `BackgroundSyncService` abstract interface
- [ ] Create `WorkManagerSyncService` for Android
- [ ] Create `BGTaskSchedulerService` for iOS
- [ ] Create `BackgroundSyncConfig` with intervals and constraints
- [ ] Implement platform detection and service selection
- [ ] Add integration tests

### Task 30: Production Reliability ⏳ PENDING
**Files**: `lib/src/reliability/circuit_breaker.dart`, `lib/src/reliability/health_check.dart`, `lib/src/reliability/degradation.dart`
**Implements**: REQ-036, REQ-037, REQ-038
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `CircuitBreaker` with closed/open/half-open states
- [ ] Create `CircuitBreakerConfig` with thresholds and cooldown
- [ ] Create `HealthCheck` service with component health aggregation
- [ ] Create `HealthStatus` model with overall and per-component status
- [ ] Create `DegradationMode` enum (readOnlyCache, failFast, staleData)
- [ ] Create `DegradationConfig` with mode selection
- [ ] Add `healthCheck()` method to `NexusStore`
- [ ] Add unit tests

### Task 31: Memory Management ⏳ PENDING
**Files**: `lib/src/cache/memory_manager.dart`, `lib/src/cache/pressure_handler.dart`
**Implements**: REQ-039
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `MemoryManager` for cache pressure handling
- [ ] Create `MemoryPressureHandler` interface
- [ ] Implement LRU eviction under pressure
- [ ] Create `MemoryConfig` with thresholds
- [ ] Implement pinned item protection
- [ ] Add memory metrics reporting
- [ ] Add unit tests

### Task 32: Lazy Field Loading ⏳ PENDING
**Files**: `lib/src/core/lazy_field.dart`, `lib/src/core/field_loader.dart`
**Implements**: REQ-040
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `@LazyLoad()` annotation
- [ ] Create `LazyField<T>` wrapper class
- [ ] Create `FieldLoader` service
- [ ] Implement on-demand field loading
- [ ] Implement batch field loading
- [ ] Add unit tests

### Task 33: Connection Pooling ⏳ PENDING
**Files**: `lib/src/backend/connection_pool.dart`, `lib/src/backend/pooled_connection.dart`
**Implements**: REQ-041
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create `ConnectionPool<C>` generic pool
- [ ] Create `PooledConnection<C>` wrapper
- [ ] Create `ConnectionPoolConfig` with size and timeouts
- [ ] Implement connection health checking
- [ ] Implement connection recycling
- [ ] Add unit tests

### Task 34: Built-in State Layer ⏳ PENDING
**Files**: `lib/src/state/nexus_registry.dart`, `lib/src/state/computed_store.dart`, `lib/src/state/nexus_state.dart`, `lib/src/state/selector.dart`
**Implements**: REQ-042, REQ-043, REQ-044, REQ-045
**Depends On**: Task 1, Task 3
**Complexity**: Medium

**Deliverables**:
- [ ] Create `NexusRegistry` singleton for store DI
  - [ ] `register<T>(store)`, `get<T>()`, `dispose<T>()`
  - [ ] Scoped registration support
  - [ ] `reset()` for testing
- [ ] Create `ComputedStore<T>` for derived state
  - [ ] Combine multiple store streams
  - [ ] distinctUntilChanged behavior
  - [ ] BehaviorSubject backing
- [ ] Create `NexusState<T>` for UI state
  - [ ] `value` getter/setter
  - [ ] `update()` transform method
  - [ ] `reset()` to initial value
  - [ ] BehaviorSubject backing
- [ ] Create `Selector<T, R>` for efficient derived values
  - [ ] Custom equality support
  - [ ] Memoization
- [ ] Add `select()` method to NexusStore
- [ ] Add unit tests

### Task 35: Riverpod Binding Package ⏳ PENDING
**Package**: `nexus_store_riverpod_binding`
**Implements**: REQ-046
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create package skeleton with Riverpod dependency
- [ ] Create `@riverpodNexusStore` annotation
- [ ] Create code generator for providers
  - [ ] Store provider
  - [ ] watchAll provider
  - [ ] watch(id) family provider
  - [ ] watchWithStatus providers
- [ ] Implement proper disposal integration
- [ ] Add example and documentation
- [ ] Add unit tests

### Task 36: Bloc Binding Package ⏳ PENDING
**Package**: `nexus_store_bloc_binding`
**Implements**: REQ-047
**Depends On**: Task 1
**Complexity**: Medium

**Deliverables**:
- [ ] Create package skeleton with Bloc dependency
- [ ] Create `NexusStoreCubit<T, ID>` base class
  - [ ] State: `NexusStoreState<T>` with data, loading, error
  - [ ] Auto-subscribe to store changes
  - [ ] CRUD method delegates
- [ ] Create `NexusStoreBloc<T, ID, E>` for event-driven
  - [ ] Load, Save, Delete events
  - [ ] Proper state transitions
- [ ] Implement disposal/cancellation
- [ ] Add example and documentation
- [ ] Add unit tests

### Task 37: Signals Binding Package ⏳ PENDING
**Package**: `nexus_store_signals_binding`
**Implements**: REQ-048
**Depends On**: Task 1
**Complexity**: Low

**Deliverables**:
- [ ] Create package skeleton with signals dependency
- [ ] Create `NexusStoreSignalExtension`
  - [ ] `store.toSignal()` → `Signal<List<T>>`
  - [ ] `store.toSignal(id)` → `Signal<T?>`
  - [ ] `store.toStatusSignal()` → `Signal<StoreResult<List<T>>>`
- [ ] Create `SignalSelector` utilities
- [ ] Implement proper cleanup/disposal
- [ ] Add example and documentation
- [ ] Add unit tests

---

## Open Questions

| Question | Status | Resolution |
|----------|--------|------------|
| Should backend adapters be separate packages? | ✅ RESOLVED | Yes, separate packages with `_adapter` suffix (e.g., `nexus_store_powersync_adapter`) |
| Support for Flutter widgets (StreamBuilder helpers)? | ✅ RESOLVED | Yes, via `nexus_store_flutter` package with `NexusStoreBuilder` and `NexusStoreProvider` widgets |
| Should we support custom serializers beyond JSON? | ✅ RESOLVED | JSON is primary; backends handle their own serialization needs |
| Can developers use multiple adapters at the same time? | ✅ RESOLVED | Single store = single backend by design. Use `CompositeBackend` for primary/fallback/cache patterns, or create separate store instances per entity type |
| How should database migrations be handled? | ✅ RESOLVED | Migrations remain backend-specific. nexus_store abstracts CRUD, not schema management. Each adapter documents how to set up migrations using native tooling. |

---

## Migration Strategy

**Principle**: nexus_store abstracts CRUD operations, not schema management. Migrations use each backend's native tooling.

### PowerSync Adapter
```dart
// Migrations happen server-side (PostgreSQL)
// PowerSync uses schema definition that maps to backend tables

final schema = Schema([
  Table('users', [
    Column.text('id'),
    Column.text('name'),
    Column.text('email'),
    Column.integer('created_at'),
  ]),
]);

// Backend is configured separately, adapter receives ready PowerSyncDatabase
final backend = PowerSyncBackend(
  database: powerSyncDb,
  tableName: 'users',
  // ...
);
```

### Brick Adapter
```dart
// Brick generates migrations via brick_sqlite
// Run: dart run build_runner build

// migrations/migration_001.dart (generated)
class Migration001 extends Migration {
  const Migration001() : super(version: 1, up: [
    InsertTable('users'),
    InsertColumn('id', Column.text),
    // ...
  ]);
}

// Adapter receives configured repository
final backend = BrickBackend(
  repository: MyRepository(),
  // Migrations already applied during repository init
);
```

### Drift Adapter
```dart
// Drift uses MigrationStrategy in database definition

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(users, users.avatarUrl);
      }
    },
  );
}

// Adapter receives configured database
final backend = DriftBackend(
  database: AppDatabase(),
  table: 'users',
);
```

### CRDT Adapter
```dart
// sqlite_crdt auto-manages CRDT columns (hlc, modified, is_deleted)
// User defines base schema, CRDT adds its columns

final crdtDb = await CrdtDatabase.open(
  'app.db',
  version: 1,
  onCreate: (db, version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT
      )
    ''');
    // CRDT adds: hlc, modified, is_deleted columns automatically
  },
);

final backend = CrdtBackend(database: crdtDb, tableName: 'users');
```

### Supabase Adapter
```dart
// Migrations happen server-side via Supabase CLI or dashboard
// supabase migration new create_users_table

// Adapter receives configured client, assumes tables exist
final backend = SupabaseBackend(
  client: supabaseClient,
  tableName: 'users',
);
```
