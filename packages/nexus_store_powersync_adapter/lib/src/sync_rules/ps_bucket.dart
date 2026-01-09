import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_query.dart';

/// The type of PowerSync bucket.
enum PSBucketType {
  /// Global bucket - data is synced to all users.
  global,

  /// User-scoped bucket - data is filtered by user_id.
  userScoped,

  /// Parameterized bucket - uses custom SQL to determine bucket parameters.
  parameterized,
}

/// Represents a PowerSync sync rules bucket definition.
///
/// Buckets define what data is synced to clients. Use factory constructors
/// to create different bucket types:
///
/// - [PSBucket.global] - For data accessible to all users
/// - [PSBucket.userScoped] - For user-specific data filtered by user_id
/// - [PSBucket.parameterized] - For custom filtering with SQL parameters
///
/// Example:
/// ```dart
/// final bucket = PSBucket.userScoped(
///   name: 'user_data',
///   queries: [
///     PSQuery.select(table: 'users', filter: 'id = bucket.user_id'),
///   ],
/// );
/// ```
class PSBucket {
  /// Creates a global bucket that syncs data to all users.
  ///
  /// Use this for public data that everyone should have access to.
  const PSBucket.global({
    required this.name,
    required this.queries,
  })  : type = PSBucketType.global,
        parameters = null;

  /// Creates a user-scoped bucket that filters data by user_id.
  ///
  /// This automatically adds `request.user_id()` as a bucket parameter.
  /// Use filters like `id = bucket.user_id` in your queries.
  const PSBucket.userScoped({
    required this.name,
    required this.queries,
  })  : type = PSBucketType.userScoped,
        parameters = null;

  /// Creates a parameterized bucket with custom SQL for bucket parameters.
  ///
  /// Use this for complex filtering logic like team membership.
  ///
  /// Example:
  /// ```dart
  /// PSBucket.parameterized(
  ///   name: 'team_data',
  ///   parameters: 'SELECT team_id FROM team_members '
  ///       'WHERE user_id = token_parameters.user_id',
  ///   queries: [
  ///     PSQuery.select(table: 'teams', filter: 'id = bucket.team_id'),
  ///   ],
  /// );
  /// ```
  const PSBucket.parameterized({
    required this.name,
    required this.parameters,
    required this.queries,
  }) : type = PSBucketType.parameterized;

  /// The bucket name used in sync rules.
  final String name;

  /// The type of bucket.
  final PSBucketType type;

  /// The queries that define what data to sync.
  final List<PSQuery> queries;

  /// SQL query for parameterized buckets. Null for global and userScoped.
  final String? parameters;

  /// Converts this bucket to a map suitable for YAML serialization.
  ///
  /// The output format follows the PowerSync sync rules specification:
  /// - `name`: The bucket name
  /// - `parameters`: SQL for bucket parameters (if applicable)
  /// - `data`: List of SELECT queries
  Map<String, dynamic> toYamlMap() {
    final map = <String, dynamic>{
      'name': name,
    };

    // Add parameters based on bucket type
    switch (type) {
      case PSBucketType.global:
        // No parameters needed for global buckets
        break;
      case PSBucketType.userScoped:
        map['parameters'] = 'SELECT request.user_id() as user_id';
      case PSBucketType.parameterized:
        map['parameters'] = parameters;
    }

    // Add data queries
    map['data'] = queries.map((q) => q.toSql()).toList();

    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PSBucket) return false;

    return other.name == name &&
        other.type == type &&
        other.parameters == parameters &&
        _listEquals(other.queries, queries);
  }

  @override
  int get hashCode => Object.hash(
        name,
        type,
        parameters,
        Object.hashAll(queries),
      );

  @override
  String toString() =>
      'PSBucket.${type.name}(name: $name, queries: ${queries.length})';
}

/// Helper function to compare lists for equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
