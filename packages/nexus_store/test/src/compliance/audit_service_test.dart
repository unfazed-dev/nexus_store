import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('AuditService', () {
    late InMemoryAuditStorage storage;
    late AuditService service;

    setUp(() {
      storage = InMemoryAuditStorage();
      service = AuditService(
        storage: storage,
        actorProvider: () async => 'test-actor',
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    group('constructor', () {
      test('should create service with required parameters', () {
        expect(service.enabled, isTrue);
        expect(service.hashChainEnabled, isTrue);
      });

      test('should allow disabling audit logging', () {
        final disabledService = AuditService(
          storage: storage,
          actorProvider: () async => 'actor',
          enabled: false,
        );

        expect(disabledService.enabled, isFalse);
      });

      test('should allow disabling hash chain', () {
        final noHashService = AuditService(
          storage: storage,
          actorProvider: () async => 'actor',
          hashChainEnabled: false,
        );

        expect(noHashService.hashChainEnabled, isFalse);
      });
    });

    group('log', () {
      test('should create audit log entry', () async {
        final entry = await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
        );

        expect(entry.action, equals(AuditAction.read));
        expect(entry.entityType, equals('User'));
        expect(entry.entityId, equals('user-123'));
        expect(entry.actorId, equals('test-actor'));
      });

      test('should assign unique id to entry', () async {
        final entry1 = await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
        );
        final entry2 = await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-2',
        );

        expect(entry1.id, isNotEmpty);
        expect(entry2.id, isNotEmpty);
        expect(entry1.id, isNot(equals(entry2.id)));
      });

      test('should compute hash for entry', () async {
        final entry = await service.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-123',
        );

        expect(entry.hash, isNotNull);
        expect(entry.hash, isNotEmpty);
      });

      test('should link entries with previousHash', () async {
        final entry1 = await service.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
        );
        final entry2 = await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
        );

        expect(entry1.previousHash, isNull);
        expect(entry2.previousHash, equals(entry1.hash));
      });

      test('should store entry in storage', () async {
        await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
        );

        final entries = await storage.query();
        expect(entries, hasLength(1));
      });

      test('should emit entry to stream', () async {
        // Skip the initial empty seed value and wait for first
        // non-empty emission
        final entriesFuture = service.entries
            .firstWhere((entries) => entries.isNotEmpty);

        await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
        );

        final entries = await entriesFuture;
        expect(entries, hasLength(1));
      });

      test('should include optional fields', () async {
        final entry = await service.log(
          action: AuditAction.update,
          entityType: 'User',
          entityId: 'user-123',
          fields: ['name', 'email'],
          previousValues: {'name': 'Old Name'},
          newValues: {'name': 'New Name'},
          success: false,
          errorMessage: 'Permission denied',
          metadata: {'source': 'api'},
        );

        expect(entry.fields, equals(['name', 'email']));
        expect(entry.previousValues, equals({'name': 'Old Name'}));
        expect(entry.newValues, equals({'name': 'New Name'}));
        expect(entry.success, isFalse);
        expect(entry.errorMessage, equals('Permission denied'));
        expect(entry.metadata['source'], equals('api'));
      });

      test('should use metadataProvider when available', () async {
        final serviceWithMetadata = AuditService(
          storage: storage,
          actorProvider: () async => 'actor',
          metadataProvider: () async => {'ip': '127.0.0.1'},
        );

        final entry = await serviceWithMetadata.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
        );

        expect(entry.metadata['ip'], equals('127.0.0.1'));
        await serviceWithMetadata.dispose();
      });

      test('should skip logging when disabled', () async {
        final disabledService = AuditService(
          storage: storage,
          actorProvider: () async => 'actor',
          enabled: false,
        );

        await disabledService.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
        );

        final entries = await storage.query();
        expect(entries, isEmpty);
        await disabledService.dispose();
      });
    });

    group('query', () {
      setUp(() async {
        // Create some test entries
        await service.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
        );
        await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
        );
        await service.log(
          action: AuditAction.read,
          entityType: 'Product',
          entityId: 'product-1',
        );
      });

      test('should return all entries when no filters', () async {
        final entries = await service.query();
        expect(entries, hasLength(3));
      });

      test('should filter by entityType', () async {
        final entries = await service.query(entityType: 'User');
        expect(entries, hasLength(2));
        expect(entries.every((e) => e.entityType == 'User'), isTrue);
      });

      test('should filter by entityId', () async {
        final entries = await service.query(entityId: 'product-1');
        expect(entries, hasLength(1));
        expect(entries.first.entityId, equals('product-1'));
      });

      test('should filter by action', () async {
        final entries = await service.query(action: AuditAction.create);
        expect(entries, hasLength(1));
        expect(entries.first.action, equals(AuditAction.create));
      });

      test('should filter by actorId', () async {
        final entries = await service.query(actorId: 'test-actor');
        expect(entries, hasLength(3));
      });
    });

    group('verifyIntegrity', () {
      test('should return true for valid hash chain', () async {
        await service.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
        );
        await service.log(
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
        );

        final isValid = await service.verifyIntegrity();
        expect(isValid, isTrue);
      });

      test('should return true when hash chain disabled', () async {
        final noHashService = AuditService(
          storage: InMemoryAuditStorage(),
          actorProvider: () async => 'actor',
          hashChainEnabled: false,
        );

        await noHashService.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
        );

        final isValid = await noHashService.verifyIntegrity();
        expect(isValid, isTrue);
        await noHashService.dispose();
      });
    });

    group('export', () {
      test('should export entries as JSON', () async {
        await service.log(
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
        );

        final exportJson = await service.export(
          startDate: DateTime(2020),
          endDate: DateTime(2030),
        );

        expect(exportJson, contains('entries'));
        expect(exportJson, contains('entryCount'));
        expect(exportJson, contains('user-1'));
      });
    });
  });

  group('InMemoryAuditStorage', () {
    late InMemoryAuditStorage storage;

    setUp(() {
      storage = InMemoryAuditStorage();
    });

    group('append', () {
      test('should add entry to storage', () async {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
          actorId: 'actor-1',
        );

        await storage.append(entry);

        final entries = await storage.query();
        expect(entries, hasLength(1));
        expect(entries.first.id, equals('entry-1'));
      });
    });

    group('query', () {
      setUp(() async {
        await storage.append(AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime(2024),
          action: AuditAction.create,
          entityType: 'User',
          entityId: 'user-1',
          actorId: 'actor-1',
        ),);
        await storage.append(AuditLogEntry(
          id: 'entry-2',
          timestamp: DateTime(2024, 1, 2),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
          actorId: 'actor-2',
        ),);
        await storage.append(AuditLogEntry(
          id: 'entry-3',
          timestamp: DateTime(2024, 1, 3),
          action: AuditAction.read,
          entityType: 'Product',
          entityId: 'product-1',
          actorId: 'actor-1',
        ),);
      });

      test('should filter by date range', () async {
        final entries = await storage.query(
          startDate: DateTime(2024, 1, 2),
          endDate: DateTime(2024, 1, 2, 23, 59, 59),
        );

        expect(entries, hasLength(1));
        expect(entries.first.id, equals('entry-2'));
      });

      test('should apply limit', () async {
        final entries = await storage.query(limit: 2);
        expect(entries, hasLength(2));
      });

      test('should apply offset', () async {
        final entries = await storage.query(offset: 1);
        expect(entries, hasLength(2));
        expect(entries.first.id, equals('entry-2'));
      });
    });

    group('getLastEntry', () {
      test('should return null when empty', () async {
        final last = await storage.getLastEntry();
        expect(last, isNull);
      });

      test('should return last entry', () async {
        await storage.append(AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-1',
          actorId: 'actor-1',
        ),);
        await storage.append(AuditLogEntry(
          id: 'entry-2',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-2',
          actorId: 'actor-1',
        ),);

        final last = await storage.getLastEntry();
        expect(last?.id, equals('entry-2'));
      });
    });
  });
}
