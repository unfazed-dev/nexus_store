import 'package:rxdart/rxdart.dart';

/// Mixin that adds reactive state management to stores.
///
/// Provides [BehaviorSubject] streams that emit the current value
/// immediately upon subscription (unlike regular streams).
///
/// ## Example
///
/// ```dart
/// class MyStore with ReactiveStoreMixin {
///   final _users = ReactiveState<List<User>>([]);
///
///   Stream<List<User>> get users => _users.stream;
///
///   Future<void> loadUsers() async {
///     _users.value = await api.getUsers();
///   }
/// }
/// ```
mixin ReactiveStoreMixin {
  final List<ReactiveState<Object?>> _reactiveStates = [];

  /// Creates a new reactive state with the given initial value.
  ReactiveState<T> createReactiveState<T>(T initialValue) {
    final state = ReactiveState<T>(initialValue);
    _reactiveStates.add(state as ReactiveState<Object?>);
    return state;
  }

  /// Disposes all reactive states.
  Future<void> disposeReactiveStates() async {
    for (final state in _reactiveStates) {
      await state.dispose();
    }
    _reactiveStates.clear();
  }
}

/// A reactive state container using [BehaviorSubject].
///
/// Unlike regular streams, [BehaviorSubject] emits the current value
/// immediately when a new listener subscribes.
class ReactiveState<T> {
  /// Creates a reactive state with the given initial value.
  ReactiveState(T initialValue) : _subject = BehaviorSubject.seeded(initialValue);

  final BehaviorSubject<T> _subject;

  /// The current value.
  T get value => _subject.value;

  /// Updates the current value.
  set value(T newValue) => _subject.add(newValue);

  /// Stream of value changes.
  ///
  /// Emits the current value immediately upon subscription.
  Stream<T> get stream => _subject.stream;

  /// Returns `true` if this state has been disposed.
  bool get isClosed => _subject.isClosed;

  /// Updates the value using a transform function.
  void update(T Function(T current) transform) {
    value = transform(value);
  }

  /// Disposes this reactive state.
  Future<void> dispose() => _subject.close();
}

/// A reactive list that emits updates when items are added/removed.
class ReactiveList<T> extends ReactiveState<List<T>> {
  /// Creates a reactive list with optional initial items.
  ReactiveList([List<T>? initialItems]) : super(List<T>.from(initialItems ?? []));

  /// Adds an item to the list.
  void add(T item) {
    update((current) => [...current, item]);
  }

  /// Removes an item from the list.
  void remove(T item) {
    update((current) => current.where((e) => e != item).toList());
  }

  /// Removes item at index.
  void removeAt(int index) {
    update((current) {
      final copy = List<T>.from(current);
      copy.removeAt(index);
      return copy;
    });
  }

  /// Clears all items.
  void clear() {
    value = [];
  }

  /// Number of items in the list.
  int get length => value.length;

  /// Whether the list is empty.
  bool get isEmpty => value.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => value.isNotEmpty;

  /// Gets item at index.
  T operator [](int index) => value[index];
}

/// A reactive map that emits updates when entries change.
class ReactiveMap<K, V> extends ReactiveState<Map<K, V>> {
  /// Creates a reactive map with optional initial entries.
  ReactiveMap([Map<K, V>? initialMap]) : super(Map<K, V>.from(initialMap ?? {}));

  /// Sets a key-value pair.
  void set(K key, V value) {
    update((current) => {...current, key: value});
  }

  /// Removes a key.
  void remove(K key) {
    update((current) {
      final copy = Map<K, V>.from(current);
      copy.remove(key);
      return copy;
    });
  }

  /// Clears all entries.
  void clear() {
    value = {};
  }

  /// Gets value for key.
  V? operator [](K key) => value[key];

  /// Whether the map contains a key.
  bool containsKey(K key) => value.containsKey(key);

  /// Number of entries.
  int get length => value.length;

  /// Whether the map is empty.
  bool get isEmpty => value.isEmpty;
}
