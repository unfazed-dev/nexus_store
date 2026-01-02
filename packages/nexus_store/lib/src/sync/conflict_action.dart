import 'conflict_details.dart';

/// Actions that can be taken to resolve a conflict.
///
/// Used as the return value from conflict resolution callbacks to indicate
/// how a conflict should be resolved.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore<User, String>(
///   backend: backend,
///   onConflict: (details) async {
///     final choice = await showConflictDialog(
///       local: details.localValue,
///       remote: details.remoteValue,
///     );
///
///     return switch (choice) {
///       'local' => ConflictAction.keepLocal(),
///       'remote' => ConflictAction.keepRemote(),
///       'merge' => ConflictAction.merge(mergedUser),
///       _ => ConflictAction.skip(),
///     };
///   },
/// );
/// ```
sealed class ConflictAction<T> {
  const ConflictAction._();

  /// Keep the local version, discarding the remote changes.
  const factory ConflictAction.keepLocal() = KeepLocal<T>;

  /// Keep the remote version, discarding the local changes.
  const factory ConflictAction.keepRemote() = KeepRemote<T>;

  /// Use a custom merged value that combines both versions.
  const factory ConflictAction.merge(T merged) = Merge<T>;

  /// Skip resolution for now, keeping the conflict unresolved.
  ///
  /// The conflict will remain and may be presented again later.
  const factory ConflictAction.skip() = SkipResolution<T>;
}

/// Keep the local version of the entity.
final class KeepLocal<T> extends ConflictAction<T> {
  /// Creates a keep local action.
  const KeepLocal() : super._();

  // coverage:ignore-start
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KeepLocal<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ConflictAction.keepLocal()';
  // coverage:ignore-end
}

/// Keep the remote version of the entity.
final class KeepRemote<T> extends ConflictAction<T> {
  /// Creates a keep remote action.
  const KeepRemote() : super._();

  // coverage:ignore-start
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KeepRemote<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ConflictAction.keepRemote()';
  // coverage:ignore-end
}

/// Use a custom merged value.
final class Merge<T> extends ConflictAction<T> {
  /// Creates a merge action with the given merged value.
  const Merge(this.merged) : super._();

  /// The merged value to use as the resolution.
  final T merged;

  // coverage:ignore-start
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Merge<T> &&
          runtimeType == other.runtimeType &&
          merged == other.merged;

  @override
  int get hashCode => Object.hash(runtimeType, merged);

  @override
  String toString() => 'ConflictAction.merge($merged)';
  // coverage:ignore-end
}

/// Skip resolution, keeping the conflict unresolved.
final class SkipResolution<T> extends ConflictAction<T> {
  /// Creates a skip action.
  const SkipResolution() : super._();

  // coverage:ignore-start
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkipResolution<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ConflictAction.skip()';
  // coverage:ignore-end
}

/// Type alias for conflict resolver callbacks.
///
/// A conflict resolver receives [ConflictDetails] and returns a [ConflictAction]
/// indicating how to resolve the conflict.
typedef ConflictResolver<T> = Future<ConflictAction<T>> Function(
  ConflictDetails<T> details,
);
