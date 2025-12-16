import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

class MockAuditService extends Mock implements AuditService {}

void main() {
  setUpAll(() {
    registerFallbackValue(AuditAction.read);
  });

  group('NexusStore', () {
    late FakeStoreBackend<TestUser, String> backend;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    group('constructor', () {
      test('should create with default config', () {
        final store = NexusStore<TestUser, String>(backend: backend);

        expect(store.backend, equals(backend));
        expect(store.config, equals(StoreConfig.defaults));
        expect(store.audit, isNull);
        expect(store.gdpr, isNull);
      });

      test('should create with custom config', () {
        const config = StoreConfig(
          fetchPolicy: FetchPolicy.networkFirst,
          writePolicy: WritePolicy.cacheFirst,
        );

        final store = NexusStore<TestUser, String>(
          backend: backend,
          config: config,
        );

        expect(store.config, equals(config));
      });

      test('should accept audit service', () {
        final auditService = MockAuditService();

        final store = NexusStore<TestUser, String>(
          backend: backend,
          auditService: auditService,
        );

        expect(store.audit, equals(auditService));
      });

      test('should create GDPR service when enabled', () {
        const config = StoreConfig(
          enableGdpr: true,
        );

        final store = NexusStore<TestUser, String>(
          backend: backend,
          config: config,
          subjectIdField: 'userId',
        );

        expect(store.gdpr, isNotNull);
      });

      test('should not create GDPR service without subjectIdField', () {
        const config = StoreConfig(
          enableGdpr: true,
        );

        final store = NexusStore<TestUser, String>(
          backend: backend,
          config: config,
        );

        expect(store.gdpr, isNull);
      });
    });

    group('lifecycle', () {
      late NexusStore<TestUser, String> store;

      setUp(() {
        store = NexusStore<TestUser, String>(backend: backend);
      });

      test('should start uninitialized', () {
        expect(store.isInitialized, isFalse);
        expect(store.isDisposed, isFalse);
      });

      test('should initialize successfully', () async {
        await store.initialize();

        expect(store.isInitialized, isTrue);
        expect(store.isDisposed, isFalse);
      });

      test('should be idempotent on multiple initialize calls', () async {
        await store.initialize();
        await store.initialize();

        expect(store.isInitialized, isTrue);
      });

      test('should dispose successfully', () async {
        await store.initialize();
        await store.dispose();

        expect(store.isDisposed, isTrue);
      });

      test('should be idempotent on multiple dispose calls', () async {
        await store.initialize();
        await store.dispose();
        await store.dispose();

        expect(store.isDisposed, isTrue);
      });

      test('should be safe to call initialize after dispose', () async {
        await store.initialize();
        await store.dispose();

        // Due to idempotent _initialized check,
        // this returns early without error
        await expectLater(store.initialize(), completes);
      });
    });

    group('state checks', () {
      late NexusStore<TestUser, String> store;

      setUp(() {
        store = NexusStore<TestUser, String>(backend: backend);
      });

      test('should throw on get before initialize', () async {
        expect(
          () => store.get('user-1'),
          throwsStateError,
        );
      });

      test('should throw on getAll before initialize', () async {
        expect(
          () => store.getAll(),
          throwsStateError,
        );
      });

      test('should throw on watch before initialize', () {
        expect(
          () => store.watch('user-1'),
          throwsStateError,
        );
      });

      test('should throw on watchAll before initialize', () {
        expect(
          () => store.watchAll(),
          throwsStateError,
        );
      });

      test('should throw on save before initialize', () async {
        expect(
          () => store.save(TestFixtures.createUser()),
          throwsStateError,
        );
      });

      test('should throw on delete before initialize', () async {
        expect(
          () => store.delete('user-1'),
          throwsStateError,
        );
      });

      test('should throw on sync before initialize', () async {
        expect(
          () => store.sync(),
          throwsStateError,
        );
      });

      test('should throw on get after dispose', () async {
        await store.initialize();
        await store.dispose();

        expect(
          () => store.get('user-1'),
          throwsStateError,
        );
      });
    });

    group('get', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should return entity when found', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await store.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when not found', () async {
        final result = await store.get('non-existent');

        expect(result, isNull);
      });

      test('should use default fetch policy', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await store.get('user-1');

        expect(result, isNotNull);
      });

      test('should allow policy override', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await store.get(
          'user-1',
          policy: FetchPolicy.cacheOnly,
        );

        expect(result, isNotNull);
      });
    });

    group('getAll', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should return all entities', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        final results = await store.getAll();

        expect(results, hasLength(2));
      });

      test('should return empty list when no entities', () async {
        final results = await store.getAll();

        expect(results, isEmpty);
      });

      test('should accept query parameter', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await store.getAll(query: const Query<TestUser>());

        expect(results, hasLength(1));
      });

      test('should allow policy override', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await store.getAll(
          policy: FetchPolicy.cacheOnly,
        );

        expect(results, hasLength(1));
      });
    });

    group('watch', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should emit current value', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final stream = store.watch('user-1');
        final result = await stream.first;

        expect(result, equals(user));
      });

      test('should emit null for non-existent entity', () async {
        final stream = store.watch('non-existent');
        final result = await stream.first;

        expect(result, isNull);
      });
    });

    group('watchAll', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should emit current list', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final stream = store.watchAll();
        final results = await stream.first;

        expect(results, hasLength(1));
      });

      test('should emit empty list when no entities', () async {
        final stream = store.watchAll();
        final results = await stream.first;

        expect(results, isEmpty);
      });
    });

    group('save', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should save entity', () async {
        final user = TestFixtures.createUser();

        final result = await store.save(user);

        expect(result, equals(user));
        expect(backend.storage['user-1'], equals(user));
      });

      test('should allow policy override', () async {
        final user = TestFixtures.createUser();

        final result = await store.save(
          user,
          policy: WritePolicy.cacheFirst,
        );

        expect(result, equals(user));
      });
    });

    group('saveAll', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should save multiple entities', () async {
        final users = TestFixtures.createUsers(3);

        final results = await store.saveAll(users);

        expect(results, hasLength(3));
        expect(backend.storage, hasLength(3));
      });

      test('should allow policy override', () async {
        final users = TestFixtures.createUsers(2);

        final results = await store.saveAll(
          users,
          policy: WritePolicy.cacheFirst,
        );

        expect(results, hasLength(2));
      });
    });

    group('delete', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should delete existing entity', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await store.delete('user-1');

        expect(result, isTrue);
        expect(backend.storage.containsKey('user-1'), isFalse);
      });

      test('should return false for non-existent entity', () async {
        final result = await store.delete('non-existent');

        expect(result, isFalse);
      });

      test('should allow policy override', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await store.delete(
          'user-1',
          policy: WritePolicy.cacheFirst,
        );

        expect(result, isTrue);
      });
    });

    group('deleteAll', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should delete multiple entities', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));
        backend.addToStorage('user-3', TestFixtures.createUser(id: 'user-3'));

        final count = await store.deleteAll(['user-1', 'user-2']);

        expect(count, equals(2));
        expect(backend.storage, hasLength(1));
      });

      test('should return count of actually deleted', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final count = await store.deleteAll(['user-1', 'non-existent']);

        expect(count, equals(1));
      });

      test('should allow policy override', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final count = await store.deleteAll(
          ['user-1'],
          policy: WritePolicy.cacheFirst,
        );

        expect(count, equals(1));
      });
    });

    group('sync', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should trigger backend sync', () async {
        await expectLater(store.sync(), completes);
      });

      test('should expose sync status', () {
        expect(store.syncStatus, equals(SyncStatus.synced));
      });

      test('should expose sync status stream', () async {
        final status = await store.syncStatusStream.first;
        expect(status, equals(SyncStatus.synced));
      });

      test('should expose pending changes count', () async {
        final count = await store.pendingChangesCount;
        expect(count, equals(0));
      });
    });

    group('cache management', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(
          backend: backend,
          config: const StoreConfig(
            staleDuration: Duration(minutes: 5),
          ),
        );
        await store.initialize();
      });

      test('should invalidate single entity', () {
        backend.addToStorage('user-1', TestFixtures.createUser());

        store.invalidate('user-1');

        // Invalidation marks as stale - subsequent get would try network
        // We can only verify this doesn't throw
      });

      test('should invalidate all entities', () {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        store.invalidateAll();

        // Invalidation marks as stale - subsequent get would try network
        // We can only verify this doesn't throw
      });
    });

    group('audit logging', () {
      late MockAuditService auditService;
      late NexusStore<TestUser, String> store;

      setUp(() async {
        auditService = MockAuditService();
        final mockEntry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'TestUser',
          entityId: 'user-1',
          actorId: 'system',
        );
        when(
          () => auditService.log(
            action: any(named: 'action'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          ),
        ).thenAnswer((_) async => mockEntry);

        store = NexusStore<TestUser, String>(
          backend: backend,
          config: const StoreConfig(
            enableAuditLogging: true,
          ),
          auditService: auditService,
        );
        await store.initialize();
      });

      test('should log read on get', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        await store.get('user-1');

        verify(
          () => auditService.log(
            action: AuditAction.read,
            entityType: any(named: 'entityType'),
            entityId: 'user-1',
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });

      test('should not log read when result is null', () async {
        await store.get('non-existent');

        verifyNever(
          () => auditService.log(
            action: AuditAction.read,
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          ),
        );
      });

      test('should log list on getAll', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        await store.getAll();

        verify(
          () => auditService.log(
            action: AuditAction.list,
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });

      test('should log update on save', () async {
        final user = TestFixtures.createUser();

        await store.save(user);

        verify(
          () => auditService.log(
            action: AuditAction.update,
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });

      test('should log delete on delete', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        await store.delete('user-1');

        verify(
          () => auditService.log(
            action: AuditAction.delete,
            entityType: any(named: 'entityType'),
            entityId: 'user-1',
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });

      test('should not log delete when entity not found', () async {
        await store.delete('non-existent');

        verifyNever(
          () => auditService.log(
            action: AuditAction.delete,
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          ),
        );
      });
    });
  });
}
