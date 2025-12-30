import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';

/// A HookConsumerWidget specialized for NexusStore data.
///
/// Extend this widget when you want to use both Flutter hooks and NexusStore
/// providers in your widget.
///
/// ## Example
///
/// ```dart
/// class UserListScreen extends NexusStoreHookWidget {
///   const UserListScreen({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final users = ref.watch(usersProvider);
///     final isEditing = useState(false);
///
///     return users.when(
///       data: (data) => ListView.builder(
///         itemCount: data.length,
///         itemBuilder: (context, index) => UserTile(data[index]),
///       ),
///       loading: () => const CircularProgressIndicator(),
///       error: (e, st) => ErrorWidget(e),
///     );
///   }
/// }
/// ```
abstract class NexusStoreHookWidget extends HookConsumerWidget {
  /// Creates a NexusStore hook widget.
  const NexusStoreHookWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref);
}

/// Extension on WidgetRef for convenient NexusStore operations.
///
/// Use these methods within a ConsumerWidget or HookConsumerWidget.
extension NexusStoreWidgetRefHooksX on WidgetRef {
  /// Watches all items from a NexusStore StreamProvider.
  ///
  /// Returns an AsyncValue that can be used with `.when()` for state handling.
  ///
  /// ## Example
  ///
  /// ```dart
  /// class UserListScreen extends HookConsumerWidget {
  ///   @override
  ///   Widget build(BuildContext context, WidgetRef ref) {
  ///     final users = ref.watchStoreList(usersProvider);
  ///
  ///     return users.when(
  ///       data: (data) => UserList(data),
  ///       loading: () => const CircularProgressIndicator(),
  ///       error: (e, st) => ErrorWidget(e),
  ///     );
  ///   }
  /// }
  /// ```
  AsyncValue<List<T>> watchStoreList<T>(StreamProvider<List<T>> provider) {
    return watch(provider);
  }

  /// Watches a single item from a NexusStore family provider.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = ref.watchStoreItem(userByIdProvider, userId);
  /// ```
  AsyncValue<T?> watchStoreItem<T, ID>(
    StreamProviderFamily<T?, ID> provider,
    ID id,
  ) {
    return watch(provider(id));
  }

  /// Gets the NexusStore instance for direct operations.
  ///
  /// Use this when you need to call store methods like save() or delete().
  ///
  /// ## Example
  ///
  /// ```dart
  /// final store = ref.readStore(userStoreProvider);
  /// await store.save(newUser);
  /// ```
  NexusStore<T, ID> readStore<T, ID>(
    ProviderListenable<NexusStore<T, ID>> provider,
  ) {
    return read(provider);
  }

  /// Refreshes a NexusStore StreamProvider.
  ///
  /// Invalidates the provider and waits for the new data.
  Future<List<T>> refreshStoreList<T>(StreamProvider<List<T>> provider) async {
    invalidate(provider);
    return read(provider.future);
  }

  /// Refreshes a single item from a NexusStore family provider.
  Future<T?> refreshStoreItem<T, ID>(
    StreamProviderFamily<T?, ID> provider,
    ID id,
  ) async {
    invalidate(provider(id));
    return read(provider(id).future);
  }
}

/// A hook for memoizing store operations.
///
/// Use this when you need to perform async operations on a store
/// and want to avoid recreating callbacks on every rebuild.
///
/// ## Example
///
/// ```dart
/// class UserFormScreen extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final store = ref.watch(userStoreProvider);
///
///     final saveUser = useStoreCallback(
///       store,
///       (store, User user) => store.save(user),
///     );
///
///     return ElevatedButton(
///       onPressed: () => saveUser(User(name: 'New User')),
///       child: const Text('Save'),
///     );
///   }
/// }
/// ```
R Function(A) useStoreCallback<T, ID, A, R>(
  NexusStore<T, ID> store,
  R Function(NexusStore<T, ID> store, A arg) callback, {
  List<Object?>? keys,
}) {
  return useCallback(
    (A arg) => callback(store, arg),
    [store, ...?keys],
  );
}

/// A hook for tracking the loading state of store operations.
///
/// Returns a tuple of (isLoading, execute) where execute wraps an async
/// operation and automatically tracks its loading state.
///
/// ## Example
///
/// ```dart
/// class UserFormScreen extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final store = ref.watch(userStoreProvider);
///     final (isLoading, execute) = useStoreOperation();
///
///     return Column(
///       children: [
///         if (isLoading) const LinearProgressIndicator(),
///         ElevatedButton(
///           onPressed: isLoading
///             ? null
///             : () => execute(() => store.save(User(name: 'Test'))),
///           child: const Text('Save'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
(bool, Future<R> Function<R>(Future<R> Function() operation))
    useStoreOperation() {
  final isLoading = useState(false);

  Future<R> execute<R>(Future<R> Function() operation) async {
    isLoading.value = true;
    try {
      return await operation();
    } finally {
      isLoading.value = false;
    }
  }

  return (isLoading.value, execute);
}

/// A hook that provides debounced store search.
///
/// Useful for search-as-you-type functionality with NexusStore queries.
///
/// ## Example
///
/// ```dart
/// class UserSearchScreen extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final (searchTerm, setSearchTerm) = useStoreDebouncedSearch(
///       duration: const Duration(milliseconds: 300),
///     );
///
///     final users = ref.watch(
///       searchTerm.isEmpty
///         ? usersProvider
///         : filteredUsersProvider(searchTerm),
///     );
///
///     return Column(
///       children: [
///         TextField(onChanged: setSearchTerm),
///         Expanded(child: UserList(users)),
///       ],
///     );
///   }
/// }
/// ```
(String, void Function(String)) useStoreDebouncedSearch({
  Duration duration = const Duration(milliseconds: 300),
  String initialValue = '',
}) {
  final searchTerm = useState(initialValue);
  final debouncedValue = useState(initialValue);

  useEffect(() {
    final timer = Future.delayed(duration, () {
      if (debouncedValue.value != searchTerm.value) {
        debouncedValue.value = searchTerm.value;
      }
    });
    return () {};
  }, [searchTerm.value]);

  return (debouncedValue.value, (value) => searchTerm.value = value);
}

/// A hook for watching async store data with previous value retention.
///
/// Unlike the standard AsyncValue, this hook retains the previous data
/// while loading, making it suitable for optimistic UI updates.
///
/// ## Example
///
/// ```dart
/// class UserListScreen extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final (users, isLoading, error) = useStoreDataWithPrevious(
///       ref.watch(usersProvider),
///     );
///
///     return Stack(
///       children: [
///         if (users != null) UserList(users),
///         if (isLoading) const LinearProgressIndicator(),
///         if (error != null) ErrorBanner(error),
///       ],
///     );
///   }
/// }
/// ```
(T?, bool, Object?) useStoreDataWithPrevious<T>(AsyncValue<T> asyncValue) {
  final previousData = useRef<T?>(null);

  if (asyncValue.hasValue) {
    previousData.value = asyncValue.value;
  }

  return (
    asyncValue.valueOrNull ?? previousData.value,
    asyncValue.isLoading,
    asyncValue.error,
  );
}
