import 'package:signals/signals.dart';

import '../bundle/signals_store_bundle.dart';
import '../signals/nexus_list_signal.dart';
import '../state/nexus_signal_state.dart';

/// Manages multiple NexusStore instances with coordinated signals.
///
/// This class creates and manages [SignalsStoreBundle] instances for
/// multiple stores, providing convenient access and cross-store computed
/// signals.
///
/// ## Example
///
/// ```dart
/// final manager = SignalsManager([
///   SignalsStoreConfig<User, String>(
///     name: 'users',
///     store: userStore,
///   ),
///   SignalsStoreConfig<Post, String>(
///     name: 'posts',
///     store: postStore,
///   ),
/// ]);
///
/// // Get a bundle
/// final userBundle = manager.getBundle('users');
///
/// // Get signals directly
/// final usersSignal = manager.getListSignal<User, String>('users');
///
/// // Cross-store computed
/// final totalCount = manager.createCrossStoreComputed<int>(
///   'totalCount',
///   (bundles) => bundles['users']!.listSignal.length +
///                bundles['posts']!.listSignal.length,
/// );
///
/// // Clean up
/// manager.dispose();
/// ```
class SignalsManager {
  /// Creates a manager with the given store configurations.
  ///
  /// Throws [ArgumentError] if duplicate store names are detected.
  SignalsManager(List<SignalsStoreConfig<dynamic, dynamic>> configs)
      : _configs = configs {
    // Validate unique names
    final names = <String>{};
    for (final config in configs) {
      if (!names.add(config.name)) {
        throw ArgumentError('Duplicate store name: ${config.name}');
      }
    }
  }

  final List<SignalsStoreConfig<dynamic, dynamic>> _configs;
  final Map<String, SignalsStoreBundle<dynamic, dynamic>> _bundles = {};
  final List<Computed<dynamic>> _crossStoreComputeds = [];

  /// Gets the list of all store names.
  List<String> get storeNames => _configs.map((c) => c.name).toList();

  /// Gets a [SignalsStoreBundle] by store name.
  ///
  /// Throws [StateError] if the store name doesn't exist.
  ///
  /// The bundle is returned with dynamic type parameters. When accessing
  /// the signals, cast to the expected types.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userBundle = manager.getBundle('users');
  /// final users = userBundle.listSignal.value as List<User>;
  /// ```
  SignalsStoreBundle<dynamic, dynamic> getBundle(String name) {
    final config = _configs.where((c) => c.name == name).firstOrNull;
    if (config == null) {
      throw StateError(
        'Store "$name" not found. Available stores: ${storeNames.join(', ')}',
      );
    }

    return _getOrCreateBundle(name, config);
  }

  /// Gets all bundles in the order they were configured.
  List<SignalsStoreBundle<dynamic, dynamic>> get allBundles {
    return _configs.map((config) => getBundle(config.name)).toList();
  }

  /// Gets the list signal for a store by name.
  ///
  /// This is a convenience method equivalent to:
  /// `manager.getBundle(name).listSignal`
  ///
  /// Note: Due to Dart's type system, returns dynamic-typed signal.
  /// Cast values when accessing: `listSignal.value as List<User>`
  ///
  /// Throws [StateError] if the store name doesn't exist.
  NexusListSignal<dynamic, dynamic> getListSignal(String name) {
    final bundle = getBundle(name);
    return bundle.listSignal;
  }

  /// Gets the state signal for a store by name.
  ///
  /// This is a convenience method equivalent to:
  /// `manager.getBundle(name).stateSignal`
  ///
  /// Note: Due to Dart's type system, returns dynamic-typed signal.
  ///
  /// Throws [StateError] if the store name doesn't exist.
  Signal<NexusSignalState<dynamic>> getStateSignal(String name) {
    final bundle = getBundle(name);
    return bundle.stateSignal;
  }

  /// Creates a computed signal that depends on multiple stores.
  ///
  /// The compute function receives a map of all bundles by name,
  /// allowing you to derive state from multiple stores.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userPostCount = manager.createCrossStoreComputed<Map<String, int>>(
  ///   'userPostCount',
  ///   (bundles) {
  ///     final users = bundles['users']!.listSignal.value as List<User>;
  ///     final posts = bundles['posts']!.listSignal.value as List<Post>;
  ///     return Map.fromEntries(
  ///       users.map((u) => MapEntry(
  ///         u.id,
  ///         posts.where((p) => p.userId == u.id).length,
  ///       )),
  ///     );
  ///   },
  /// );
  /// ```
  Computed<R> createCrossStoreComputed<R>(
    String name,
    R Function(Map<String, SignalsStoreBundle<dynamic, dynamic>> bundles)
        compute,
  ) {
    // Ensure all bundles are created
    final bundles = <String, SignalsStoreBundle<dynamic, dynamic>>{};
    for (final config in _configs) {
      bundles[config.name] = getBundle(config.name);
    }

    final crossComputed = computed(() => compute(bundles));
    _crossStoreComputeds.add(crossComputed);
    return crossComputed;
  }

  /// Disposes all bundles and cross-store computed signals.
  ///
  /// After calling dispose, this manager should not be used.
  void dispose() {
    for (final bundle in _bundles.values) {
      bundle.dispose();
    }
    _bundles.clear();

    for (final computed in _crossStoreComputeds) {
      computed.dispose();
    }
    _crossStoreComputeds.clear();
  }

  /// Gets or creates a bundle and caches it.
  SignalsStoreBundle<dynamic, dynamic> _getOrCreateBundle(
    String name,
    SignalsStoreConfig<dynamic, dynamic> config,
  ) {
    final existing = _bundles[name];
    if (existing != null) {
      return existing;
    }

    final bundle = SignalsStoreBundle<dynamic, dynamic>.create(
      config: config,
    );
    _bundles[name] = bundle;
    return bundle;
  }
}
