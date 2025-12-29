import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'circuit_breaker.dart';
import 'circuit_breaker_state.dart';
import 'degradation_config.dart';
import 'degradation_mode.dart';
import 'health_status.dart';

/// Manages graceful degradation based on system health and circuit breaker state.
///
/// The DegradationManager monitors system components and automatically adjusts
/// the operational mode when issues are detected, helping maintain partial
/// functionality during outages.
///
/// ## Features
///
/// - Automatic degradation when circuit breaker opens
/// - Health-based degradation and recovery
/// - Configurable cooldown before recovery
/// - Manual mode control for testing/operations
///
/// ## Example
///
/// ```dart
/// final manager = DegradationManager(
///   circuitBreaker: myCircuitBreaker,
///   config: DegradationConfig(
///     autoDegradation: true,
///     fallbackMode: DegradationMode.cacheOnly,
///     cooldown: Duration(seconds: 60),
///   ),
/// );
///
/// // Listen to mode changes
/// manager.modeStream.listen((mode) {
///   if (mode.isDegraded) {
///     showBanner('Operating in ${mode.name} mode');
///   }
/// });
///
/// // Check before writes
/// if (!manager.currentMode.allowsWrites) {
///   showError('Writes temporarily disabled');
/// }
/// ```
class DegradationManager {
  /// Creates a degradation manager.
  ///
  /// If [circuitBreaker] is provided, auto-degradation will listen to
  /// circuit breaker state changes.
  DegradationManager({
    DegradationConfig? config,
    CircuitBreaker? circuitBreaker,
  })  : _config = config ?? DegradationConfig.defaults,
        _circuitBreaker = circuitBreaker,
        _modeSubject = BehaviorSubject.seeded(DegradationMode.normal),
        _metricsSubject = BehaviorSubject.seeded(DegradationMetrics.initial()) {
    _setupCircuitBreakerListener();
  }

  final DegradationConfig _config;
  final CircuitBreaker? _circuitBreaker;
  final BehaviorSubject<DegradationMode> _modeSubject;
  final BehaviorSubject<DegradationMetrics> _metricsSubject;

  StreamSubscription<CircuitBreakerState>? _circuitBreakerSubscription;
  int _degradationCount = 0;
  int _recoveryCount = 0;
  DateTime? _lastModeChange;

  /// Configuration for this manager.
  DegradationConfig get config => _config;

  /// Current degradation mode.
  DegradationMode get currentMode => _modeSubject.value;

  /// Whether the system is currently in a degraded mode.
  bool get isDegraded => currentMode.isDegraded;

  /// Current metrics snapshot.
  DegradationMetrics get metrics => DegradationMetrics(
        mode: currentMode,
        timestamp: DateTime.now(),
        degradationCount: _degradationCount,
        recoveryCount: _recoveryCount,
        lastModeChange: _lastModeChange,
      );

  /// Stream of degradation mode changes.
  ///
  /// Emits the current mode immediately upon subscription.
  Stream<DegradationMode> get modeStream => _modeSubject.stream;

  /// Stream of metrics snapshots.
  ///
  /// Emits the current metrics immediately upon subscription.
  Stream<DegradationMetrics> get metricsStream => _metricsSubject.stream;

  /// Whether recovery is allowed based on cooldown.
  ///
  /// Returns `true` if:
  /// - Not currently degraded, OR
  /// - Cooldown period has elapsed since last mode change
  bool get canRecover {
    if (!isDegraded) return true;
    if (_lastModeChange == null) return true;

    final elapsed = DateTime.now().difference(_lastModeChange!);
    return elapsed >= _config.cooldown;
  }

  /// Degrades to the specified mode.
  ///
  /// If [mode] is the same as the current mode, this is a no-op.
  /// Does nothing if degradation is disabled in config.
  void degrade(DegradationMode mode) {
    if (!_config.enabled) return;
    if (mode == currentMode) return;

    _degradationCount++;
    _setMode(mode);
  }

  /// Recovers from degradation.
  ///
  /// By default, recovers to [DegradationMode.normal].
  /// Optionally specify a [to] mode for partial recovery.
  ///
  /// Does nothing if already in normal mode.
  void recover({DegradationMode to = DegradationMode.normal}) {
    if (!isDegraded) return;

    _recoveryCount++;
    _setMode(to);
  }

  /// Directly sets the degradation mode.
  ///
  /// Tracks degradation and recovery counts based on the transition.
  void setMode(DegradationMode mode) {
    if (mode == currentMode) return;

    final wasDegraded = isDegraded;
    final willBeDegraded = mode != DegradationMode.normal;

    if (!wasDegraded && willBeDegraded) {
      _degradationCount++;
    } else if (wasDegraded && !willBeDegraded) {
      _recoveryCount++;
    }

    _setMode(mode);
  }

  /// Handles health status changes for automatic degradation.
  ///
  /// Called by HealthCheckService when system health changes.
  void onHealthChange(HealthStatus status) {
    if (!_config.autoDegradation) return;

    if (status == HealthStatus.unhealthy) {
      if (!isDegraded) {
        degrade(_config.fallbackMode);
      }
    } else if (status == HealthStatus.healthy) {
      if (isDegraded && canRecover) {
        recover();
      }
    }
  }

  /// Releases resources used by this manager.
  void dispose() {
    _circuitBreakerSubscription?.cancel();
    _modeSubject.close();
    _metricsSubject.close();
  }

  void _setupCircuitBreakerListener() {
    if (_circuitBreaker == null || !_config.autoDegradation) return;

    _circuitBreakerSubscription = _circuitBreaker.stateStream.listen((state) {
      if (state == CircuitBreakerState.open) {
        if (!isDegraded) {
          degrade(_config.fallbackMode);
        }
      } else if (state == CircuitBreakerState.closed) {
        if (isDegraded && canRecover) {
          recover();
        }
      }
    });
  }

  void _setMode(DegradationMode mode) {
    _lastModeChange = DateTime.now();
    _modeSubject.add(mode);
    _metricsSubject.add(metrics);
  }
}
