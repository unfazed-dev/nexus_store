import 'package:meta/meta.dart';
import 'package:nexus_store/src/pagination/cursor.dart';

/// Metadata about a page of results in cursor-based pagination.
///
/// [PageInfo] provides navigation hints and optional total count
/// for paginated result sets.
///
/// ## Example
///
/// ```dart
/// final pageInfo = PageInfo(
///   hasNextPage: true,
///   hasPreviousPage: false,
///   startCursor: Cursor.fromValues({'id': 'first'}),
///   endCursor: Cursor.fromValues({'id': 'last'}),
///   totalCount: 100,
/// );
///
/// if (pageInfo.hasNextPage) {
///   loadNextPage(after: pageInfo.endCursor);
/// }
/// ```
@immutable
class PageInfo {
  /// Creates page info with the specified fields.
  const PageInfo({
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.startCursor,
    this.endCursor,
    this.totalCount,
  });

  /// Creates an empty page info indicating no pages.
  const PageInfo.empty()
      : hasNextPage = false,
        hasPreviousPage = false,
        startCursor = null,
        endCursor = null,
        totalCount = null;

  /// Whether there are more items after this page.
  final bool hasNextPage;

  /// Whether there are items before this page.
  final bool hasPreviousPage;

  /// Cursor for the first item in this page.
  ///
  /// Used to fetch items before this page with `before()`.
  final Cursor? startCursor;

  /// Cursor for the last item in this page.
  ///
  /// Used to fetch items after this page with `after()`.
  final Cursor? endCursor;

  /// Total count of items across all pages, if known.
  ///
  /// Some backends don't support total counts, in which case this is null.
  final int? totalCount;

  /// Returns `true` if no cursors are present.
  bool get isEmpty => startCursor == null && endCursor == null;

  /// Returns `true` if at least one cursor is present.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this PageInfo with the specified fields replaced.
  PageInfo copyWith({
    bool? hasNextPage,
    bool? hasPreviousPage,
    Cursor? startCursor,
    Cursor? endCursor,
    int? totalCount,
  }) {
    return PageInfo(
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      startCursor: startCursor ?? this.startCursor,
      endCursor: endCursor ?? this.endCursor,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PageInfo) return false;
    return hasNextPage == other.hasNextPage &&
        hasPreviousPage == other.hasPreviousPage &&
        startCursor == other.startCursor &&
        endCursor == other.endCursor &&
        totalCount == other.totalCount;
  }

  @override
  int get hashCode => Object.hash(
        hasNextPage,
        hasPreviousPage,
        startCursor,
        endCursor,
        totalCount,
      );

  @override
  String toString() => 'PageInfo('
      'hasNextPage: $hasNextPage, '
      'hasPreviousPage: $hasPreviousPage, '
      'startCursor: $startCursor, '
      'endCursor: $endCursor, '
      'totalCount: $totalCount)';
}
