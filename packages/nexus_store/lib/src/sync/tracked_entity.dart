import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/delta_tracker.dart';

/// A function that extracts the ID from an entity.
typedef IdExtractor<T, ID> = ID Function(T entity);

/// Wrapper that tracks changes to an entity over time.
///
/// Stores the original snapshot and allows tracking modifications
/// to generate deltas for efficient sync.
///
/// ## Example
///
/// ```dart
/// final tracked = TrackedEntity(
///   user,
///   idExtractor: (u) => u.id,
/// );
///
/// // Make changes
/// tracked.current = user.copyWith(name: 'Updated Name');
/// tracked.current = tracked.current.copyWith(age: 31);
///
/// // Check for changes
/// if (tracked.hasChanges) {
///   final delta = tracked.getDelta();
///   print('Changed fields: ${delta.changedFields}');
///   // Changed fields: {name, age}
///
///   // Commit changes (update original to current)
///   tracked.commit();
/// }
///
/// // Or reset to original
/// tracked.reset();
/// ```
class TrackedEntity<T, ID> {
  /// Creates a tracked entity wrapper.
  ///
  /// The [entity] becomes both the original snapshot and current value.
  /// Optionally provide an [idExtractor] to automatically extract entity IDs.
  /// Optionally provide a [config] for delta tracking configuration.
  TrackedEntity(
    T entity, {
    IdExtractor<T, ID>? idExtractor,
    DeltaSyncConfig? config,
  })  : _original = entity,
        _current = entity,
        _idExtractor = idExtractor,
        _tracker = DeltaTracker(config: config);

  T _original;
  T _current;
  final IdExtractor<T, ID>? _idExtractor;
  final DeltaTracker _tracker;

  /// The original snapshot of the entity.
  ///
  /// This value remains unchanged until [commit] is called.
  T get original => _original;

  /// The current value of the entity.
  ///
  /// Set this to track changes from the original.
  T get current => _current;

  set current(T value) {
    _current = value;
  }

  /// The entity ID, extracted using the [idExtractor].
  ///
  /// Returns `null` if no [idExtractor] was provided.
  ID? get entityId {
    final extractor = _idExtractor;
    if (extractor == null) return null;
    return extractor(_current);
  }

  /// Returns `true` if the current value differs from the original.
  bool get hasChanges => _tracker.hasChanges(
        original: _original,
        modified: _current,
      );

  /// Resets the current value to the original snapshot.
  void reset() {
    _current = _original;
  }

  /// Gets the delta between original and current.
  ///
  /// If [entityId] is provided, it overrides the extracted ID.
  /// If neither is available, an empty string is used as the ID.
  DeltaChange<ID> getDelta({ID? entityId}) {
    final id = entityId ?? this.entityId;
    if (id == null) {
      throw StateError(
        'No entityId provided and no idExtractor configured. '
        'Either provide entityId parameter or configure idExtractor.',
      );
    }

    return _tracker.trackChanges<ID>(
      original: _original,
      modified: _current,
      entityId: id,
    );
  }

  /// Returns a list of field names that have changed.
  List<String> getChangedFields() {
    return _tracker.getChangedFields(
      original: _original,
      modified: _current,
    );
  }

  /// Commits the current changes, updating the original snapshot.
  ///
  /// Returns the delta representing the committed changes.
  /// After commit, [hasChanges] will return `false`.
  DeltaChange<ID> commit({ID? entityId}) {
    final delta = getDelta(entityId: entityId);
    _original = _current;
    return delta;
  }
}
