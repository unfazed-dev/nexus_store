import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

// Test model
class TestItem {
  const TestItem({
    required this.id,
    required this.name,
    this.description,
    this.count,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        count: json['count'] as int?,
      );

  final String id;
  final String name;
  final String? description;
  final int? count;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'count': count,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          count == other.count;

  @override
  int get hashCode => Object.hash(id, name, description, count);
}

void main() {
  group('DriftBackend.withDatabase', () {
    late DriftBackend<TestItem, String> backend;
    late LazyDatabase lazyDb;

    setUp(() {
      // Use in-memory database for testing
      lazyDb = LazyDatabase(() async => NativeDatabase.memory());
    });

    tearDown(() async {
      await backend.close();
    });

    test('creates backend with column definitions', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        executor: lazyDb,
      );

      await backend.initialize();

      expect(backend.name, equals('drift'));
      expect(backend.supportsOffline, isTrue);
    });

    test('creates table schema automatically', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        executor: lazyDb,
      );

      await backend.initialize();

      // Should be able to save and retrieve items
      const item = TestItem(id: '1', name: 'Test', description: 'Desc', count: 5);
      await backend.save(item);

      final retrieved = await backend.get('1');
      expect(retrieved, equals(item));
    });

    test('supports CRUD operations after initialization', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        executor: lazyDb,
      );

      await backend.initialize();

      // Create
      const item1 = TestItem(id: '1', name: 'Item 1', count: 10);
      const item2 = TestItem(id: '2', name: 'Item 2', count: 20);
      await backend.save(item1);
      await backend.save(item2);

      // Read
      final all = await backend.getAll();
      expect(all.length, equals(2));

      // Update
      const updated = TestItem(id: '1', name: 'Updated', count: 15);
      await backend.save(updated);
      final retrieved = await backend.get('1');
      expect(retrieved?.name, equals('Updated'));
      expect(retrieved?.count, equals(15));

      // Delete
      final deleted = await backend.delete('1');
      expect(deleted, isTrue);
      expect(await backend.get('1'), isNull);
    });

    test('uses custom primary key column', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        executor: lazyDb,
      );

      await backend.initialize();

      const item = TestItem(id: 'custom-id', name: 'Test');
      await backend.save(item);

      final retrieved = await backend.get('custom-id');
      expect(retrieved?.id, equals('custom-id'));
    });

    test('creates indexes when specified', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        indexes: [
          const DriftIndex(name: 'idx_items_name', columns: ['name']),
        ],
        executor: lazyDb,
      );

      await backend.initialize();

      // If indexes failed to create, this would throw
      // Just verify we can still use the backend
      const item = TestItem(id: '1', name: 'Test');
      await backend.save(item);
      expect(await backend.get('1'), equals(item));
    });

    test('throws when calling operations before initialize', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        executor: lazyDb,
      );

      // Don't call initialize

      expect(
        () => backend.getAll(),
        throwsA(isA<Exception>()),
      );
    });

    test('handles field mapping', () async {
      backend = DriftBackend<TestItem, String>.withDatabase(
        tableName: 'items',
        columns: [
          DriftColumn.text('id', nullable: false),
          DriftColumn.text('name', nullable: false),
          DriftColumn.text('description'),
          DriftColumn.integer('count'),
        ],
        getId: (item) => item.id,
        fromJson: TestItem.fromJson,
        toJson: (item) => item.toJson(),
        fieldMapping: {'description': 'item_description'},
        executor: lazyDb,
      );

      await backend.initialize();

      // Backend should still work with field mapping configured
      const item = TestItem(id: '1', name: 'Test', description: 'A description');
      await backend.save(item);

      final retrieved = await backend.get('1');
      expect(retrieved?.description, equals('A description'));
    });
  });
}
