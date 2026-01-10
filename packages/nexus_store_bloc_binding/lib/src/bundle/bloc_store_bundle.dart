import 'package:nexus_store/nexus_store.dart';

import '../bloc/nexus_store_bloc.dart';
import '../bloc/nexus_store_event.dart';
import '../cubit/nexus_item_cubit.dart';
import '../cubit/nexus_store_cubit.dart';

/// Configuration for loading state behavior.
///
/// Controls how the bundle handles loading states, debouncing, and retries.
///
/// ## Example
///
/// ```dart
/// final loadingConfig = LoadingStateConfig(
///   showPreviousDataWhileLoading: true,
///   debounceMs: 300,
///   retryCount: 3,
/// );
/// ```
class LoadingStateConfig {
  /// Creates a loading state configuration.
  const LoadingStateConfig({
    this.showPreviousDataWhileLoading = false,
    this.debounceMs,
    this.retryCount,
    this.retryDelayMs = 1000,
  });

  /// Whether to show previous data while loading new data.
  final bool showPreviousDataWhileLoading;

  /// Debounce delay in milliseconds for load operations.
  final int? debounceMs;

  /// Number of retry attempts on failure.
  final int? retryCount;

  /// Delay between retries in milliseconds.
  final int retryDelayMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingStateConfig &&
          runtimeType == other.runtimeType &&
          showPreviousDataWhileLoading == other.showPreviousDataWhileLoading &&
          debounceMs == other.debounceMs &&
          retryCount == other.retryCount &&
          retryDelayMs == other.retryDelayMs;

  @override
  int get hashCode => Object.hash(
        showPreviousDataWhileLoading,
        debounceMs,
        retryCount,
        retryDelayMs,
      );

  @override
  String toString() => 'LoadingStateConfig('
      'showPreviousDataWhileLoading: $showPreviousDataWhileLoading, '
      'debounceMs: $debounceMs, '
      'retryCount: $retryCount, '
      'retryDelayMs: $retryDelayMs)';
}

/// Configuration for a store managed by [BlocStoreBundle].
///
/// Each config defines a store name, store instance, and optional settings.
///
/// ## Example
///
/// ```dart
/// final userConfig = BlocStoreConfig<User, String>(
///   name: 'users',
///   store: userStore,
///   useBloc: true, // Use Bloc instead of Cubit
///   loadingStateConfig: LoadingStateConfig(
///     showPreviousDataWhileLoading: true,
///     debounceMs: 300,
///   ),
/// );
/// ```
class BlocStoreConfig<T, ID> {
  /// Creates a store configuration.
  ///
  /// [name] is the unique identifier for this store.
  /// [store] is the NexusStore instance to wrap.
  /// [useBloc] determines whether to use Bloc (event-driven) or Cubit (simpler).
  /// [autoLoad] determines whether to load data immediately on creation.
  /// [loadingStateConfig] configures loading behavior.
  const BlocStoreConfig({
    required this.name,
    required this.store,
    this.useBloc = false,
    this.autoLoad = true,
    this.loadingStateConfig,
  });

  /// The unique name for this store.
  final String name;

  /// The NexusStore instance.
  final NexusStore<T, ID> store;

  /// Whether to use Bloc (event-driven) instead of Cubit (simpler).
  ///
  /// Default is false (uses Cubit).
  final bool useBloc;

  /// Whether to automatically load data on creation.
  ///
  /// Default is true.
  final bool autoLoad;

  /// Configuration for loading state behavior.
  final LoadingStateConfig? loadingStateConfig;
}

/// A bundle of Blocs/Cubits for a NexusStore.
///
/// This class creates and manages all Blocs/Cubits related to a single store:
/// - [listCubit] or [listBloc] - The main list cubit/bloc
/// - [itemCubit] - Factory method for item-specific cubits
///
/// ## Example
///
/// ```dart
/// final userBundle = BlocStoreBundle.create(
///   config: BlocStoreConfig<User, String>(
///     name: 'users',
///     store: userStore,
///   ),
/// );
///
/// // Access the list cubit
/// final users = userBundle.listCubit.state;
///
/// // Access an item cubit
/// final userCubit = userBundle.itemCubit('user-123');
///
/// // Close when done
/// await userBundle.close();
/// ```
class BlocStoreBundle<T, ID> {
  BlocStoreBundle._({
    required this.name,
    required this.store,
    required NexusStoreCubit<T, ID>? listCubit,
    required NexusStoreBloc<T, ID>? listBloc,
  })  : _listCubit = listCubit,
        _listBloc = listBloc;

  /// Creates a [BlocStoreBundle] from a [BlocStoreConfig].
  ///
  /// The bundle will create either a Cubit or Bloc based on [BlocStoreConfig.useBloc],
  /// and optionally auto-load based on [BlocStoreConfig.autoLoad].
  factory BlocStoreBundle.create({
    required BlocStoreConfig<T, ID> config,
  }) {
    NexusStoreCubit<T, ID>? cubit;
    NexusStoreBloc<T, ID>? bloc;

    if (config.useBloc) {
      bloc = NexusStoreBloc<T, ID>(config.store);
      if (config.autoLoad) {
        bloc.add(LoadAll<T, ID>());
      }
    } else {
      cubit = NexusStoreCubit<T, ID>(config.store);
      if (config.autoLoad) {
        cubit.load();
      }
    }

    return BlocStoreBundle._(
      name: config.name,
      store: config.store,
      listCubit: cubit,
      listBloc: bloc,
    );
  }

  /// The name of this store bundle.
  final String name;

  /// The underlying NexusStore.
  final NexusStore<T, ID> store;

  final NexusStoreCubit<T, ID>? _listCubit;
  final NexusStoreBloc<T, ID>? _listBloc;
  final Map<ID, NexusItemCubit<T, ID>> _itemCubits = {};

  /// The list cubit for this store.
  ///
  /// Throws [UnsupportedError] if the bundle was created with [BlocStoreConfig.useBloc] = true.
  NexusStoreCubit<T, ID> get listCubit {
    final cubit = _listCubit;
    if (cubit == null) {
      throw UnsupportedError(
        'listCubit is not available. This bundle was created with useBloc=true. '
        'Use listBloc instead.',
      );
    }
    return cubit;
  }

  /// The list bloc for this store.
  ///
  /// Throws [UnsupportedError] if the bundle was created with [BlocStoreConfig.useBloc] = false.
  NexusStoreBloc<T, ID> get listBloc {
    final bloc = _listBloc;
    if (bloc == null) {
      throw UnsupportedError(
        'listBloc is not available. This bundle was created with useBloc=false. '
        'Use listCubit instead.',
      );
    }
    return bloc;
  }

  /// Creates or retrieves an item cubit for the given ID.
  ///
  /// Item cubits are cached and reused for the same ID.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userCubit = bundle.itemCubit('user-123');
  /// await userCubit.load();
  /// ```
  NexusItemCubit<T, ID> itemCubit(ID id) {
    return _itemCubits.putIfAbsent(
      id,
      () => NexusItemCubit<T, ID>(store, id),
    );
  }

  /// Closes all cubits/blocs and cleans up resources.
  ///
  /// After calling close, this bundle should not be used.
  Future<void> close() async {
    await _listCubit?.close();
    await _listBloc?.close();

    for (final cubit in _itemCubits.values) {
      await cubit.close();
    }
    _itemCubits.clear();
  }
}
