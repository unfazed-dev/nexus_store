import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

/// Extension methods for Ref to create NexusStore stream providers.
extension NexusStoreRefX on Ref<Object?> {
  /// Watches all items from a NexusStore provider.
  ///
  /// Returns a stream that emits the list of all items whenever the store changes.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final usersProvider = StreamProvider<List<User>>((ref) {
  ///   return ref.watchStoreAll(userStoreProvider);
  /// });
  /// ```
  Stream<List<T>> watchStoreAll<T, ID>(
    ProviderListenable<NexusStore<T, ID>> storeProvider, {
    Query<T>? query,
  }) {
    final store = watch(storeProvider);
    return store.watchAll(query: query);
  }

  /// Watches a single item from a NexusStore provider by ID.
  ///
  /// Returns a stream that emits the item whenever it changes, or null if not found.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userProvider = StreamProvider.family<User?, String>((ref, userId) {
  ///   return ref.watchStoreItem(userStoreProvider, userId);
  /// });
  /// ```
  Stream<T?> watchStoreItem<T, ID>(
    ProviderListenable<NexusStore<T, ID>> storeProvider,
    ID id,
  ) {
    final store = watch(storeProvider);
    return store.watch(id);
  }

  /// Watches all items from a NexusStore provider with status information.
  ///
  /// Returns a stream of [StoreResult] that includes loading/error states
  /// along with the data.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final usersStatusProvider = StreamProvider<StoreResult<List<User>>>((ref) {
  ///   return ref.watchStoreAllWithStatus(userStoreProvider);
  /// });
  /// ```
  Stream<StoreResult<List<T>>> watchStoreAllWithStatus<T, ID>(
    ProviderListenable<NexusStore<T, ID>> storeProvider, {
    Query<T>? query,
  }) {
    final store = watch(storeProvider);
    return store.watchAll(query: query).map(StoreResult.success);
  }
}

/// Extension methods for WidgetRef to access NexusStore data.
extension NexusStoreWidgetRefX on WidgetRef {
  /// Watches all items from a NexusStore provider.
  ///
  /// Returns an AsyncValue that can be used with `.when()` for loading/error handling.
  ///
  /// ## Example
  ///
  /// ```dart
  /// class UserListScreen extends ConsumerWidget {
  ///   @override
  ///   Widget build(BuildContext context, WidgetRef ref) {
  ///     final users = ref.watchStoreAll(userStoreProvider);
  ///     return users.when(
  ///       data: (data) => ListView(...),
  ///       loading: () => CircularProgressIndicator(),
  ///       error: (e, st) => ErrorWidget(e),
  ///     );
  ///   }
  /// }
  /// ```
  AsyncValue<List<T>> watchStoreAll<T, ID>(
    StreamProvider<List<T>> provider,
  ) {
    return watch(provider);
  }

  /// Watches a single item from a NexusStore provider.
  ///
  /// ## Example
  ///
  /// ```dart
  /// class UserDetailScreen extends ConsumerWidget {
  ///   final String userId;
  ///
  ///   @override
  ///   Widget build(BuildContext context, WidgetRef ref) {
  ///     final user = ref.watchStoreItem(userByIdProvider(userId));
  ///     return user.when(...);
  ///   }
  /// }
  /// ```
  AsyncValue<T?> watchStoreItem<T, ID>(
    ProviderListenable<AsyncValue<T?>> provider,
  ) {
    return watch(provider);
  }
}
