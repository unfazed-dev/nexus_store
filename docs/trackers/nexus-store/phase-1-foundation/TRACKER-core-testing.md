# TRACKER: Core Package Unit Tests

## Status: PENDING

## Overview

Comprehensive unit test coverage for the nexus_store core package. All core components are implemented but have zero test coverage.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - Testing Requirements section
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Setup
- [ ] Create test directory structure matching lib/src/
- [ ] Create mock backend (MockStoreBackend) for testing
- [ ] Create test fixtures (sample entities, configs)
- [ ] Configure test coverage reporting

### Core Module Tests
- [ ] `nexus_store_test.dart`
  - [ ] Lifecycle tests (initialize, dispose)
  - [ ] StateError when used before initialize
  - [ ] StateError when used after dispose
  - [ ] Get operation delegates to policy handler
  - [ ] GetAll operation with queries
  - [ ] Watch returns BehaviorSubject stream
  - [ ] WatchAll returns BehaviorSubject stream
  - [ ] Save operation delegates to policy handler
  - [ ] SaveAll batch operation
  - [ ] Delete operation
  - [ ] DeleteAll batch operation
  - [ ] Sync triggers backend sync
  - [ ] Cache invalidation (invalidate, invalidateAll)
  - [ ] Audit logging integration
  - [ ] GDPR service integration
  - [ ] Encryption integration

- [ ] `store_backend_test.dart`
  - [ ] StoreBackendDefaults mixin behavior
  - [ ] Default implementations return expected values

- [ ] `composite_backend_test.dart`
  - [ ] Primary/fallback/cache construction
  - [ ] CompositeReadStrategy.primaryFirst behavior
  - [ ] CompositeReadStrategy.cacheFirst behavior
  - [ ] CompositeReadStrategy.fastest behavior
  - [ ] CompositeWriteStrategy.primaryOnly behavior
  - [ ] CompositeWriteStrategy.all behavior
  - [ ] CompositeWriteStrategy.primaryAndCache behavior
  - [ ] Watch stream merging

### Config Module Tests
- [ ] `store_config_test.dart`
  - [ ] Default values are correct
  - [ ] StoreConfig.defaults() factory
  - [ ] StoreConfig.offlineFirst() factory
  - [ ] StoreConfig.onlineOnly() factory
  - [ ] StoreConfig.realtime() factory
  - [ ] Freezed copyWith works correctly

- [ ] `policies_test.dart`
  - [ ] FetchPolicy enum values (6 policies)
  - [ ] WritePolicy enum values (4 policies)
  - [ ] SyncStatus enum values (6 statuses)
  - [ ] ConflictResolution enum values (6 strategies)
  - [ ] SyncMode enum values (5 modes)

- [ ] `retry_config_test.dart`
  - [ ] Default exponential backoff values
  - [ ] RetryConfig.defaults() factory
  - [ ] Delay calculation for retries

### Policy Module Tests
- [ ] `fetch_policy_handler_test.dart`
  - [ ] cacheFirst - returns cache when available
  - [ ] cacheFirst - fetches from network when cache miss
  - [ ] networkFirst - fetches from network first
  - [ ] networkFirst - falls back to cache on network error
  - [ ] cacheAndNetwork - returns cache immediately
  - [ ] cacheAndNetwork - triggers background network fetch
  - [ ] cacheOnly - never calls network
  - [ ] networkOnly - never uses cache
  - [ ] staleWhileRevalidate - returns stale data while refreshing
  - [ ] Staleness tracking per entity

- [ ] `write_policy_handler_test.dart`
  - [ ] cacheAndNetwork - optimistic cache update
  - [ ] cacheAndNetwork - rollback on network failure
  - [ ] networkFirst - waits for network confirmation
  - [ ] cacheFirst - writes cache, queues network sync
  - [ ] cacheOnly - never syncs to network

### Query Module Tests
- [ ] `query_test.dart`
  - [ ] Empty query returns all items
  - [ ] where() with equality filter
  - [ ] where() with greaterThan operator
  - [ ] where() with lessThan operator
  - [ ] where() with greaterThanOrEqual operator
  - [ ] where() with lessThanOrEqual operator
  - [ ] where() with notEquals operator
  - [ ] where() with whereIn operator
  - [ ] where() with whereNotIn operator
  - [ ] where() with isNull operator
  - [ ] Multiple where() conditions (AND)
  - [ ] orderBy() ascending
  - [ ] orderBy() descending
  - [ ] Multiple orderBy() conditions
  - [ ] limit() restricts result count
  - [ ] offset() skips results
  - [ ] Combined limit + offset for pagination
  - [ ] Query immutability (returns new instance)

### Reactive Module Tests
- [ ] `reactive_store_mixin_test.dart`
  - [ ] ReactiveState emits initial value immediately
  - [ ] ReactiveState.value getter returns current
  - [ ] ReactiveState.value setter emits new value
  - [ ] ReactiveState.update() transforms value
  - [ ] ReactiveState.dispose() closes stream
  - [ ] ReactiveList add/remove/clear operations
  - [ ] ReactiveList stream emissions
  - [ ] ReactiveMap set/remove/clear operations
  - [ ] ReactiveMap stream emissions
  - [ ] ReactiveStoreMixin disposeReactiveStates()
  - [ ] Multiple subscribers receive same values (broadcast)

### Security Module Tests
- [ ] `encryption_service_test.dart`
  - [ ] Encrypts configured fields only
  - [ ] Decrypts configured fields only
  - [ ] Passes through non-encrypted fields unchanged
  - [ ] Handles null values in encrypted fields

- [ ] `field_encryptor_test.dart`
  - [ ] AES-256-GCM encryption roundtrip
  - [ ] ChaCha20-Poly1305 encryption roundtrip
  - [ ] Different keys produce different ciphertext
  - [ ] Tampered ciphertext throws exception
  - [ ] Nonce is unique per encryption
  - [ ] Version prefix in encrypted output

- [ ] `encryption_config_test.dart`
  - [ ] EncryptionConfig.none() factory
  - [ ] EncryptionConfig.sqlCipher() factory
  - [ ] EncryptionConfig.fieldLevel() factory
  - [ ] Freezed sealed class matching

### Compliance Module Tests
- [ ] `audit_service_test.dart`
  - [ ] Log entries are appended
  - [ ] Log entries cannot be modified (immutability)
  - [ ] Hash chain links entries correctly
  - [ ] Tampered entries detected via hash verification
  - [ ] Query by action type
  - [ ] Query by entity type
  - [ ] Query by actor
  - [ ] Query by time range
  - [ ] Actor provider integration

- [ ] `audit_log_entry_test.dart`
  - [ ] AuditAction enum values
  - [ ] ActorType enum values
  - [ ] AuditLogEntry serialization (toJson/fromJson)
  - [ ] Freezed equality

- [ ] `gdpr_service_test.dart`
  - [ ] processErasureRequest deletes user data
  - [ ] processErasureRequest anonymizes when retention required
  - [ ] processErasureRequest creates audit log
  - [ ] exportUserData returns JSON format
  - [ ] exportUserData returns CSV format
  - [ ] exportUserData includes checksum
  - [ ] getAccessReport returns user's data

### Error Module Tests
- [ ] `store_errors_test.dart`
  - [ ] NotFoundError construction and properties
  - [ ] NetworkError isRetryable = true
  - [ ] TimeoutError isRetryable = true
  - [ ] ValidationError with violations list
  - [ ] ConflictError properties
  - [ ] SyncError properties
  - [ ] AuthenticationError properties
  - [ ] AuthorizationError properties
  - [ ] TransactionError properties
  - [ ] StateError properties
  - [ ] CancellationError properties
  - [ ] QuotaExceededError properties
  - [ ] Sealed class exhaustive matching

## Files

**Test Directory Structure:**
```
packages/nexus_store/test/
├── src/
│   ├── core/
│   │   ├── nexus_store_test.dart
│   │   ├── store_backend_test.dart
│   │   └── composite_backend_test.dart
│   ├── config/
│   │   ├── store_config_test.dart
│   │   ├── policies_test.dart
│   │   └── retry_config_test.dart
│   ├── policy/
│   │   ├── fetch_policy_handler_test.dart
│   │   └── write_policy_handler_test.dart
│   ├── query/
│   │   └── query_test.dart
│   ├── reactive/
│   │   └── reactive_store_mixin_test.dart
│   ├── security/
│   │   ├── encryption_service_test.dart
│   │   ├── field_encryptor_test.dart
│   │   └── encryption_config_test.dart
│   ├── compliance/
│   │   ├── audit_service_test.dart
│   │   ├── audit_log_entry_test.dart
│   │   └── gdpr_service_test.dart
│   └── errors/
│       └── store_errors_test.dart
├── fixtures/
│   ├── mock_backend.dart
│   └── test_entities.dart
└── nexus_store_test.dart (barrel file)
```

**Source Files Being Tested:**
- `lib/src/core/nexus_store.dart`
- `lib/src/core/store_backend.dart`
- `lib/src/core/composite_backend.dart`
- `lib/src/config/store_config.dart`
- `lib/src/config/policies.dart`
- `lib/src/config/retry_config.dart`
- `lib/src/policy/fetch_policy_handler.dart`
- `lib/src/policy/write_policy_handler.dart`
- `lib/src/query/query.dart`
- `lib/src/reactive/reactive_store_mixin.dart`
- `lib/src/security/encryption_service.dart`
- `lib/src/security/field_encryptor.dart`
- `lib/src/security/encryption_config.dart`
- `lib/src/compliance/audit_service.dart`
- `lib/src/compliance/audit_log_entry.dart`
- `lib/src/compliance/gdpr_service.dart`
- `lib/src/errors/store_errors.dart`

## Dependencies

- `test: ^1.25.0` (already in pubspec)
- `mocktail: ^1.0.4` (already in pubspec)
- Core package implementation (complete)

## Notes

- Target: 80%+ code coverage
- Use mocktail for mocking StoreBackend
- Follow AAA pattern (Arrange, Act, Assert)
- Group related tests with `group()`
- Use descriptive test names: "should [expected behavior] when [condition]"
- Test edge cases: null values, empty lists, concurrent operations
