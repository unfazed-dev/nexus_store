import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'pending_change.dart';

/// Manages pending changes that have not yet been synced to the server.
///
/// Provides tracking of pending changes with support for:
/// - Adding new pending changes with original values for undo
/// - Removing changes when sync succeeds
/// - Updating retry counts and error states
/// - Streaming changes for UI visibility
///
/// ## Example
///
/// ```dart
/// final manager = PendingChangesManager<User, String>(
///   idExtractor: (user) => user.id,
/// );
///
/// // Add a pending change
/// final change = await manager.addChange(
///   item: updatedUser,
///   operation: PendingChangeOperation.update,
///   originalValue: originalUser,
/// );
///
/// // Listen for changes
/// manager.pendingChangesStream.listen((changes) {
///   print('Pending: ${changes.length}');
/// });
///
/// // Remove on success
/// manager.removeChange(change.id);
/// ```
class PendingChangesManager<T, ID> {
  /// Creates a pending changes manager.
  ///
  /// The [idExtractor] function extracts the entity ID from an item.
  PendingChangesManager({
    required this.idExtractor,
  });

  /// Extracts the ID from an entity.
  final ID Function(T item) idExtractor;

  final _uuid = const Uuid();
  final Map<String, PendingChange<T>> _changes = {};
  late final BehaviorSubject<List<PendingChange<T>>> _changesSubject =
      BehaviorSubject.seeded([]);

  /// Stream of pending changes.
  ///
  /// Emits the current list immediately on subscription and whenever
  /// changes are added, removed, or updated.
  Stream<List<PendingChange<T>>> get pendingChangesStream =>
      _changesSubject.stream;

  /// Current list of pending changes.
  List<PendingChange<T>> get pendingChanges => List.unmodifiable(_changes.values.toList());

  /// Number of pending changes.
  int get pendingCount => _changes.length;

  /// Number of failed changes.
  int get failedCount => _changes.values.where((c) => c.hasFailed).length;

  /// List of failed changes.
  List<PendingChange<T>> get failedChanges =>
      _changes.values.where((c) => c.hasFailed).toList();

  /// Adds a new pending change.
  ///
  /// Returns the created [PendingChange] with a unique ID.
  Future<PendingChange<T>> addChange({
    required T item,
    required PendingChangeOperation operation,
    T? originalValue,
  }) async {
    final change = PendingChange<T>(
      id: _uuid.v4(),
      item: item,
      operation: operation,
      createdAt: DateTime.now(),
      originalValue: originalValue,
    );

    _changes[change.id] = change;
    _notifyChanges();

    return change;
  }

  /// Removes a pending change by ID.
  ///
  /// Returns the removed change, or `null` if not found.
  PendingChange<T>? removeChange(String changeId) {
    final removed = _changes.remove(changeId);
    if (removed != null) {
      _notifyChanges();
    }
    return removed;
  }

  /// Gets a pending change by ID.
  ///
  /// Returns `null` if not found.
  PendingChange<T>? getChange(String changeId) {
    return _changes[changeId];
  }

  /// Updates a pending change with new retry information.
  ///
  /// Returns the updated change, or `null` if not found.
  PendingChange<T>? updateChange(
    String changeId, {
    int? retryCount,
    Object? lastError,
    DateTime? lastAttempt,
  }) {
    final existing = _changes[changeId];
    if (existing == null) return null;

    final updated = existing.copyWith(
      retryCount: retryCount ?? existing.retryCount,
      lastError: lastError,
      lastAttempt: lastAttempt,
    );

    _changes[changeId] = updated;
    _notifyChanges();

    return updated;
  }

  /// Gets all pending changes for a specific entity.
  List<PendingChange<T>> getChangesForEntity(ID entityId) {
    return _changes.values
        .where((c) => idExtractor(c.item) == entityId)
        .toList();
  }

  /// Clears all pending changes.
  ///
  /// Returns the list of removed changes.
  List<PendingChange<T>> clearAll() {
    final removed = _changes.values.toList();
    _changes.clear();
    _notifyChanges();
    return removed;
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _changesSubject.close();
  }

  void _notifyChanges() {
    _changesSubject.add(pendingChanges);
  }
}
