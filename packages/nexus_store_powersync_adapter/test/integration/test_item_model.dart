/// Shared test model for integration tests using the `test_items` table.
///
/// The `test_items` table has the following schema:
/// - id: text (primary key)
/// - name: text
/// - value: integer (nullable)
/// - created_at: timestamp (nullable)
library;

import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;

/// Test item model matching the `test_items` Supabase table.
class TestItem {
  TestItem({
    required this.id,
    required this.name,
    this.value,
    this.createdAt,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'] as String,
        name: json['name'] as String,
        value: json['value'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String name;
  final int? value;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (value != null) 'value': value,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => Object.hash(id, name, value);

  @override
  String toString() => 'TestItem(id: $id, name: $name, value: $value)';
}

/// PowerSync schema for test_items table.
const testItemsSchema = ps.Schema([
  ps.Table(
    'test_items',
    [
      ps.Column.text('name'),
      ps.Column.integer('value'),
      ps.Column.text('created_at'),
    ],
  ),
]);

/// PSTableConfig for test_items table.
final testItemsConfig = PSTableConfig<TestItem, String>(
  tableName: 'test_items',
  columns: [
    PSColumn.text('name'),
    PSColumn.integer('value'),
    PSColumn.text('created_at'),
  ],
  fromJson: TestItem.fromJson,
  toJson: (item) => item.toJson(),
  getId: (item) => item.id,
);

/// Generates a unique test ID with optional prefix.
String generateTestId([String prefix = 'test']) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
