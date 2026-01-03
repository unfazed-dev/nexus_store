/// Extension methods for [BuildContext] to access [NexusStore] instances.
library;

import 'package:flutter/widgets.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/src/providers/nexus_store_provider.dart';

/// Extension methods for accessing [NexusStore] from [BuildContext].
extension NexusStoreContextExtensions on BuildContext {
  /// Returns the [NexusStore] from the nearest ancestor [NexusStoreProvider].
  ///
  /// Throws a [FlutterError] if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final store = context.nexusStore<User, String>();
  /// ```
  NexusStore<T, ID> nexusStore<T, ID>() => NexusStoreProvider.of<T, ID>(this);

  /// Returns the [NexusStore] from the nearest ancestor [NexusStoreProvider],
  /// or null if no provider is found.
  ///
  /// Example:
  /// ```dart
  /// final store = context.maybeNexusStore<User, String>();
  /// if (store != null) {
  ///   // Use the store
  /// }
  /// ```
  NexusStore<T, ID>? maybeNexusStore<T, ID>() =>
      NexusStoreProvider.maybeOf<T, ID>(this);

  /// Returns a stream that watches all items in the store.
  ///
  /// This is a convenience method for:
  /// ```dart
  /// context.nexusStore<T, ID>().watchAll(query: query)
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final stream = context.watchNexusStore<User, String>();
  /// ```
  Stream<List<T>> watchNexusStore<T, ID>({Query<T>? query}) =>
      nexusStore<T, ID>().watchAll(query: query);

  /// Returns a stream that watches a single item in the store.
  ///
  /// This is a convenience method for:
  /// ```dart
  /// context.nexusStore<T, ID>().watch(id)
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final stream = context.watchNexusStoreItem<User, String>('user-123');
  /// ```
  Stream<T?> watchNexusStoreItem<T, ID>(ID id) => nexusStore<T, ID>().watch(id);
}
