/// Flutter extension for nexus_store with StreamBuilder widgets and providers.
///
/// This package provides Flutter-specific utilities for working with
/// [NexusStore] including:
///
/// - **StoreResult**: A sealed class for representing async states
/// - **Widgets**: StreamBuilder-style widgets for reactive UI
/// - **Providers**: InheritedWidget-based dependency injection
/// - **Extensions**: BuildContext extensions for convenient store access
/// - **Utilities**: Lifecycle observers for background sync management
///
/// ## Quick Start
///
/// ```dart
/// import 'package:nexus_store/nexus_store.dart';
/// import 'package:nexus_store_flutter/nexus_store_flutter.dart';
///
/// // Provide a store to the widget tree
/// NexusStoreProvider<User, String>(
///   store: userStore,
///   child: MyApp(),
/// )
///
/// // Use a builder widget to display data
/// NexusStoreBuilder<User, String>(
///   store: context.nexusStore<User, String>(),
///   builder: (context, users) => ListView(
///     children: users.map((u) => Text(u.name)).toList(),
///   ),
/// )
/// ```
library;

export 'src/extensions/build_context_extensions.dart';
export 'src/providers/multi_nexus_store_provider.dart';
export 'src/providers/nexus_store_provider.dart';
export 'src/types/store_result.dart';
export 'src/utils/store_lifecycle_observer.dart';
export 'src/widgets/nexus_store_builder.dart';
export 'src/widgets/nexus_store_item_builder.dart';
export 'src/widgets/pagination_state_builder.dart';
export 'src/widgets/store_result_builder.dart';
export 'src/widgets/store_result_stream_builder.dart';
