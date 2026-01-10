import 'package:nexus_store_crdt_adapter/src/crdt_column.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_merge_strategy.dart';

/// A type-safe table configuration that bundles table metadata with
/// serialization functions and merge strategy.
///
/// This provides a convenient way to configure a CRDT table with all the
/// information needed for CRUD operations and conflict resolution.
///
/// Example:
/// ```dart
/// final config = CrdtTableConfig<User, String>(
///   tableName: 'users',
///   columns: [
///     CrdtColumn.text('id', nullable: false),
///     CrdtColumn.text('name', nullable: false),
///     CrdtColumn.text('email'),
///     CrdtColumn.integer('age'),
///   ],
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
///   mergeConfig: CrdtMergeConfig<User>(
///     defaultStrategy: CrdtMergeStrategy.lww,
///     fieldStrategies: {'name': CrdtMergeStrategy.fww},
///   ),
/// );
/// ```
class CrdtTableConfig<T, ID> {
  /// Creates a table configuration.
  const CrdtTableConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    this.primaryKeyColumn = 'id',
    this.fieldMapping,
    this.indexes,
    this.mergeConfig,
  });

  /// The table name in the database.
  final String tableName;

  /// The column definitions for the table.
  final List<CrdtColumn> columns;

  /// Function to deserialize a JSON map to an entity.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Function to serialize an entity to a JSON map.
  final Map<String, dynamic> Function(T item) toJson;

  /// Function to extract the ID from an entity.
  final ID Function(T item) getId;

  /// The name of the primary key column. Defaults to 'id'.
  final String primaryKeyColumn;

  /// Optional field mapping from Dart field names to database column names.
  ///
  /// Example: `{'firstName': 'first_name'}` maps the Dart field `firstName`
  /// to the database column `first_name`.
  final Map<String, String>? fieldMapping;

  /// Optional indexes for the table.
  final List<CrdtIndex>? indexes;

  /// Optional merge configuration for conflict resolution.
  ///
  /// If not provided, defaults to Last-Writer-Wins for all fields.
  final CrdtMergeConfig<T>? mergeConfig;

  /// Gets the effective merge configuration.
  ///
  /// Returns the configured [mergeConfig] or a default LWW config.
  CrdtMergeConfig<T> get effectiveMergeConfig =>
      mergeConfig ?? CrdtMergeConfig<T>();

  /// Converts this configuration to a table definition.
  CrdtTableDefinition toTableDefinition() => CrdtTableDefinition(
        tableName: tableName,
        columns: columns,
        primaryKeyColumn: primaryKeyColumn,
        indexes: indexes,
      );

  /// Returns a dynamically-typed wrapper for [getId].
  ///
  /// This allows the function to be called with dynamic types,
  /// bypassing Dart's type contravariance restrictions.
  // ignore: inference_failure_on_function_return_type
  Object? Function(Object?) get dynamicGetId {
    final fn = getId as Function;
    return (item) => Function.apply(fn, [item]);
  }

  /// Returns a dynamically-typed wrapper for [fromJson].
  // ignore: inference_failure_on_function_return_type
  Object? Function(Map<String, dynamic>) get dynamicFromJson {
    final fn = fromJson as Function;
    return (Map<String, dynamic> json) => Function.apply(fn, [json]);
  }

  /// Returns a dynamically-typed wrapper for [toJson].
  Map<String, dynamic> Function(Object?) get dynamicToJson {
    final fn = toJson as Function;
    return (item) => Function.apply(fn, [item]) as Map<String, dynamic>;
  }

  /// Creates a copy of this config with the given overrides.
  CrdtTableConfig<T, ID> copyWith({
    String? tableName,
    List<CrdtColumn>? columns,
    T Function(Map<String, dynamic> json)? fromJson,
    Map<String, dynamic> Function(T item)? toJson,
    ID Function(T item)? getId,
    String? primaryKeyColumn,
    Map<String, String>? fieldMapping,
    List<CrdtIndex>? indexes,
    CrdtMergeConfig<T>? mergeConfig,
  }) => CrdtTableConfig<T, ID>(
        tableName: tableName ?? this.tableName,
        columns: columns ?? this.columns,
        fromJson: fromJson ?? this.fromJson,
        toJson: toJson ?? this.toJson,
        getId: getId ?? this.getId,
        primaryKeyColumn: primaryKeyColumn ?? this.primaryKeyColumn,
        fieldMapping: fieldMapping ?? this.fieldMapping,
        indexes: indexes ?? this.indexes,
        mergeConfig: mergeConfig ?? this.mergeConfig,
      );
}
