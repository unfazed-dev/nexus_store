/// Merge strategy for CRDT conflict resolution.
///
/// CRDT (Conflict-free Replicated Data Types) use these strategies to
/// resolve conflicts when the same field is modified on multiple nodes.
enum CrdtMergeStrategy {
  /// Last-Writer-Wins: The value with the latest timestamp wins.
  ///
  /// This is the most common strategy and is suitable for most use cases.
  /// It ensures that the most recent change always takes precedence.
  lww,

  /// First-Writer-Wins: The value with the earliest timestamp wins.
  ///
  /// Use this when you want the original value to be preserved and
  /// subsequent changes should be ignored. Useful for immutable fields
  /// or fields that should only be set once.
  fww,

  /// Custom merge function.
  ///
  /// Use this when you need complex merge logic that considers both
  /// values and potentially produces a new merged value.
  custom,
}

/// Type signature for custom merge functions.
///
/// The function receives:
/// - [local]: The local entity value
/// - [remote]: The remote entity value
/// - [localTimestamp]: When the local value was created/modified
/// - [remoteTimestamp]: When the remote value was created/modified
///
/// Returns the merged entity.
typedef CrdtMergeFunction<T> = T Function(
  T local,
  T remote,
  DateTime localTimestamp,
  DateTime remoteTimestamp,
);

/// Configuration for CRDT merge behavior.
///
/// This class allows fine-grained control over how conflicts are resolved
/// at both the entity level and individual field level.
///
/// Example:
/// ```dart
/// final config = CrdtMergeConfig<User>(
///   defaultStrategy: CrdtMergeStrategy.lww,
///   fieldStrategies: {
///     'name': CrdtMergeStrategy.fww, // Name can only be set once
///     'email': CrdtMergeStrategy.lww, // Email uses latest value
///   },
/// );
/// ```
class CrdtMergeConfig<T> {
  /// Creates a merge configuration.
  ///
  /// - [defaultStrategy]: The default strategy for fields not explicitly
  ///   configured. Defaults to [CrdtMergeStrategy.lww].
  /// - [fieldStrategies]: Map of field names to their merge strategies.
  /// - [customMerge]: Custom merge function when using
  ///   [CrdtMergeStrategy.custom].
  const CrdtMergeConfig({
    this.defaultStrategy = CrdtMergeStrategy.lww,
    this.fieldStrategies = const {},
    this.customMerge,
  });

  /// The default merge strategy for fields not explicitly configured.
  final CrdtMergeStrategy defaultStrategy;

  /// Per-field merge strategies.
  ///
  /// Keys are field names, values are the merge strategies to use.
  final Map<String, CrdtMergeStrategy> fieldStrategies;

  /// Custom merge function for entity-level merging.
  ///
  /// Only used when [defaultStrategy] is [CrdtMergeStrategy.custom].
  final CrdtMergeFunction<T>? customMerge;

  /// Gets the merge strategy for a specific field.
  ///
  /// Returns the field-specific strategy if configured, otherwise
  /// returns [defaultStrategy].
  CrdtMergeStrategy getStrategyForField(String fieldName) =>
      fieldStrategies[fieldName] ?? defaultStrategy;
}

/// Utility class for merging individual field values.
///
/// This class implements the actual merge logic for different strategies.
class CrdtFieldMerger {
  /// Creates a field merger.
  const CrdtFieldMerger();

  /// Merges two field values using the specified strategy.
  ///
  /// Returns the winning value based on the strategy and timestamps.
  ///
  /// Throws [UnsupportedError] if [CrdtMergeStrategy.custom] is used,
  /// as custom strategies require entity-level handling.
  V mergeField<V>({
    required V localValue,
    required V remoteValue,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
    required CrdtMergeStrategy strategy,
  }) {
    switch (strategy) {
      case CrdtMergeStrategy.lww:
        // Last Writer Wins: use the value with the later timestamp
        // On tie, prefer local (arbitrary but consistent)
        if (remoteTimestamp.isAfter(localTimestamp)) {
          return remoteValue;
        }
        return localValue;

      case CrdtMergeStrategy.fww:
        // First Writer Wins: use the value with the earlier timestamp
        // On tie, prefer local (arbitrary but consistent)
        if (remoteTimestamp.isBefore(localTimestamp)) {
          return remoteValue;
        }
        return localValue;

      case CrdtMergeStrategy.custom:
        throw UnsupportedError(
          'Custom merge strategy requires a custom merge function. '
          'Use CrdtMergeConfig.customMerge for entity-level merging.',
        );
    }
  }
}

/// Result of a merge operation.
///
/// Contains the merged entity and information about any conflicts
/// that were resolved during the merge.
class CrdtMergeResult<T> {
  /// Creates a merge result.
  const CrdtMergeResult({
    required this.mergedEntity,
    required this.hadConflict,
    this.conflictDetails,
  });

  /// The merged entity after conflict resolution.
  final T mergedEntity;

  /// Whether any conflicts were detected and resolved.
  final bool hadConflict;

  /// Details about each field conflict that was resolved.
  ///
  /// Keys are field names, values contain conflict information.
  /// Only populated if [hadConflict] is true.
  final Map<String, CrdtConflictDetail>? conflictDetails;
}

/// Details about a single field conflict.
///
/// This provides visibility into what values conflicted and how
/// they were resolved, useful for debugging and auditing.
class CrdtConflictDetail {
  /// Creates a conflict detail.
  const CrdtConflictDetail({
    required this.localValue,
    required this.remoteValue,
    required this.resolvedValue,
    required this.strategy,
  });

  /// The local value before merge.
  final Object? localValue;

  /// The remote value that caused the conflict.
  final Object? remoteValue;

  /// The final resolved value.
  final Object? resolvedValue;

  /// The strategy used to resolve the conflict.
  final CrdtMergeStrategy strategy;
}
