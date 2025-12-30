import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';

/// Extension methods for NexusStore to integrate with Riverpod.
extension NexusStoreRiverpodX<T, ID> on NexusStore<T, ID> {
  /// Binds store disposal to the Ref lifecycle.
  ///
  /// When the Ref is disposed (e.g., when a provider is no longer watched),
  /// the store will be automatically disposed.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  ///   return NexusStore<User, String>(backend: createBackend())
  ///     ..bindToRef(ref);
  /// });
  /// ```
  ///
  /// This is equivalent to:
  ///
  /// ```dart
  /// final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  ///   final store = NexusStore<User, String>(backend: createBackend());
  ///   ref.onDispose(() => store.dispose());
  ///   return store;
  /// });
  /// ```
  void bindToRef(Ref<Object?> ref) {
    ref.onDispose(dispose);
  }

  /// Binds store disposal to an AutoDisposeRef lifecycle.
  ///
  /// Similar to [bindToRef], but for auto-dispose providers.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userStoreProvider = Provider.autoDispose<NexusStore<User, String>>((ref) {
  ///   return NexusStore<User, String>(backend: createBackend())
  ///     ..bindToAutoDisposeRef(ref);
  /// });
  /// ```
  void bindToAutoDisposeRef(AutoDisposeRef<Object?> ref) {
    ref.onDispose(dispose);
  }
}
