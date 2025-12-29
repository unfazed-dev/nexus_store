import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/reliability/health_status.dart';

part 'component_health.freezed.dart';

/// Health status of an individual component.
///
/// Represents the health of a specific system component (e.g., backend,
/// cache, sync service) at a point in time.
///
/// ## Example
///
/// ```dart
/// final backendHealth = ComponentHealth.healthy(
///   'backend',
///   responseTime: Duration(milliseconds: 50),
/// );
///
/// if (backendHealth.status.isUnhealthy) {
///   print('Backend is down: ${backendHealth.message}');
/// }
/// ```
@freezed
abstract class ComponentHealth with _$ComponentHealth {
  /// Creates a component health record.
  const factory ComponentHealth({
    /// Name of the component (e.g., 'backend', 'cache', 'sync').
    required String name,

    /// Health status of the component.
    required HealthStatus status,

    /// Time when this health check was performed.
    required DateTime checkedAt,

    /// Optional message describing the health state.
    String? message,

    /// Time taken to perform the health check.
    Duration? responseTime,

    /// Additional details about the component's health.
    Map<String, dynamic>? details,
  }) = _ComponentHealth;

  const ComponentHealth._();

  /// Creates a healthy component record.
  factory ComponentHealth.healthy(
    String name, {
    Duration? responseTime,
    Map<String, dynamic>? details,
  }) =>
      ComponentHealth(
        name: name,
        status: HealthStatus.healthy,
        checkedAt: DateTime.now(),
        responseTime: responseTime,
        details: details,
      );

  /// Creates a degraded component record.
  factory ComponentHealth.degraded(
    String name,
    String message, {
    Duration? responseTime,
    Map<String, dynamic>? details,
  }) =>
      ComponentHealth(
        name: name,
        status: HealthStatus.degraded,
        checkedAt: DateTime.now(),
        message: message,
        responseTime: responseTime,
        details: details,
      );

  /// Creates an unhealthy component record.
  factory ComponentHealth.unhealthy(
    String name,
    String message, {
    Duration? responseTime,
    Map<String, dynamic>? details,
  }) =>
      ComponentHealth(
        name: name,
        status: HealthStatus.unhealthy,
        checkedAt: DateTime.now(),
        message: message,
        responseTime: responseTime,
        details: details,
      );
}

/// Aggregate health status of the entire system.
///
/// Combines the health of multiple components into an overall system
/// health assessment.
///
/// ## Example
///
/// ```dart
/// final health = SystemHealth.fromComponents([
///   backendHealth,
///   cacheHealth,
///   syncHealth,
/// ]);
///
/// if (health.overallStatus.isUnhealthy) {
///   final unhealthy = health.components
///       .where((c) => c.status.isUnhealthy)
///       .map((c) => c.name)
///       .join(', ');
///   alertOps('Unhealthy components: $unhealthy');
/// }
/// ```
@freezed
abstract class SystemHealth with _$SystemHealth {
  /// Creates a system health record.
  const factory SystemHealth({
    /// Overall health status of the system.
    required HealthStatus overallStatus,

    /// Health status of individual components.
    required List<ComponentHealth> components,

    /// Time when this health check was performed.
    required DateTime checkedAt,

    /// Optional version string of the system.
    String? version,
  }) = _SystemHealth;

  const SystemHealth._();

  /// Creates system health from a list of component health records.
  ///
  /// The overall status is determined by the worst component status.
  factory SystemHealth.fromComponents(
    List<ComponentHealth> components, {
    String? version,
  }) {
    final overallStatus = HealthStatus.worst(
      components.map((c) => c.status),
    );
    return SystemHealth(
      overallStatus: overallStatus,
      components: components,
      checkedAt: DateTime.now(),
      version: version,
    );
  }

  /// Creates an empty system health with healthy status.
  factory SystemHealth.empty() => SystemHealth(
        overallStatus: HealthStatus.healthy,
        components: [],
        checkedAt: DateTime.now(),
      );

  /// Gets a component by name.
  ///
  /// Returns `null` if the component is not found.
  ComponentHealth? getComponent(String name) {
    for (final component in components) {
      if (component.name == name) return component;
    }
    return null;
  }

  /// Returns `true` if any component is unhealthy.
  bool get hasUnhealthyComponents =>
      components.any((c) => c.status.isUnhealthy);

  /// Returns `true` if any component is degraded.
  bool get hasDegradedComponents => components.any((c) => c.status.isDegraded);
}
