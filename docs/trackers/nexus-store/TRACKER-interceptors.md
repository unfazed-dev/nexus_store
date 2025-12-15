# TRACKER: Middleware/Interceptor API

## Status: PENDING

## Overview

Implement a middleware/interceptor system for NexusStore that allows pre/post hooks on all operations for logging, transformation, validation, and caching.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-030, Task 27
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `StoreOperation` enum
  - [ ] `get`, `getAll`, `save`, `saveAll`, `delete`, `deleteAll`
  - [ ] `watch`, `watchAll`, `sync`

- [ ] Create `InterceptorContext<T, R>` class
  - [ ] `operation: StoreOperation`
  - [ ] `request: T` - Input data (ID, item, query)
  - [ ] `response: R?` - Output data (set by interceptor or operation)
  - [ ] `metadata: Map<String, dynamic>` - Custom data passing
  - [ ] `timestamp: DateTime`
  - [ ] `stopPropagation()` - Skip remaining interceptors

- [ ] Create `InterceptorResult<R>` sealed class
  - [ ] `Continue(R? modifiedResponse)` - Proceed to next
  - [ ] `ShortCircuit(R response)` - Return immediately
  - [ ] `Error(Object error)` - Throw error

### Core Implementation
- [ ] Create `StoreInterceptor` abstract class
  - [ ] `Future<InterceptorResult<R>> onRequest<T, R>(InterceptorContext<T, R> ctx)`
  - [ ] `Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx)`
  - [ ] `Future<void> onError<T, R>(InterceptorContext<T, R> ctx, Object error)`
  - [ ] `Set<StoreOperation> get operations` - Which ops to intercept

- [ ] Create `InterceptorChain` class
  - [ ] `addInterceptor(StoreInterceptor interceptor)`
  - [ ] `removeInterceptor(StoreInterceptor interceptor)`
  - [ ] `executeRequest<T, R>(StoreOperation op, T request)`
  - [ ] `executeResponse<T, R>(InterceptorContext ctx, R response)`

- [ ] Implement ordered execution
  - [ ] Request interceptors run in add order
  - [ ] Response interceptors run in reverse order
  - [ ] Error interceptors run in reverse order

### StoreConfig Integration
- [ ] Add `interceptors` to `StoreConfig`
  - [ ] `List<StoreInterceptor>` ordered list
  - [ ] Support for conditional interceptors

- [ ] Update NexusStore to use interceptor chain
  - [ ] Wrap all operations with interceptor calls
  - [ ] Pass context through operation

### Built-in Interceptors
- [ ] Create `LoggingInterceptor`
  - [ ] Log operation, duration, success/failure
  - [ ] Configurable log level
  - [ ] Configurable output format

- [ ] Create `TimingInterceptor`
  - [ ] Measure operation duration
  - [ ] Report to MetricsReporter

- [ ] Create `ValidationInterceptor`
  - [ ] Validate items before save
  - [ ] Custom validation rules

- [ ] Create `CachingInterceptor`
  - [ ] In-memory request deduplication
  - [ ] Short-circuit for cached responses

### Unit Tests
- [ ] `test/src/interceptors/interceptor_chain_test.dart`
  - [ ] Interceptors run in correct order
  - [ ] Short-circuit stops propagation
  - [ ] Error handling works
  - [ ] Metadata passes between interceptors

- [ ] `test/src/interceptors/logging_interceptor_test.dart`
  - [ ] Logs correct information
  - [ ] Respects log levels

## Files

**Source Files:**
```
packages/nexus_store/lib/src/interceptors/
├── store_interceptor.dart      # StoreInterceptor interface
├── interceptor_chain.dart      # InterceptorChain executor
├── interceptor_context.dart    # InterceptorContext model
├── interceptor_result.dart     # InterceptorResult sealed class
├── logging_interceptor.dart    # LoggingInterceptor
├── timing_interceptor.dart     # TimingInterceptor
├── validation_interceptor.dart # ValidationInterceptor
└── caching_interceptor.dart    # CachingInterceptor
```

**Test Files:**
```
packages/nexus_store/test/src/interceptors/
├── interceptor_chain_test.dart
├── logging_interceptor_test.dart
└── validation_interceptor_test.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22) - for metrics integration

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

## Notes

- Interceptors should be lightweight to avoid performance overhead
- Consider async vs sync interceptors for different use cases
- Order matters: auth before validation, timing wraps everything
- Short-circuit is powerful but use carefully (can break expectations)
- Document that response interceptors see final response, not intermediate
- Consider adding "around" interceptor pattern for full request lifecycle
