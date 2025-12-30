import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:signals/signals.dart';

/// A scope for managing signal lifecycles.
///
/// [SignalScope] tracks created signals and provides a way to dispose
/// them all at once. This is useful for managing signals in widgets
/// or other scoped contexts.
///
/// Example:
/// ```dart
/// final scope = SignalScope();
///
/// // Create signals through the scope
/// final counter = scope.createSignal(0);
/// final name = scope.createSignal('');
/// final users = scope.createFromStore(userStore);
///
/// // Dispose all signals at once
/// scope.disposeAll();
/// ```
class SignalScope {
  final List<Signal<dynamic>> _signals = [];
  final List<Computed<dynamic>> _computeds = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isDisposed = false;

  /// Whether this scope has been disposed.
  bool get isDisposed => _isDisposed;

  /// The number of tracked signals.
  int get signalCount => _signals.length + _computeds.length;

  /// Creates a signal and tracks it in this scope.
  ///
  /// The signal will be disposed when [disposeAll] is called.
  Signal<T> createSignal<T>(T initialValue) {
    final signal = Signal<T>(initialValue);
    _signals.add(signal);
    return signal;
  }

  /// Creates a computed signal and tracks it in this scope.
  ///
  /// The computed will be disposed when [disposeAll] is called.
  Computed<T> createComputed<T>(T Function() compute) {
    final comp = computed(compute);
    _computeds.add(comp);
    return comp;
  }

  /// Creates a signal from a NexusStore and tracks it in this scope.
  ///
  /// The signal will be disposed when [disposeAll] is called.
  Signal<List<T>> createFromStore<T, ID>(
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

    _signals.add(signal);
    _subscriptions.add(subscription);

    return signal;
  }

  /// Creates a signal for a single item from a NexusStore and tracks it.
  ///
  /// The signal will be disposed when [disposeAll] is called.
  Signal<T?> createItemFromStore<T, ID>(
    NexusStore<T, ID> store,
    ID id,
  ) {
    final signal = Signal<T?>(null);

    final subscription = store.watch(id).listen(
      (data) => signal.value = data,
      onError: (Object error) {
        // Errors silently ignored
      },
    );

    _signals.add(signal);
    _subscriptions.add(subscription);

    return signal;
  }

  /// Disposes all tracked signals.
  ///
  /// After calling this method, [isDisposed] will return true
  /// and [signalCount] will return 0.
  void disposeAll() {
    if (_isDisposed) return;

    // Cancel all subscriptions first
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Dispose all signals
    for (final signal in _signals) {
      if (!signal.disposed) {
        signal.dispose();
      }
    }
    _signals.clear();

    // Dispose all computed
    for (final comp in _computeds) {
      if (!comp.disposed) {
        comp.dispose();
      }
    }
    _computeds.clear();

    _isDisposed = true;
  }
}

/// A mixin for [State] that provides automatic signal disposal.
///
/// Signals created through [createSignal], [createComputed], or
/// [createFromStore] will be automatically disposed when the
/// widget is disposed.
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with NexusSignalsMixin {
///   late final counter = createSignal(0);
///   late final users = createFromStore(userStore);
///
///   @override
///   Widget build(BuildContext context) {
///     return Watch((context) {
///       return Text('Count: ${counter.value}');
///     });
///   }
///
///   // Signals are automatically disposed when widget is disposed
/// }
/// ```
mixin NexusSignalsMixin<T extends Object> {
  final SignalScope _scope = SignalScope();

  /// Creates a signal that will be automatically disposed.
  Signal<V> createSignal<V>(V initialValue) {
    return _scope.createSignal(initialValue);
  }

  /// Creates a computed signal that will be automatically disposed.
  Computed<V> createComputed<V>(V Function() compute) {
    return _scope.createComputed(compute);
  }

  /// Creates a signal from a store that will be automatically disposed.
  Signal<List<E>> createFromStore<E, ID>(
    NexusStore<E, ID> store, {
    Query<E>? query,
  }) {
    return _scope.createFromStore(store, query: query);
  }

  /// Creates a signal for a single item that will be automatically disposed.
  Signal<E?> createItemFromStore<E, ID>(
    NexusStore<E, ID> store,
    ID id,
  ) {
    return _scope.createItemFromStore(store, id);
  }

  /// Disposes all signals created through this mixin.
  ///
  /// This is automatically called in [dispose] but can be called
  /// manually if needed.
  void disposeSignals() {
    _scope.disposeAll();
  }
}
