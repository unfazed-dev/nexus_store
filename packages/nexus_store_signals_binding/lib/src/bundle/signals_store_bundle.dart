import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:signals/signals.dart';

import '../signals/nexus_list_signal.dart';
import '../state/nexus_signal_state.dart';

/// Type alias for computed signal factory function.
typedef ComputedFactory<T, R> = Computed<R> Function(
    Signal<List<T>> listSignal);

/// Configuration for a store managed by [SignalsStoreBundle].
///
/// Each config defines a store name, store instance, and optional computed
/// signals.
///
/// ## Example
///
/// ```dart
/// final userConfig = SignalsStoreConfig<User, String>(
///   name: 'users',
///   store: userStore,
///   computedSignals: {
///     'activeCount': (list) => computed(() => list.value.where((u) => u.isActive).length),
///   },
/// );
/// ```
class SignalsStoreConfig<T, ID> {
  /// Creates a store configuration.
  ///
  /// [name] is the unique identifier for this store.
  /// [store] is the NexusStore instance to wrap.
  /// [computedSignals] is a map of named computed signal factories.
  const SignalsStoreConfig({
    required this.name,
    required this.store,
    this.computedSignals = const {},
  });

  /// The unique name for this store.
  final String name;

  /// The NexusStore instance.
  final NexusStore<T, ID> store;

  /// Map of named computed signal factories.
  ///
  /// Each factory receives the list signal and should return a computed signal.
  final Map<String, ComputedFactory<T, dynamic>> computedSignals;
}

/// A bundle of signals for a NexusStore.
///
/// This class creates and manages all signals related to a single store:
/// - [listSignal] - The main list signal with CRUD methods
/// - [stateSignal] - Loading/error state tracking
/// - Named computed signals for derived data
///
/// ## Example
///
/// ```dart
/// final userBundle = SignalsStoreBundle.create(
///   config: SignalsStoreConfig<User, String>(
///     name: 'users',
///     store: userStore,
///     computedSignals: {
///       'activeCount': (list) => computed(
///         () => list.value.where((u) => u.isActive).length,
///       ),
///     },
///   ),
/// );
///
/// // Access signals
/// final users = userBundle.listSignal.value;
/// final state = userBundle.stateSignal.value;
/// final activeCount = userBundle.computed<int>('activeCount');
///
/// // Dispose when done
/// userBundle.dispose();
/// ```
class SignalsStoreBundle<T, ID> {
  SignalsStoreBundle._({
    required this.name,
    required this.listSignal,
    required Signal<NexusSignalState<T>> stateSignal,
    required StreamSubscription<List<T>> subscription,
    required Map<String, Computed<dynamic>> computedSignals,
  })  : _stateSignal = stateSignal,
        _subscription = subscription,
        _computedSignals = computedSignals;

  /// Creates a [SignalsStoreBundle] from a [SignalsStoreConfig].
  ///
  /// The bundle will automatically subscribe to store changes and update
  /// all signals accordingly.
  factory SignalsStoreBundle.create({
    required SignalsStoreConfig<T, ID> config,
    Query<T>? query,
  }) {
    // Create list signal using existing NexusListSignal
    final listSignal = NexusListSignal<T, ID>.fromStore(config.store);

    // Create state signal for loading/error tracking
    final stateSignal = Signal<NexusSignalState<T>>(
      const NexusSignalInitial(),
    );

    // Subscribe to store changes to update state signal
    final subscription = config.store.watchAll(query: query).listen(
      (data) {
        stateSignal.value = NexusSignalData<T>(data: data);
      },
      onError: (Object error, StackTrace stackTrace) {
        stateSignal.value = NexusSignalError<T>(
          error: error,
          stackTrace: stackTrace,
          previousData: stateSignal.value.dataOrNull,
        );
      },
    );

    // Create the underlying signal for computed factories
    final underlyingSignal = Signal<List<T>>([]);
    config.store.watchAll(query: query).listen(
      (data) => underlyingSignal.value = data,
      onError: (Object _) {
        // Errors silently ignored for computed signals
        // The stateSignal will capture errors
      },
    );

    // Create computed signals from config
    final computedSignals = <String, Computed<dynamic>>{};
    for (final entry in config.computedSignals.entries) {
      computedSignals[entry.key] = entry.value(underlyingSignal);
    }

    return SignalsStoreBundle._(
      name: config.name,
      listSignal: listSignal,
      stateSignal: stateSignal,
      subscription: subscription,
      computedSignals: computedSignals,
    );
  }

  /// The name of this store bundle.
  final String name;

  /// The list signal for this store.
  ///
  /// Provides access to the list data with CRUD helper methods.
  final NexusListSignal<T, ID> listSignal;

  final Signal<NexusSignalState<T>> _stateSignal;
  final StreamSubscription<List<T>> _subscription;
  final Map<String, Computed<dynamic>> _computedSignals;

  /// The state signal for loading/error tracking.
  ///
  /// Use this for optimistic UI patterns:
  /// ```dart
  /// bundle.stateSignal.value.when(
  ///   initial: () => Text('Ready'),
  ///   loading: (prev) => CircularProgressIndicator(),
  ///   data: (users) => UserList(users: users),
  ///   error: (e, st, prev) => Text('Error: $e'),
  /// );
  /// ```
  Signal<NexusSignalState<T>> get stateSignal => _stateSignal;

  /// Gets a named computed signal by name.
  ///
  /// Returns null if no computed signal with the given name exists.
  ///
  /// Note: Due to Dart's type system limitations, the returned Computed
  /// has a dynamic value type. Cast the value when accessing:
  ///
  /// ```dart
  /// final activeCount = bundle.computed('activeCount');
  /// if (activeCount != null) {
  ///   print('Active users: ${activeCount.value as int}');
  /// }
  /// ```
  Computed<dynamic>? computed(String name) {
    return _computedSignals[name];
  }

  /// Gets the names of all configured computed signals.
  List<String> get computedNames => _computedSignals.keys.toList();

  /// Disposes all signals and cleans up resources.
  ///
  /// After calling dispose, this bundle should not be used.
  void dispose() {
    _subscription.cancel();
    listSignal.dispose();
    _stateSignal.dispose();
    for (final computed in _computedSignals.values) {
      computed.dispose();
    }
  }
}
