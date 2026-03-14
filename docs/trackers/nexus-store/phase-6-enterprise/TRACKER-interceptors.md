# TRACKER: Middleware/Interceptor API

## Status: COMPLETE

## Overview

Implement a middleware/interceptor system for NexusStore that allows pre/post hooks on all operations for logging, transformation, validation, and caching.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-030, Task 27
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `StoreOperation` enum
  - [x] `get`, `getAll`, `save`, `saveAll`, `delete`, `deleteAll`
  - [x] `watch`, `watchAll`, `sync`

- [x] Create `InterceptorContext<T, R>` class
  - [x] `operation: StoreOperation`
  - [x] `request: T` - Input data (ID, item, query)
  - [x] `response: R?` - Output data (set by interceptor or operation)
  - [x] `metadata: Map<String, dynamic>` - Custom data passing
  - [x] `timestamp: DateTime`
  - [x] `withResponse()` - Create context with response set

- [x] Create `InterceptorResult<R>` sealed class
  - [x] `Continue(R? modifiedResponse)` - Proceed to next
  - [x] `ShortCircuit(R response)` - Return immediately
  - [x] `Error(Object error, StackTrace? stackTrace)` - Throw error

### Core Implementation
- [x] Create `StoreInterceptor` abstract class
  - [x] `Future<InterceptorResult<R>> onRequest<T, R>(InterceptorContext<T, R> ctx)`
  - [x] `Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx)`
  - [x] `Future<void> onError<T, R>(InterceptorContext<T, R> ctx, Object error, StackTrace stackTrace)`
  - [x] `Set<StoreOperation> get operations` - Which ops to intercept

- [x] Create `InterceptorChain` class
  - [x] Constructor with immutable interceptors list
  - [x] `execute<T, R>()` wraps operations with interceptor chain
  - [x] Operation filtering based on interceptor `operations` getter

- [x] Implement ordered execution
  - [x] Request interceptors run in add order
  - [x] Response interceptors run in reverse order
  - [x] Error interceptors run in reverse order

### StoreConfig Integration
- [x] Add `interceptors` to `StoreConfig`
  - [x] `List<StoreInterceptor>` ordered list
  - [x] Default empty list

- [x] Update NexusStore to use interceptor chain
  - [x] Create `InterceptorChain` from config
  - [x] Wrap all operations with interceptor chain (get, getAll, save, saveAll, delete, deleteAll, sync)

### Built-in Interceptors
- [x] Create `LoggingInterceptor`
  - [x] Log operation, duration, success/failure
  - [x] Configurable log level
  - [x] Configurable logging flags (logRequests, logResponses, logErrors)

- [x] Create `TimingInterceptor`
  - [x] Measure operation duration
  - [x] Report to MetricsReporter
  - [x] Maps StoreOperation to OperationType

- [x] Create `ValidationInterceptor`
  - [x] Validate items before save/saveAll
  - [x] Custom validation function
  - [x] Custom error factory

- [x] Create `CachingInterceptor`
  - [x] In-memory request deduplication
  - [x] Custom cache key generator
  - [x] Concurrent request coalescing via Completer

### Unit Tests
- [x] `test/src/interceptors/store_operation_test.dart`
- [x] `test/src/interceptors/interceptor_context_test.dart`
- [x] `test/src/interceptors/interceptor_result_test.dart`
- [x] `test/src/interceptors/store_interceptor_test.dart`
- [x] `test/src/interceptors/interceptor_chain_test.dart`
  - [x] Interceptors run in correct order
  - [x] Short-circuit stops propagation
  - [x] Error handling works
  - [x] Metadata passes between interceptors
- [x] `test/src/interceptors/logging_interceptor_test.dart`
- [x] `test/src/interceptors/timing_interceptor_test.dart`
- [x] `test/src/interceptors/validation_interceptor_test.dart`
- [x] `test/src/interceptors/caching_interceptor_test.dart`

## Files

**Source Files:**
```
packages/nexus_store/lib/src/interceptors/
├── caching_interceptor.dart      # CachingInterceptor (request deduplication)
├── interceptor_chain.dart        # InterceptorChain executor
├── interceptor_context.dart      # InterceptorContext model
├── interceptor_result.dart       # InterceptorResult sealed class
├── logging_interceptor.dart      # LoggingInterceptor
├── store_interceptor.dart        # StoreInterceptor abstract class
├── store_operation.dart          # StoreOperation enum
├── timing_interceptor.dart       # TimingInterceptor
└── validation_interceptor.dart   # ValidationInterceptor
```

**Test Files:**
```
packages/nexus_store/test/src/interceptors/
├── caching_interceptor_test.dart
├── interceptor_chain_test.dart
├── interceptor_context_test.dart
├── interceptor_result_test.dart
├── logging_interceptor_test.dart
├── store_interceptor_test.dart
├── store_operation_test.dart
├── timing_interceptor_test.dart
└── validation_interceptor_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22, complete) - for metrics integration

## API Preview

```dart
// Configure store with interceptors
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    interceptors: [
      LoggingInterceptor(level: LogLevel.debug),
      TimingInterceptor(reporter: metricsReporter),
      ValidationInterceptor<User>(
        validator: (user) => user.email.isNotEmpty,
        errorMessage: 'Email is required',
      ),
      MyCustomInterceptor(),
    ],
  ),
);

// Custom interceptor
class AuthInterceptor extends StoreInterceptor {
  @override
  Set<StoreOperation> get operations => {
    StoreOperation.save,
    StoreOperation.delete,
  };

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    final user = authService.currentUser;
    if (user == null) {
      return InterceptorResult.error(UnauthorizedException());
    }
    ctx.metadata['userId'] = user.id;
    return InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    auditService.log('${ctx.operation} by ${ctx.metadata['userId']}');
  }
}

// Caching interceptor for deduplication
class DeduplicationInterceptor extends StoreInterceptor {
  final _pending = <String, Future>{};

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    if (ctx.operation == StoreOperation.get) {
      final key = 'get:${ctx.request}';
      if (_pending.containsKey(key)) {
        final result = await _pending[key];
        return InterceptorResult.shortCircuit(result as R);
      }
    }
    return InterceptorResult.continue_();
  }
}
```

## Implementation Summary

The interceptor system was implemented following TDD methodology with all tests written before implementation:

1. **Phase 1 - Data Models**: Created `StoreOperation` enum, `InterceptorContext` class, and `InterceptorResult` sealed class with tests.

2. **Phase 2 - Core Infrastructure**: Implemented `StoreInterceptor` abstract class and `InterceptorChain` with forward/reverse order execution.

3. **Phase 3 - StoreConfig Integration**: Added `interceptors` field to `StoreConfig` using Freezed.

4. **Phase 4 - NexusStore Integration**: Wrapped all store operations with the interceptor chain.

5. **Phase 5 - Built-in Interceptors**: Created four production-ready interceptors:
   - `LoggingInterceptor`: Logs operations with configurable levels
   - `TimingInterceptor`: Reports metrics to MetricsReporter
   - `ValidationInterceptor`: Validates items before save operations
   - `CachingInterceptor`: Deduplicates concurrent identical requests

**Test Coverage**: 139+ tests covering all interceptor functionality.

## Notes

- Interceptors should be lightweight to avoid performance overhead
- Consider async vs sync interceptors for different use cases
- Order matters: auth before validation, timing wraps everything
- Short-circuit is powerful but use carefully (can break expectations)
- Document that response interceptors see final response, not intermediate
- Consider adding "around" interceptor pattern for full request lifecycle
