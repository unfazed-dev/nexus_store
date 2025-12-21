import 'package:meta/meta.dart';
import 'package:nexus_store/src/pagination/page_info.dart';

/// Sealed class representing the state of paginated data loading.
///
/// Follows the pattern of [StoreResult] for consistent state handling.
///
/// ## States
///
/// - [PaginationInitial]: Initial state before any loading
/// - [PaginationLoading]: Loading first page or refreshing
/// - [PaginationLoadingMore]: Loading additional pages
/// - [PaginationData]: Data loaded successfully
/// - [PaginationError]: Error occurred during loading
///
/// ## Example
///
/// ```dart
/// Widget build(BuildContext context) {
///   return StreamBuilder<PaginationState<User>>(
///     stream: controller.stream,
///     builder: (context, snapshot) {
///       final state = snapshot.data ?? PaginationState.initial();
///
///       return state.when(
///         initial: () => const Text('Pull to refresh'),
///         loading: (_) => const CircularProgressIndicator(),
///         loadingMore: (items, _) => UserList(items, isLoadingMore: true),
///         data: (items, _) => UserList(items),
///         error: (error, items, _) => ErrorWidget(error, items: items),
///       );
///     },
///   );
/// }
/// ```
@immutable
sealed class PaginationState<T> {
  const PaginationState();

  /// Creates an initial state before any data is loaded.
  factory PaginationState.initial() = PaginationInitial<T>;

  /// Creates a loading state for first page or refresh.
  factory PaginationState.loading({List<T>? previousItems}) =
      PaginationLoading<T>;

  /// Creates a loading more state for subsequent pages.
  factory PaginationState.loadingMore({
    required List<T> items,
    required PageInfo pageInfo,
  }) = PaginationLoadingMore<T>;

  /// Creates a data state with loaded items.
  factory PaginationState.data({
    required List<T> items,
    required PageInfo pageInfo,
  }) = PaginationData<T>;

  /// Creates an error state.
  factory PaginationState.error(
    Object error, {
    List<T>? previousItems,
    PageInfo? pageInfo,
  }) = PaginationError<T>;

  /// The items in the current state.
  List<T> get items;

  /// Whether data is currently being loaded (first page or refresh).
  bool get isLoading;

  /// Whether more data is being loaded (subsequent pages).
  bool get isLoadingMore;

  /// Whether there are more items available.
  bool get hasMore;

  /// The error if in error state, otherwise null.
  Object? get error;

  /// Page info for the current state.
  PageInfo? get pageInfo;

  /// Number of items currently loaded.
  int get itemCount => items.length;

  /// Whether the items list is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the items list is not empty.
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether the state contains an error.
  bool get hasError => error != null;

  /// Pattern matching method covering all states.
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  });

  /// Pattern matching with optional handlers and fallback.
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  });
}

/// Initial state before any data is loaded.
@immutable
class PaginationInitial<T> extends PaginationState<T> {
  const PaginationInitial();

  @override
  List<T> get items => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => true;

  @override
  Object? get error => null;

  @override
  PageInfo? get pageInfo => null;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  }) =>
      initial();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  }) =>
      initial?.call() ?? orElse();

  @override
  String toString() => 'PaginationInitial<$T>()';
}

/// Loading state for first page or refresh.
@immutable
class PaginationLoading<T> extends PaginationState<T> {
  const PaginationLoading({List<T>? previousItems})
      : _previousItems = previousItems;

  final List<T>? _previousItems;

  @override
  List<T> get items => _previousItems ?? const [];

  @override
  bool get isLoading => true;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => true;

  @override
  Object? get error => null;

  @override
  PageInfo? get pageInfo => null;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  }) =>
      loading(items);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  }) =>
      loading?.call(items) ?? orElse();

  @override
  String toString() => 'PaginationLoading<$T>(${items.length} previous items)';
}

/// Loading more state for subsequent pages.
@immutable
class PaginationLoadingMore<T> extends PaginationState<T> {
  const PaginationLoadingMore({
    required List<T> items,
    required this.pageInfo,
  }) : _items = items;

  final List<T> _items;

  @override
  final PageInfo pageInfo;

  @override
  List<T> get items => _items;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => true;

  @override
  bool get hasMore => pageInfo.hasNextPage;

  @override
  Object? get error => null;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  }) =>
      loadingMore(items, pageInfo);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  }) =>
      loadingMore?.call(items, pageInfo) ?? orElse();

  @override
  String toString() =>
      'PaginationLoadingMore<$T>(${items.length} items, hasMore: $hasMore)';
}

/// Data state with successfully loaded items.
@immutable
class PaginationData<T> extends PaginationState<T> {
  const PaginationData({
    required List<T> items,
    required this.pageInfo,
  }) : _items = items;

  final List<T> _items;

  @override
  final PageInfo pageInfo;

  @override
  List<T> get items => _items;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => pageInfo.hasNextPage;

  @override
  Object? get error => null;

  /// Creates a copy with updated fields.
  PaginationData<T> copyWith({
    List<T>? items,
    PageInfo? pageInfo,
  }) =>
      PaginationData<T>(
        items: items ?? _items,
        pageInfo: pageInfo ?? this.pageInfo,
      );

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  }) =>
      data(items, pageInfo);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  }) =>
      data?.call(items, pageInfo) ?? orElse();

  @override
  String toString() =>
      'PaginationData<$T>(${items.length} items, hasMore: $hasMore)';
}

/// Error state with optional previous data.
@immutable
class PaginationError<T> extends PaginationState<T> {
  const PaginationError(
    this.error, {
    List<T>? previousItems,
    this.pageInfo,
  }) : _previousItems = previousItems;

  @override
  final Object error;

  final List<T>? _previousItems;

  @override
  final PageInfo? pageInfo;

  @override
  List<T> get items => _previousItems ?? const [];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => pageInfo?.hasNextPage ?? false;

  /// Creates a copy with updated fields.
  PaginationError<T> copyWith({
    Object? error,
    List<T>? previousItems,
    PageInfo? pageInfo,
  }) =>
      PaginationError<T>(
        error ?? this.error,
        previousItems: previousItems ?? _previousItems,
        pageInfo: pageInfo ?? this.pageInfo,
      );

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T> previousItems) loading,
    required R Function(List<T> items, PageInfo pageInfo) loadingMore,
    required R Function(List<T> items, PageInfo pageInfo) data,
    required R Function(Object error, List<T> items, PageInfo? pageInfo) error,
  }) =>
      error(this.error, items, pageInfo);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T> previousItems)? loading,
    R Function(List<T> items, PageInfo pageInfo)? loadingMore,
    R Function(List<T> items, PageInfo pageInfo)? data,
    R Function(Object error, List<T> items, PageInfo? pageInfo)? error,
    required R Function() orElse,
  }) =>
      error?.call(this.error, items, pageInfo) ?? orElse();

  @override
  String toString() =>
      'PaginationError<$T>($error, ${items.length} previous items)';
}
