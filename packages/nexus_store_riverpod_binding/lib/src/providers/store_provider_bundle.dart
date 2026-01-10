import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

import '../extensions/store_extensions.dart';

/// A bundle of providers for a NexusStore.
///
/// This class creates and manages a set of related providers for a single
/// NexusStore, reducing boilerplate when setting up Riverpod providers.
///
/// ## Example
///
/// ```dart
/// final userBundle = StoreProviderBundle.forStore<User, String>(
///   create: (ref) => NexusStore<User, String>(backend: createBackend()),
///   name: 'users',
/// );
///
/// // In a widget:
/// final users = ref.watch(userBundle.allProvider);
/// final user = ref.watch(userBundle.byIdProvider('user-123'));
/// ```
class StoreProviderBundle<T, ID> {
  /// Creates a provider bundle from pre-built providers.
  ///
  /// Prefer using [StoreProviderBundle.forStore] factory instead.
  StoreProviderBundle._({
    required this.storeProvider,
    required this.allProvider,
    required this.byIdProvider,
    required this.statusProvider,
    required this.byIdStatusProvider,
    this.name,
    this.keepAlive = false,
  });

  /// Creates a provider bundle for a NexusStore.
  ///
  /// The [create] function is called to create the store instance.
  /// The [name] is optional and used for debugging.
  /// Set [keepAlive] to `true` to prevent auto-disposal when unused.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userBundle = StoreProviderBundle.forStore<User, String>(
  ///   create: (ref) => NexusStore<User, String>(backend: createBackend()),
  ///   name: 'users',
  ///   keepAlive: true,
  /// );
  /// ```
  factory StoreProviderBundle.forStore({
    required NexusStore<T, ID> Function(Ref ref) create,
    String? name,
    bool keepAlive = false,
  }) {
    // Create the store provider
    final storeProvider = Provider<NexusStore<T, ID>>((ref) {
      final store = create(ref);
      store.bindToRef(ref);
      return store;
    });

    // Create all items stream provider
    final allProvider = StreamProvider<List<T>>((ref) {
      final store = ref.watch(storeProvider);
      return store.watchAll();
    });

    // Create by-ID family provider
    final byIdProvider = StreamProvider.family<T?, ID>((ref, id) {
      final store = ref.watch(storeProvider);
      return store.watch(id);
    });

    // Create status provider with StoreResult wrapper
    final statusProvider = StreamProvider<StoreResult<List<T>>>((ref) {
      final store = ref.watch(storeProvider);
      return store.watchAll().map<StoreResult<List<T>>>(StoreResult.success);
    });

    // Create by-ID status family provider
    final byIdStatusProvider =
        StreamProvider.family<StoreResult<T?>, ID>((ref, id) {
      final store = ref.watch(storeProvider);
      return store.watch(id).map<StoreResult<T?>>(StoreResult.success);
    });

    return StoreProviderBundle<T, ID>._(
      storeProvider: storeProvider,
      allProvider: allProvider,
      byIdProvider: byIdProvider,
      statusProvider: statusProvider,
      byIdStatusProvider: byIdStatusProvider,
      name: name,
      keepAlive: keepAlive,
    );
  }

  /// The provider for the NexusStore instance.
  final ProviderListenable<NexusStore<T, ID>> storeProvider;

  /// StreamProvider that emits all items from the store.
  final StreamProvider<List<T>> allProvider;

  /// StreamProvider.family that emits a single item by ID.
  final StreamProviderFamily<T?, ID> byIdProvider;

  /// StreamProvider that emits all items wrapped in StoreResult.
  final StreamProvider<StoreResult<List<T>>> statusProvider;

  /// StreamProvider.family that emits a single item wrapped in StoreResult.
  final StreamProviderFamily<StoreResult<T?>, ID> byIdStatusProvider;

  /// Optional name for debugging.
  final String? name;

  /// Whether to keep the store alive when unused.
  final bool keepAlive;
}
