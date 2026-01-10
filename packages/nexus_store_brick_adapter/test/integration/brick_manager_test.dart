import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

// Mock repository
class MockOfflineFirstRepository extends Mock
    implements OfflineFirstRepository<OfflineFirstModel> {}

// Test models
class TestUser extends OfflineFirstModel {
  TestUser({required this.id, required this.name, int? primaryKeyId})
      : _primaryKeyId = primaryKeyId;

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
  final int? _primaryKeyId;

  @override
  int? get primaryKey => _primaryKeyId;

  @override
  set primaryKey(int? value) {}

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TestPost extends OfflineFirstModel {
  TestPost({required this.id, required this.title, int? primaryKeyId})
      : _primaryKeyId = primaryKeyId;

  factory TestPost.fromJson(Map<String, dynamic> json) => TestPost(
        id: json['id'] as String,
        title: json['title'] as String,
      );

  final String id;
  final String title;
  final int? _primaryKeyId;

  @override
  int? get primaryKey => _primaryKeyId;

  @override
  set primaryKey(int? value) {}

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

void main() {
  setUpAll(() {
    registerFallbackValue(TestUser(id: 'fallback', name: 'Fallback'));
  });

  group('BrickManager', () {
    late MockOfflineFirstRepository mockRepository;
    late BrickTableConfig<TestUser, String> userConfig;
    late BrickTableConfig<TestPost, String> postConfig;

    setUp(() {
      mockRepository = MockOfflineFirstRepository();
      when(() => mockRepository.initialize()).thenAnswer((_) async {});

      userConfig = BrickTableConfig<TestUser, String>(
        tableName: 'users',
        getId: (u) => u.id,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        syncConfig: const BrickSyncConfig.immediate(),
      );

      postConfig = BrickTableConfig<TestPost, String>(
        tableName: 'posts',
        getId: (p) => p.id,
        fromJson: TestPost.fromJson,
        toJson: (p) => p.toJson(),
        syncConfig: const BrickSyncConfig.batch(),
      );
    });

    group('creation', () {
      test('withRepository creates manager with tables', () {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig, postConfig],
        );

        expect(manager.isInitialized, isFalse);
        expect(manager.tableNames, ['users', 'posts']);
      });

      test('withRepository accepts sync config override', () {
        const syncConfig = BrickSyncConfig.manual();

        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
          syncConfig: syncConfig,
        );

        expect(manager.syncConfig.syncPolicy, BrickSyncPolicy.manual);
      });
    });

    group('initialization', () {
      test('initialize sets isInitialized to true', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );

        await manager.initialize();

        expect(manager.isInitialized, isTrue);
      });

      test('initialize is idempotent', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );

        await manager.initialize();
        await manager.initialize();

        verify(() => mockRepository.initialize()).called(1);
      });
    });

    group('getBackend', () {
      test('returns backend for valid table name', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig, postConfig],
        );
        await manager.initialize();

        final userBackend = manager.getBackend('users');
        final postBackend = manager.getBackend('posts');

        expect(userBackend, isNotNull);
        expect(postBackend, isNotNull);
      });

      test('throws StateError when not initialized', () {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );

        expect(
          () => manager.getBackend('users'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for unknown table', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        expect(
          () => manager.getBackend('unknown'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('sync operations', () {
      test('syncAll triggers sync on all backends', () async {
        when(
          () => mockRepository.get<OfflineFirstModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) async => <OfflineFirstModel>[]);

        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig, postConfig],
        );
        await manager.initialize();

        await manager.syncAll();

        // Each backend calls repository.get() during sync
        verify(() => mockRepository.get<OfflineFirstModel>()).called(2);
      });

      test('syncAll sets error status when sync throws', () async {
        when(
          () => mockRepository.get<OfflineFirstModel>(
            query: any(named: 'query'),
          ),
        ).thenThrow(Exception('Sync failed'));

        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        try {
          await manager.syncAll();
        } on Exception catch (_) {
          // Expected
        }

        expect(manager.syncStatus, nexus.SyncStatus.error);
      });

      test('totalPendingChanges aggregates from all backends', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig, postConfig],
        );
        await manager.initialize();

        final pending = await manager.totalPendingChanges;

        expect(pending, isA<int>());
      });

      test('totalPendingChanges throws StateError when not initialized', () {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );

        expect(
          () => manager.totalPendingChanges,
          throwsA(isA<StateError>()),
        );
      });

      test('syncStatusStream emits combined status', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        final statusStream = manager.syncStatusStream;

        expect(statusStream, isA<Stream<nexus.SyncStatus>>());
      });

      test('syncStatus getter returns current status', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        expect(manager.syncStatus, nexus.SyncStatus.synced);
      });

      test(
        'updates combined status to error when backend emits error',
        () async {
          // Setup: repository.get fails during sync
          when(() => mockRepository.get<OfflineFirstModel>()).thenThrow(
            Exception('Sync failed'),
          );

          final manager = BrickManager.withRepository(
            repository: mockRepository,
            tables: [userConfig],
          );
          await manager.initialize();

          // Collect statuses
          final statuses = <nexus.SyncStatus>[];
          final subscription = manager.syncStatusStream.listen(statuses.add);

          try {
            await manager.syncAll();
          } on Exception catch (_) {
            // Expected
          }

          await Future<void>.delayed(Duration.zero);
          await subscription.cancel();

          // Should have received error status
          expect(statuses, contains(nexus.SyncStatus.error));
        },
      );

      test('updates status to pending when backend emits pending', () async {
        when(() => mockRepository.upsert<OfflineFirstModel>(any())).thenAnswer(
          (invocation) async =>
              invocation.positionalArguments[0] as OfflineFirstModel,
        );

        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        // Subscribe before operation to capture all status changes
        final statuses = <nexus.SyncStatus>[];
        final subscription = manager.syncStatusStream.listen(statuses.add);

        final backend = manager.getBackend('users');
        final user = TestUser(id: 'test-1', name: 'Test');

        await backend.save(user);

        // Allow stream events to propagate
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        // Should have transitioned through pending
        expect(statuses, contains(nexus.SyncStatus.pending));
      });
    });

    group('dispose', () {
      test('dispose cleans up resources', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        await manager.dispose();

        expect(manager.isInitialized, isFalse);
      });

      test('dispose can be called multiple times safely', () async {
        final manager = BrickManager.withRepository(
          repository: mockRepository,
          tables: [userConfig],
        );
        await manager.initialize();

        await manager.dispose();
        await manager.dispose();

        expect(manager.isInitialized, isFalse);
      });
    });
  });
}
