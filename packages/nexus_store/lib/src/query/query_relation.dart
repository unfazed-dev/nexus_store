import 'package:meta/meta.dart';
import 'package:nexus_store/src/query/query.dart';

/// Describes a related entity to include via resource embedding (JOIN).
///
/// Used with [Query.withRelation] to specify related tables that should
/// be loaded alongside the main query results using PostgREST resource
/// embedding syntax (`select=*,foreign_table(*)`).
///
/// ## Example
///
/// ```dart
/// // Simple relation
/// const relation = QueryRelation(foreignTable: 'posts');
///
/// // With foreign key hint and column selection
/// const relation = QueryRelation(
///   foreignTable: 'posts',
///   foreignKey: 'author_id',
///   columns: {'id', 'title', 'body'},
/// );
///
/// // Nested relations via subQuery
/// final relation = QueryRelation(
///   foreignTable: 'posts',
///   subQuery: Query().withRelation('comments'),
/// );
/// ```
@immutable
class QueryRelation {
  /// Creates a relation descriptor.
  ///
  /// [foreignTable] is the name of the related table to embed.
  /// [foreignKey] optionally specifies which FK to use when ambiguous.
  /// [columns] optionally limits which columns to return (null = all).
  /// [subQuery] optionally specifies nested relations via another query.
  const QueryRelation({
    required this.foreignTable,
    this.foreignKey,
    this.columns,
    this.subQuery,
  });

  /// The name of the related table to embed.
  final String foreignTable;

  /// Optional foreign key hint for disambiguating relationships.
  final String? foreignKey;

  /// Optional column selection for the relation. Null means all columns (`*`).
  final Set<String>? columns;

  /// Optional sub-query for nested relations and filtering.
  final Query<dynamic>? subQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryRelation &&
          runtimeType == other.runtimeType &&
          foreignTable == other.foreignTable &&
          foreignKey == other.foreignKey &&
          _setsEqual(columns, other.columns) &&
          subQuery == other.subQuery;

  @override
  int get hashCode => Object.hash(
        foreignTable,
        foreignKey,
        columns == null ? null : Object.hashAll(columns!),
        subQuery,
      );

  @override
  String toString() => 'QueryRelation('
      '$foreignTable'
      '${foreignKey != null ? '!$foreignKey' : ''}'
      '${columns != null ? '(${columns!.join(', ')})' : ''}'
      '${subQuery != null ? ', subQuery: $subQuery' : ''}'
      ')';

  static bool _setsEqual<E>(Set<E>? a, Set<E>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
