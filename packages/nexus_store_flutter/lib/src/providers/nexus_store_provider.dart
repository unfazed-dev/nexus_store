/// Provides a [NexusStore] to the widget tree.
library;

import 'package:flutter/widgets.dart';
import 'package:nexus_store/nexus_store.dart';

/// An [InheritedWidget] that provides a [NexusStore] to its descendants.
///
/// Use this widget to make a store available throughout a widget subtree
/// without passing it explicitly through constructors.
///
/// Example:
/// ```dart
/// NexusStoreProvider<User, String>(
///   store: userStore,
///   child: MyApp(),
/// )
///
/// // Later, in a descendant widget:
/// final store = NexusStoreProvider.of<User, String>(context);
/// ```
class NexusStoreProvider<T, ID> extends InheritedWidget {
  /// Creates a provider that makes [store] available to descendants.
  const NexusStoreProvider({
    required this.store,
    required super.child,
    super.key,
  });

  /// The store to provide to descendants.
  final NexusStore<T, ID> store;

  /// Returns the [NexusStore] from the nearest ancestor [NexusStoreProvider].
  ///
  /// Throws a [FlutterError] if no provider is found in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final store = NexusStoreProvider.of<User, String>(context);
  /// ```
  static NexusStore<T, ID> of<T, ID>(BuildContext context) {
    final provider = maybeOf<T, ID>(context);
    if (provider == null) {
      throw FlutterError.fromParts([
        ErrorSummary('NexusStoreProvider.of<$T, $ID> called with a context '
            'that does not contain a NexusStoreProvider<$T, $ID>.'),
        ErrorDescription(
          'No NexusStoreProvider<$T, $ID> ancestor could be found starting '
          'from the context that was passed to '
          'NexusStoreProvider.of<$T, $ID>(). '
          'This can happen if the context you used comes from a widget above '
          'the NexusStoreProvider.',
        ),
        ErrorHint(
          'Make sure that NexusStoreProvider<$T, $ID> is an ancestor of the '
          'context you are using.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return provider;
  }

  /// Returns the [NexusStore] from the nearest ancestor [NexusStoreProvider],
  /// or null if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final store = NexusStoreProvider.maybeOf<User, String>(context);
  /// if (store != null) {
  ///   // Use the store
  /// }
  /// ```
  static NexusStore<T, ID>? maybeOf<T, ID>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<NexusStoreProvider<T, ID>>();
    return provider?.store;
  }

  @override
  bool updateShouldNotify(NexusStoreProvider<T, ID> oldWidget) =>
      store != oldWidget.store;
}
