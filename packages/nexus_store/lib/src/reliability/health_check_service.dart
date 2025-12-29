import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'component_health.dart';
import 'health_check_config.dart';

/// Interface for implementing health checks.
///
/// Implement this interface to create custom health checkers for
/// different components of the system.
///
/// ## Example
///
/// ```dart
/// class BackendHealthChecker implements HealthChecker {
///   @override
///   String get name => 'backend';
///
///   @override
///   Future<ComponentHealth> check() async {
///     try {
///       final response = await http.get(Uri.parse('$baseUrl/health'));
///       if (response.statusCode == 200) {
///         return ComponentHealth.healthy(name);
///       }
///       return ComponentHealth.degraded(name, 'Status: ${response.statusCode}');
///     } catch (e) {
///       return ComponentHealth.unhealthy(name, e.toString());
///     }
///   }
/// }
/// ```
abstract class HealthChecker {
  /// Unique name of the component being checked.
  String get name;

  /// Performs a health check and returns the component's health status.
  ///
  /// This method should:
  /// - Return [ComponentHealth.healthy] if the component is working normally
  /// - Return [ComponentHealth.degraded] if working with reduced functionality
  /// - Return [ComponentHealth.unhealthy] if the component has failed
  ///
  /// Implementations should handle their own exceptions and return appropriate
  /// [ComponentHealth] results rather than throwing.
  Future<ComponentHealth> check();
}

/// Service for managing and executing health checks.
///
/// Coordinates multiple [HealthChecker] implementations, provides periodic
/// health checking, and exposes health status via streams.
///
/// ## Example
///
/// ```dart
/// final service = HealthCheckService(
///   config: HealthCheckConfig(
///     checkInterval: Duration(seconds: 30),
///   ),
/// );
///
/// service.registerChecker(BackendHealthChecker());
/// service.registerChecker(CacheHealthChecker());
///
/// service.healthStream.listen((health) {
///   if (health.overallStatus.isUnhealthy) {
///     alertOps('System unhealthy!');
///   }
/// });
///
/// service.start();
/// ```
class HealthCheckService {
  /// Creates a health check service.
  HealthCheckService({
    HealthCheckConfig config = HealthCheckConfig.defaults,
  }) : _config = config {
    if (_config.autoStart && _config.enabled) {
      start();
    }
  }

  final HealthCheckConfig _config;
  final Map<String, HealthChecker> _checkers = {};
  final BehaviorSubject<SystemHealth> _healthSubject = BehaviorSubject();
  Timer? _timer;
  bool _isRunning = false;

  /// Stream of health updates.
  ///
  /// Emits a new [SystemHealth] after each health check cycle.
  Stream<SystemHealth> get healthStream => _healthSubject.stream;

  /// The most recent health check result.
  ///
  /// Returns `null` if no health check has been performed yet.
  SystemHealth? get currentHealth => _healthSubject.valueOrNull;

  /// Whether periodic health checks are currently running.
  bool get isRunning => _isRunning;

  /// Names of all registered health checkers.
  Iterable<String> get checkerNames => _checkers.keys;

  /// Registers a health checker.
  ///
  /// If a checker with the same name already exists, it will be replaced.
  void registerChecker(HealthChecker checker) {
    _checkers[checker.name] = checker;
  }

  /// Unregisters a health checker by name.
  void unregisterChecker(String name) {
    _checkers.remove(name);
  }

  /// Performs a health check on all registered components.
  ///
  /// Returns aggregate [SystemHealth] with results from all checkers.
  /// Individual checker failures or timeouts result in unhealthy status
  /// for that component.
  Future<SystemHealth> checkHealth() async {
    if (_checkers.isEmpty) {
      final health = SystemHealth.empty();
      _healthSubject.add(health);
      return health;
    }

    final components = await Future.wait(
      _checkers.values.map(_checkWithTimeout),
    );

    final health = SystemHealth.fromComponents(components);
    _healthSubject.add(health);
    return health;
  }

  /// Performs a health check on a single component.
  ///
  /// Returns the component health, or `null` if no checker with that
  /// name is registered.
  Future<ComponentHealth?> checkComponent(String name) async {
    final checker = _checkers[name];
    if (checker == null) return null;
    return _checkWithTimeout(checker);
  }

  /// Starts periodic health checks.
  ///
  /// Health checks are performed at the interval specified in [HealthCheckConfig].
  void start() {
    if (_isRunning || !_config.enabled) return;

    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(_config.checkInterval, (_) => checkHealth());

    // Perform initial check
    checkHealth();
  }

  /// Stops periodic health checks.
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes the service and releases resources.
  void dispose() {
    stop();
    _healthSubject.close();
  }

  /// Executes a health check with timeout handling.
  Future<ComponentHealth> _checkWithTimeout(HealthChecker checker) async {
    try {
      return await checker.check().timeout(
        _config.timeout,
        onTimeout: () => ComponentHealth.unhealthy(
          checker.name,
          'Health check timeout after ${_config.timeout.inSeconds}s',
        ),
      );
    } catch (e) {
      return ComponentHealth.unhealthy(
        checker.name,
        'Health check failed: $e',
      );
    }
  }
}
