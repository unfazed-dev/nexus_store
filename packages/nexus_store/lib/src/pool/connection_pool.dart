import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';

import 'connection_factory.dart';
import 'connection_health_check.dart';
import 'connection_pool_config.dart';
import 'pool_errors.dart';
import 'pool_metrics.dart';
import 'pooled_connection.dart';

/// A generic connection pool that manages a set of reusable connections.
///
/// The pool maintains a set of connections that can be borrowed and returned,
/// reducing the overhead of creating new connections for each operation.
///
/// ## Features
///
/// - Pre-warming with minimum connections
/// - Automatic connection validation on borrow/return
/// - Waiting queue when pool is exhausted
/// - Health checking of idle connections
/// - Connection lifetime management
/// - Metrics and observability
///
/// ## Example
///
/// ```dart
/// final pool = ConnectionPool<Database>(
///   factory: DatabaseConnectionFactory(connectionString),
///   config: ConnectionPoolConfig(
///     minConnections: 2,
///     maxConnections: 10,
///     acquireTimeout: Duration(seconds: 5),
///   ),
/// );
///
/// await pool.initialize();
///
/// // Use with automatic release
/// await pool.withConnection((db) async {
///   await db.execute('SELECT * FROM users');
/// });
///
/// // Or manual acquire/release
/// final conn = await pool.acquire();
/// try {
///   conn.connection.execute('SELECT 1');
/// } finally {
///   pool.release(conn);
/// }
///
/// await pool.close();
/// ```
class ConnectionPool<C> {
  /// Creates a connection pool.
  ///
  /// [factory] is used to create and destroy connections.
  /// [config] configures pool behavior (defaults to [ConnectionPoolConfig.defaults]).
  /// [healthCheck] is used for periodic health checks (defaults to [NoOpHealthCheck]).
  ConnectionPool({
    required ConnectionFactory<C> factory,
    ConnectionPoolConfig? config,
    ConnectionHealthCheck<C>? healthCheck,
  })  : _factory = factory,
        _config = config ?? ConnectionPoolConfig.defaults,
        _healthCheck = healthCheck ?? NoOpHealthCheck<C>();

  final ConnectionFactory<C> _factory;
  final ConnectionPoolConfig _config;
  final ConnectionHealthCheck<C> _healthCheck;

  // State
  bool _initialized = false;
  bool _disposed = false;

  // Connection tracking
  final List<PooledConnection<C>> _idleConnections = [];
  final Set<PooledConnection<C>> _activeConnections = {};

  // Waiting queue (FIFO with Completer)
  final Queue<_WaitingRequest<C>> _waitingQueue = Queue();

  // Timers for periodic maintenance
  Timer? _healthCheckTimer;
  Timer? _cleanupTimer;

  // Metrics tracking
  final BehaviorSubject<PoolMetrics> _metricsSubject =
      BehaviorSubject.seeded(PoolMetrics.empty);
  int _peakActive = 0;
  int _totalCreated = 0;
  int _totalDestroyed = 0;
  final List<Duration> _acquireTimes = [];

  // --- Public Properties ---

  /// The pool configuration.
  ConnectionPoolConfig get config => _config;

  /// Whether the pool has been initialized.
  bool get isInitialized => _initialized;

  /// Whether the pool has been disposed.
  bool get isDisposed => _disposed;

  /// Stream of pool metrics updates.
  Stream<PoolMetrics> get metricsStream => _metricsSubject.stream;

  /// Current pool metrics.
  PoolMetrics get currentMetrics => _metricsSubject.value;

  // --- Lifecycle ---

  /// Initializes the pool.
  ///
  /// Pre-warms the pool with [ConnectionPoolConfig.minConnections] connections.
  /// Must be called before acquiring connections.
  ///
  /// Throws [PoolDisposedError] if the pool has been disposed.
  Future<void> initialize() async {
    if (_disposed) {
      throw const PoolDisposedError(
        message: 'Cannot initialize a disposed pool',
      );
    }
    if (_initialized) return;

    // Pre-warm with minimum connections
    for (var i = 0; i < _config.minConnections; i++) {
      final pooled = await _createConnection();
      if (pooled != null) {
        _idleConnections.add(pooled);
      }
    }

    // Start periodic maintenance
    _startHealthCheckTimer();
    _startCleanupTimer();

    _initialized = true;
    _updateMetrics();
  }

  /// Closes the pool and releases all connections.
  ///
  /// After closing, the pool cannot be reused.
  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;

    // Cancel timers
    _healthCheckTimer?.cancel();
    _cleanupTimer?.cancel();

    // Reject all waiting requests
    while (_waitingQueue.isNotEmpty) {
      final request = _waitingQueue.removeFirst();
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          const PoolClosedError(message: 'Pool is closing'),
        );
      }
    }

    // Destroy all connections
    final allConnections = [..._idleConnections, ..._activeConnections];
    _idleConnections.clear();
    _activeConnections.clear();

    for (final pooled in allConnections) {
      await _destroyConnection(pooled);
    }

    await _metricsSubject.close();
  }

  // --- Core Operations ---

  /// Acquires a connection from the pool.
  ///
  /// Returns a [PooledConnection] wrapper containing the connection.
  /// The connection must be returned using [release] when done.
  ///
  /// Throws [PoolNotInitializedError] if the pool hasn't been initialized.
  /// Throws [PoolDisposedError] if the pool has been disposed.
  /// Throws [PoolAcquireTimeoutError] if no connection becomes available
  /// within [ConnectionPoolConfig.acquireTimeout].
  Future<PooledConnection<C>> acquire() async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();

    // Try to get an idle connection
    final connection = await _tryAcquireIdle();
    if (connection != null) {
      stopwatch.stop();
      _recordAcquireTime(stopwatch.elapsed);
      return connection;
    }

    // Try to create a new connection if under max
    if (_totalConnectionCount < _config.maxConnections) {
      final newConnection = await _createConnection();
      if (newConnection != null) {
        _markAsActive(newConnection);
        stopwatch.stop();
        _recordAcquireTime(stopwatch.elapsed);
        return newConnection;
      }
    }

    // Must wait for a connection
    return _waitForConnection(stopwatch);
  }

  /// Releases a connection back to the pool.
  ///
  /// The connection becomes available for reuse by other callers.
  void release(PooledConnection<C> connection) {
    if (_disposed) {
      // Pool is closing, destroy the connection
      _destroyConnection(connection);
      return;
    }

    _activeConnections.remove(connection);

    // Validate on return if configured
    if (_config.testOnReturn) {
      _factory.validate(connection.connection).then((valid) {
        if (valid && !_disposed) {
          _returnToPool(connection);
        } else {
          _destroyConnection(connection);
        }
      });
    } else {
      _returnToPool(connection);
    }

    _updateMetrics();
  }

  /// Executes an operation with a connection.
  ///
  /// Acquires a connection, executes the operation, and releases
  /// the connection automatically, even if an error occurs.
  ///
  /// ```dart
  /// final result = await pool.withConnection((conn) async {
  ///   return await conn.execute('SELECT * FROM users');
  /// });
  /// ```
  Future<R> withConnection<R>(
    Future<R> Function(C connection) operation,
  ) async {
    final pooled = await acquire();
    try {
      return await operation(pooled.connection);
    } finally {
      release(pooled);
    }
  }

  // --- Internal Methods ---

  void _ensureInitialized() {
    if (!_initialized) {
      throw const PoolNotInitializedError(
        message: 'Pool has not been initialized',
      );
    }
    if (_disposed) {
      throw const PoolDisposedError(
        message: 'Pool has been disposed',
      );
    }
  }

  int get _totalConnectionCount =>
      _idleConnections.length + _activeConnections.length;

  Future<PooledConnection<C>?> _tryAcquireIdle() async {
    while (_idleConnections.isNotEmpty) {
      final pooled = _idleConnections.removeLast();

      // Check lifetime
      if (pooled.hasExceededLifetime(_config.maxLifetime)) {
        await _destroyConnection(pooled);
        continue;
      }

      // Validate on borrow if configured
      if (_config.testOnBorrow) {
        final valid = await _factory.validate(pooled.connection);
        if (!valid) {
          await _destroyConnection(pooled);
          continue;
        }
      }

      _markAsActive(pooled);
      return pooled;
    }
    return null;
  }

  Future<PooledConnection<C>?> _createConnection() async {
    try {
      final connection = await _factory.create();
      final pooled = PooledConnection<C>(
        connection: connection,
        createdAt: DateTime.now(),
      );
      _totalCreated++;
      _updateMetrics();
      return pooled;
    } catch (_) {
      return null;
    }
  }

  Future<void> _destroyConnection(PooledConnection<C> pooled) async {
    try {
      await _factory.destroy(pooled.connection);
      _totalDestroyed++;
      _updateMetrics();
    } catch (_) {
      // Ignore destroy errors
    }
  }

  void _markAsActive(PooledConnection<C> pooled) {
    pooled.markUsed();
    _activeConnections.add(pooled);
    if (_activeConnections.length > _peakActive) {
      _peakActive = _activeConnections.length;
    }
    _updateMetrics();
  }

  void _returnToPool(PooledConnection<C> connection) {
    // coverage:ignore-start
    // Defensive: Pool disposed during async validation in release()
    if (_disposed) {
      _destroyConnection(connection);
      return;
    }
    // coverage:ignore-end

    // Check if there are waiting requests
    while (_waitingQueue.isNotEmpty) {
      final request = _waitingQueue.removeFirst();
      if (!request.isTimedOut && !request.completer.isCompleted) {
        _markAsActive(connection);
        request.completer.complete(connection);
        _updateMetrics();
        return;
      }
    }

    // Return to idle pool
    _idleConnections.add(connection);
    _updateMetrics();
  }

  Future<PooledConnection<C>> _waitForConnection(Stopwatch stopwatch) async {
    final request = _WaitingRequest<C>();
    _waitingQueue.add(request);
    _updateMetrics();

    final remainingTimeout = _config.acquireTimeout - stopwatch.elapsed;

    // coverage:ignore-start
    // Defensive: Race condition where timeout already exceeded before wait
    if (remainingTimeout <= Duration.zero) {
      _waitingQueue.remove(request);
      request.isTimedOut = true;
      _updateMetrics();
      throw PoolAcquireTimeoutError(
        message:
            'Failed to acquire connection within ${_config.acquireTimeout}',
      );
    }
    // coverage:ignore-end

    try {
      final connection = await request.completer.future.timeout(
        remainingTimeout,
        onTimeout: () {
          request.isTimedOut = true;
          _waitingQueue.remove(request);
          _updateMetrics();
          throw PoolAcquireTimeoutError(
            message:
                'Failed to acquire connection within ${_config.acquireTimeout}',
          );
        },
      );

      stopwatch.stop();
      _recordAcquireTime(stopwatch.elapsed);
      return connection;
    } catch (e) {
      if (e is! PoolAcquireTimeoutError) {
        _waitingQueue.remove(request);
        _updateMetrics();
      }
      rethrow;
    }
  }

  void _startHealthCheckTimer() {
    if (_config.healthCheckInterval <= Duration.zero) return;

    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthChecks(),
    );
  }

  Future<void> _performHealthChecks() async {
    if (_disposed) return;

    final toCheck = List<PooledConnection<C>>.from(_idleConnections);

    for (final pooled in toCheck) {
      if (_disposed) return;

      try {
        final healthy = await _healthCheck.isHealthy(pooled.connection);
        pooled.setHealthy(healthy);

        if (!healthy) {
          _idleConnections.remove(pooled);

          // Try to reset
          final reset = await _healthCheck.reset(pooled.connection);
          if (reset) {
            pooled.setHealthy(true);
            if (!_disposed) {
              _idleConnections.add(pooled);
            }
          } else {
            await _destroyConnection(pooled);
          }
        }
      } catch (_) {
        pooled.setHealthy(false);
        _idleConnections.remove(pooled);
        await _destroyConnection(pooled);
      }
    }

    // Ensure minimum connections
    await _ensureMinConnections();
    _updateMetrics();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _trimIdleConnections(),
    );
  }

  Future<void> _trimIdleConnections() async {
    if (_disposed) return;

    while (_idleConnections.length > _config.minConnections) {
      // coverage:ignore-start
      // Defensive: Async operations could modify list between checks
      if (_idleConnections.isEmpty) break;
      // coverage:ignore-end

      final oldest = _idleConnections.first;

      if (oldest.hasExceededIdleTimeout(_config.idleTimeout)) {
        _idleConnections.removeAt(0);
        await _destroyConnection(oldest);
      } else {
        break;
      }
    }

    _updateMetrics();
  }

  Future<void> _ensureMinConnections() async {
    while (_totalConnectionCount < _config.minConnections && !_disposed) {
      final created = await _createConnection();
      if (created != null) {
        _idleConnections.add(created);
      } else {
        break;
      }
    }
  }

  void _recordAcquireTime(Duration duration) {
    _acquireTimes.add(duration);
    if (_acquireTimes.length > 100) {
      _acquireTimes.removeAt(0);
    }
  }

  Duration _calculateAverageAcquireTime() {
    if (_acquireTimes.isEmpty) return Duration.zero;
    final total = _acquireTimes.fold<int>(
      0,
      (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: total ~/ _acquireTimes.length);
  }

  void _updateMetrics() {
    if (_disposed && _metricsSubject.isClosed) return;

    try {
      _metricsSubject.add(PoolMetrics(
        totalConnections: _totalConnectionCount,
        idleConnections: _idleConnections.length,
        activeConnections: _activeConnections.length,
        waitingRequests: _waitingQueue.length,
        averageAcquireTime: _calculateAverageAcquireTime(),
        peakActiveConnections: _peakActive,
        totalConnectionsCreated: _totalCreated,
        totalConnectionsDestroyed: _totalDestroyed,
        timestamp: DateTime.now(),
      ));
    } catch (_) {
      // Ignore if subject is closed
    }
  }
}

/// Internal class representing a waiting request for a connection.
class _WaitingRequest<C> {
  final Completer<PooledConnection<C>> completer = Completer();
  bool isTimedOut = false;
}
