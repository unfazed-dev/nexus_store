import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'state_storage.dart';

/// Function type for serializing a value to a string.
typedef StateSerializer<T> = String Function(T value);

/// Function type for deserializing a string to a value.
typedef StateDeserializer<T> = T Function(String data);

/// A state container that automatically persists to storage.
///
/// Similar to [NexusState], but automatically saves to storage on every value
/// change and restores from storage on creation.
///
/// Uses [BehaviorSubject] internally, so subscribers receive the current value
/// immediately upon subscription.
///
/// ## Example
///
/// ```dart
/// // Create a persisted counter
/// final counter = await PersistedState.create<int>(
///   key: 'counter',
///   initialValue: 0,
///   storage: myStorage,
///   serialize: (v) => v.toString(),
///   deserialize: (s) => int.parse(s),
/// );
///
/// // Value is restored from storage if available
/// print(counter.value); // May be > 0 if previously saved
///
/// // Updates are automatically persisted
/// counter.value = 10; // Saved to storage
/// counter.emit(20);   // Saved to storage
/// counter.update((v) => v + 1); // Saved to storage
///
/// // Reset reverts to initial and saves
/// counter.reset(); // Saves initial value to storage
///
/// // Clean up
/// await counter.dispose();
/// ```
///
/// ## JSON Serialization Example
///
/// ```dart
/// import 'dart:convert';
///
/// final userState = await PersistedState.create<User>(
///   key: 'current_user',
///   initialValue: User.guest(),
///   storage: SharedPrefsStorage(prefs),
///   serialize: (u) => jsonEncode(u.toJson()),
///   deserialize: (s) => User.fromJson(jsonDecode(s)),
/// );
/// ```
class PersistedState<T> {
  /// Creates a persisted state that auto-saves to storage.
  ///
  /// This is an async factory because it needs to read from storage.
  ///
  /// - [key]: Unique storage key for this state.
  /// - [initialValue]: Default value if nothing is in storage or if
  ///   deserialization fails.
  /// - [storage]: Storage implementation (SharedPreferences, Hive, etc.).
  /// - [serialize]: Function to convert the value to a string.
  /// - [deserialize]: Function to convert a string back to the value.
  static Future<PersistedState<T>> create<T>({
    required String key,
    required T initialValue,
    required StateStorage storage,
    required StateSerializer<T> serialize,
    required StateDeserializer<T> deserialize,
  }) async {
    T restoredValue = initialValue;

    try {
      final stored = await storage.read(key);
      if (stored != null) {
        restoredValue = deserialize(stored);
      }
    } catch (_) {
      // Fall back to initial value on any error
      restoredValue = initialValue;
    }

    return PersistedState._(
      key: key,
      initialValue: initialValue,
      currentValue: restoredValue,
      storage: storage,
      serialize: serialize,
    );
  }

  PersistedState._({
    required this.key,
    required T initialValue,
    required T currentValue,
    required this.storage,
    required this.serialize,
  })  : _initialValue = initialValue,
        _subject = BehaviorSubject.seeded(currentValue) {
    // Subscribe to changes and auto-save
    _saveSubscription = _subject.stream
        .skip(1) // Skip initial value (already in storage or default)
        .listen(_persistValue);
  }

  /// The storage key for this state.
  final String key;

  final T _initialValue;
  final BehaviorSubject<T> _subject;

  /// The storage implementation.
  final StateStorage storage;

  /// The serialization function.
  final StateSerializer<T> serialize;

  late final StreamSubscription<T> _saveSubscription;

  /// The initial value this state was created with.
  ///
  /// This value never changes and is used by [reset].
  T get initialValue => _initialValue;

  /// The current value.
  T get value => _subject.value;

  /// Updates the current value.
  ///
  /// This will emit the new value to all stream subscribers and
  /// automatically persist to storage.
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
  /// The new value is automatically persisted to storage.
  ///
  /// ```dart
  /// state.update((current) => current + 1);
  /// ```
  void update(T Function(T current) transform) {
    value = transform(value);
  }

  /// Resets the value to the initial value.
  ///
  /// This will emit the initial value to all stream subscribers and
  /// persist it to storage.
  void reset() {
    value = _initialValue;
  }

  /// Emits a new value.
  ///
  /// This is an alias for the [value] setter.
  /// The new value is automatically persisted to storage.
  void emit(T newValue) {
    value = newValue;
  }

  Future<void> _persistValue(T value) async {
    try {
      await storage.write(key, serialize(value));
    } catch (_) {
      // Fail silently - value is still updated in memory
    }
  }

  /// Disposes this state and closes the stream.
  ///
  /// After calling this method, [isClosed] will return `true`.
  Future<void> dispose() async {
    await _saveSubscription.cancel();
    await _subject.close();
  }
}
