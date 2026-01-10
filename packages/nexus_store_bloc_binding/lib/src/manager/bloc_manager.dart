import 'dart:async';

import '../bloc/nexus_store_bloc.dart';
import '../bloc/nexus_store_event.dart';
import '../bundle/bloc_store_bundle.dart';
import '../cubit/nexus_store_cubit.dart';
import '../state/nexus_store_state.dart';

/// Manages multiple NexusStore instances with coordinated Blocs/Cubits.
///
/// This class creates and manages [BlocStoreBundle] instances for
/// multiple stores, providing convenient access and coordinated operations.
///
/// ## Example
///
/// ```dart
/// final manager = BlocManager([
///   BlocStoreConfig<User, String>(
///     name: 'users',
///     store: userStore,
///   ),
///   BlocStoreConfig<Post, String>(
///     name: 'posts',
///     store: postStore,
///   ),
/// ]);
///
/// // Get a bundle
/// final userBundle = manager.getBundle('users');
///
/// // Get cubits directly
/// final usersCubit = manager.getListCubit('users');
///
/// // Coordinated operations
/// await manager.refreshAll();
/// final anyLoading = manager.isAnyLoading;
///
/// // Clean up
/// manager.dispose();
/// ```
class BlocManager {
  /// Creates a manager with the given store configurations.
  ///
  /// Throws [ArgumentError] if duplicate store names are detected.
  BlocManager(List<BlocStoreConfig<dynamic, dynamic>> configs)
      : _configs = configs {
    // Validate unique names
    final names = <String>{};
    for (final config in configs) {
      if (!names.add(config.name)) {
        throw ArgumentError('Duplicate store name: ${config.name}');
      }
    }
  }

  final List<BlocStoreConfig<dynamic, dynamic>> _configs;
  final Map<String, BlocStoreBundle<dynamic, dynamic>> _bundles = {};
  bool _isDisposed = false;

  // Stream controllers for coordinated state
  final _loadingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<Object?>.broadcast();

  /// Gets the list of all store names.
  List<String> get storeNames => _configs.map((c) => c.name).toList();

  /// Gets a [BlocStoreBundle] by store name.
  ///
  /// Throws [UnsupportedError] if the store name doesn't exist or manager is disposed.
  ///
  /// The bundle is returned with dynamic type parameters.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userBundle = manager.getBundle('users');
  /// ```
  BlocStoreBundle<dynamic, dynamic> getBundle(String name) {
    _checkDisposed();

    final config = _configs.where((c) => c.name == name).firstOrNull;
    if (config == null) {
      throw UnsupportedError(
        'Store "$name" not found. Available stores: ${storeNames.join(', ')}',
      );
    }

    return _getOrCreateBundle(name, config);
  }

  /// Gets all bundles in the order they were configured.
  List<BlocStoreBundle<dynamic, dynamic>> get allBundles {
    _checkDisposed();
    return _configs.map((config) => getBundle(config.name)).toList();
  }

  /// Gets the list cubit for a store by name.
  ///
  /// This is a convenience method equivalent to:
  /// `manager.getBundle(name).listCubit`
  ///
  /// Throws [UnsupportedError] if the store was configured with useBloc=true.
  NexusStoreCubit<dynamic, dynamic> getListCubit(String name) {
    final bundle = getBundle(name);
    return bundle.listCubit;
  }

  /// Gets the list bloc for a store by name.
  ///
  /// This is a convenience method equivalent to:
  /// `manager.getBundle(name).listBloc`
  ///
  /// Throws [UnsupportedError] if the store was configured with useBloc=false.
  NexusStoreBloc<dynamic, dynamic> getListBloc(String name) {
    final bundle = getBundle(name);
    return bundle.listBloc;
  }

  /// Refreshes all stores by calling load/refresh on each.
  ///
  /// Returns a Future that completes when all stores have started loading.
  Future<void> refreshAll() async {
    _checkDisposed();

    for (final config in _configs) {
      final bundle = getBundle(config.name);
      if (config.useBloc) {
        bundle.listBloc.add(const Refresh<dynamic, dynamic>());
      } else {
        await bundle.listCubit.refresh();
      }
    }
    _updateLoadingState();
  }

  /// Whether any store is currently in a loading state.
  bool get isAnyLoading {
    _checkDisposed();

    for (final bundle in _bundles.values) {
      try {
        if (bundle.listCubit.state.isLoading) {
          return true;
        }
      } catch (_) {
        // Using bloc instead
        try {
          if (bundle.listBloc.state.isLoading) {
            return true;
          }
        } catch (_) {
          // Neither cubit nor bloc available
        }
      }
    }
    return false;
  }

  /// Stream of loading state changes across all stores.
  Stream<bool> get isAnyLoadingStream => _loadingController.stream;

  /// Gets the first error from any store, or null if no errors.
  Object? get firstError {
    _checkDisposed();

    for (final bundle in _bundles.values) {
      try {
        final error = bundle.listCubit.state.error;
        if (error != null) return error;
      } catch (_) {
        try {
          final error = bundle.listBloc.state.error;
          if (error != null) return error;
        } catch (_) {
          // Neither available
        }
      }
    }
    return null;
  }

  /// Stream of errors from any store.
  Stream<Object?> get errorStream => _errorController.stream;

  /// Disposes all bundles and cleans up resources.
  ///
  /// After calling dispose, this manager should not be used.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final bundle in _bundles.values) {
      bundle.close();
    }
    _bundles.clear();

    _loadingController.close();
    _errorController.close();
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw UnsupportedError('BlocManager has been disposed');
    }
  }

  /// Gets or creates a bundle and caches it.
  BlocStoreBundle<dynamic, dynamic> _getOrCreateBundle(
    String name,
    BlocStoreConfig<dynamic, dynamic> config,
  ) {
    final existing = _bundles[name];
    if (existing != null) {
      return existing;
    }

    final bundle = BlocStoreBundle<dynamic, dynamic>.create(
      config: config,
    );
    _bundles[name] = bundle;

    // Set up listeners for coordinated state
    _setupStateListeners(bundle, config);

    return bundle;
  }

  void _setupStateListeners(
    BlocStoreBundle<dynamic, dynamic> bundle,
    BlocStoreConfig<dynamic, dynamic> config,
  ) {
    if (config.useBloc) {
      bundle.listBloc.stream.listen(
        _onStateChanged,
        onError: _onError,
      );
    } else {
      bundle.listCubit.stream.listen(
        _onStateChanged,
        onError: _onError,
      );
    }
  }

  void _onStateChanged(NexusStoreState<dynamic> state) {
    _updateLoadingState();
    if (state.hasError) {
      _errorController.add(state.error);
    }
  }

  void _onError(Object error) {
    _errorController.add(error);
  }

  void _updateLoadingState() {
    if (!_isDisposed) {
      _loadingController.add(isAnyLoading);
    }
  }
}
