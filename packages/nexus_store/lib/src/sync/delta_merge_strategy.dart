/// Strategy for merging delta changes when conflicts occur.
///
/// Determines how field-level conflicts are resolved when the same field
/// has been modified both locally and remotely.
///
/// ## Example
///
/// ```dart
/// final config = DeltaSyncConfig(
///   enabled: true,
///   mergeStrategy: DeltaMergeStrategy.fieldLevel,
/// );
/// ```
enum DeltaMergeStrategy {
  /// Last write wins - the change with the latest timestamp wins.
  ///
  /// Simple strategy that uses timestamps to resolve conflicts.
  /// The change with the most recent timestamp is applied.
  ///
  /// Best for: Simple use cases where data freshness is the priority.
  lastWriteWins,

  /// Field-level conflict resolution.
  ///
  /// Each field conflict is resolved independently based on timestamps.
  /// Non-conflicting fields are merged automatically.
  ///
  /// Best for: Complex entities where different fields may be updated
  /// by different sources.
  fieldLevel,

  /// Custom merge strategy using a callback.
  ///
  /// Delegates conflict resolution to a custom callback function.
  /// Provides full control over how conflicts are resolved.
  ///
  /// Best for: Complex business logic that requires custom rules.
  custom,
}
