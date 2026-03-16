import 'package:meta/meta.dart';

/// Configuration for automatic background refetching.
///
/// Controls when and how the store automatically refreshes data
/// from the backend. Supports interval-based polling, connectivity
/// change triggers, and app resume triggers.
///
/// ## Example
///
/// ```dart
/// final config = RefetchConfig(
///   interval: Duration(minutes: 5),
///   refetchOnReconnect: true,
///   refetchOnResume: true,
/// );
/// ```
@immutable
class RefetchConfig {
  /// Creates a refetch configuration.
  const RefetchConfig({
    this.interval,
    this.refetchOnReconnect = false,
    this.refetchOnResume = false,
  });

  /// Interval for periodic refetching.
  ///
  /// When set, the store will automatically refetch data at this interval.
  /// When null, no periodic refetching occurs.
  final Duration? interval;

  /// Whether to refetch when connectivity is restored.
  ///
  /// Requires a connectivity stream to be provided to the [RefetchManager].
  final bool refetchOnReconnect;

  /// Whether to refetch when the app resumes from background.
  ///
  /// Requires a resume stream to be provided to the [RefetchManager].
  final bool refetchOnResume;

  /// Whether any refetch trigger is enabled.
  bool get isEnabled =>
      interval != null || refetchOnReconnect || refetchOnResume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefetchConfig &&
          runtimeType == other.runtimeType &&
          interval == other.interval &&
          refetchOnReconnect == other.refetchOnReconnect &&
          refetchOnResume == other.refetchOnResume;

  @override
  int get hashCode =>
      Object.hash(interval, refetchOnReconnect, refetchOnResume);

  @override
  String toString() => 'RefetchConfig('
      'interval: $interval, '
      'refetchOnReconnect: $refetchOnReconnect, '
      'refetchOnResume: $refetchOnResume)';
}
