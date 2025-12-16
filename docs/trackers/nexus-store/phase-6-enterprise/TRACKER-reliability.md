# TRACKER: Production Reliability

## Status: PENDING

## Overview

Implement production reliability features including circuit breaker pattern, health check API, schema validation, and graceful degradation modes.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-035, REQ-036, REQ-037, REQ-038, Task 30
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Circuit Breaker (REQ-036)

#### Data Models
- [ ] Create `CircuitBreakerState` enum
  - [ ] `closed` - Normal operation
  - [ ] `open` - Failing fast
  - [ ] `halfOpen` - Testing recovery

- [ ] Create `CircuitBreakerConfig` class
  - [ ] `failureThreshold: int` - Failures before open (default 5)
  - [ ] `successThreshold: int` - Successes to close (default 2)
  - [ ] `cooldownPeriod: Duration` - Time before half-open
  - [ ] `timeout: Duration` - Request timeout

#### Implementation
- [ ] Create `CircuitBreaker` class
  - [ ] Track failure count
  - [ ] Manage state transitions
  - [ ] Emit state change events

- [ ] Implement state transitions
  - [ ] Closed → Open: failures >= threshold
  - [ ] Open → HalfOpen: cooldown elapsed
  - [ ] HalfOpen → Closed: success >= threshold
  - [ ] HalfOpen → Open: any failure

- [ ] Integrate with backend operations
  - [ ] Wrap remote calls with circuit breaker
  - [ ] Fail fast when open

### Health Check API (REQ-037)

#### Data Models
- [ ] Create `HealthStatus` class
  - [ ] `overall: HealthState`
  - [ ] `components: Map<String, ComponentHealth>`
  - [ ] `timestamp: DateTime`
  - [ ] `latency: Duration`

- [ ] Create `HealthState` enum
  - [ ] `healthy`, `degraded`, `unhealthy`

- [ ] Create `ComponentHealth` class
  - [ ] `name: String`
  - [ ] `state: HealthState`
  - [ ] `message: String?`
  - [ ] `lastCheck: DateTime`

#### Implementation
- [ ] Create `HealthCheckService` class
  - [ ] `Future<HealthStatus> check()` - Run all checks
  - [ ] `Stream<HealthStatus> get statusStream` - Live updates
  - [ ] Register custom health checks

- [ ] Implement component checks
  - [ ] Backend connectivity check
  - [ ] Cache status check
  - [ ] Sync status check
  - [ ] Memory usage check

- [ ] Add `healthCheck()` method to NexusStore
  - [ ] Aggregate component health
  - [ ] Return overall status

### Schema Validation (REQ-035)

#### Data Models
- [ ] Create `SchemaDefinition` class
  - [ ] `fields: Map<String, FieldSchema>`
  - [ ] `version: int`

- [ ] Create `FieldSchema` class
  - [ ] `type: Type`
  - [ ] `required: bool`
  - [ ] `nullable: bool`
  - [ ] `validators: List<Validator>`

- [ ] Create `SchemaValidationError` class
  - [ ] `field: String`
  - [ ] `expected: String`
  - [ ] `actual: String`
  - [ ] `message: String`

#### Implementation
- [ ] Create `SchemaValidator` class
  - [ ] `validate(T item, SchemaDefinition schema)`
  - [ ] Return list of validation errors

- [ ] Integrate with save operations
  - [ ] Validate before save
  - [ ] Configurable validation mode (strict, warn, skip)

### Graceful Degradation (REQ-038)

#### Data Models
- [ ] Create `DegradationMode` enum
  - [ ] `normal` - Full functionality
  - [ ] `readOnlyCache` - Reads work, writes queued
  - [ ] `staleData` - Return expired cache
  - [ ] `failFast` - Throw immediately

- [ ] Create `DegradationConfig` class
  - [ ] `mode: DegradationMode`
  - [ ] `staleDataMaxAge: Duration?`
  - [ ] `onDegradation: Function?` - Callback

#### Implementation
- [ ] Create `DegradationManager` class
  - [ ] Detect backend unavailability
  - [ ] Apply degradation mode
  - [ ] Track degradation state

- [ ] Implement each mode
  - [ ] readOnlyCache: queue writes, serve cache
  - [ ] staleData: ignore TTL when degraded
  - [ ] failFast: throw clear error

- [ ] Add `degradationStatus` stream to NexusStore
  - [ ] Emit current degradation state
  - [ ] Include reason for degradation

### StoreConfig Integration
- [ ] Add `circuitBreaker` to `StoreConfig`
- [ ] Add `healthCheck` to `StoreConfig`
- [ ] Add `schemaValidation` to `StoreConfig`
- [ ] Add `degradation` to `StoreConfig`

### Unit Tests
- [ ] `test/src/reliability/circuit_breaker_test.dart`
- [ ] `test/src/reliability/health_check_test.dart`
- [ ] `test/src/reliability/schema_validator_test.dart`
- [ ] `test/src/reliability/degradation_test.dart`

## Files

**Source Files:**
```
packages/nexus_store/lib/src/reliability/
├── circuit_breaker.dart       # CircuitBreaker class
├── circuit_breaker_config.dart
├── health_check.dart          # HealthCheckService
├── health_status.dart         # HealthStatus, ComponentHealth
├── schema_validator.dart      # SchemaValidator
├── schema_definition.dart     # SchemaDefinition, FieldSchema
├── degradation_manager.dart   # DegradationManager
└── degradation_config.dart    # DegradationConfig, DegradationMode
```

**Test Files:**
```
packages/nexus_store/test/src/reliability/
├── circuit_breaker_test.dart
├── health_check_test.dart
├── schema_validator_test.dart
└── degradation_manager_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22) - for metrics reporting

## API Preview

```dart
// Configure reliability features
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    // Circuit breaker
    circuitBreaker: CircuitBreakerConfig(
      failureThreshold: 5,
      successThreshold: 2,
      cooldownPeriod: Duration(seconds: 30),
    ),

    // Health checks
    healthCheck: HealthCheckConfig(
      checkInterval: Duration(minutes: 1),
      customChecks: [MyCustomHealthCheck()],
    ),

    // Schema validation
    schemaValidation: SchemaValidationConfig(
      schema: userSchema,
      mode: ValidationMode.strict,
    ),

    // Graceful degradation
    degradation: DegradationConfig(
      mode: DegradationMode.readOnlyCache,
      staleDataMaxAge: Duration(hours: 1),
      onDegradation: (reason) => showOfflineBanner(),
    ),
  ),
);

// Health check
final health = await store.healthCheck();
print('Overall: ${health.overall}'); // healthy, degraded, unhealthy
print('Backend: ${health.components['backend']?.state}');
print('Cache: ${health.components['cache']?.state}');

// Monitor health
store.healthStatusStream.listen((status) {
  if (status.overall == HealthState.unhealthy) {
    alertOps(status);
  }
});

// Circuit breaker events
store.circuitBreakerStream.listen((state) {
  if (state == CircuitBreakerState.open) {
    showMaintenanceMessage();
  }
});

// Degradation status
store.degradationStatusStream.listen((status) {
  if (status.mode != DegradationMode.normal) {
    showOfflineBanner(status.reason);
  }
});

// Schema validation errors
try {
  await store.save(invalidUser);
} on SchemaValidationError catch (e) {
  print('Invalid field: ${e.field}');
  print('Expected: ${e.expected}, Got: ${e.actual}');
}
```

## Notes

- Circuit breaker prevents cascade failures during outages
- Health checks should be lightweight (don't query entire database)
- Schema validation adds overhead - use appropriately
- Degradation mode should be clearly communicated to users
- Consider adding circuit breaker metrics to telemetry
- Health endpoints are useful for load balancer health checks
- Document recovery procedures for each degradation mode
