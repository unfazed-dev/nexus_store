import 'package:rxdart/rxdart.dart';

import 'persisted_state.dart';
import 'state_storage.dart';

/// A UI state container using [BehaviorSubject].
///
/// Unlike regular streams, [BehaviorSubject] emits the current value
/// immediately when a new listener subscribes.
///
/// [NexusState] extends the basic reactive pattern with [reset] functionality
/// to revert to the initial value, making it ideal for UI state management.
///
/// ## Example
///
/// ```dart
/// // Create state with initial value
/// final counter = NexusState<int>(0);
///
/// // Read current value
/// print(counter.value); // 0
///
/// // Update value
/// counter.value = 1;
/// counter.emit(2); // Alias for setter
///
/// // Transform value
/// counter.update((current) => current + 1);
///
/// // Watch changes
/// counter.stream.listen((value) => print('Counter: $value'));
///
/// // Reset to initial value
/// counter.reset();
/// print(counter.value); // 0
///
/// // Clean up
/// await counter.dispose();
/// ```
class NexusState<T> {
  /// Creates a [NexusState] with the given initial value.
  ///
  /// The [initialValue] is stored and can be restored via [reset].
  NexusState(T initialValue)
      : _initialValue = initialValue,
        _subject = BehaviorSubject.seeded(initialValue);

  final T _initialValue;
  final BehaviorSubject<T> _subject;

  /// The initial value this state was created with.
  ///
  /// This value never changes and is used by [reset].
  T get initialValue => _initialValue;

  /// The current value.
  T get value => _subject.value;

  /// Updates the current value.
  ///
  /// This will emit the new value to all stream subscribers.
  set value(T newValue) => _subject.add(newValue);

  /// Stream of value changes.
  ///
  /// Emits the current value immediately upon subscription
  /// (BehaviorSubject behavior).
  Stream<T> get stream => _subject.stream;

  /// Returns `true` if this state has been disposed.
  bool get isClosed => _subject.isClosed;

  /// Updates the value using a transform function.
  ///
  /// ```dart
  /// state.update((current) => current + 1);
  /// ```
  void update(T Function(T current) transform) {
    value = transform(value);
  }

  /// Resets the value to the initial value.
  ///
  /// This will emit the initial value to all stream subscribers.
  void reset() {
    value = _initialValue;
  }

  /// Emits a new value.
  ///
  /// This is an alias for the [value] setter.
  void emit(T newValue) {
    value = newValue;
  }

  /// Disposes this state and closes the stream.
  ///
  /// After calling this method, [isClosed] will return `true`.
  Future<void> dispose() => _subject.close();

  /// Creates a persisted [NexusState] that auto-saves to storage.
  ///
  /// Returns a [PersistedState] that automatically persists to the provided
  /// storage on every value change and restores from storage on creation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final counter = await NexusState.persisted<int>(
  ///   key: 'counter',
  ///   initial: 0,
  ///   storage: SharedPrefsStorage(prefs),
  ///   serialize: (v) => v.toString(),
  ///   deserialize: (s) => int.parse(s),
  /// );
  ///
  /// counter.value = 10; // Automatically saved
  /// ```
  ///
  /// ## JSON Example
  ///
  /// ```dart
  /// import 'dart:convert';
  ///
  /// final userState = await NexusState.persisted<User>(
  ///   key: 'current_user',
  ///   initial: User.guest(),
  ///   storage: myStorage,
  ///   serialize: (u) => jsonEncode(u.toJson()),
  ///   deserialize: (s) => User.fromJson(jsonDecode(s)),
  /// );
  /// ```
  static Future<PersistedState<T>> persisted<T>({
    required String key,
    required T initial,
    required StateStorage storage,
    required StateSerializer<T> serialize,
    required StateDeserializer<T> deserialize,
  }) {
    return PersistedState.create(
      key: key,
      initialValue: initial,
      storage: storage,
      serialize: serialize,
      deserialize: deserialize,
    );
  }
}
