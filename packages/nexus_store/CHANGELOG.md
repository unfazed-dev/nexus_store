# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store core package
- Unified reactive data store abstraction with `NexusStore<T, ID>` class
- `StoreBackend` interface for pluggable storage backends
- Policy-based data fetching (`FetchPolicy`: cacheFirst, networkFirst, cacheAndNetwork, networkOnly, cacheOnly)
- Policy-based data writing (`WritePolicy`: cacheFirst, networkFirst, cacheAndNetwork, networkOnly)
- Fluent query builder with type-safe field expressions
- RxDart reactive streams integration with `BehaviorSubject` support
- Cursor-based pagination with `PaginationController`
- Transaction support with commit/rollback semantics
- Saga coordination for distributed transactions
- Interceptor chain for request/response processing
- Store interceptors: caching, logging, validation, timing
- HIPAA-compliant audit logging with `AuditService`
- GDPR compliance with `GDPRService` (data erasure, portability)
- Consent management with `ConsentService`
- Data breach monitoring with `BreachService`
- Field-level AES-256-GCM encryption
- Key derivation with PBKDF2
- Circuit breaker pattern for fault tolerance
- Health check service for backend monitoring
- Connection pooling for backend connections
- Delta sync for efficient data synchronization
- Conflict resolution strategies
- Memory management with LRU eviction
- Telemetry and metrics reporting
- Lazy field loading with annotations

### Dependencies
- rxdart: ^0.28.0
- freezed_annotation: ^3.1.0
- json_annotation: ^4.9.0
- meta: ^1.16.0
- logging: ^1.3.0
- collection: ^1.19.0
- cryptography: ^2.7.0
- crypto: ^3.0.5
- uuid: ^4.5.1
