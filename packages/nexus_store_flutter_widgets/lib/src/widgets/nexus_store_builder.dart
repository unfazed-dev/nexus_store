/// A widget that watches all items in a [NexusStore].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus_store/nexus_store.dart';

/// A widget that subscribes to [NexusStore.watchAll] and rebuilds on changes.
///
/// This widget automatically handles subscription lifecycle - subscribing
/// in [initState] and disposing in [dispose].
///
/// Example:
/// ```dart
/// NexusStoreBuilder<User, String>(
///   store: userStore,
///   builder: (context, users) => ListView.builder(
///     itemCount: users.length,
///     itemBuilder: (context, i) => Text(users[i].name),
///   ),
/// )
/// ```
///
/// With a query:
/// ```dart
/// NexusStoreBuilder<User, String>(
///   store: userStore,
///   query: Query<User>().where('isActive', isEqualTo: true),
///   builder: (context, activeUsers) => ...,
/// )
/// ```
class NexusStoreBuilder<T, ID> extends StatefulWidget {
  /// Creates a widget that watches all items in a [NexusStore].
  ///
  /// The [store] and [builder] parameters are required.
  const NexusStoreBuilder({
    required this.store,
    required this.builder,
    this.query,
    this.loading,
    this.error,
    super.key,
  });

  /// The store to watch.
  final NexusStore<T, ID> store;

  /// Optional query to filter and order results.
  final Query<T>? query;

  /// Builder called when data is available.
  final Widget Function(BuildContext context, List<T> items) builder;

  /// Widget to show while loading.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loading;

  /// Builder for error states.
  ///
  /// Defaults to a centered error [Text] widget.
  final Widget Function(BuildContext context, Object error)? error;

  @override
  State<NexusStoreBuilder<T, ID>> createState() =>
      _NexusStoreBuilderState<T, ID>();
}

class _NexusStoreBuilderState<T, ID> extends State<NexusStoreBuilder<T, ID>> {
  StreamSubscription<List<T>>? _subscription;
  List<T>? _items;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(NexusStoreBuilder<T, ID> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-subscribe if store or query changed
    if (oldWidget.store != widget.store || oldWidget.query != widget.query) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;

    _subscription = widget.store.watchAll(query: widget.query).listen(
      (items) {
        if (mounted) {
          setState(() {
            _items = items;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (Object err) {
        if (mounted) {
          setState(() {
            _error = err;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildError(context);
    }

    if (_isLoading) {
      return _buildLoading();
    }

    return widget.builder(context, _items ?? []);
  }

  Widget _buildLoading() =>
      widget.loading ?? const Center(child: CircularProgressIndicator());

  Widget _buildError(BuildContext context) {
    if (widget.error != null) {
      return widget.error!(context, _error!);
    }

    return Center(
      child: Text(
        'Error: $_error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
