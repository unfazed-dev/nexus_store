/// Provides multiple [NexusStore]s to the widget tree with reduced nesting.
library;

import 'package:flutter/widgets.dart';

/// A function that creates a provider widget with a given child.
typedef ProviderBuilder = Widget Function(Widget child);

/// A widget that nests multiple store providers without deep nesting.
///
/// Instead of writing:
/// ```dart
/// NexusStoreProvider<User, String>(
///   store: userStore,
///   child: NexusStoreProvider<Product, String>(
///     store: productStore,
///     child: NexusStoreProvider<Order, String>(
///       store: orderStore,
///       child: MyApp(),
///     ),
///   ),
/// )
/// ```
///
/// You can write:
/// ```dart
/// MultiNexusStoreProvider(
///   providers: [
///     (child) => NexusStoreProvider<User, String>(
///       store: userStore,
///       child: child,
///     ),
///     (child) => NexusStoreProvider<Product, String>(
///       store: productStore,
///       child: child,
///     ),
///     (child) => NexusStoreProvider<Order, String>(
///       store: orderStore,
///       child: child,
///     ),
///   ],
///   child: MyApp(),
/// )
/// ```
class MultiNexusStoreProvider extends StatelessWidget {
  /// Creates a widget that nests multiple providers.
  ///
  /// The [providers] list must not be empty.
  const MultiNexusStoreProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  /// The list of provider builders to nest.
  ///
  /// Providers are nested from first to last, with the first provider
  /// being the outermost and the last being closest to the child.
  final List<ProviderBuilder> providers;

  /// The widget below all the providers.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var result = child;

    // Nest providers from last to first (reverse order)
    for (var i = providers.length - 1; i >= 0; i--) {
      result = providers[i](result);
    }

    return result;
  }
}
