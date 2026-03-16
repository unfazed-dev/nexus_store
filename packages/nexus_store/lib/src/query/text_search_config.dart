import 'package:meta/meta.dart';

/// The type of text search to perform.
enum TextSearchType {
  /// Plain text search — each word is searched individually.
  plain,

  /// Phrase search — words must appear in the given order.
  phrase,

  /// Web search — supports operators like quotes and minus for exclusion.
  websearch,
}

/// Configuration for full-text search queries.
///
/// Used with [FilterOperator.textSearch] to specify the search query,
/// locale configuration, and search type.
///
/// ```dart
/// final query = Query<Post>().where(
///   'body',
///   textSearch: TextSearchConfig(
///     query: 'fat cats',
///     config: 'english',
///     type: TextSearchType.websearch,
///   ),
/// );
/// ```
@immutable
class TextSearchConfig {
  /// Creates a text search configuration.
  ///
  /// [query] is the search string.
  /// [config] is the optional PostgreSQL text search configuration
  /// (e.g., 'english', 'spanish').
  /// [type] defaults to [TextSearchType.plain].
  const TextSearchConfig({
    required this.query,
    this.config,
    this.type = TextSearchType.plain,
  });

  /// The search query string.
  final String query;

  /// The PostgreSQL text search configuration (e.g., 'english', 'spanish').
  ///
  /// When null, the database default configuration is used.
  final String? config;

  /// The type of text search to perform.
  final TextSearchType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSearchConfig &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          config == other.config &&
          type == other.type;

  @override
  int get hashCode => Object.hash(query, config, type);

  @override
  String toString() =>
      'TextSearchConfig(query: $query, config: $config, type: $type)';
}
