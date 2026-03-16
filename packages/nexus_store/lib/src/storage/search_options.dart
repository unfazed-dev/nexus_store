import 'package:meta/meta.dart';

/// Options for listing files in a bucket.
@immutable
class SearchOptions {
  /// Creates search options with sensible defaults.
  const SearchOptions({
    this.limit = 100,
    this.offset = 0,
    this.sortBy,
    this.search,
  });

  /// Maximum number of files to return.
  final int limit;

  /// Number of files to skip.
  final int offset;

  /// Sort configuration.
  final SortBy? sortBy;

  /// Filter files by name prefix.
  final String? search;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchOptions) return false;
    return limit == other.limit &&
        offset == other.offset &&
        sortBy == other.sortBy &&
        search == other.search;
  }

  @override
  int get hashCode => Object.hash(limit, offset, sortBy, search);

  @override
  String toString() => 'SearchOptions('
      'limit: $limit, '
      'offset: $offset, '
      'sortBy: $sortBy, '
      'search: $search)';
}

/// Sort configuration for file listing.
@immutable
class SortBy {
  /// Creates a sort configuration.
  const SortBy({
    required this.column,
    required this.order,
  });

  /// Column to sort by (e.g., 'name', 'created_at', 'updated_at').
  final String column;

  /// Sort direction.
  final SortOrder order;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SortBy) return false;
    return column == other.column && order == other.order;
  }

  @override
  int get hashCode => Object.hash(column, order);

  @override
  String toString() => 'SortBy(column: $column, order: $order)';
}

/// Sort direction for file listing.
enum SortOrder {
  /// Ascending order.
  asc,

  /// Descending order.
  desc,
}
