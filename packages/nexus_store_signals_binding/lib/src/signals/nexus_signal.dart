import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:signals/signals.dart';

/// A signal wrapper that provides store-aware methods for list data.
///
/// [NexusSignal] wraps a [Signal] and provides additional methods
/// for interacting with the underlying [NexusStore], such as [refresh].
///
/// Example:
/// ```dart
/// final usersSignal = NexusSignal.fromStore(userStore);
///
/// // Access value like a regular signal
/// print(usersSignal.value);
///
/// // Refresh data from the store
/// await usersSignal.refresh();
///
/// // Dispose when done
/// usersSignal.dispose();
/// ```
class NexusSignal<T, ID> {
  NexusSignal._({
    required Signal<List<T>> signal,
    required this.store,
    required StreamSubscription<List<T>> subscription,
  })  : _signal = signal,
        _subscription = subscription;

  /// Creates a [NexusSignal] from a [NexusStore] that watches all items.
  ///
  /// The signal automatically updates when the store emits new data.
  factory NexusSignal.fromStore(
    NexusStore<T, ID> store, {
    Query<T>? query,
  }) {
    final signal = Signal<List<T>>(<T>[]);

    final subscription = store.watchAll(query: query).listen(
      (data) => signal.value = data,
      onError: (Object error) {
        // Errors silently ignored - use NexusStateSignal for error handling
      },
    );

    signal.onDispose(() {
      subscription.cancel();
    });

    return NexusSignal._(
      signal: signal,
      store: store,
      subscription: subscription,
    );
  }

  final Signal<List<T>> _signal;
  final StreamSubscription<List<T>> _subscription;

  /// The underlying store.
  final NexusStore<T, ID> store;

  /// The current value of the signal.
  List<T> get value => _signal.value;

  /// Sets the value of the signal.
  set value(List<T> newValue) => _signal.value = newValue;

  /// Returns the current value without tracking dependencies.
  List<T> peek() => _signal.peek();

  /// Whether this signal has been disposed.
  bool get disposed => _signal.disposed;

  /// Subscribes to changes in this signal.
  ///
  /// Returns an unsubscribe function.
  void Function() subscribe(void Function(List<T> value) callback) {
    return _signal.subscribe(callback);
  }

  /// Refreshes the data by syncing the store.
  Future<void> refresh() async {
    await store.sync();
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
