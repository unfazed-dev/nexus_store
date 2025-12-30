import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A ConsumerWidget that simplifies displaying NexusStore data.
///
/// Provides automatic handling of loading and error states with customizable
/// builders for each state.
///
/// ## Example
///
/// ```dart
/// NexusStoreListConsumer<User>(
///   provider: usersProvider,
///   builder: (context, users) => ListView.builder(
///     itemCount: users.length,
///     itemBuilder: (context, index) => UserTile(users[index]),
///   ),
///   loading: (context) => const Center(
///     child: CircularProgressIndicator(),
///   ),
///   error: (context, error, stackTrace) => ErrorView(error),
/// )
/// ```
class NexusStoreListConsumer<T> extends ConsumerWidget {
  /// Creates a consumer for list data from a NexusStore StreamProvider.
  const NexusStoreListConsumer({
    required this.provider,
    required this.builder,
    this.loading,
    this.error,
    this.skipLoadingOnReload = false,
    this.skipLoadingOnRefresh = true,
    this.skipError = false,
    super.key,
  });

  /// The StreamProvider that provides the list data.
  final StreamProvider<List<T>> provider;

  /// Builder for rendering the data when available.
  final Widget Function(BuildContext context, List<T> data) builder;

  /// Builder for rendering the loading state.
  ///
  /// If null, a centered CircularProgressIndicator is shown.
  final Widget Function(BuildContext context)? loading;

  /// Builder for rendering the error state.
  ///
  /// If null, an ErrorWidget is shown.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? error;

  /// Whether to skip the loading state on subsequent reloads.
  final bool skipLoadingOnReload;

  /// Whether to skip the loading state on refresh.
  final bool skipLoadingOnRefresh;

  /// Whether to skip showing errors.
  final bool skipError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return asyncValue.when(
      skipLoadingOnReload: skipLoadingOnReload,
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      skipError: skipError,
      data: (data) => builder(context, data),
      loading: () =>
          loading?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          error?.call(context, e, st) ?? Center(child: ErrorWidget(e)),
    );
  }
}

/// A ConsumerWidget for displaying a single item from a NexusStore.
///
/// Uses a family provider to watch a specific item by ID.
///
/// ## Example
///
/// ```dart
/// NexusStoreItemConsumer<User, String>(
///   provider: userByIdProvider,
///   id: userId,
///   builder: (context, user) => user != null
///     ? UserDetail(user)
///     : const Text('User not found'),
/// )
/// ```
class NexusStoreItemConsumer<T, ID> extends ConsumerWidget {
  /// Creates a consumer for a single item from a NexusStore.
  const NexusStoreItemConsumer({
    required this.provider,
    required this.id,
    required this.builder,
    this.loading,
    this.error,
    this.notFound,
    super.key,
  });

  /// The family StreamProvider that provides item data.
  final StreamProviderFamily<T?, ID> provider;

  /// The ID of the item to watch.
  final ID id;

  /// Builder for rendering the item when available.
  final Widget Function(BuildContext context, T? item) builder;

  /// Builder for rendering the loading state.
  final Widget Function(BuildContext context)? loading;

  /// Builder for rendering the error state.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? error;

  /// Builder for rendering when the item is not found (null).
  ///
  /// If provided, this will be called instead of [builder] when the item
  /// is null. If not provided, [builder] will receive null.
  final Widget Function(BuildContext context)? notFound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider(id));

    return asyncValue.when(
      data: (item) {
        if (item == null && notFound != null) {
          return notFound!(context);
        }
        return builder(context, item);
      },
      loading: () =>
          loading?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          error?.call(context, e, st) ?? Center(child: ErrorWidget(e)),
    );
  }
}

/// A consumer with built-in pull-to-refresh support.
///
/// ## Example
///
/// ```dart
/// NexusStoreRefreshableConsumer<User>(
///   provider: usersProvider,
///   onRefresh: () => ref.refresh(usersProvider.future),
///   builder: (context, users) => ListView.builder(...),
/// )
/// ```
class NexusStoreRefreshableConsumer<T> extends ConsumerWidget {
  /// Creates a refreshable consumer for NexusStore data.
  const NexusStoreRefreshableConsumer({
    required this.provider,
    required this.builder,
    required this.onRefresh,
    this.loading,
    this.error,
    super.key,
  });

  /// The StreamProvider that provides the list data.
  final StreamProvider<List<T>> provider;

  /// Builder for rendering the data when available.
  final Widget Function(BuildContext context, List<T> data) builder;

  /// Callback when pull-to-refresh is triggered.
  final Future<void> Function() onRefresh;

  /// Builder for rendering the loading state.
  final Widget Function(BuildContext context)? loading;

  /// Builder for rendering the error state.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return asyncValue.when(
      data: (data) => RefreshIndicator(
        onRefresh: onRefresh,
        child: builder(context, data),
      ),
      loading: () =>
          loading?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          error?.call(context, e, st) ?? Center(child: ErrorWidget(e)),
    );
  }
}
