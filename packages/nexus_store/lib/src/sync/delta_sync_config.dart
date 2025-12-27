import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/sync/delta_merge_strategy.dart';

part 'delta_sync_config.freezed.dart';

/// Callback for custom merge conflict resolution.
///
/// Called when a field has been modified both locally and remotely.
/// Returns the value that should be used after merge.
typedef MergeConflictCallback = Future<dynamic> Function(
  String fieldName,
  dynamic localValue,
  dynamic remoteValue,
);

/// Configuration for delta sync behavior.
///
/// Controls how field-level changes are tracked and merged during sync.
///
/// ## Example
///
/// ```dart
/// final config = DeltaSyncConfig(
///   enabled: true,
///   excludeFields: {'updatedAt', 'createdAt'},
///   mergeStrategy: DeltaMergeStrategy.fieldLevel,
/// );
///
/// final store = NexusStore<User, String>(
///   backend: backend,
///   config: StoreConfig(deltaSync: config),
/// );
/// ```
@freezed
abstract class DeltaSyncConfig with _$DeltaSyncConfig {
  /// Creates a delta sync configuration.
  const factory DeltaSyncConfig({
    /// Whether delta sync is enabled.
    ///
    /// When enabled, only changed fields are synced instead of entire entities.
    @Default(false) bool enabled,

    /// Fields to exclude from delta tracking.
    ///
    /// These fields will always be synced in full, not as deltas.
    /// Useful for fields like `updatedAt` that change frequently.
    @Default({}) Set<String> excludeFields,

    /// Strategy for merging conflicting changes.
    @Default(DeltaMergeStrategy.lastWriteWins) DeltaMergeStrategy mergeStrategy,

    /// Custom callback for resolving merge conflicts.
    ///
    /// Only used when [mergeStrategy] is [DeltaMergeStrategy.custom].
    MergeConflictCallback? onMergeConflict,
  }) = _DeltaSyncConfig;

  const DeltaSyncConfig._();

  /// Configuration with delta sync disabled (default).
  static const DeltaSyncConfig off = DeltaSyncConfig();

  /// Configuration with delta sync enabled using last-write-wins.
  static const DeltaSyncConfig defaults = DeltaSyncConfig(enabled: true);

  /// Configuration with delta sync enabled using field-level merging.
  static const DeltaSyncConfig fieldLevelMerge = DeltaSyncConfig(
    enabled: true,
    mergeStrategy: DeltaMergeStrategy.fieldLevel,
  );

  /// Returns `true` if the given field should be tracked for changes.
  ///
  /// Returns `false` for fields in [excludeFields].
  bool shouldTrackField(String fieldName) => !excludeFields.contains(fieldName);

  /// Returns `true` if using the custom merge strategy.
  bool get isCustomStrategy => mergeStrategy == DeltaMergeStrategy.custom;
}
