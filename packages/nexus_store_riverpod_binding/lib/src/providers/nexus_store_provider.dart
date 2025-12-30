import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';

import '../extensions/store_extensions.dart';

/// Creates a Provider for a NexusStore with optional automatic disposal.
///
/// This is a convenience function for creating store providers with proper
/// lifecycle management.
///
/// ## Example
///
/// ```dart
/// final userStoreProvider = createNexusStoreProvider<User, String>(
///   (ref) => NexusStore<User, String>(backend: createBackend()),
/// );
/// ```
///
/// With auto-dispose disabled (for long-lived stores):
///
/// ```dart
/// final userStoreProvider = createNexusStoreProvider<User, String>(
///   (ref) => NexusStore<User, String>(backend: createBackend()),
///   autoDispose: false,
/// );
/// ```
Provider<NexusStore<T, ID>> createNexusStoreProvider<T, ID>(
  NexusStore<T, ID> Function(Ref ref) create, {
  bool autoDispose = true,
}) {
  return Provider<NexusStore<T, ID>>((ref) {
    final store = create(ref);
    if (autoDispose) {
      store.bindToRef(ref);
    }
    return store;
  });
}

/// Creates an auto-dispose Provider for a NexusStore.
///
/// The store will be automatically disposed when there are no more listeners.
///
/// ## Example
///
/// ```dart
/// final userStoreProvider = createAutoDisposeNexusStoreProvider<User, String>(
///   (ref) => NexusStore<User, String>(backend: createBackend()),
/// );
/// ```
AutoDisposeProvider<NexusStore<T, ID>>
    createAutoDisposeNexusStoreProvider<T, ID>(
  NexusStore<T, ID> Function(AutoDisposeRef<NexusStore<T, ID>> ref) create,
) {
  return Provider.autoDispose<NexusStore<T, ID>>((ref) {
    final store = create(ref);
    store.bindToAutoDisposeRef(ref);
    return store;
  });
}

/// Options for configuring a NexusStore provider.
class NexusStoreProviderOptions {
  /// Creates options for a NexusStore provider.
  const NexusStoreProviderOptions({
    this.autoDispose = true,
    this.name,
  });

  /// Whether to automatically dispose the store when there are no listeners.
  ///
  /// Defaults to `true`.
  final bool autoDispose;

  /// Optional name for debugging purposes.
  final String? name;
}
