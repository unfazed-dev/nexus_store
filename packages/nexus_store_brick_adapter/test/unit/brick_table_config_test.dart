import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

// Test model
class TestUser {
  TestUser({required this.id, required this.name, this.email});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );

  final String id;
  final String name;
  final String? email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
      };
}

void main() {
  group('BrickTableConfig', () {
    test('creates with required parameters', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      expect(config.tableName, 'users');
      expect(config.primaryKeyField, 'id');
      expect(config.syncConfig, isNull);
      expect(config.fieldMapping, isNull);
    });

    test('creates with custom primary key field', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        primaryKeyField: 'user_id',
      );

      expect(config.primaryKeyField, 'user_id');
    });

    test('creates with sync config', () {
      const syncConfig = BrickSyncConfig(
        syncPolicy: BrickSyncPolicy.batch,
        batchSize: 100,
      );

      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        syncConfig: syncConfig,
      );

      expect(config.syncConfig, isNotNull);
      expect(config.syncConfig!.syncPolicy, BrickSyncPolicy.batch);
      expect(config.syncConfig!.batchSize, 100);
    });

    test('creates with field mapping', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        fieldMapping: {'firstName': 'first_name', 'lastName': 'last_name'},
      );

      expect(config.fieldMapping, isNotNull);
      expect(config.fieldMapping!['firstName'], 'first_name');
    });

    test('getId extracts ID correctly', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      final user = TestUser(id: 'user-123', name: 'John');
      expect(config.getId(user), 'user-123');
    });

    test('fromJson deserializes correctly', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      final json = {'id': 'user-123', 'name': 'John', 'email': 'john@test.com'};
      final user = config.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.name, 'John');
      expect(user.email, 'john@test.com');
    });

    test('toJson serializes correctly', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      final user = TestUser(
        id: 'user-123',
        name: 'John',
        email: 'john@test.com',
      );
      final json = config.toJson(user);

      expect(json['id'], 'user-123');
      expect(json['name'], 'John');
      expect(json['email'], 'john@test.com');
    });

    test('effectiveSyncConfig returns config when provided', () {
      const syncConfig = BrickSyncConfig.manual();

      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        syncConfig: syncConfig,
      );

      expect(config.effectiveSyncConfig.syncPolicy, BrickSyncPolicy.manual);
    });

    test('effectiveSyncConfig returns default when not provided', () {
      final config = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      expect(config.effectiveSyncConfig.syncPolicy, BrickSyncPolicy.immediate);
    });

    test('copyWith creates new instance with overrides', () {
      final original = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      final copy = original.copyWith(
        tableName: 'app_users',
        primaryKeyField: 'user_id',
      );

      expect(copy.tableName, 'app_users');
      expect(copy.primaryKeyField, 'user_id');
      // Original functions preserved
      expect(copy.getId(TestUser(id: 'test', name: 'Test')), 'test');
    });

    test('copyWith preserves original values when not overridden', () {
      const syncConfig = BrickSyncConfig.batch();
      final original = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        syncConfig: syncConfig,
        fieldMapping: {'a': 'b'},
      );

      final copy = original.copyWith(tableName: 'new_users');

      expect(copy.tableName, 'new_users');
      expect(copy.syncConfig!.syncPolicy, BrickSyncPolicy.batch);
      expect(copy.fieldMapping!['a'], 'b');
    });

    test('copyWith preserves tableName when not overridden', () {
      final original = BrickTableConfig<TestUser, String>(
        tableName: 'original_table',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      final copy = original.copyWith(primaryKeyField: 'user_id');

      expect(copy.tableName, 'original_table');
      expect(copy.primaryKeyField, 'user_id');
    });

    group('dynamic wrappers', () {
      test('dynamicGetId works with Object types', () {
        final config = BrickTableConfig<TestUser, String>(
          tableName: 'users',
          getId: (u) => u.id,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
        );

        final user = TestUser(id: 'dynamic-123', name: 'Dynamic');
        // Use as dynamic to simulate manager usage
        final Object item = user;
        final result = config.dynamicGetId(item);

        expect(result, 'dynamic-123');
      });

      test('dynamicFromJson works with Object return types', () {
        final config = BrickTableConfig<TestUser, String>(
          tableName: 'users',
          getId: (u) => u.id,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
        );

        final json = {'id': 'test', 'name': 'Test'};
        final result = config.dynamicFromJson(json);

        expect(result, isA<TestUser>());
        expect((result! as TestUser).id, 'test');
      });

      test('dynamicToJson works with Object input types', () {
        final config = BrickTableConfig<TestUser, String>(
          tableName: 'users',
          getId: (u) => u.id,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
        );

        final Object user = TestUser(id: 'test', name: 'Test');
        final result = config.dynamicToJson(user);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 'test');
      });
    });
  });
}
