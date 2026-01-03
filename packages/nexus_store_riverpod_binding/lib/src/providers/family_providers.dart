import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

/// Creates a StreamProvider.family that watches a single item by ID.
///
/// The provider will emit the item whenever it changes, or null if not found.
///
/// ## Example
///
/// ```dart
/// final userStoreProvider = Provider<NexusStore<User, String>>(...);
///
/// final userByIdProvider = createWatchByIdProvider<User, String>(
///   userStoreProvider,
/// );
///
/// // In a widget:
/// class UserDetailScreen extends ConsumerWidget {
///   final String userId;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ref.watch(userByIdProvider(userId)).when(
///       data: (user) => user != null
///         ? UserDetail(user)
///         : Text('User not found'),
///       loading: () => CircularProgressIndicator(),
///       error: (e, st) => ErrorWidget(e),
///     );
///   }
/// }
/// ```
StreamProviderFamily<T?, ID> createWatchByIdProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider,
) {
  return StreamProvider.family<T?, ID>((ref, id) {
    final store = ref.watch(storeProvider);
    return store.watch(id);
  });
}

/// Creates an auto-dispose StreamProvider.family that watches a single item.
///
/// The stream will be automatically cancelled when there are no listeners.
AutoDisposeStreamProviderFamily<T?, ID>
    createAutoDisposeWatchByIdProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider,
) {
  return StreamProvider.autoDispose.family<T?, ID>((ref, id) {
    final store = ref.watch(storeProvider);
    return store.watch(id);
  });
}

/// Creates a StreamProvider.family that watches a single item with status.
///
/// Returns a [StoreResult] that includes loading/error states.
///
/// ## Example
///
/// ```dart
/// final userStatusByIdProvider = createWatchByIdWithStatusProvider<User, String>(
///   userStoreProvider,
/// );
///
/// // In a widget:
/// ref.watch(userStatusByIdProvider(userId)).when(
///   data: (result) => result.when(
///     idle: () => Text('Loading...'),
///     pending: (prev) => UserDetail(prev, isLoading: true),
///     success: (user) => UserDetail(user),
///     error: (e, prev) => UserErrorView(e, fallback: prev),
///   ),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
StreamProviderFamily<StoreResult<T?>, ID>
    createWatchByIdWithStatusProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider,
) {
  return StreamProvider.family<StoreResult<T?>, ID>((ref, id) {
    final store = ref.watch(storeProvider);
    return store.watch(id).map<StoreResult<T?>>(StoreResult.success);
  });
}

/// Creates an auto-dispose StreamProvider.family with status information.
AutoDisposeStreamProviderFamily<StoreResult<T?>, ID>
    createAutoDisposeWatchByIdWithStatusProvider<T, ID>(
  ProviderListenable<NexusStore<T, ID>> storeProvider,
) {
  return StreamProvider.autoDispose.family<StoreResult<T?>, ID>((ref, id) {
    final store = ref.watch(storeProvider);
    return store.watch(id).map<StoreResult<T?>>(StoreResult.success);
  });
}
