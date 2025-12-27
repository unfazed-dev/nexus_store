import 'package:flutter/foundation.dart';

/// Configuration for background sync operations.
///
/// Controls when and how background sync tasks are executed.
/// Use the presets [disabled], [conservative], or [aggressive]
/// for common configurations.
///
/// ## Example
///
/// ```dart
/// // Default configuration
/// const config = BackgroundSyncConfig();
///
/// // Custom configuration
/// const config = BackgroundSyncConfig(
///   minInterval: Duration(minutes: 30),
///   requiresCharging: true,
/// );
///
/// // Conservative preset for battery-conscious apps
/// const config = BackgroundSyncConfig.conservative();
/// ```
@immutable
class BackgroundSyncConfig {
  /// Creates a background sync configuration.
  const BackgroundSyncConfig({
    this.enabled = true,
    this.minInterval = const Duration(minutes: 15),
    this.requiresNetwork = true,
    this.requiresCharging = false,
    this.requiresBatteryNotLow = true,
  });

  /// Creates a disabled configuration.
  ///
  /// Use this to completely disable background sync.
  const BackgroundSyncConfig.disabled()
      : enabled = false,
        minInterval = const Duration(minutes: 15),
        requiresNetwork = true,
        requiresCharging = false,
        requiresBatteryNotLow = true;

  /// Creates a conservative configuration.
  ///
  /// Syncs less frequently and only when charging.
  /// Best for: Apps where data freshness is not critical.
  const BackgroundSyncConfig.conservative()
      : enabled = true,
        minInterval = const Duration(hours: 1),
        requiresNetwork = true,
        requiresCharging = true,
        requiresBatteryNotLow = true;

  /// Creates an aggressive configuration.
  ///
  /// Syncs frequently with minimal constraints.
  /// Best for: Apps where data freshness is critical.
  const BackgroundSyncConfig.aggressive()
      : enabled = true,
        minInterval = const Duration(minutes: 15),
        requiresNetwork = true,
        requiresCharging = false,
        requiresBatteryNotLow = false;

  /// Whether background sync is enabled.
  ///
  /// When false, no background sync tasks will be scheduled.
  final bool enabled;

  /// Minimum time between sync operations.
  ///
  /// The system may delay syncs beyond this interval based on
  /// battery, network conditions, and other constraints.
  ///
  /// Default: 15 minutes (minimum allowed by most platforms).
  final Duration minInterval;

  /// Whether network connectivity is required for sync.
  ///
  /// When true, sync will only run when the device has network access.
  final bool requiresNetwork;

  /// Whether the device must be charging for sync.
  ///
  /// When true, sync will only run while plugged in.
  /// Use this for battery-conscious applications.
  final bool requiresCharging;

  /// Whether battery must not be low for sync.
  ///
  /// When true, sync will be deferred if battery is below ~20%.
  final bool requiresBatteryNotLow;

  /// Creates a copy with the given fields replaced.
  BackgroundSyncConfig copyWith({
    bool? enabled,
    Duration? minInterval,
    bool? requiresNetwork,
    bool? requiresCharging,
    bool? requiresBatteryNotLow,
  }) =>
      BackgroundSyncConfig(
        enabled: enabled ?? this.enabled,
        minInterval: minInterval ?? this.minInterval,
        requiresNetwork: requiresNetwork ?? this.requiresNetwork,
        requiresCharging: requiresCharging ?? this.requiresCharging,
        requiresBatteryNotLow:
            requiresBatteryNotLow ?? this.requiresBatteryNotLow,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundSyncConfig &&
        other.enabled == enabled &&
        other.minInterval == minInterval &&
        other.requiresNetwork == requiresNetwork &&
        other.requiresCharging == requiresCharging &&
        other.requiresBatteryNotLow == requiresBatteryNotLow;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        minInterval,
        requiresNetwork,
        requiresCharging,
        requiresBatteryNotLow,
      );

  @override
  String toString() => 'BackgroundSyncConfig('
      'enabled: $enabled, '
      'minInterval: $minInterval, '
      'requiresNetwork: $requiresNetwork, '
      'requiresCharging: $requiresCharging, '
      'requiresBatteryNotLow: $requiresBatteryNotLow)';
}
