# TRACKER: NexusStore API Gap Closure

## Status: IN_PROGRESS

## Progress

### Overview
| Phase | Status | Tests | Coverage | Committed | Last Updated |
|-------|--------|-------|----------|-----------|--------------|
| 1. RPC Support | ✅ Complete | 8 | ✅ 100.0% | `2b76534` | 2026-03-17 |
| 2. Text Search | ✅ Complete | 22 | ✅ 100.0% | `3379523` | 2026-03-17 |
| 3. JOIN / Relations | ✅ Complete | 30 | ✅ 100.0% | `aef7c7d` | 2026-03-17 |
| 4. Storage API | ✅ Complete | 94 | ⚠️ 88.1% / 82.7% | `46fbe84` | 2026-03-17 |
| 5. Transaction Support | ⏳ Pending | — | — | — | — |

**Overall:** ████████████░░░░ 80% complete
**Tests:** 154 passing | 0 failing

### Progress Log

**Current State (2026-03-17):**
- Working on: COMPLETE (Phase 4)
- Last completed: Phase 4 — Storage API
- Blocked by: Nothing
- Next up: Phase 5 — Transaction Support

**Phase 4 Results (2026-03-17):**
- Sub-Phase 4A: Core types & interface — `Bucket`, `BucketOptions`, `StorageFile`, `FileOptions`, `TransformOptions`, `SearchOptions`, `SignedUrl`, `SortBy`, `ImageFormat`, `ResizeMode`, `SortOrder` enums, `StorageBackend` abstract interface
- Sub-Phase 4B: `SupabaseStorageBackend` + `SupabaseStorageWrapper` / `DefaultSupabaseStorageWrapper` — full delegation, type mapping, error wrapping
- 94 tests: 53 core (7 model type files + interface mock) + 25 Supabase backend + 16 wrapper delegation
- Harness: accepted, package coverage passes 95% threshold
- Delta coverage: `nexus_store` 88.1% (141/160) — `bucket.dart` 49/53 92.5%, `storage_file.dart` 39/41 95.1%, `file_options.dart` 11/13 84.6%, `signed_url.dart` 11/13 84.6%, `search_options.dart` 18/23 78.3%, `transform_options.dart` 13/17 76.5%; `supabase_adapter` 82.7% (134/162) — `supabase_storage_backend.dart` 101/129 78.3%, `supabase_storage_wrapper.dart` 33/33 100%
- Note: `ImageFormat.avif`/`webp` throw `UnsupportedError` — `storage_client` v2.4.1 only supports `RequestImageFormat.origin`

**Phase 3 Results (2026-03-17):**
- Added `QueryRelation` class in core (foreignTable, foreignKey, columns, subQuery)
- Added `Query.withRelation()` method with immutable builder pattern
- Added `relations` getter, updated `isEmpty`, `copyWith`, `==`, `hashCode`, `toString`
- Added `SupabaseQueryTranslator.buildSelectString()` for PostgREST resource embedding
- Supports: single/multiple relations, nested relations, column selection, FK hints
- 30 tests: 21 core (QueryRelation + Query.withRelation) + 9 Supabase translator
- Harness: accepted, delta coverage 100.0% — `nexus_store` 35/35, `supabase_adapter` 21/21

**Phase 2 Results (2026-03-17):**
- Added `FilterOperator.textSearch` enum value + `TextSearchConfig` + `TextSearchType` in core
- Added `textSearch` parameter to `Query.where()`
- Updated `SupabaseQueryTranslator` to map to PostgREST `.textSearch()` with type mapping
- Updated 12 exhaustive switches across 7 packages (adapters throw `UnsupportedError`)
- Updated `hasLength(18)` to `hasLength(19)` in query_test.dart
- 22 tests: 17 core (types, evaluator, SQL translator, query builder) + 5 Supabase translator
- Harness: accepted, delta coverage 100.0% — `nexus_store` 22/22, `supabase_adapter` 11/11

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
- [x] Phase 1 complete and committed
- [x] Read `packages/nexus_store/lib/src/query/query.dart`
- [x] Read `packages/nexus_store/lib/src/query/filter.dart` (FilterOperator in query.dart)
- [x] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart`
- [x] Run `prior-art` agent to check existing filter/operator patterns
- [x] Search for all exhaustive switches on `FilterOperator` and `hasLength` count assertions

### Tasks
#### RED: Write Failing Tests
- [x] Invoke `test-scaffold` agent for text search test scaffolding
- [x] Write test: `TextSearchConfig` construction with all parameters
- [x] Write test: `FilterOperator.textSearch` exists in enum
- [x] Write test: Query builder accepts `textSearch` parameter
- [x] Write test: `SupabaseQueryTranslator` translates `textSearch` to PostgREST `.textSearch()`
- [x] Write test: `textSearch` with `plain` type
- [x] Write test: `textSearch` with `phrase` type
- [x] Write test: `textSearch` with `websearch` type
- [x] Write test: `textSearch` with custom locale config
- [x] Update `hasLength(18)` to `hasLength(19)` in query_test.dart
- [x] Verify all new tests FAIL

#### GREEN: Implement
- [x] Add `FilterOperator.textSearch` to enum
- [x] Create `TextSearchConfig` class (query, config, type)
- [x] Create `TextSearchType` enum (plain, phrase, websearch)
- [x] Add `textSearch` parameter to query `where()` / filter builder
- [x] Update `SupabaseQueryTranslator` to handle `textSearch` operator
- [x] Export new types from both barrel files
- [x] Update all 12 exhaustive switches on `FilterOperator` across 7 packages
- [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- Core query API supports text search filter
- `SupabaseQueryTranslator` correctly maps to PostgREST `.textSearch()`
- All three search types supported (plain, phrase, websearch)
- Locale config passthrough works
- No breaking changes to existing query API

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 22 (17 core + 5 Supabase translator)
- [x] Tracker progress table updated
- [x] Delta coverage: ✅ 100.0% (33/33 lines) — `nexus_store`: `query.dart` 2/2 100%, `text_search_config.dart` 11/11 100%, `query_evaluator.dart` 6/6 100%, `expression.dart` 1/1 100%, `query_translator.dart` 2/2 100%; `supabase_adapter`: `supabase_query_translator.dart` 11/11 100%
- [x] Harness verification checkpoint passed
- [x] Commit: `feat: phase 2 — text search support in Query API` (`3379523`)

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
- [x] Phase 2 complete and committed
- [x] Read `packages/nexus_store/lib/src/query/query.dart`
- [x] Read `packages/nexus_store_supabase_adapter/lib/src/supabase_query_translator.dart`
- [x] Run `prior-art` agent to check existing query composition patterns
- [x] Research PostgREST resource embedding syntax for edge cases

### Tasks
#### RED: Write Failing Tests
- [x] Invoke `test-scaffold` agent for relation query test scaffolding
- [x] Write test: `QueryRelation` construction with table name
- [x] Write test: `QueryRelation` with foreign key override
- [x] Write test: `QueryRelation` with sub-query (nested relation)
- [x] Write test: `Query.withRelation()` adds relation to query
- [x] Write test: `Query.withRelation()` supports multiple relations
- [x] Write test: `SupabaseQueryTranslator` generates `select=*,table(*)` for single relation
- [x] Write test: `SupabaseQueryTranslator` generates correct select for multiple relations
- [x] Write test: `SupabaseQueryTranslator` generates nested relation embedding
- [x] Write test: `SupabaseQueryTranslator` applies sub-query filters to relation
- [x] Verify all new tests FAIL

#### GREEN: Implement
- [x] Create `QueryRelation` class (foreignTable, foreignKey, subQuery, columns)
- [x] Add `withRelation()` method to `Query`
- [x] Add `relations` getter to `Query`
- [x] Update `SupabaseQueryTranslator` to build PostgREST `select` with embedded resources
- [x] Handle nested relations recursively
- [x] Export new types from barrel files
- [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- Core query API supports relation embedding via `withRelation()`
- Multiple relations per query supported
- Nested relations (relation within relation) supported
- `SupabaseQueryTranslator` generates correct PostgREST `select` syntax
- Raw JSON response — no opinionated deserialization of nested data
- No breaking changes to existing query API

### Post-Implementation Checklist
- [x] All tasks checked
- [x] Tests passing: 30 (21 core + 9 Supabase translator)
- [x] Tracker progress table updated
- [x] Delta coverage: ✅ 100.0% (56/56 lines) — `nexus_store`: `query_relation.dart` 16/16 100%, `query.dart` 19/19 100%; `supabase_adapter`: `supabase_query_translator.dart` 21/21 100%
- [x] Harness verification checkpoint passed
- [x] Commit: `feat: phase 3 — JOIN / relation query support` (`aef7c7d`)

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
- [x] Phase 3 complete and committed
- [x] Read existing core interfaces for pattern consistency
- [x] Run `prior-art` agent to check existing backend interface patterns
- [x] Review Supabase Storage Dart client API for completeness

### Sub-Phase 4A: Core Types & Interface

#### RED: Write Failing Tests
- [x] Invoke `test-scaffold` agent for storage type test scaffolding
- [x] Write test: `Bucket` model construction and equality
- [x] Write test: `StorageFile` model construction and equality
- [x] Write test: `FileOptions` defaults and overrides
- [x] Write test: `TransformOptions` construction
- [x] Write test: `SearchOptions` construction with defaults
- [x] Write test: `SignedUrl` model construction
- [x] Write test: `BucketOptions` construction
- [x] Verify all new tests FAIL

#### GREEN: Implement Core Types
- [x] Create `Bucket` — id, name, public, createdAt, updatedAt, fileSizeLimit, allowedMimeTypes
- [x] Create `StorageFile` — id, name, bucket, createdAt, updatedAt, metadata, size
- [x] Create `FileOptions` — contentType, cacheControl, upsert
- [x] Create `TransformOptions` — width, height, quality, format, resize
- [x] Create `SearchOptions` — limit, offset, sortBy, search prefix
- [x] Create `SignedUrl` — path, signedUrl, error
- [x] Create `BucketOptions` — public, fileSizeLimit, allowedMimeTypes
- [x] Create `StorageBackend` abstract interface
- [x] Export all types from barrel file
- [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Sub-Phase 4B: Supabase Storage Implementation

#### RED: Write Failing Tests
- [x] Invoke `test-scaffold` agent for Supabase storage test scaffolding
- [x] Write test: `SupabaseStorageBackend.listBuckets()` delegates to client
- [x] Write test: `SupabaseStorageBackend.getBucket()` delegates to client
- [x] Write test: `SupabaseStorageBackend.createBucket()` with options
- [x] Write test: `SupabaseStorageBackend.upload()` delegates correctly
- [x] Write test: `SupabaseStorageBackend.download()` with transform options
- [x] Write test: `SupabaseStorageBackend.remove()` with multiple paths
- [x] Write test: `SupabaseStorageBackend.move()` delegates correctly
- [x] Write test: `SupabaseStorageBackend.copy()` delegates correctly
- [x] Write test: `SupabaseStorageBackend.createSignedUrl()` with expiry
- [x] Write test: `SupabaseStorageBackend.createSignedUrls()` batch
- [x] Write test: `SupabaseStorageBackend.getPublicUrl()` with transforms
- [x] Write test: `SupabaseStorageBackend.list()` with search options
- [x] Write test: error wrapping for storage exceptions
- [x] Verify all new tests FAIL

#### GREEN: Implement
- [x] Create `SupabaseStorageBackend implements StorageBackend`
- [x] Implement bucket management methods (delegate to `supabase.storage.*`)
- [x] Implement file operations (delegate to `supabase.storage.from(bucket).*`)
- [x] Implement URL generation methods
- [x] Implement listing with search options
- [x] Handle `Uint8List` upload path for web compatibility
- [x] Map `TransformOptions` to Supabase transform params
- [x] Wrap Supabase storage exceptions in NexusStore error types
- [x] Export from barrel file
- [x] Verify all tests PASS

#### REFACTOR
- [x] Clean up, run `smart-test-run.py` — all green

### Acceptance Criteria
- `StorageBackend` interface in core covers bucket management, file ops, URLs, and listing
- `SupabaseStorageBackend` delegates all calls to Supabase Storage client
- Image transforms supported via `TransformOptions`
- All Supabase storage exceptions wrapped in NexusStore error types
- No dependency on `dart:io` in core interface (use `Uint8List` for cross-platform)
- No breaking changes to existing packages

### Post-Implementation Checklist
- [x] All sub-phase tasks checked
- [x] Tests passing: 94 (53 core + 25 Supabase backend + 16 wrapper delegation)
- [x] Tracker progress table updated
- [x] Delta coverage: ⚠️ `nexus_store` 88.1% (141/160) — `bucket.dart` 49/53 92.5%, `storage_file.dart` 39/41 95.1%, `file_options.dart` 11/13 84.6%, `signed_url.dart` 11/13 84.6%, `search_options.dart` 18/23 78.3%, `transform_options.dart` 13/17 76.5%; `supabase_adapter` 82.7% (134/162) — `supabase_storage_backend.dart` 101/129 78.3%, `supabase_storage_wrapper.dart` 33/33 100%. Package-level coverage: `nexus_store` 97.96%, `supabase_adapter` 96.53% — both pass 95% threshold.
- [x] Harness verification checkpoint passed
- [x] Commit: `feat: phase 4 — Storage API with Supabase implementation` (`46fbe84`)

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
| `packages/nexus_store_supabase_adapter/lib/src/supabase_storage_wrapper.dart` | NEW — `SupabaseStorageWrapper`, `DefaultSupabaseStorageWrapper` |
| `packages/nexus_store_supabase_adapter/lib/nexus_store_supabase_adapter.dart` | Export storage backend + wrapper |
| `packages/nexus_store/test/src/storage/` | NEW — 7 core storage type test files (53 tests) |
| `packages/nexus_store_supabase_adapter/test/src/supabase_storage_backend_test.dart` | NEW — 25 backend tests |
| `packages/nexus_store_supabase_adapter/test/src/supabase_storage_wrapper_test.dart` | NEW — 16 wrapper delegation tests |

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
| 2026-03-17 | Phase 2 ✅ | Text search — 22 tests, 100% delta coverage, `3379523` + `0c36873` + `dd641f9` |
| 2026-03-17 | Phase 3 ✅ | JOIN / relations — 30 tests, 100% delta coverage, `aef7c7d` |
| 2026-03-17 | Phase 4 ✅ | Storage API — 94 tests, package coverage 97.96%/96.53%, `46fbe84` |
