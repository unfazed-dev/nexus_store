/// Riverpod integration for NexusStore.
///
/// This library provides Riverpod providers, extensions, widgets, and hooks
/// for seamless integration with NexusStore data.
///
/// ## Basic Usage
///
/// ```dart
/// // Create a store provider
/// final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
///   final store = NexusStore<User, String>(backend: createBackend());
///   ref.onDispose(() => store.dispose());
///   return store;
/// });
///
/// // Create stream providers for reactive data
/// final usersProvider = StreamProvider<List<User>>((ref) {
///   return ref.watch(userStoreProvider).watchAll();
/// });
///
/// // Use in a widget
/// class UserListScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ref.watch(usersProvider).when(
///       data: (users) => ListView(...),
///       loading: () => CircularProgressIndicator(),
///       error: (e, st) => ErrorWidget(e),
///     );
///   }
/// }
/// ```
///
/// ## With Extensions
///
/// ```dart
/// // Cleaner with bindToRef extension
/// final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
///   return NexusStore<User, String>(backend: createBackend())
///     ..bindToRef(ref);
/// });
/// ```
library;

// Annotations
export 'src/annotations/riverpod_nexus_store.dart';

// Extensions
export 'src/extensions/ref_extensions.dart';
export 'src/extensions/store_extensions.dart';

// Providers
export 'src/providers/family_providers.dart';
export 'src/providers/nexus_store_provider.dart';
export 'src/providers/stream_providers.dart';

// Utils
export 'src/utils/disposal.dart';

// Widgets
export 'src/widgets/nexus_store_consumer.dart';
export 'src/widgets/nexus_store_hooks.dart';
