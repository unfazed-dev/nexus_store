import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart' hide StateError;

import '../providers/store_provider_bundle.dart';

/// Configuration for a store managed by [RiverpodStoreManager].
///
/// Each config defines a store name, creation function, and optional settings.
///
/// ## Example
///
/// ```dart
/// final userConfig = RiverpodStoreConfig<User, String>(
///   name: 'users',
///   create: (ref) => NexusStore<User, String>(backend: createBackend()),
///   keepAlive: true,
/// );
/// ```
class RiverpodStoreConfig<T, ID> {
  /// Creates a store configuration.
  ///
  /// [name] is the unique identifier for this store.
  /// [create] is the function that creates the store instance.
  /// [keepAlive] controls whether the store stays alive when unused.
  /// [dependencies] lists store names that must be initialized first.
  const RiverpodStoreConfig({
    required this.name,
    required this.create,
    this.keepAlive = false,
    this.dependencies = const [],
  });

  /// The unique name for this store.
  final String name;

  /// The function that creates the store instance.
  final NexusStore<T, ID> Function(Ref ref) create;

  /// Whether to keep the store alive when unused.
  final bool keepAlive;

  /// Names of stores that this store depends on.
  final List<String> dependencies;
}

/// Manages multiple NexusStore instances with coordinated providers.
///
/// This class creates and manages [StoreProviderBundle] instances for
/// multiple stores, providing convenient access and test override support.
///
/// ## Example
///
/// ```dart
/// final storeManager = RiverpodStoreManager([
///   RiverpodStoreConfig<User, String>(
///     name: 'users',
///     create: (ref) => NexusStore(backend: userBackend),
///   ),
///   RiverpodStoreConfig<Post, String>(
///     name: 'posts',
///     create: (ref) => NexusStore(backend: postBackend),
///     dependencies: ['users'],
///   ),
/// ]);
///
/// // Get a bundle
/// final userBundle = storeManager.getBundle<User, String>('users');
///
/// // In tests
/// testWidgets('my test', (tester) async {
///   await tester.pumpWidget(
///     ProviderScope(
///       overrides: storeManager.createOverrides({
///         'users': mockUserStore,
///         'posts': mockPostStore,
///       }),
///       child: MyApp(),
///     ),
///   );
/// });
/// ```
class RiverpodStoreManager {
  /// Creates a manager with the given store configurations.
  ///
  /// Throws [ArgumentError] if duplicate store names are detected.
  RiverpodStoreManager(List<RiverpodStoreConfig<dynamic, dynamic>> configs)
      : _configs = configs {
    // Validate unique names
    final names = <String>{};
    for (final config in configs) {
      if (!names.add(config.name)) {
        throw ArgumentError('Duplicate store name: ${config.name}');
      }
    }
  }

  final List<RiverpodStoreConfig<dynamic, dynamic>> _configs;
  final Map<String, StoreProviderBundle<dynamic, dynamic>> _bundles = {};

  /// Gets the list of all store names.
  List<String> get storeNames => _configs.map((c) => c.name).toList();

  /// Gets a [StoreProviderBundle] by store name.
  ///
  /// Throws [StateError] if the store name doesn't exist.
  ///
  /// The bundle is returned with dynamic type parameters. When accessing
  /// the store, you can cast the provider result to the expected type.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userBundle = storeManager.getBundle('users');
  /// final store = ref.watch(userBundle.storeProvider) as NexusStore<User, String>;
  /// ```
  StoreProviderBundle<dynamic, dynamic> getBundle(String name) {
    final config = _configs.where((c) => c.name == name).firstOrNull;
    if (config == null) {
      throw StateError(
        'Store "$name" not found. Available stores: ${storeNames.join(', ')}',
      );
    }

    return _getOrCreateBundle(name, config);
  }

  /// Gets all store providers in the order they were configured.
  ///
  /// Useful for initializing all stores at app startup.
  List<ProviderListenable<NexusStore<dynamic, dynamic>>> get allStoreProviders {
    return _configs.map((config) {
      final bundle = getBundle(config.name);
      return bundle.storeProvider;
    }).toList();
  }

  /// Creates provider overrides for testing.
  ///
  /// Pass a map of store names to mock store instances.
  /// Throws [StateError] if a store name doesn't exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final overrides = storeManager.createOverrides({
  ///   'users': mockUserStore,
  ///   'posts': mockPostStore,
  /// });
  ///
  /// await tester.pumpWidget(
  ///   ProviderScope(
  ///     overrides: overrides,
  ///     child: MyApp(),
  ///   ),
  /// );
  /// ```
  List<Override> createOverrides(
    Map<String, NexusStore<dynamic, dynamic>> mocks,
  ) {
    final overrides = <Override>[];

    for (final entry in mocks.entries) {
      final name = entry.key;
      final mockStore = entry.value;

      // Verify the store exists
      final config = _configs.where((c) => c.name == name).firstOrNull;
      if (config == null) {
        throw StateError(
          'Store "$name" not found. Available stores: ${storeNames.join(', ')}',
        );
      }

      // Use _getOrCreateBundle to ensure consistent providers
      final bundle = _getOrCreateBundle(name, config);
      final storeProvider = bundle.storeProvider as Provider<dynamic>;
      overrides.add(storeProvider.overrideWithValue(mockStore));
    }

    return overrides;
  }

  /// Gets or creates a bundle and caches it.
  /// This ensures the same providers are used regardless of calling order.
  StoreProviderBundle<dynamic, dynamic> _getOrCreateBundle(
    String name,
    RiverpodStoreConfig<dynamic, dynamic> config,
  ) {
    // If already cached, return it
    final existing = _bundles[name];
    if (existing != null) {
      return existing;
    }

    // Create and cache the bundle
    final bundle = StoreProviderBundle<dynamic, dynamic>.forStore(
      create: config.create,
      name: config.name,
      keepAlive: config.keepAlive,
    );
    _bundles[name] = bundle;
    return bundle;
  }
}
