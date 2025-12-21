import 'package:flutter/widgets.dart';
import 'package:nexus_store/nexus_store.dart';

/// A widget that builds different UI based on [PaginationState].
///
/// Similar to how [StreamBuilder] works with [AsyncSnapshot], this widget
/// provides a declarative way to handle all pagination states.
///
/// ## Example
///
/// ```dart
/// PaginationStateBuilder<User>(
///   state: paginationState,
///   initial: () => Center(child: Text('Start loading')),
///   loading: (previousItems) => Center(child: CircularProgressIndicator()),
///   loadingMore: (items, pageInfo) => Column(
///     children: [
///       Expanded(child: UserList(users: items)),
///       LinearProgressIndicator(),
///     ],
///   ),
///   data: (items, pageInfo) => UserList(users: items),
///   error: (error, previousItems, pageInfo) => ErrorWidget(error: error),
/// )
/// ```
class PaginationStateBuilder<T> extends StatelessWidget {
  /// Creates a pagination state builder.
  ///
  /// All builder callbacks are required to ensure exhaustive handling
  /// of all possible states.
  const PaginationStateBuilder({
    super.key,
    required this.state,
    required this.initial,
    required this.loading,
    required this.loadingMore,
    required this.data,
    required this.error,
  }) : _orElse = null;

  /// Creates a pagination state builder with optional callbacks.
  ///
  /// Use [orElse] for states that don't have an explicit builder.
  const PaginationStateBuilder.maybeWhen({
    super.key,
    required this.state,
    this.initial,
    this.loading,
    this.loadingMore,
    this.data,
    this.error,
    required Widget Function() orElse,
  }) : _orElse = orElse;

  /// The current pagination state to render.
  final PaginationState<T> state;

  /// Builder for the initial state (before any loading).
  final Widget Function()? initial;

  /// Builder for the loading state.
  ///
  /// [previousItems] contains any items from a previous load if available.
  final Widget Function(List<T>? previousItems)? loading;

  /// Builder for the loading more state (loading additional pages).
  ///
  /// [items] contains the currently loaded items.
  /// [pageInfo] contains pagination metadata.
  final Widget Function(List<T> items, PageInfo pageInfo)? loadingMore;

  /// Builder for the data state (successful load).
  ///
  /// [items] contains all loaded items.
  /// [pageInfo] contains pagination metadata.
  final Widget Function(List<T> items, PageInfo pageInfo)? data;

  /// Builder for the error state.
  ///
  /// [error] is the error that occurred.
  /// [previousItems] contains any items from a previous load if available.
  /// [pageInfo] contains pagination metadata if available.
  final Widget Function(
    Object error,
    List<T>? previousItems,
    PageInfo? pageInfo,
  )? error;

  /// Fallback builder for states without explicit handlers.
  final Widget Function()? _orElse;

  @override
  Widget build(BuildContext context) => state.when(
      initial: () {
        if (initial != null) return initial!();
        if (_orElse != null) return _orElse();
        return const SizedBox.shrink();
      },
      loading: (previousItems) {
        if (loading != null) return loading!(previousItems);
        if (_orElse != null) return _orElse();
        return const SizedBox.shrink();
      },
      loadingMore: (items, pageInfo) {
        if (loadingMore != null) return loadingMore!(items, pageInfo);
        if (_orElse != null) return _orElse();
        return const SizedBox.shrink();
      },
      data: (items, pageInfo) {
        if (data != null) return data!(items, pageInfo);
        if (_orElse != null) return _orElse();
        return const SizedBox.shrink();
      },
      error: (err, previousItems, pageInfo) {
        if (error != null) return error!(err, previousItems, pageInfo);
        if (_orElse != null) return _orElse();
        return const SizedBox.shrink();
      },
    );
}
