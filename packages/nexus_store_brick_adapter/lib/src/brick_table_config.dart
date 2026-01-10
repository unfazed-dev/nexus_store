import 'package:nexus_store_brick_adapter/src/brick_sync_config.dart';

/// Configuration for a Brick-backed table.
///
/// Bundles table name, serialization functions, and sync configuration
/// into a single reusable configuration object.
///
/// Example:
/// ```dart
/// final config = BrickTableConfig<User, String>(
///   tableName: 'users',
///   getId: (u) => u.id,
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   syncConfig: BrickSyncConfig.immediate(),
/// );
/// ```
class BrickTableConfig<T, ID> {
  /// Creates a table configuration.
  const BrickTableConfig({
    required this.tableName,
    required this.getId,
    required this.fromJson,
    required this.toJson,
    this.primaryKeyField = 'id',
    this.syncConfig,
    this.fieldMapping,
  });

  /// The table name in the database.
  final String tableName;

  /// Function to extract the ID from an entity.
  final ID Function(T item) getId;

  /// Function to deserialize a JSON map to an entity.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Function to serialize an entity to a JSON map.
  final Map<String, dynamic> Function(T item) toJson;

  /// The name of the primary key field. Defaults to 'id'.
  final String primaryKeyField;

  /// Optional sync configuration for this table.
  final BrickSyncConfig? syncConfig;

  /// Optional field mapping from Dart field names to database column names.
  ///
  /// Example: `{'firstName': 'first_name'}` maps the Dart field `firstName`
  /// to the database column `first_name`.
  final Map<String, String>? fieldMapping;

  /// Gets the effective sync configuration.
  ///
  /// Returns the configured [syncConfig] or a default immediate sync config.
  BrickSyncConfig get effectiveSyncConfig =>
      syncConfig ?? const BrickSyncConfig();

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

  /// Creates a copy with optional overrides.
  BrickTableConfig<T, ID> copyWith({
    String? tableName,
    ID Function(T item)? getId,
    T Function(Map<String, dynamic> json)? fromJson,
    Map<String, dynamic> Function(T item)? toJson,
    String? primaryKeyField,
    BrickSyncConfig? syncConfig,
    Map<String, String>? fieldMapping,
  }) => BrickTableConfig<T, ID>(
        tableName: tableName ?? this.tableName,
        getId: getId ?? this.getId,
        fromJson: fromJson ?? this.fromJson,
        toJson: toJson ?? this.toJson,
        primaryKeyField: primaryKeyField ?? this.primaryKeyField,
        syncConfig: syncConfig ?? this.syncConfig,
        fieldMapping: fieldMapping ?? this.fieldMapping,
      );
}
