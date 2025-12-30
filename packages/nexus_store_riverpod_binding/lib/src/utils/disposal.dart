import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';

/// Configuration for store disposal behavior.
class StoreDisposalConfig {
  /// Creates a disposal configuration.
  const StoreDisposalConfig({
    this.autoDispose = true,
    this.disposeOnClose = true,
  });

  /// Whether to automatically dispose the store when the provider is invalidated.
  final bool autoDispose;

  /// Whether to dispose the store when explicitly closed.
  final bool disposeOnClose;

  /// Default configuration with auto-dispose enabled.
  static const StoreDisposalConfig defaults = StoreDisposalConfig();

  /// Configuration for long-lived stores that should not auto-dispose.
  static const StoreDisposalConfig keepAlive = StoreDisposalConfig(
    autoDispose: false,
  );
}

/// Helper class for managing store lifecycle with keepAlive support.
///
/// Use this when you need more control over when a store is disposed,
/// particularly for stores that should persist but may need manual invalidation.
///
/// ## Example
///
/// ```dart
/// final userStoreProvider = Provider<NexusStoreKeepAlive<User, String>>((ref) {
///   final store = NexusStore<User, String>(backend: createBackend());
///   return NexusStoreKeepAlive(
///     store: store,
///     keepAliveLink: ref.keepAlive(),
///     ref: ref,
///   );
/// });
///
/// // Later, when you want to invalidate and dispose:
/// ref.read(userStoreProvider).invalidate();
/// ```
class NexusStoreKeepAlive<T, ID> {
  /// Creates a keep-alive wrapper for a NexusStore.
  NexusStoreKeepAlive({
    required this.store,
    required this.keepAliveLink,
    required Ref<Object?> ref,
  }) : _ref = ref {
    // Still register disposal for when the provider is eventually disposed
    ref.onDispose(() async {
      await store.dispose();
    });
  }

  /// The wrapped NexusStore.
  final NexusStore<T, ID> store;

  /// The keep-alive link that prevents auto-disposal.
  final KeepAliveLink keepAliveLink;

  final Ref<Object?> _ref;

  /// Manually invalidates the provider and disposes the store.
  ///
  /// Call this when you want to force the store to be recreated.
  void invalidate() {
    keepAliveLink.close();
    _ref.invalidateSelf();
  }

  /// Closes the keep-alive link without invalidating.
  ///
  /// The store will now be disposed when there are no more listeners.
  void allowDispose() {
    keepAliveLink.close();
  }
}

/// Extension for creating keep-alive store providers.
extension NexusStoreKeepAliveX<T, ID> on NexusStore<T, ID> {
  /// Wraps this store with keep-alive support.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userStoreProvider = Provider<NexusStoreKeepAlive<User, String>>((ref) {
  ///   return NexusStore<User, String>(backend: createBackend())
  ///     .withKeepAlive(ref);
  /// });
  /// ```
  NexusStoreKeepAlive<T, ID> withKeepAlive(Ref<Object?> ref) {
    return NexusStoreKeepAlive(
      store: this,
      keepAliveLink: ref.keepAlive(),
      ref: ref,
    );
  }
}

/// Utility for managing multiple store disposals.
class StoreDisposalManager {
  final List<Future<void> Function()> _disposers = [];

  /// Registers a store for disposal.
  void register(NexusStore<dynamic, dynamic> store) {
    _disposers.add(store.dispose);
  }

  /// Disposes all registered stores.
  Future<void> disposeAll() async {
    for (final disposer in _disposers) {
      await disposer();
    }
    _disposers.clear();
  }

  /// Creates a disposal manager bound to a Ref.
  ///
  /// All registered stores will be disposed when the Ref is disposed.
  static StoreDisposalManager forRef(Ref<Object?> ref) {
    final manager = StoreDisposalManager();
    ref.onDispose(manager.disposeAll);
    return manager;
  }
}
