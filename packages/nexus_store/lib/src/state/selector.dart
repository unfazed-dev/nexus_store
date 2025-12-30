import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../core/nexus_store.dart';

/// A selector that derives a value from a source stream.
///
/// Selectors transform data from a source stream and emit only when the
/// transformed value changes (using [distinctUntilChanged]).
///
/// Uses [BehaviorSubject] internally, so subscribers receive the current value
/// immediately upon subscription.
///
/// ## Example
///
/// ```dart
/// // Select active users only
/// final selector = Selector<User, List<User>>(
///   store.watchAll(),
///   (users) => users.where((u) => u.isActive).toList(),
///   equals: (a, b) => listEquals(a, b),
/// );
///
/// // Watch selected values
/// selector.stream.listen((activeUsers) {
///   print('Active users: ${activeUsers.length}');
/// });
///
/// // Clean up
/// await selector.dispose();
/// ```
class Selector<T, R> {
  /// Creates a [Selector] from a source stream.
  ///
  /// - [source]: The source stream to select from.
  /// - [select]: The function to transform source data into the selected value.
  /// - [equals]: Optional custom equality function. If not provided, uses `==`.
  Selector(
    Stream<List<T>> source,
    R Function(List<T>) select, {
    bool Function(R, R)? equals,
  }) {
    _subscription = source
        .map(select)
        .distinct(equals)
        .listen(_subject.add, onError: _subject.addError);
  }

  final BehaviorSubject<R> _subject = BehaviorSubject<R>();
  late final StreamSubscription<R> _subscription;

  /// The current selected value.
  ///
  /// May throw [StateError] if accessed before any value has been selected.
  R get value => _subject.value;

  /// Stream of selected values.
  ///
  /// Emits the current value immediately upon subscription (BehaviorSubject).
  /// Only emits when the selected value changes.
  Stream<R> get stream => _subject.stream;

  /// Returns `true` if this selector has been disposed.
  bool get isClosed => _subject.isClosed;

  /// Disposes this selector.
  ///
  /// Cancels the source subscription and closes the stream.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _subject.close();
  }
}

/// Extension methods for selecting data from [NexusStore].
///
/// Provides convenient methods for common selection patterns.
extension NexusStoreSelectors<T, ID> on NexusStore<T, ID> {
  /// Selects and transforms store data.
  ///
  /// Returns a stream that emits whenever the selected value changes.
  ///
  /// ```dart
  /// // Select total count
  /// store.select((users) => users.length).listen((count) {
  ///   print('User count: $count');
  /// });
  ///
  /// // Select with custom equality
  /// store.select(
  ///   (users) => users.map((u) => u.name).toList(),
  ///   equals: listEquals,
  /// ).listen((names) {
  ///   print('Names: $names');
  /// });
  /// ```
  Stream<R> select<R>(
    R Function(List<T>) selector, {
    bool Function(R, R)? equals,
  }) {
    return watchAll().map(selector).distinct(equals);
  }

  /// Selects a single item by ID.
  ///
  /// Returns a stream that emits the item with the given ID, or `null`
  /// if not found.
  ///
  /// This is a convenience wrapper around [watch] that applies
  /// [distinctUntilChanged].
  ///
  /// ```dart
  /// store.selectById('user-123').listen((user) {
  ///   print('User: ${user?.name}');
  /// });
  /// ```
  Stream<T?> selectById(ID id) {
    return watch(id).distinct();
  }

  /// Selects items matching a predicate.
  ///
  /// Returns a stream that emits only items matching the predicate.
  ///
  /// ```dart
  /// store.selectWhere((user) => user.isActive).listen((activeUsers) {
  ///   print('Active users: ${activeUsers.length}');
  /// });
  /// ```
  Stream<List<T>> selectWhere(bool Function(T) predicate) {
    return watchAll()
        .map((items) => items.where(predicate).toList())
        .distinct(_listEquals);
  }

  /// Selects the count of items.
  ///
  /// Returns a stream that emits the total number of items.
  ///
  /// ```dart
  /// store.selectCount().listen((count) {
  ///   print('Total items: $count');
  /// });
  /// ```
  Stream<int> selectCount() {
    return watchAll().map((items) => items.length).distinct();
  }

  /// Selects the first item, or null if empty.
  ///
  /// ```dart
  /// store.selectFirst().listen((first) {
  ///   print('First item: $first');
  /// });
  /// ```
  Stream<T?> selectFirst() {
    return watchAll()
        .map((items) => items.isEmpty ? null : items.first)
        .distinct();
  }

  /// Selects the last item, or null if empty.
  ///
  /// ```dart
  /// store.selectLast().listen((last) {
  ///   print('Last item: $last');
  /// });
  /// ```
  Stream<T?> selectLast() {
    return watchAll()
        .map((items) => items.isEmpty ? null : items.last)
        .distinct();
  }

  /// Helper for list equality comparison.
  bool _listEquals(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
