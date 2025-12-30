import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

/// Creates a StreamProvider that watches all items from a NexusStore.
///
/// The provider will emit the list of all items whenever the store changes.
///
/// ## Example
///
/// ```dart
/// final userStoreProvider = Provider<NexusStore<User, String>>(...);
///
/// final usersProvider = createWatchAllProvider<User, String>(
///   userStoreProvider,
/// );
///
/// // In a widget:
/// ref.watch(usersProvider).when(
///   data: (users) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// With a query filter:
///
/// ```dart
/// final activeUsersProvider = createWatchAllProvider<User, String>(
///   userStoreProvider,
///   query: Query<User>().where((u) => u.isActive),
/// );
/// ```
StreamProvider<List<T>> createWatchAllProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider, {
  Query<T>? query,
}) {
  return StreamProvider<List<T>>((ref) {
    final store = ref.watch(storeProvider);
    return store.watchAll(query: query);
  });
}

/// Creates an auto-dispose StreamProvider that watches all items.
///
/// The stream will be automatically cancelled when there are no listeners.
AutoDisposeStreamProvider<List<T>> createAutoDisposeWatchAllProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider, {
  Query<T>? query,
}) {
  return StreamProvider.autoDispose<List<T>>((ref) {
    final store = ref.watch(storeProvider);
    return store.watchAll(query: query);
  });
}

/// Creates a StreamProvider that watches all items with status information.
///
/// Returns a [StoreResult] that includes loading/error states along with data.
///
/// ## Example
///
/// ```dart
/// final usersStatusProvider = createWatchWithStatusProvider<User, String>(
///   userStoreProvider,
/// );
///
/// // In a widget:
/// ref.watch(usersStatusProvider).when(
///   data: (result) => result.when(
///     idle: () => Text('Idle'),
///     pending: (prev) => Stack([UserList(prev ?? []), LoadingIndicator()]),
///     success: (users) => UserList(users),
///     error: (e, prev) => ErrorWithRetry(e, prev),
///   ),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
StreamProvider<StoreResult<List<T>>> createWatchWithStatusProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider, {
  Query<T>? query,
}) {
  return StreamProvider<StoreResult<List<T>>>((ref) {
    final store = ref.watch(storeProvider);
    return store
        .watchAll(query: query)
        .map<StoreResult<List<T>>>(StoreResult.success);
  });
}

/// Creates an auto-dispose StreamProvider with status information.
AutoDisposeStreamProvider<StoreResult<List<T>>>
    createAutoDisposeWatchWithStatusProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider, {
  Query<T>? query,
}) {
  return StreamProvider.autoDispose<StoreResult<List<T>>>((ref) {
    final store = ref.watch(storeProvider);
    return store
        .watchAll(query: query)
        .map<StoreResult<List<T>>>(StoreResult.success);
  });
}
