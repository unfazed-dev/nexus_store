import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict_details.freezed.dart';

/// Details about a conflict between local and remote versions of an entity.
///
/// Used by conflict resolution callbacks to provide information about
/// conflicting values and when they were modified.
///
/// ## Example
///
/// ```dart
/// store.conflicts.listen((details) {
///   print('Conflict detected:');
///   print('  Local: ${details.localValue}');
///   print('  Remote: ${details.remoteValue}');
///   print('  Conflicting fields: ${details.conflictingFields}');
///
///   if (details.isNewerRemote) {
///     print('  Remote version is newer');
///   }
/// });
/// ```
@freezed
abstract class ConflictDetails<T> with _$ConflictDetails<T> {
  /// Creates conflict details.
  const factory ConflictDetails({
    /// The local version of the entity.
    required T localValue,

    /// The remote version of the entity.
    required T remoteValue,

    /// When the local version was last modified.
    required DateTime localTimestamp,

    /// When the remote version was last modified.
    required DateTime remoteTimestamp,

    /// The set of field names that have conflicting values.
    ///
    /// If null, the specific conflicting fields are not known.
    Set<String>? conflictingFields,
  }) = _ConflictDetails<T>;

  const ConflictDetails._();

  /// Returns `true` if the local version is newer than the remote version.
  bool get isNewerLocal => localTimestamp.isAfter(remoteTimestamp);

  /// Returns `true` if the remote version is newer than the local version.
  bool get isNewerRemote => remoteTimestamp.isAfter(localTimestamp);
}
