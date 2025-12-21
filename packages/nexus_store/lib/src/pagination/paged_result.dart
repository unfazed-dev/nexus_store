import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/page_info.dart';

/// A page of results from cursor-based pagination.
///
/// [PagedResult] contains both the items in the current page and
/// metadata about pagination state via [pageInfo].
///
/// ## Example
///
/// ```dart
/// final firstPage = await store.getAllPaged(
///   query: Query<User>().orderBy('name').first(20),
/// );
///
/// print('Loaded ${firstPage.length} users');
/// print('Has more: ${firstPage.hasMore}');
///
/// if (firstPage.hasMore && firstPage.nextCursor != null) {
///   final secondPage = await store.getAllPaged(
///     query: Query<User>()
///         .orderBy('name')
///         .after(firstPage.nextCursor!)
///         .first(20),
///   );
/// }
/// ```
@immutable
class PagedResult<T> {
  /// Creates a paged result with the given items and page info.
  PagedResult({
    required List<T> items,
    required this.pageInfo,
  }) : _items = List<T>.unmodifiable(items);

  /// Creates an empty paged result.
  factory PagedResult.empty() => PagedResult<T>(
        items: const [],
        pageInfo: const PageInfo.empty(),
      );

  final List<T> _items;

  /// The items in this page.
  ///
  /// This list is unmodifiable.
  List<T> get items => _items;

  /// Metadata about pagination state.
  final PageInfo pageInfo;

  /// Whether there are more items available after this page.
  ///
  /// Shorthand for `pageInfo.hasNextPage`.
  bool get hasMore => pageInfo.hasNextPage;

  /// Cursor to fetch the next page of results.
  ///
  /// Shorthand for `pageInfo.endCursor`.
  /// Use with `Query.after(nextCursor)` to fetch the next page.
  Cursor? get nextCursor => pageInfo.endCursor;

  /// Cursor to fetch the previous page of results.
  ///
  /// Shorthand for `pageInfo.startCursor`.
  /// Use with `Query.before(previousCursor)` to fetch the previous page.
  Cursor? get previousCursor => pageInfo.startCursor;

  /// Total count of items across all pages, if known.
  ///
  /// Shorthand for `pageInfo.totalCount`.
  int? get totalCount => pageInfo.totalCount;

  /// Whether this page contains no items.
  bool get isEmpty => _items.isEmpty;

  /// Whether this page contains items.
  bool get isNotEmpty => _items.isNotEmpty;

  /// The number of items in this page.
  int get length => _items.length;

  /// Transforms the items in this page, preserving pagination info.
  ///
  /// Example:
  /// ```dart
  /// final userPage = await store.getAllPaged(...);
  /// final namePage = userPage.map((user) => user.name);
  /// ```
  PagedResult<R> map<R>(R Function(T item) transform) {
    return PagedResult<R>(
      items: _items.map(transform).toList(),
      pageInfo: pageInfo,
    );
  }

  /// Creates a copy with the specified fields replaced.
  PagedResult<T> copyWith({
    List<T>? items,
    PageInfo? pageInfo,
  }) {
    return PagedResult<T>(
      items: items ?? _items,
      pageInfo: pageInfo ?? this.pageInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PagedResult<T>) return false;
    return const ListEquality<dynamic>().equals(_items, other._items) &&
        pageInfo == other.pageInfo;
  }

  @override
  int get hashCode => Object.hash(
        const ListEquality<dynamic>().hash(_items),
        pageInfo,
      );

  @override
  String toString() => 'PagedResult<$T>(${_items.length} items, $pageInfo)';
}
