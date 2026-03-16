# TRACKER: NexusStore API Gap Closure

## Status: IN_PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| 1. RPC Support | ✅ Complete | 8 | ✅ 100.0% | `2b76534` | 2026-03-17 |
| 2. Text Search | ⏳ Pending | — | — | — | — |
| 3. JOIN / Relations | ⏳ Pending | — | — | — | — |
| 4. Storage API | ⏳ Pending | — | — | — | — |
| 5. Transaction Support | ⏳ Pending | — | — | — | — |

**Overall:** ███░░░░░░░░░░░░░ 20% complete
**Tests:** 8 passing | 0 failing

### Progress Log

**Current State (2026-03-17):**
- Working on: COMPLETE (Phase 1)
- Last completed: Phase 1 — RPC Support
- Blocked by: Nothing
- Next up: Phase 2 — Text Search

**Phase 1 Results (2026-03-17):**
- Added `rpc<R>()` method to `SupabaseBackend` with optional `fromJson` deserializer
- Added `rpc()` to `SupabaseClientWrapper` interface + `DefaultSupabaseClientWrapper` implementation
- 8 tests: 6 for backend rpc behavior, 2 for default wrapper delegation
- Harness: accepted, delta coverage 100.0% (7/7 lines)

## Overview

The raw Supabase to NexusStore migration audit identified 5 API gaps. While none block the current 7-repo migration, closing them expands NexusStore's coverage for future consumers and eliminates the need for raw Supabase escape hatches. The Storage API phase (Phase 4) is the most comprehensive — it introduces an entirely new domain to NexusStore.

**Related tracker:** [`TRACKER-transactions.md`](../nexus-store/phase-5-production/TRACKER-transactions.md) — Phase 5 of this tracker references/supersedes the existing core transaction support with Supabase-specific RPC-based transaction wrapping.

## Skills & Agents by Phase

| Phase | Skills | Agents |
|-------|--------|--------|
| 1. RPC Support | `/nexus-store` | `prior-art`, `test-scaffold`, `arch-check` |
| 2. Text Search | `/nexus-store` | `prior-art`, `test-scaffold`, `arch-check` |
| 3. JOIN / Relations | `/nexus-store` | `prior-art`, `test-scaffold`, `arch-check` |
| 4. Storage API | `/nexus-store` | `prior-art`, `test-scaffold`, `arch-check`, `api-surface` |
| 5. Transaction Support | `/nexus-store` | `prior-art`, `test-scaffold`, `arch-check` |
| **Every phase end** | `/commit-helper` | `verify-packages` |

---

## Phase 1: RPC Support

**Complexity:** LOW-MEDIUM
**Key Challenge:** New `rpc()` method + typed response handling

### Architecture Decision
- Add `Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params, T Function(dynamic)? fromJson})` to `SupabaseBackend`
- NOT on `StoreBackend` interface — RPC is Supabase-specific, not a generic backend concern
- When `fromJson` is null, returns raw `dynamic` response
- Delegates to `supabase.rpc('fn_name', params: {...})`

### Pre-Implementation Checklist
- [x] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart`
- [x] Read `packages/nexus_store_supabase_adapter/lib/nexus_store_supabase_adapter.dart` (barrel)
- [x] Run `prior-art` agent to check existing RPC patterns
- [x] Identify test fixtures and mocking patterns in supabase_adapter tests

### Tasks
#### RED: Write Failing Tests
- [x] Invoke `test-scaffold` agent for RPC test scaffolding
- [x] Write test: `rpc()` calls Supabase client with correct function name
- [x] Write test: `rpc()` passes params correctly
- [x] Write test: `rpc()` applies `fromJson` deserializer when provided
- [x] Write test: `rpc()` returns raw response when no `fromJson`
- [x] Write test: `rpc()` propagates Supabase errors as `StoreError`
- [x] Verify all new tests FAIL

#### GREEN: Implement
- [x] Add `rpc<R>()` method to `SupabaseBackend`
- [x] Handle typed response via generic `fromJson` callback
- [x] Wrap Supabase exceptions in `StoreError`
- [x] Export any new types from barrel file (none needed)
- [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- `SupabaseBackend.rpc()` calls PostgreSQL functions via Supabase client
- Typed responses via optional `fromJson` callback
- Errors wrapped in NexusStore error types
- No changes to core `StoreBackend` interface

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 8 (6 backend + 2 wrapper)
- [x] Tracker progress table updated
- [x] Delta coverage: ✅ 100.0% (7/7 lines) — `supabase_backend.dart` 5/5 100%, `supabase_client_wrapper.dart` 2/2 100%
- [x] Harness verification checkpoint passed
- [x] Commit: `feat(nexus_store_supabase_adapter): phase 1 — RPC support` (`2b76534`)

### Harness Verification Checkpoint
```bash
cd packages/nexus_store_supabase_adapter && dart test
melos run analyze
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
| File | Changes |
|------|---------|
| `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart` | Added `rpc<R>()` method |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_client_wrapper.dart` | Added `rpc()` to interface + default impl |
| `packages/nexus_store_supabase_adapter/test/supabase_backend_rpc_test.dart` | NEW — 8 RPC tests |

---

## Phase 2: Text Search / Full-Text Search in Query API

**Complexity:** MEDIUM
**Key Challenge:** New `FilterOperator.textSearch` + PostgREST `.textSearch()` translation

### Architecture Decision
- New `FilterOperator.textSearch` enum value in core `Query`
- New `TextSearchConfig` class: query string, config locale, type (plain/phrase/websearch)
- New `where()` parameter: `textSearch` accepting `TextSearchConfig`
- `SupabaseQueryTranslator` maps to PostgREST `.textSearch(column, query, config: ..., type: ...)`

### Pre-Implementation Checklist
- [ ] Phase 1 complete and committed
- [ ] Read `packages/nexus_store/lib/src/query/query.dart`
- [ ] Read `packages/nexus_store/lib/src/query/filter.dart` (or wherever `FilterOperator` lives)
- [ ] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart`
- [ ] Run `prior-art` agent to check existing filter/operator patterns
- [ ] Search for all exhaustive switches on `FilterOperator` and `hasLength` count assertions

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for text search test scaffolding
- [ ] Write test: `TextSearchConfig` construction with all parameters
- [ ] Write test: `FilterOperator.textSearch` exists in enum
- [ ] Write test: Query builder accepts `textSearch` parameter
- [ ] Write test: `SupabaseQueryTranslator` translates `textSearch` to PostgREST `.textSearch()`
- [ ] Write test: `textSearch` with `plain` type
- [ ] Write test: `textSearch` with `phrase` type
- [ ] Write test: `textSearch` with `websearch` type
- [ ] Write test: `textSearch` with custom locale config
- [ ] Update any `hasLength(N)` assertions for `FilterOperator` enum count
- [ ] Verify all new tests FAIL

#### GREEN: Implement
- [ ] Add `FilterOperator.textSearch` to enum
- [ ] Create `TextSearchConfig` class (query, config, type)
- [ ] Create `TextSearchType` enum (plain, phrase, websearch)
- [ ] Add `textSearch` parameter to query `where()` / filter builder
- [ ] Update `SupabaseQueryTranslator` to handle `textSearch` operator
- [ ] Export new types from both barrel files
- [ ] Update all exhaustive switches on `FilterOperator`
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- Core query API supports text search filter
- `SupabaseQueryTranslator` correctly maps to PostgREST `.textSearch()`
- All three search types supported (plain, phrase, websearch)
- Locale config passthrough works
- No breaking changes to existing query API

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~8-10)
- [ ] Tracker progress table updated
- [ ] Delta coverage >= 95% for changed files
  - _Per-file delta breakdown recorded on completion_
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 2 — text search support in Query API`

### Harness Verification Checkpoint
```bash
cd packages/nexus_store && dart test
cd packages/nexus_store_supabase_adapter && dart test
melos run analyze
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
| File | Changes |
|------|---------|
| `packages/nexus_store/lib/src/query/query.dart` | Add `textSearch` param, `TextSearchConfig` |
| `packages/nexus_store/lib/src/query/filter.dart` | Add `FilterOperator.textSearch` |
| `packages/nexus_store/lib/src/query/text_search_config.dart` | NEW — `TextSearchConfig`, `TextSearchType` |
| `packages/nexus_store/lib/nexus_store.dart` | Export new types |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart` | Add textSearch translation |
| `packages/nexus_store/test/src/query/text_search_test.dart` | NEW — core text search tests |
| `packages/nexus_store_supabase_adapter/test/src/supabase_query_translator_text_search_test.dart` | NEW — translator tests |

---

## Phase 3: Native JOIN / Relation Queries

**Complexity:** MEDIUM-HIGH
**Key Challenge:** New `QueryRelation` + PostgREST `select=*,relation(*)` embedding

### Architecture Decision
- New `QueryRelation` class in core — describes a related entity to include
- `Query.withRelation(String foreignTable, {String? foreignKey, Query? subQuery})`
- `SupabaseQueryTranslator` maps to PostgREST resource embedding: `select=*,foreign_table(*)`
- Returns raw JSON — consumer handles deserialization of nested objects
- Nested relations supported: `withRelation('posts', subQuery: Query().withRelation('comments'))`

### Pre-Implementation Checklist
- [ ] Phase 2 complete and committed
- [ ] Read `packages/nexus_store/lib/src/query/query.dart`
- [ ] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart`
- [ ] Run `prior-art` agent to check existing query composition patterns
- [ ] Research PostgREST resource embedding syntax for edge cases

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for relation query test scaffolding
- [ ] Write test: `QueryRelation` construction with table name
- [ ] Write test: `QueryRelation` with foreign key override
- [ ] Write test: `QueryRelation` with sub-query (nested relation)
- [ ] Write test: `Query.withRelation()` adds relation to query
- [ ] Write test: `Query.withRelation()` supports multiple relations
- [ ] Write test: `SupabaseQueryTranslator` generates `select=*,table(*)` for single relation
- [ ] Write test: `SupabaseQueryTranslator` generates correct select for multiple relations
- [ ] Write test: `SupabaseQueryTranslator` generates nested relation embedding
- [ ] Write test: `SupabaseQueryTranslator` applies sub-query filters to relation
- [ ] Verify all new tests FAIL

#### GREEN: Implement
- [ ] Create `QueryRelation` class (foreignTable, foreignKey, subQuery, columns)
- [ ] Add `withRelation()` method to `Query`
- [ ] Add `relations` getter to `Query`
- [ ] Update `SupabaseQueryTranslator` to build PostgREST `select` with embedded resources
- [ ] Handle nested relations recursively
- [ ] Export new types from barrel files
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- Core query API supports relation embedding via `withRelation()`
- Multiple relations per query supported
- Nested relations (relation within relation) supported
- `SupabaseQueryTranslator` generates correct PostgREST `select` syntax
- Raw JSON response — no opinionated deserialization of nested data
- No breaking changes to existing query API

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~9-12)
- [ ] Tracker progress table updated
- [ ] Delta coverage >= 95% for changed files
  - _Per-file delta breakdown recorded on completion_
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 3 — JOIN / relation query support`

### Harness Verification Checkpoint
```bash
cd packages/nexus_store && dart test
cd packages/nexus_store_supabase_adapter && dart test
melos run analyze
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
| File | Changes |
|------|---------|
| `packages/nexus_store/lib/src/query/query_relation.dart` | NEW — `QueryRelation` class |
| `packages/nexus_store/lib/src/query/query.dart` | Add `withRelation()`, `relations` getter |
| `packages/nexus_store/lib/nexus_store.dart` | Export `QueryRelation` |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart` | Add relation embedding translation |
| `packages/nexus_store/test/src/query/query_relation_test.dart` | NEW — core relation tests |
| `packages/nexus_store_supabase_adapter/test/src/supabase_query_translator_relation_test.dart` | NEW — translator tests |

---

## Phase 4: Storage API (Comprehensive)

**Complexity:** HIGH
**Key Challenge:** New `StorageBackend` interface + `SupabaseStorageAdapter` — buckets, upload, download, signed URLs, transforms

This is the largest phase — it introduces an entirely new domain to NexusStore. Split into sub-phases for tractability.

### Architecture Decision

**Core interface** (`nexus_store` core):
```dart
abstract interface class StorageBackend {
  // Bucket management
  Future<List<Bucket>> listBuckets();
  Future<Bucket> getBucket(String id);
  Future<Bucket> createBucket(String id, {BucketOptions? options});
  Future<void> updateBucket(String id, BucketOptions options);
  Future<void> deleteBucket(String id);
  Future<void> emptyBucket(String id);

  // File operations
  Future<StorageFile> upload(String bucket, String path, File file, {FileOptions? options});
  Future<Uint8List> download(String bucket, String path, {TransformOptions? transform});
  Future<StorageFile> update(String bucket, String path, File file, {FileOptions? options});
  Future<void> remove(String bucket, List<String> paths);
  Future<StorageFile> move(String bucket, String from, String to);
  Future<StorageFile> copy(String bucket, String from, String to);

  // URL generation
  Future<String> createSignedUrl(String bucket, String path, int expiresIn);
  Future<List<SignedUrl>> createSignedUrls(String bucket, List<String> paths, int expiresIn);
  String getPublicUrl(String bucket, String path, {TransformOptions? transform});

  // Listing
  Future<List<StorageFile>> list(String bucket, {String? path, SearchOptions? options});
}
```

**Supabase implementation** (`nexus_store_supabase_adapter`):
- `SupabaseStorageBackend implements StorageBackend`
- Delegates to `supabase.storage.from(bucket).*`
- Handles web/mobile file differences (`Uint8List` vs `dart:io File`)
- Image transforms via `TransformOptions` (width, height, quality, format, resize)

### Pre-Implementation Checklist
- [ ] Phase 3 complete and committed
- [ ] Read existing core interfaces for pattern consistency
- [ ] Run `prior-art` agent to check existing backend interface patterns
- [ ] Review Supabase Storage Dart client API for completeness

### Sub-Phase 4A: Core Types & Interface

#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for storage type test scaffolding
- [ ] Write test: `Bucket` model construction and equality
- [ ] Write test: `StorageFile` model construction and equality
- [ ] Write test: `FileOptions` defaults and overrides
- [ ] Write test: `TransformOptions` construction
- [ ] Write test: `SearchOptions` construction with defaults
- [ ] Write test: `SignedUrl` model construction
- [ ] Write test: `BucketOptions` construction
- [ ] Verify all new tests FAIL

#### GREEN: Implement Core Types
- [ ] Create `Bucket` — id, name, public, createdAt, updatedAt, fileSizeLimit, allowedMimeTypes
- [ ] Create `StorageFile` — id, name, bucket, createdAt, updatedAt, metadata, size
- [ ] Create `FileOptions` — contentType, cacheControl, upsert
- [ ] Create `TransformOptions` — width, height, quality, format, resize
- [ ] Create `SearchOptions` — limit, offset, sortBy, search prefix
- [ ] Create `SignedUrl` — path, signedUrl, error
- [ ] Create `BucketOptions` — public, fileSizeLimit, allowedMimeTypes
- [ ] Create `StorageBackend` abstract interface
- [ ] Export all types from barrel file
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Sub-Phase 4B: Supabase Storage Implementation

#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for Supabase storage test scaffolding
- [ ] Write test: `SupabaseStorageBackend.listBuckets()` delegates to client
- [ ] Write test: `SupabaseStorageBackend.getBucket()` delegates to client
- [ ] Write test: `SupabaseStorageBackend.createBucket()` with options
- [ ] Write test: `SupabaseStorageBackend.upload()` delegates correctly
- [ ] Write test: `SupabaseStorageBackend.download()` with transform options
- [ ] Write test: `SupabaseStorageBackend.remove()` with multiple paths
- [ ] Write test: `SupabaseStorageBackend.move()` delegates correctly
- [ ] Write test: `SupabaseStorageBackend.copy()` delegates correctly
- [ ] Write test: `SupabaseStorageBackend.createSignedUrl()` with expiry
- [ ] Write test: `SupabaseStorageBackend.createSignedUrls()` batch
- [ ] Write test: `SupabaseStorageBackend.getPublicUrl()` with transforms
- [ ] Write test: `SupabaseStorageBackend.list()` with search options
- [ ] Write test: error wrapping for storage exceptions
- [ ] Verify all new tests FAIL

#### GREEN: Implement
- [ ] Create `SupabaseStorageBackend implements StorageBackend`
- [ ] Implement bucket management methods (delegate to `supabase.storage.*`)
- [ ] Implement file operations (delegate to `supabase.storage.from(bucket).*`)
- [ ] Implement URL generation methods
- [ ] Implement listing with search options
- [ ] Handle `Uint8List` upload path for web compatibility
- [ ] Map `TransformOptions` to Supabase transform params
- [ ] Wrap Supabase storage exceptions in NexusStore error types
- [ ] Export from barrel file
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- `StorageBackend` interface in core covers bucket management, file ops, URLs, and listing
- `SupabaseStorageBackend` delegates all calls to Supabase Storage client
- Image transforms supported via `TransformOptions`
- All Supabase storage exceptions wrapped in NexusStore error types
- No dependency on `dart:io` in core interface (use `Uint8List` for cross-platform)
- No breaking changes to existing packages

### Post-Implementation Checklist
- [ ] All sub-phase tasks checked
- [ ] Tests passing (expected: ~20-25)
- [ ] Tracker progress table updated
- [ ] Delta coverage >= 95% for changed files
  - _Per-file delta breakdown recorded on completion_
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat: phase 4 — Storage API with Supabase implementation`

### Harness Verification Checkpoint
```bash
cd packages/nexus_store && dart test
cd packages/nexus_store_supabase_adapter && dart test
melos run analyze
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
| File | Changes |
|------|---------|
| `packages/nexus_store/lib/src/storage/storage_backend.dart` | NEW — `StorageBackend` interface |
| `packages/nexus_store/lib/src/storage/bucket.dart` | NEW — `Bucket`, `BucketOptions` |
| `packages/nexus_store/lib/src/storage/storage_file.dart` | NEW — `StorageFile` |
| `packages/nexus_store/lib/src/storage/file_options.dart` | NEW — `FileOptions` |
| `packages/nexus_store/lib/src/storage/transform_options.dart` | NEW — `TransformOptions` |
| `packages/nexus_store/lib/src/storage/search_options.dart` | NEW — `SearchOptions` |
| `packages/nexus_store/lib/src/storage/signed_url.dart` | NEW — `SignedUrl` |
| `packages/nexus_store/lib/nexus_store.dart` | Export storage types |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_storage_backend.dart` | NEW — `SupabaseStorageBackend` |
| `packages/nexus_store_supabase_adapter/lib/nexus_store_supabase_adapter.dart` | Export storage backend |
| `packages/nexus_store/test/src/storage/` | NEW — core storage type tests |
| `packages/nexus_store_supabase_adapter/test/src/supabase_storage_backend_test.dart` | NEW — implementation tests |

---

## Phase 5: Transaction Support (Supabase RPC-based)

**Complexity:** MEDIUM
**Key Challenge:** RPC-based transaction wrapper via `BEGIN`/`COMMIT`/`ROLLBACK` in stored procedures

### Architecture Decision
- Core `StoreBackend` already has `supportsTransactions = false` and stub methods from `StoreBackendDefaults` (see [TRACKER-transactions.md](../nexus-store/phase-5-production/TRACKER-transactions.md))
- This phase implements Supabase-specific transaction support via RPC wrapper
- Create a Supabase stored procedure that accepts an array of operations and executes within `BEGIN`/`COMMIT`
- `SupabaseBackend.runInTransaction()` batches operations into a single RPC call
- Rollback on any failure within the procedure
- `supportsTransactions` returns `true` after implementation
- **Alternative documented:** True client-side transactions are not supported by PostgREST — RPC-based approach is the recommended pattern

### Pre-Implementation Checklist
- [ ] Phase 4 complete and committed
- [ ] Read `packages/nexus_store/lib/src/core/store_backend.dart` (transaction interface)
- [ ] Read `packages/nexus_store/lib/src/transaction/` (existing transaction support)
- [ ] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart`
- [ ] Run `prior-art` agent to check existing transaction patterns
- [ ] Review Phase 1 RPC implementation (dependency)

### Tasks
#### RED: Write Failing Tests
- [ ] Invoke `test-scaffold` agent for transaction test scaffolding
- [ ] Write test: `supportsTransactions` returns `true`
- [ ] Write test: `runInTransaction()` batches multiple save operations into single RPC call
- [ ] Write test: `runInTransaction()` rolls back all operations on failure
- [ ] Write test: `runInTransaction()` returns callback result on success
- [ ] Write test: `beginTransaction()` / `commitTransaction()` / `rollbackTransaction()` lifecycle
- [ ] Write test: transaction timeout respected
- [ ] Write test: error within transaction wraps in `TransactionError`
- [ ] Verify all new tests FAIL

#### GREEN: Implement
- [ ] Override `supportsTransactions` to return `true` in `SupabaseBackend`
- [ ] Implement `runInTransaction()` — batch operations via RPC call (uses Phase 1 `rpc()`)
- [ ] Implement `beginTransaction()` / `commitTransaction()` / `rollbackTransaction()`
- [ ] Create SQL migration for transaction wrapper stored procedure
- [ ] Handle transaction timeout
- [ ] Wrap errors in `TransactionError` with `wasRolledBack` flag
- [ ] Document PostgREST transaction limitations in code comments
- [ ] Verify all tests PASS

#### REFACTOR
- [ ] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- `SupabaseBackend.supportsTransactions` returns `true`
- `runInTransaction()` executes multiple operations atomically via RPC
- Failures trigger automatic rollback
- `TransactionError` includes rollback status
- PostgREST limitations documented
- Depends on Phase 1 RPC support

### Post-Implementation Checklist
- [ ] All tasks checked
- [ ] Tests passing (expected: ~7-10)
- [ ] Tracker progress table updated
- [ ] Delta coverage >= 95% for changed files
  - _Per-file delta breakdown recorded on completion_
- [ ] Harness verification checkpoint passed (below)
- [ ] Commit: `feat(nexus_store_supabase_adapter): phase 5 — RPC-based transaction support`

### Harness Verification Checkpoint
```bash
cd packages/nexus_store_supabase_adapter && dart test
melos run analyze
bash .claude/orchestrators/pre-commit-check.sh
```

### Critical Files
| File | Changes |
|------|---------|
| `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart` | Override transaction methods, set `supportsTransactions = true` |
| `packages/nexus_store_supabase_adapter/test/src/supabase_backend_transaction_test.dart` | NEW — transaction tests |

---

## Completion Checklist
- [ ] All phases ✅ in progress table
- [ ] Status updated to `COMPLETE`
- [ ] Move tracker to `docs/trackers/completed/infrastructure/`
- [ ] Final History entry added
- [ ] Run full test suite: `melos run test:dart`
- [ ] Run full analysis: `melos run analyze`

## Files

### Files to Create
| File | Purpose |
|------|---------|
| `packages/nexus_store/lib/src/query/text_search_config.dart` | `TextSearchConfig`, `TextSearchType` |
| `packages/nexus_store/lib/src/query/query_relation.dart` | `QueryRelation` class |
| `packages/nexus_store/lib/src/storage/storage_backend.dart` | `StorageBackend` interface |
| `packages/nexus_store/lib/src/storage/bucket.dart` | `Bucket`, `BucketOptions` models |
| `packages/nexus_store/lib/src/storage/storage_file.dart` | `StorageFile` model |
| `packages/nexus_store/lib/src/storage/file_options.dart` | `FileOptions` model |
| `packages/nexus_store/lib/src/storage/transform_options.dart` | `TransformOptions` model |
| `packages/nexus_store/lib/src/storage/search_options.dart` | `SearchOptions` model |
| `packages/nexus_store/lib/src/storage/signed_url.dart` | `SignedUrl` model |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_storage_backend.dart` | `SupabaseStorageBackend` implementation |

### Files to Modify
| File | Changes |
|------|---------|
| `packages/nexus_store/lib/src/query/query.dart` | Add `textSearch` param, `withRelation()` method |
| `packages/nexus_store/lib/src/query/filter.dart` | Add `FilterOperator.textSearch` |
| `packages/nexus_store/lib/nexus_store.dart` | Export new types (text search, relations, storage) |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart` | Add `rpc()`, override transaction methods |
| `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart` | Add textSearch + relation translation |
| `packages/nexus_store_supabase_adapter/lib/nexus_store_supabase_adapter.dart` | Export new types |

## Supabase API References

- **RPC**: `supabase.rpc('fn_name', params: {...})` — calls PostgreSQL functions
- **Text Search**: PostgREST `.textSearch(column, query, config: 'english', type: TextSearchType.plain|phrase|websearch)`
- **Storage**: `supabase.storage.from(bucket).upload/download/createSignedUrl/getPublicUrl/list/remove/move/copy`
- **Transforms**: `supabase.storage.from(bucket).getPublicUrl(path, transform: TransformOptions(width: 200, height: 200))`
- **Transactions**: Not supported by PostgREST client — must use RPC wrapping a PostgreSQL function with `BEGIN/COMMIT`

## History

| Date | Action | Details |
|------|--------|---------|
| 2026-03-17 | Created | Initial tracker — 5 phases for API gap closure |
| 2026-03-17 | Phase 1 ✅ | RPC support — 8 tests, 100% delta coverage, `2b76534` + `334bd7d` |
