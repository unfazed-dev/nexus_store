import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/delta_merge_strategy.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/field_change.dart';

/// Represents a conflict between local and remote changes.
class FieldConflict {
  /// Creates a field conflict.
  const FieldConflict({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
    required this.localTimestamp,
    required this.remoteTimestamp,
  });

  /// The name of the conflicting field.
  final String fieldName;

  /// The local value of the field.
  final dynamic localValue;

  /// The remote value of the field.
  final dynamic remoteValue;

  /// When the local change was made.
  final DateTime localTimestamp;

  /// When the remote change was made.
  final DateTime remoteTimestamp;

  /// Returns `true` if the local change is newer.
  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);

  /// Returns `true` if the remote change is newer.
  bool get isRemoteNewer => remoteTimestamp.isAfter(localTimestamp);
}

/// Result of merging two deltas.
class MergeResult {
  /// Creates a merge result.
  const MergeResult({
    required this.merged,
    required this.conflicts,
    required this.resolvedConflicts,
  });

  /// The merged data.
  final Map<String, dynamic> merged;

  /// Conflicts that were detected.
  final List<FieldConflict> conflicts;

  /// How each conflict was resolved (fieldName -> chosen value).
  final Map<String, dynamic> resolvedConflicts;

  /// Returns `true` if there were any conflicts.
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Returns the number of conflicts.
  int get conflictCount => conflicts.length;
}

/// Merges delta changes with conflict detection and resolution.
///
/// Supports multiple merge strategies for handling conflicts when the same
/// field has been modified both locally and remotely.
///
/// ## Example
///
/// ```dart
/// final merger = DeltaMerger(
///   config: DeltaSyncConfig(
///     mergeStrategy: DeltaMergeStrategy.lastWriteWins,
///   ),
/// );
///
/// final result = await merger.mergeDeltas(
///   base: originalData,
///   local: localDelta,
///   remote: remoteDelta,
/// );
///
/// if (result.hasConflicts) {
///   print('Resolved ${result.conflictCount} conflicts');
/// }
///
/// final mergedData = result.merged;
/// ```
class DeltaMerger {
  /// Creates a delta merger with optional configuration.
  DeltaMerger({DeltaSyncConfig? config})
      : _config = config ?? const DeltaSyncConfig();

  final DeltaSyncConfig _config;

  /// Applies a delta to a base entity.
  ///
  /// Returns a new map with the delta changes applied.
  Map<String, dynamic> applyDelta(
    Map<String, dynamic> base,
    DeltaChange<dynamic> delta,
  ) {
    final result = Map<String, dynamic>.from(base);

    for (final change in delta.changes) {
      result[change.fieldName] = change.newValue;
    }

    return result;
  }

  /// Detects conflicts between two deltas.
  ///
  /// A conflict occurs when the same field has been modified
  /// in both the local and remote deltas.
  List<FieldConflict> detectConflicts(
    DeltaChange<dynamic> local,
    DeltaChange<dynamic> remote,
  ) {
    final conflicts = <FieldConflict>[];

    for (final localChange in local.changes) {
      final remoteChange = remote.getChange(localChange.fieldName);

      if (remoteChange != null) {
        // Same field changed in both - this is a conflict
        conflicts.add(FieldConflict(
          fieldName: localChange.fieldName,
          localValue: localChange.newValue,
          remoteValue: remoteChange.newValue,
          localTimestamp: localChange.timestamp,
          remoteTimestamp: remoteChange.timestamp,
        ));
      }
    }

    return conflicts;
  }

  /// Merges local and remote deltas with conflict resolution.
  ///
  /// Applies the configured merge strategy to resolve any conflicts.
  Future<MergeResult> mergeDeltas({
    required Map<String, dynamic> base,
    required DeltaChange<dynamic> local,
    required DeltaChange<dynamic> remote,
  }) async {
    final result = Map<String, dynamic>.from(base);
    final conflicts = detectConflicts(local, remote);
    final resolvedConflicts = <String, dynamic>{};

    // Track which fields have conflicts
    final conflictingFields = conflicts.map((c) => c.fieldName).toSet();

    // Apply non-conflicting local changes
    for (final change in local.changes) {
      if (!conflictingFields.contains(change.fieldName)) {
        result[change.fieldName] = change.newValue;
      }
    }

    // Apply non-conflicting remote changes
    for (final change in remote.changes) {
      if (!conflictingFields.contains(change.fieldName)) {
        result[change.fieldName] = change.newValue;
      }
    }

    // Resolve conflicts
    for (final conflict in conflicts) {
      final resolvedValue = await _resolveConflict(conflict);
      result[conflict.fieldName] = resolvedValue;
      resolvedConflicts[conflict.fieldName] = resolvedValue;
    }

    return MergeResult(
      merged: result,
      conflicts: conflicts,
      resolvedConflicts: resolvedConflicts,
    );
  }

  /// Resolves a single conflict using the configured strategy.
  Future<dynamic> _resolveConflict(FieldConflict conflict) async {
    switch (_config.mergeStrategy) {
      case DeltaMergeStrategy.lastWriteWins:
        // Use the value with the later timestamp
        return conflict.isRemoteNewer
            ? conflict.remoteValue
            : conflict.localValue;

      case DeltaMergeStrategy.fieldLevel:
        // For field-level, also use last-write-wins per field
        return conflict.isRemoteNewer
            ? conflict.remoteValue
            : conflict.localValue;

      case DeltaMergeStrategy.custom:
        final callback = _config.onMergeConflict;
        if (callback != null) {
          return await callback(
            conflict.fieldName,
            conflict.localValue,
            conflict.remoteValue,
          );
        }
        // Fallback to last-write-wins if no callback
        return conflict.isRemoteNewer
            ? conflict.remoteValue
            : conflict.localValue;
    }
  }
}
