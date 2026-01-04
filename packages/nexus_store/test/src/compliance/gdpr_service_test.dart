import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class MockAuditService extends Mock implements AuditService {}

/// Test backend that supports query filtering for GDPR tests.
class TestGdprBackend
    with StoreBackendDefaults<Map<String, dynamic>, String>
    implements StoreBackend<Map<String, dynamic>, String> {
  final Map<String, Map<String, dynamic>> _storage = {};
  final List<String> deletedIds = [];

  @override
  String get name => 'TestGdprBackend';

  @override
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  @override
  Future<void> initialize() async {}

  @override
  SyncStatus get syncStatus => SyncStatus.synced;

  @override
  Stream<SyncStatus> get syncStatusStream =>
      BehaviorSubject.seeded(SyncStatus.synced).stream;

  @override
  Future<int> get pendingChangesCount async => 0;

  @override
  Future<Map<String, dynamic>?> get(String id) async => _storage[id];

  @override
  Future<List<Map<String, dynamic>>> getAll({
    Query<Map<String, dynamic>>? query,
  }) async {
    var results = _storage.values.toList();

    if (query != null) {
      for (final filter in query.filters) {
        results = results.where((entity) {
          final fieldValue = entity[filter.field];
          return switch (filter.operator) {
            FilterOperator.equals => fieldValue == filter.value,
            _ => true, // Other operators not implemented for test backend
          };
        }).toList();
      }
    }

    return results;
  }

  @override
  Stream<Map<String, dynamic>?> watch(String id) =>
      BehaviorSubject.seeded(_storage[id]).stream;

  @override
  Stream<List<Map<String, dynamic>>> watchAll({
    Query<Map<String, dynamic>>? query,
  }) =>
      BehaviorSubject.seeded(_storage.values.toList()).stream;

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    _storage[id] = item;
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
    List<Map<String, dynamic>> items,
  ) async {
    for (final item in items) {
      await save(item);
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async {
    deletedIds.add(id);
    final existed = _storage.containsKey(id);
    _storage.remove(id);
    return existed;
  }

  @override
  Future<int> deleteAll(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      if (await delete(id)) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async {
    final toDelete = await getAll(query: query);
    for (final entity in toDelete) {
      await delete(entity['id'] as String);
    }
    return toDelete.length;
  }

  @override
  Future<void> sync() async {}

  @override
  Future<void> close() async {}

  /// Add test data.
  void addEntity(Map<String, dynamic> entity) {
    _storage[entity['id'] as String] = entity;
  }

  /// Get current storage state.
  Map<String, dynamic>? getEntity(String id) => _storage[id];
}

void main() {
  setUpAll(() {
    registerFallbackValue(AuditAction.read);
  });

  group('GdprService', () {
    late TestGdprBackend backend;
    late GdprService<Map<String, dynamic>, String> service;

    setUp(() {
      backend = TestGdprBackend();
      service = GdprService(
        backend: backend,
        subjectIdField: 'userId',
      );
    });

    group('constructor', () {
      test('should create service with required parameters', () {
        expect(service.backend, equals(backend));
        expect(service.subjectIdField, equals('userId'));
        expect(service.auditService, isNull);
        expect(service.pseudonymizeFields, isEmpty);
        expect(service.retainedFields, isEmpty);
      });

      test('should accept optional parameters', () {
        final auditService = MockAuditService();
        final serviceWithOptions = GdprService<Map<String, dynamic>, String>(
          backend: backend,
          subjectIdField: 'userId',
          auditService: auditService,
          pseudonymizeFields: ['email', 'name'],
          retainedFields: ['createdAt'],
        );

        expect(serviceWithOptions.auditService, equals(auditService));
        expect(
          serviceWithOptions.pseudonymizeFields,
          equals(['email', 'name']),
        );
        expect(serviceWithOptions.retainedFields, equals(['createdAt']));
      });
    });

    group('exportSubjectData', () {
      test('should export all data for a subject (Article 20)', () async {
        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John Doe',
          'email': 'john@example.com',
        });
        backend.addEntity({
          'id': 'record-2',
          'userId': 'user-123',
          'data': 'Some data',
        });
        backend.addEntity({
          'id': 'record-3',
          'userId': 'user-456',
          'name': 'Other User',
        });

        final export = await service.exportSubjectData('user-123');

        expect(export.subjectId, equals('user-123'));
        expect(export.entityCount, equals(2));
        expect(export.data, hasLength(2));
        expect(export.exportDate, isA<DateTime>());
      });

      test('should return empty export when no data found', () async {
        final export = await service.exportSubjectData('non-existent');

        expect(export.entityCount, equals(0));
        expect(export.data, isEmpty);
      });

      test('should log audit when auditService provided', () async {
        final auditService = MockAuditService();
        final mockEntry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.export_,
          entityType: 'Map<String, dynamic>',
          entityId: 'user-123',
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

        final serviceWithAudit = GdprService<Map<String, dynamic>, String>(
          backend: backend,
          subjectIdField: 'userId',
          auditService: auditService,
        );

        await serviceWithAudit.exportSubjectData('user-123');

        verify(
          () => auditService.log(
            action: AuditAction.export_,
            entityType: any(named: 'entityType'),
            entityId: 'user-123',
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });
    });

    group('eraseSubjectData', () {
      test('should erase all data for a subject (Article 17)', () async {
        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John Doe',
        });
        backend.addEntity({
          'id': 'record-2',
          'userId': 'user-123',
          'data': 'Some data',
        });
        backend.addEntity({
          'id': 'record-3',
          'userId': 'user-456',
          'name': 'Other User',
        });

        final summary = await service.eraseSubjectData('user-123');

        expect(summary.subjectId, equals('user-123'));
        expect(summary.deletedCount, equals(2));
        expect(summary.pseudonymizedCount, equals(0));
        expect(summary.totalAffected, equals(2));
        expect(backend.deletedIds, containsAll(['record-1', 'record-2']));
        expect(backend.getEntity('record-3'), isNotNull);
      });

      test('should return empty summary when no data found', () async {
        final summary = await service.eraseSubjectData('non-existent');

        expect(summary.deletedCount, equals(0));
        expect(summary.pseudonymizedCount, equals(0));
        expect(summary.totalAffected, equals(0));
      });

      test('should pseudonymize when configured', () async {
        final pseudonymService = GdprService<Map<String, dynamic>, String>(
          backend: backend,
          subjectIdField: 'userId',
          pseudonymizeFields: ['name', 'email'],
        );

        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final summary = await pseudonymService.eraseSubjectData(
          'user-123',
          pseudonymize: true,
        );

        expect(summary.deletedCount, equals(0));
        expect(summary.pseudonymizedCount, equals(1));

        final entity = backend.getEntity('record-1');
        expect(entity?['name'], startsWith('REDACTED-'));
        expect(entity?['email'], startsWith('REDACTED-'));
      });

      test('should retain specified fields during pseudonymization', () async {
        final pseudonymService = GdprService<Map<String, dynamic>, String>(
          backend: backend,
          subjectIdField: 'userId',
          pseudonymizeFields: ['name', 'email', 'createdAt'],
          retainedFields: ['createdAt'],
        );

        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John Doe',
          'email': 'john@example.com',
          'createdAt': '2024-01-01',
        });

        await pseudonymService.eraseSubjectData(
          'user-123',
          pseudonymize: true,
        );

        final entity = backend.getEntity('record-1');
        expect(entity?['name'], startsWith('REDACTED-'));
        expect(entity?['email'], startsWith('REDACTED-'));
        expect(entity?['createdAt'], equals('2024-01-01'));
      });
    });

    group('accessSubjectData', () {
      test('should return access report (Article 15)', () async {
        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final report = await service.accessSubjectData('user-123');

        expect(report.subjectId, equals('user-123'));
        expect(report.entityCount, equals(1));
        expect(
          report.categories,
          containsAll(['id', 'userId', 'name', 'email']),
        );
        expect(report.retentionPeriod, isNotEmpty);
        expect(report.purposes, isNotEmpty);
        expect(report.reportDate, isA<DateTime>());
      });

      test('should return empty report when no data found', () async {
        final report = await service.accessSubjectData('non-existent');

        expect(report.entityCount, equals(0));
        expect(report.categories, isEmpty);
      });

      test('should combine categories from multiple entities', () async {
        backend.addEntity({
          'id': 'record-1',
          'userId': 'user-123',
          'name': 'John',
        });
        backend.addEntity({
          'id': 'record-2',
          'userId': 'user-123',
          'email': 'john@example.com',
          'phone': '555-1234',
        });

        final report = await service.accessSubjectData('user-123');

        expect(report.entityCount, equals(2));
        expect(
          report.categories,
          containsAll(['name', 'email', 'phone']),
        );
      });
    });
  });

  group('GdprExport', () {
    test('should create with required properties', () {
      final export = GdprExport(
        subjectId: 'user-123',
        exportDate: DateTime.utc(2024),
        entityType: 'User',
        entityCount: 5,
        data: [
          {'id': '1'},
          {'id': '2'},
        ],
      );

      expect(export.subjectId, equals('user-123'));
      expect(export.exportDate, equals(DateTime.utc(2024)));
      expect(export.entityType, equals('User'));
      expect(export.entityCount, equals(5));
      expect(export.data, hasLength(2));
    });

    test('should serialize to JSON', () {
      final export = GdprExport(
        subjectId: 'user-123',
        exportDate: DateTime.utc(2024),
        entityType: 'User',
        entityCount: 1,
        data: [
          {'name': 'John'},
        ],
      );

      final json = export.toJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['subjectId'], equals('user-123'));
      expect(decoded['entityType'], equals('User'));
      expect(decoded['entityCount'], equals(1));
      expect(decoded['data'], hasLength(1));
    });
  });

  group('ErasureSummary', () {
    test('should create with required properties', () {
      final summary = ErasureSummary(
        subjectId: 'user-123',
        erasureDate: DateTime.utc(2024),
        deletedCount: 5,
        pseudonymizedCount: 3,
      );

      expect(summary.subjectId, equals('user-123'));
      expect(summary.erasureDate, equals(DateTime.utc(2024)));
      expect(summary.deletedCount, equals(5));
      expect(summary.pseudonymizedCount, equals(3));
    });

    test('should compute totalAffected correctly', () {
      final summary = ErasureSummary(
        subjectId: 'user-123',
        erasureDate: DateTime.utc(2024),
        deletedCount: 5,
        pseudonymizedCount: 3,
      );

      expect(summary.totalAffected, equals(8));
    });

    test('should return zero totalAffected when nothing affected', () {
      final summary = ErasureSummary(
        subjectId: 'user-123',
        erasureDate: DateTime.utc(2024),
        deletedCount: 0,
        pseudonymizedCount: 0,
      );

      expect(summary.totalAffected, equals(0));
    });
  });

  group('AccessReport', () {
    test('should create with required properties', () {
      final report = AccessReport(
        subjectId: 'user-123',
        reportDate: DateTime.utc(2024),
        entityType: 'User',
        entityCount: 5,
        categories: ['name', 'email', 'phone'],
        retentionPeriod: '5 years',
        purposes: ['Service provision', 'Analytics'],
      );

      expect(report.subjectId, equals('user-123'));
      expect(report.reportDate, equals(DateTime.utc(2024)));
      expect(report.entityType, equals('User'));
      expect(report.entityCount, equals(5));
      expect(report.categories, hasLength(3));
      expect(report.retentionPeriod, equals('5 years'));
      expect(report.purposes, hasLength(2));
    });
  });

  group('GdprService audit logging (lines 107, 109, 130, 132)', () {
    late TestGdprBackend backend;
    late MockAuditService mockAuditService;
    late GdprService<Map<String, dynamic>, String> service;

    setUp(() {
      backend = TestGdprBackend();
      mockAuditService = MockAuditService();
      service = GdprService<Map<String, dynamic>, String>(
        backend: backend,
        subjectIdField: 'userId',
        auditService: mockAuditService,
      );
    });

    test('logs audit event during erasure with entity type and metadata (lines 107, 109)',
        () async {
      when(() => mockAuditService.log(
            action: any(named: 'action'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => AuditLogEntry(
                id: 'log-1',
                timestamp: DateTime.now(),
                action: AuditAction.delete,
                entityType: 'Test',
                entityId: 'test-id',
                actorId: 'system',
              ));

      backend.addEntity({
        'id': 'record-1',
        'userId': 'user-123',
        'name': 'John Doe',
      });

      await service.eraseSubjectData('user-123');

      verify(() => mockAuditService.log(
            action: AuditAction.delete,
            entityType: 'Map<String, dynamic>', // T.toString() - line 107
            entityId: 'user-123',
            metadata: {
              'operation': 'gdpr_erasure', // line 109
              'deletedCount': 1,
              'pseudonymizedCount': 0,
            },
          )).called(1);
    });

    test('logs audit event during access with entity type and metadata (lines 130, 132)',
        () async {
      when(() => mockAuditService.log(
            action: any(named: 'action'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => AuditLogEntry(
                id: 'log-2',
                timestamp: DateTime.now(),
                action: AuditAction.read,
                entityType: 'Test',
                entityId: 'test-id',
                actorId: 'system',
              ));

      backend.addEntity({
        'id': 'record-1',
        'userId': 'user-123',
        'name': 'John Doe',
      });
      backend.addEntity({
        'id': 'record-2',
        'userId': 'user-123',
        'email': 'john@example.com',
      });

      await service.accessSubjectData('user-123');

      verify(() => mockAuditService.log(
            action: AuditAction.read,
            entityType: 'Map<String, dynamic>', // T.toString() - line 130
            entityId: 'user-123',
            metadata: {
              'operation': 'gdpr_access', // line 132
              'entityCount': 2,
            },
          )).called(1);
    });
  });
}
