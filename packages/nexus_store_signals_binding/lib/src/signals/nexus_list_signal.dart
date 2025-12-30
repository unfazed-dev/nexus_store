import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:signals/signals.dart';

/// A signal wrapper for list data with CRUD helper methods.
///
/// [NexusListSignal] wraps a [Signal] of list data and provides
/// convenient methods for adding, removing, and updating items
/// that delegate to the underlying [NexusStore].
///
/// Example:
/// ```dart
/// final usersListSignal = NexusListSignal.fromStore(userStore);
///
/// // Access list value
/// print(usersListSignal.value);
/// print(usersListSignal.length);
/// print(usersListSignal[0]);
///
/// // CRUD operations
/// await usersListSignal.add(newUser);
/// await usersListSignal.remove(userId);
/// await usersListSignal.update(userId, (u) => u.copyWith(name: 'New'));
///
/// // Dispose when done
/// usersListSignal.dispose();
/// ```
class NexusListSignal<T, ID> {
  NexusListSignal._({
    required Signal<List<T>> signal,
    required this.store,
    required StreamSubscription<List<T>> subscription,
  })  : _signal = signal,
        _subscription = subscription;

  /// Creates a [NexusListSignal] from a [NexusStore].
  ///
  /// The signal automatically updates when the store emits new data.
  factory NexusListSignal.fromStore(
    NexusStore<T, ID> store, {
    Query<T>? query,
  }) {
    final signal = Signal<List<T>>(<T>[]);

    final subscription = store.watchAll(query: query).listen(
      (data) => signal.value = data,
      onError: (Object error) {
        // Errors silently ignored
      },
    );

    signal.onDispose(() {
      subscription.cancel();
    });

    return NexusListSignal._(
      signal: signal,
      store: store,
      subscription: subscription,
    );
  }

  final Signal<List<T>> _signal;
  final StreamSubscription<List<T>> _subscription;

  /// The underlying store.
  final NexusStore<T, ID> store;

  /// The current list value.
  List<T> get value => _signal.value;

  /// The number of items in the list.
  int get length => _signal.value.length;

  /// Whether the list is empty.
  bool get isEmpty => _signal.value.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => _signal.value.isNotEmpty;

  /// Whether this signal has been disposed.
  bool get disposed => _signal.disposed;

  /// Returns the item at the given index.
  T operator [](int index) => _signal.value[index];

  /// Adds an item to the store.
  ///
  /// This delegates to [NexusStore.save] and the signal will update
  /// automatically when the store emits the new data.
  Future<T> add(T item) async {
    return store.save(item);
  }

  /// Removes an item from the store by ID.
  ///
  /// This delegates to [NexusStore.delete] and the signal will update
  /// automatically when the store emits the new data.
  Future<bool> remove(ID id) async {
    return store.delete(id);
  }

  /// Updates an item in the store.
  ///
  /// Gets the current item, applies the transform function, and saves
  /// the result. If the item is not found, does nothing.
  Future<void> update(ID id, T Function(T item) transform) async {
    final item = await store.get(id);
    if (item != null) {
      final updated = transform(item);
      await store.save(updated);
    }
  }

  /// Subscribes to changes in this signal.
  void Function() subscribe(void Function(List<T> value) callback) {
    return _signal.subscribe(callback);
  }

  /// Disposes this signal and cleans up resources.
  void dispose() {
    _subscription.cancel();
    _signal.dispose();
  }

  /// Registers a callback to be called when this signal is disposed.
  void onDispose(void Function() callback) {
    _signal.onDispose(callback);
  }
}
