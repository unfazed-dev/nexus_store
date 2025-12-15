# TRACKER: Connection Pooling

## Status: PENDING

## Overview

Implement a generic connection pooling abstraction for backend connections, reducing connection overhead and improving performance for high-throughput applications.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-041, Task 33
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `ConnectionPoolConfig` class
  - [ ] `minConnections: int` - Minimum idle connections (default 1)
  - [ ] `maxConnections: int` - Maximum connections (default 10)
  - [ ] `acquireTimeout: Duration` - Wait time for connection
  - [ ] `idleTimeout: Duration` - Close idle connections after
  - [ ] `maxLifetime: Duration` - Max connection lifetime
  - [ ] `healthCheckInterval: Duration` - Check connection health

- [ ] Create `PooledConnection<C>` wrapper
  - [ ] `connection: C` - The underlying connection
  - [ ] `createdAt: DateTime`
  - [ ] `lastUsedAt: DateTime`
  - [ ] `useCount: int`
  - [ ] `isHealthy: bool`

- [ ] Create `PoolMetrics` class
  - [ ] `totalConnections: int`
  - [ ] `idleConnections: int`
  - [ ] `activeConnections: int`
  - [ ] `waitingRequests: int`
  - [ ] `acquireTime: Duration` - Average acquire time

### Pool Implementation
- [ ] Create `ConnectionPool<C>` class
  - [ ] `Future<C> acquire()` - Get connection from pool
  - [ ] `void release(C connection)` - Return to pool
  - [ ] `Future<void> close()` - Close all connections

- [ ] Implement connection lifecycle
  - [ ] Create new connections as needed
  - [ ] Reuse idle connections
  - [ ] Close connections exceeding lifetime

- [ ] Implement waiting queue
  - [ ] Queue requests when pool exhausted
  - [ ] Timeout if wait exceeds limit
  - [ ] FIFO processing of waiters

### Health Checking
- [ ] Create `ConnectionHealthCheck<C>` interface
  - [ ] `Future<bool> isHealthy(C connection)`
  - [ ] `Future<void> reset(C connection)` - Reset connection state

- [ ] Implement periodic health checks
  - [ ] Check idle connections
  - [ ] Replace unhealthy connections
  - [ ] Report health metrics

### Connection Factory
- [ ] Create `ConnectionFactory<C>` interface
  - [ ] `Future<C> create()` - Create new connection
  - [ ] `Future<void> destroy(C connection)` - Cleanup connection
  - [ ] `Future<bool> validate(C connection)` - Quick validation

- [ ] Implement for common backends
  - [ ] Document factory implementation per adapter

### Pool Scoping
- [ ] Implement `withConnection<R>` pattern
  - [ ] Acquire, execute, release automatically
  - [ ] Handle errors with release

- [ ] Create `ConnectionScope` class
  - [ ] Tracks borrowed connections
  - [ ] Auto-release on scope exit

### Backend Integration
- [ ] Update `StoreBackend` to support pooling
  - [ ] Accept `ConnectionPool` in constructor
  - [ ] Use pool for all operations

- [ ] Create pooled adapter wrappers
  - [ ] `PooledPowerSyncBackend`
  - [ ] `PooledDriftBackend`
  - [ ] etc.

### Metrics & Monitoring
- [ ] Add pool metrics to telemetry
  - [ ] Connection creation/destruction
  - [ ] Acquire/release events
  - [ ] Wait times
  - [ ] Health check results

- [ ] Add `poolMetrics` getter
  - [ ] Current pool state
  - [ ] Historical statistics

### Unit Tests
- [ ] `test/src/backend/connection_pool_test.dart`
  - [ ] Connections reused correctly
  - [ ] Pool respects max size
  - [ ] Timeout on exhausted pool
  - [ ] Health checks work
  - [ ] Idle connections closed

## Files

**Source Files:**
```
packages/nexus_store/lib/src/backend/
├── connection_pool.dart        # ConnectionPool<C> class
├── connection_pool_config.dart # Configuration
├── pooled_connection.dart      # PooledConnection wrapper
├── connection_factory.dart     # ConnectionFactory interface
├── connection_health_check.dart # Health check interface
├── pool_metrics.dart           # PoolMetrics class
└── connection_scope.dart       # Auto-release scope
```

**Test Files:**
```
packages/nexus_store/test/src/backend/
├── connection_pool_test.dart
├── pooled_connection_test.dart
└── connection_scope_test.dart
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
