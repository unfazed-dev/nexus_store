/// A widget that watches a single item in a [NexusStore].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus_store/nexus_store.dart';

/// A widget that subscribes to [NexusStore.watch] for a single item.
///
/// This widget automatically handles subscription lifecycle - subscribing
/// in [initState] and disposing in [dispose].
///
/// Example:
/// ```dart
/// NexusStoreItemBuilder<User, String>(
///   store: userStore,
///   id: 'user-123',
///   builder: (context, user) => user != null
///     ? Text(user.name)
///     : Text('User not found'),
/// )
/// ```
class NexusStoreItemBuilder<T, ID> extends StatefulWidget {
  /// Creates a widget that watches a single item in a [NexusStore].
  ///
  /// The [store], [id], and [builder] parameters are required.
  const NexusStoreItemBuilder({
    required this.store,
    required this.id,
    required this.builder,
    this.loading,
    this.error,
    super.key,
  });

  /// The store to watch.
  final NexusStore<T, ID> store;

  /// The ID of the item to watch.
  final ID id;

  /// Builder called when data is available.
  ///
  /// The item may be null if not found.
  final Widget Function(BuildContext context, T? item) builder;

  /// Widget to show while loading.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loading;

  /// Builder for error states.
  ///
  /// Defaults to a centered error [Text] widget.
  final Widget Function(BuildContext context, Object error)? error;

  @override
  State<NexusStoreItemBuilder<T, ID>> createState() =>
      _NexusStoreItemBuilderState<T, ID>();
}

class _NexusStoreItemBuilderState<T, ID>
    extends State<NexusStoreItemBuilder<T, ID>> {
  StreamSubscription<T?>? _subscription;
  T? _item;
  Object? _error;
  bool _isLoading = true;
  bool _hasReceivedData = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(NexusStoreItemBuilder<T, ID> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-subscribe if store or id changed
    if (oldWidget.store != widget.store || oldWidget.id != widget.id) {
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
    _hasReceivedData = false;

    _subscription = widget.store.watch(widget.id).listen(
      (item) {
        if (mounted) {
          setState(() {
            _item = item;
            _isLoading = false;
            _error = null;
            _hasReceivedData = true;
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

    if (_isLoading && !_hasReceivedData) {
      return _buildLoading();
    }

    return widget.builder(context, _item);
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
