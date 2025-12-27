# TRACKER: Connection Pooling

## Status: ✅ COMPLETE

## Overview

Implement a generic connection pooling abstraction for backend connections, reducing connection overhead and improving performance for high-throughput applications.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-041, Task 33
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Completion Summary

- **Total Tests**: 175 tests
- **Completion Date**: 2025-12-27
- **Files Created**: 10 source files, 8 test files

## Tasks

### Data Models
- [x] Create `ConnectionPoolConfig` class (30 tests)
  - [x] `minConnections: int` - Minimum idle connections (default 1)
  - [x] `maxConnections: int` - Maximum connections (default 10)
  - [x] `acquireTimeout: Duration` - Wait time for connection
  - [x] `idleTimeout: Duration` - Close idle connections after
  - [x] `maxLifetime: Duration` - Max connection lifetime
  - [x] `healthCheckInterval: Duration` - Check connection health

- [x] Create `PooledConnection<C>` wrapper (22 tests)
  - [x] `connection: C` - The underlying connection
  - [x] `createdAt: DateTime`
  - [x] `lastUsedAt: DateTime`
  - [x] `useCount: int`
  - [x] `isHealthy: bool`

- [x] Create `PoolMetrics` class (13 tests)
  - [x] `totalConnections: int`
  - [x] `idleConnections: int`
  - [x] `activeConnections: int`
  - [x] `waitingRequests: int`
  - [x] `acquireTime: Duration` - Average acquire time

### Pool Implementation
- [x] Create `ConnectionPool<C>` class (34 tests)
  - [x] `Future<C> acquire()` - Get connection from pool
  - [x] `void release(C connection)` - Return to pool
  - [x] `Future<void> close()` - Close all connections

- [x] Implement connection lifecycle
  - [x] Create new connections as needed
  - [x] Reuse idle connections
  - [x] Close connections exceeding lifetime

- [x] Implement waiting queue
  - [x] Queue requests when pool exhausted
  - [x] Timeout if wait exceeds limit
  - [x] FIFO processing of waiters

### Health Checking
- [x] Create `ConnectionHealthCheck<C>` interface (12 tests)
  - [x] `Future<bool> isHealthy(C connection)`
  - [x] `Future<void> reset(C connection)` - Reset connection state

- [x] Implement periodic health checks
  - [x] Check idle connections
  - [x] Replace unhealthy connections
  - [x] Report health metrics

### Connection Factory
- [x] Create `ConnectionFactory<C>` interface (22 tests)
  - [x] `Future<C> create()` - Create new connection
  - [x] `Future<void> destroy(C connection)` - Cleanup connection
  - [x] `Future<bool> validate(C connection)` - Quick validation

- [ ] Implement for common backends (deferred to adapter packages)
  - [ ] Document factory implementation per adapter

### Pool Scoping
- [x] Implement `withConnection<R>` pattern
  - [x] Acquire, execute, release automatically
  - [x] Handle errors with release

- [x] Create `ConnectionScope` class (12 tests)
  - [x] Tracks borrowed connections
  - [x] Auto-release on scope exit

### Backend Integration
- [ ] Update `StoreBackend` to support pooling (deferred to adapter packages)
  - [ ] Accept `ConnectionPool` in constructor
  - [ ] Use pool for all operations

- [ ] Create pooled adapter wrappers (deferred to adapter packages)
  - [ ] `PooledPowerSyncBackend`
  - [ ] `PooledDriftBackend`
  - [ ] etc.

### Metrics & Monitoring
- [x] Add pool metrics to telemetry
  - [x] `PoolMetric` class with pool events
  - [x] `reportPoolEvent()` on MetricsReporter
  - [x] NoOp, Console, and Buffered reporter implementations

- [x] Add `poolMetrics` getter
  - [x] Current pool state via `currentMetrics`
  - [x] Reactive updates via `metricsStream`

### Unit Tests
- [x] `test/src/pool/connection_pool_test.dart` (34 tests)
  - [x] Connections reused correctly
  - [x] Pool respects max size
  - [x] Timeout on exhausted pool
  - [x] Health checks work
  - [x] Idle connections closed
- [x] `test/src/pool/connection_pool_config_test.dart` (30 tests)
- [x] `test/src/pool/pooled_connection_test.dart` (22 tests)
- [x] `test/src/pool/pool_metrics_test.dart` (13 tests)
- [x] `test/src/pool/pool_errors_test.dart` (30 tests)
- [x] `test/src/pool/connection_factory_test.dart` (22 tests)
- [x] `test/src/pool/connection_health_check_test.dart` (12 tests)
- [x] `test/src/pool/connection_scope_test.dart` (12 tests)

## Files

**Source Files:**
```
packages/nexus_store/lib/src/pool/
├── pool.dart                   # Barrel export
├── connection_pool.dart        # ConnectionPool<C> class
├── connection_pool_config.dart # @freezed Configuration
├── pooled_connection.dart      # PooledConnection wrapper
├── connection_factory.dart     # ConnectionFactory interface
├── connection_health_check.dart # Health check interface + NoOpHealthCheck
├── pool_metrics.dart           # @freezed PoolMetrics class
├── pool_metric.dart            # @freezed PoolMetric for telemetry
├── pool_errors.dart            # Re-export of pool errors
└── connection_scope.dart       # Auto-release scope + withScope extension
```

**Test Files:**
```
packages/nexus_store/test/src/pool/
├── connection_pool_test.dart
├── connection_pool_config_test.dart
├── pooled_connection_test.dart
├── pool_metrics_test.dart
├── pool_errors_test.dart
├── connection_factory_test.dart
├── connection_health_check_test.dart
└── connection_scope_test.dart

packages/nexus_store/test/fixtures/
├── fake_connection.dart
└── fake_connection_factory.dart
```

## Dependencies

- Core package (Task 1, complete)
- Telemetry (Task 22) - for metrics

## API Preview

```dart
// Configure connection pool
final pool = ConnectionPool<Database>(
  config: ConnectionPoolConfig(
    minConnections: 2,
    maxConnections: 10,
    acquireTimeout: Duration(seconds: 5),
    idleTimeout: Duration(minutes: 5),
    maxLifetime: Duration(hours: 1),
  ),
  factory: DatabaseConnectionFactory(
    host: 'localhost',
    port: 5432,
    database: 'mydb',
  ),
  healthCheck: DatabaseHealthCheck(),
);

// Use pool in backend
final backend = PooledDriftBackend(
  pool: pool,
  tableName: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
);

// Use with store
final store = NexusStore<User, String>(backend: backend);

// Manual pool usage (if needed)
final conn = await pool.acquire();
try {
  await conn.execute('SELECT * FROM users');
} finally {
  pool.release(conn);
}

// Better: scoped usage
await pool.withConnection((conn) async {
  await conn.execute('SELECT * FROM users');
  // Connection auto-released after scope
});

// Monitor pool
pool.metricsStream.listen((metrics) {
  print('Active: ${metrics.activeConnections}/${metrics.totalConnections}');
  print('Waiting: ${metrics.waitingRequests}');
  print('Avg acquire: ${metrics.acquireTime.inMilliseconds}ms');
});

// Get current state
final metrics = pool.currentMetrics;
if (metrics.waitingRequests > 5) {
  // Consider increasing pool size
  logger.warn('Connection pool contention detected');
}

// Custom connection factory
class PostgresConnectionFactory implements ConnectionFactory<PgConnection> {
  final String connectionString;

  PostgresConnectionFactory(this.connectionString);

  @override
  Future<PgConnection> create() async {
    return await PgConnection.open(connectionString);
  }

  @override
  Future<void> destroy(PgConnection conn) async {
    await conn.close();
  }

  @override
  Future<bool> validate(PgConnection conn) async {
    try {
      await conn.execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Custom health check
class PostgresHealthCheck implements ConnectionHealthCheck<PgConnection> {
  @override
  Future<bool> isHealthy(PgConnection conn) async {
    try {
      final result = await conn.execute('SELECT 1');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> reset(PgConnection conn) async {
    await conn.execute('DISCARD ALL');
  }
}

// Cleanup
await pool.close(); // Closes all connections
```

## Notes

- Connection pooling most beneficial for databases with connection overhead
- SQLite typically doesn't benefit (single connection is common)
- Pool size should match expected concurrency
- Too many connections can overwhelm database
- Health checks prevent using stale connections
- Monitor wait times to detect undersized pools
- Consider separate pools for read vs write operations
- Document thread safety requirements per backend
- Connection lifetime prevents resource leaks
