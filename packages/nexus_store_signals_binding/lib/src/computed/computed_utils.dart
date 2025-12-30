import 'package:signals/signals.dart';

/// Extension methods on [Signal<List<T>>] for common computed patterns.
///
/// These methods create derived signals that automatically update
/// when the source signal changes.
///
/// Example:
/// ```dart
/// final usersSignal = userStore.toSignal();
///
/// // Computed signals
/// final activeUsers = usersSignal.filtered((u) => u.isActive);
/// final sortedByName = usersSignal.sorted((a, b) => a.name.compareTo(b.name));
/// final userCount = usersSignal.count();
/// final firstAdmin = usersSignal.firstWhereOrNull((u) => u.isAdmin);
/// ```
extension SignalListExtensions<T> on Signal<List<T>> {
  /// Returns a computed signal with items filtered by the predicate.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final activeUsers = usersSignal.filtered((u) => u.isActive);
  /// ```
  Computed<List<T>> filtered(bool Function(T item) predicate) {
    return computed(() => value.where(predicate).toList());
  }

  /// Returns a computed signal with items sorted by the comparator.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final sortedByAge = usersSignal.sorted((a, b) => a.age.compareTo(b.age));
  /// ```
  Computed<List<T>> sorted(Comparator<T> comparator) {
    return computed(() => [...value]..sort(comparator));
  }

  /// Returns a computed signal with the count of items.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final userCount = usersSignal.count();
  /// ```
  Computed<int> count() {
    return computed(() => value.length);
  }

  /// Returns a computed signal with the first item matching the predicate,
  /// or null if no item matches.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final admin = usersSignal.firstWhereOrNull((u) => u.isAdmin);
  /// ```
  Computed<T?> firstWhereOrNull(bool Function(T item) predicate) {
    return computed(() {
      for (final item in value) {
        if (predicate(item)) return item;
      }
      return null;
    });
  }

  /// Returns a computed signal with items mapped by the transform function.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final userNames = usersSignal.mapped((u) => u.name);
  /// ```
  Computed<List<R>> mapped<R>(R Function(T item) transform) {
    return computed(() => value.map(transform).toList());
  }

  /// Returns a computed signal that is true if any item matches the predicate.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final hasAdmin = usersSignal.any((u) => u.isAdmin);
  /// ```
  Computed<bool> any(bool Function(T item) predicate) {
    return computed(() => value.any(predicate));
  }

  /// Returns a computed signal that is true if all items match the predicate.
  ///
  /// The resulting signal updates automatically when the source changes.
  ///
  /// Example:
  /// ```dart
  /// final allActive = usersSignal.every((u) => u.isActive);
  /// ```
  Computed<bool> every(bool Function(T item) predicate) {
    return computed(() => value.every(predicate));
  }
}
