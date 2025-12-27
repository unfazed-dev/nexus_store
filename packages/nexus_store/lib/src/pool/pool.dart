// Barrel export for the connection pool module.
//
// This module provides a generic connection pooling abstraction that can be
// used with any backend connection type.
//
// Example:
// ```dart
// import 'package:nexus_store/src/pool/pool.dart';
//
// final pool = ConnectionPool<Database>(
//   factory: DatabaseConnectionFactory(),
//   config: ConnectionPoolConfig(minConnections: 2, maxConnections: 10),
// );
// ```

export 'connection_factory.dart';
export 'connection_health_check.dart';
export 'connection_pool.dart';
export 'connection_pool_config.dart';
export 'connection_scope.dart';
export 'pool_errors.dart';
export 'pool_metric.dart';
export 'pool_metrics.dart';
export 'pooled_connection.dart';
