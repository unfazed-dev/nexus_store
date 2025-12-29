/// Represents the health status of a component or system.
///
/// Health status is used to indicate the operational state:
/// - [healthy]: Operating normally
/// - [degraded]: Operating with reduced functionality
/// - [unhealthy]: Not operating correctly
///
/// ## Example
///
/// ```dart
/// final status = healthCheck.check();
/// if (status.isUnhealthy) {
///   alertOps('System is unhealthy');
/// } else if (status.isDegraded) {
///   showWarning('Running in degraded mode');
/// }
/// ```
enum HealthStatus {
  /// System is operating normally.
  ///
  /// All components are functioning as expected.
  healthy,

  /// System is operating with reduced functionality.
  ///
  /// Some components may be impaired but the system is still usable.
  degraded,

  /// System is not operating correctly.
  ///
  /// Critical components have failed and immediate attention is required.
  unhealthy;

  /// Returns `true` if this status indicates healthy operation.
  bool get isHealthy => this == healthy;

  /// Returns `true` if this status indicates degraded operation.
  bool get isDegraded => this == degraded;

  /// Returns `true` if this status indicates unhealthy operation.
  bool get isUnhealthy => this == unhealthy;

  /// Returns `true` if this status is worse than [other].
  ///
  /// Status severity order: healthy < degraded < unhealthy.
  bool isWorseThan(HealthStatus other) => index > other.index;

  /// Returns the worst (most severe) status from a list.
  ///
  /// Returns [healthy] if the list is empty.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final overall = HealthStatus.worst([
  ///   backendStatus,
  ///   cacheStatus,
  ///   syncStatus,
  /// ]);
  /// ```
  static HealthStatus worst(Iterable<HealthStatus> statuses) {
    if (statuses.isEmpty) return healthy;
    return statuses.reduce((a, b) => a.index > b.index ? a : b);
  }
}
