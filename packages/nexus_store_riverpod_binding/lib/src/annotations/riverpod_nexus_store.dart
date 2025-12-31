import 'package:meta/meta.dart';

/// Annotation for generating Riverpod providers for NexusStore.
///
/// When applied to a function that returns a NexusStore, the generator will
/// create the following providers:
///
/// - `{name}StoreProvider` - `Provider<NexusStore<T, ID>>`
/// - `{name}Provider` - `StreamProvider<List<T>>` (from watchAll)
/// - `{name}ByIdProvider` - `StreamProvider.family<T?, ID>` (from watch)
/// - `{name}StatusProvider` - `StreamProvider<StoreResult<List<T>>>`
///
/// ## Example
///
/// ```dart
/// @riverpodNexusStore
/// NexusStore<User, String> userStore(UserStoreRef ref) {
///   return NexusStore<User, String>(
///     backend: ref.watch(backendProvider),
///   );
/// }
///
/// // Generated:
/// // - userStoreProvider
/// // - usersProvider (watchAll)
/// // - userByIdProvider (watch family)
/// // - usersStatusProvider (watchWithStatus)
/// ```
@immutable
class RiverpodNexusStore {
  /// Creates a RiverpodNexusStore annotation.
  const RiverpodNexusStore({
    this.keepAlive = false,
    this.name,
  });

  /// Whether to keep the store alive (prevent auto-dispose).
  ///
  /// When `true`, the store will not be disposed when all listeners are removed.
  /// Use this for stores that should persist throughout the app lifecycle.
  ///
  /// Defaults to `false` (auto-dispose enabled).
  final bool keepAlive;

  /// Custom name prefix for generated providers.
  ///
  /// If not specified, the name is derived from the annotated function name.
  /// For example, `userStore` becomes `user` prefix, generating:
  /// - `userStoreProvider`
  /// - `usersProvider`
  /// - `userByIdProvider`
  final String? name;
}

/// Default annotation instance for generating Riverpod providers.
///
/// Use this when you want default settings (auto-dispose enabled, name derived
/// from function).
///
/// ## Example
///
/// ```dart
/// @riverpodNexusStore
/// NexusStore<User, String> userStore(UserStoreRef ref) {
///   return NexusStore<User, String>(backend: createBackend());
/// }
/// ```
const riverpodNexusStore = RiverpodNexusStore();
