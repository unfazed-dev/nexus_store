import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/data_minimization_service.dart';
import 'package:nexus_store/src/compliance/retention_policy.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';

// Mock classes
class MockAuditService extends Mock implements AuditService {}

class MockStoreBackend extends Mock implements StoreBackend<TestEntity, String> {}

// Test entity class
class TestEntity {
  final String id;
  final String userId;
  final String? ipAddress;
  final String? email;
  final DateTime createdAt;
  final bool isActive;

  TestEntity({
    required this.id,
    required this.userId,
    this.ipAddress,
    this.email,
    required this.createdAt,
    this.isActive = true,
  });

  TestEntity copyWith({
    String? id,
    String? userId,
    String? ipAddress,
    String? email,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TestEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ipAddress: ipAddress,
      email: email,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'ipAddress': ipAddress,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };
}

// In-memory test backend using the mixin for defaults
class TestBackend with StoreBackendDefaults<TestEntity, String> {
  final Map<String, TestEntity> _storage = {};

  @override
  String get name => 'TestBackend';

  void addEntity(TestEntity entity) {
    _storage[entity.id] = entity;
  }

  @override
  Future<TestEntity?> get(String id) async => _storage[id];

  @override
  Future<List<TestEntity>> getAll({Query<TestEntity>? query}) async {
    return _storage.values.toList();
  }

  @override
  Future<TestEntity> save(TestEntity item) async {
    _storage[item.id] = item;
    return item;
  }

  @override
  Future<List<TestEntity>> saveAll(List<TestEntity> items) async {
    for (final item in items) {
      _storage[item.id] = item;
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async {
    final existed = _storage.containsKey(id);
    _storage.remove(id);
    return existed;
  }

  @override
  Future<int> deleteAll(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      if (_storage.containsKey(id)) {
        _storage.remove(id);
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<TestEntity> query) async {
    // Simple implementation - just return 0 for testing
    return 0;
  }

  @override
  Stream<TestEntity?> watch(String id) => Stream.value(_storage[id]);

  @override
  Stream<List<TestEntity>> watchAll({Query<TestEntity>? query}) =>
      Stream.value(_storage.values.toList());

  List<TestEntity> get entities => _storage.values.toList();
}

void main() {
  late TestBackend backend;
  late MockAuditService mockAuditService;

  setUpAll(() {
    registerFallbackValue(AuditAction.delete);
    registerFallbackValue(Query<TestEntity>());
  });

  setUp(() {
    backend = TestBackend();
    mockAuditService = MockAuditService();

    when(() => mockAuditService.log(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          fields: any(named: 'fields'),
          previousValues: any(named: 'previousValues'),
          newValues: any(named: 'newValues'),
          success: any(named: 'success'),
          errorMessage: any(named: 'errorMessage'),
          metadata: any(named: 'metadata'),
        )).thenAnswer((_) async => _createMockAuditEntry());
  });

  group('DataMinimizationService', () {
    group('constructor', () {
      test('creates with required parameters', () {
        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
        );

        expect(service, isNotNull);
      });

      test('creates with optional audit service', () {
        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          auditService: mockAuditService,
        );

        expect(service, isNotNull);
      });
    });

    group('processRetention', () {
      test('returns empty result when no entities exist', () async {
        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
        );

        final result = await service.processRetention();

        expect(result.totalProcessed, equals(0));
        expect(result.hasErrors, isFalse);
      });

      test('nullifies expired field', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 31));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          createdAt: expiredDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          fieldNullifier: (entity, field) {
            if (field == 'ipAddress') {
              return entity.copyWith(ipAddress: null);
            }
            return entity;
          },
        );

        final result = await service.processRetention();

        expect(result.nullifiedCount, equals(1));
        final updatedEntity = await backend.get('user-1');
        expect(updatedEntity?.ipAddress, isNull);
      });

      test('does not nullify non-expired field', () async {
        final recentDate = DateTime.now().subtract(const Duration(days: 10));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          createdAt: recentDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          fieldNullifier: (entity, field) {
            if (field == 'ipAddress') {
              return entity.copyWith(ipAddress: null);
            }
            return entity;
          },
        );

        final result = await service.processRetention();

        expect(result.nullifiedCount, equals(0));
        final entity = await backend.get('user-1');
        expect(entity?.ipAddress, equals('192.168.1.1'));
      });

      test('anonymizes expired field', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 366));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          email: 'test@example.com',
          createdAt: expiredDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'email',
              duration: const Duration(days: 365),
              action: RetentionAction.anonymize,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          fieldAnonymizer: (entity, field) {
            if (field == 'email') {
              return entity.copyWith(email: 'anonymized@example.com');
            }
            return entity;
          },
        );

        final result = await service.processRetention();

        expect(result.anonymizedCount, equals(1));
        final entity = await backend.get('user-1');
        expect(entity?.email, equals('anonymized@example.com'));
      });

      test('deletes record when action is deleteRecord', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 91));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          createdAt: expiredDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: '*',
              duration: const Duration(days: 90),
              action: RetentionAction.deleteRecord,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
        );

        final result = await service.processRetention();

        expect(result.deletedCount, equals(1));
        final entity = await backend.get('user-1');
        expect(entity, isNull);
      });

      test('creates audit log for retention action', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 31));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          createdAt: expiredDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          auditService: mockAuditService,
          fieldNullifier: (entity, field) {
            if (field == 'ipAddress') {
              return entity.copyWith(ipAddress: null);
            }
            return entity;
          },
        );

        await service.processRetention();

        verify(() => mockAuditService.log(
              action: AuditAction.update,
              entityType: any(named: 'entityType'),
              entityId: 'user-1',
              fields: any(named: 'fields'),
              previousValues: any(named: 'previousValues'),
              newValues: any(named: 'newValues'),
              success: true,
              errorMessage: any(named: 'errorMessage'),
              metadata: any(named: 'metadata'),
            )).called(1);
      });

      test('processes multiple entities', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 31));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          createdAt: expiredDate,
        ));
        backend.addEntity(TestEntity(
          id: 'user-2',
          userId: 'u2',
          ipAddress: '192.168.1.2',
          createdAt: expiredDate,
        ));
        backend.addEntity(TestEntity(
          id: 'user-3',
          userId: 'u3',
          ipAddress: '192.168.1.3',
          createdAt: DateTime.now(), // Not expired
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          fieldNullifier: (entity, field) {
            if (field == 'ipAddress') {
              return entity.copyWith(ipAddress: null);
            }
            return entity;
          },
        );

        final result = await service.processRetention();

        expect(result.nullifiedCount, equals(2));
      });

      test('applies multiple policies to same entity', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 366));
        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          email: 'test@example.com',
          createdAt: expiredDate,
        ));

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [
            RetentionPolicy(
              field: 'ipAddress',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
            RetentionPolicy(
              field: 'email',
              duration: const Duration(days: 365),
              action: RetentionAction.anonymize,
            ),
          ],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
          fieldNullifier: (entity, field) {
            if (field == 'ipAddress') {
              return entity.copyWith(ipAddress: null);
            }
            return entity;
          },
          fieldAnonymizer: (entity, field) {
            if (field == 'email') {
              return entity.copyWith(email: 'anonymized@example.com');
            }
            return entity;
          },
        );

        final result = await service.processRetention();

        expect(result.nullifiedCount, equals(1));
        expect(result.anonymizedCount, equals(1));
        final entity = await backend.get('user-1');
        expect(entity?.ipAddress, isNull);
        expect(entity?.email, equals('anonymized@example.com'));
      });
    });

    group('getExpiredItems', () {
      test('returns only expired items for policy', () async {
        final expiredDate = DateTime.now().subtract(const Duration(days: 31));
        final recentDate = DateTime.now().subtract(const Duration(days: 10));

        backend.addEntity(TestEntity(
          id: 'user-1',
          userId: 'u1',
          ipAddress: '192.168.1.1',
          createdAt: expiredDate,
        ));
        backend.addEntity(TestEntity(
          id: 'user-2',
          userId: 'u2',
          ipAddress: '192.168.1.2',
          createdAt: recentDate,
        ));

        final policy = RetentionPolicy(
          field: 'ipAddress',
          duration: const Duration(days: 30),
          action: RetentionAction.nullify,
        );

        final service = DataMinimizationService<TestEntity, String>(
          backend: backend,
          policies: [policy],
          timestampExtractor: (entity) => entity.createdAt,
          idExtractor: (entity) => entity.id,
        );

        final expired = await service.getExpiredItems(policy);

        expect(expired.length, equals(1));
        expect(expired.first.id, equals('user-1'));
      });
    });
  });
}

AuditLogEntry _createMockAuditEntry() {
  return AuditLogEntry(
    id: 'audit-1',
    timestamp: DateTime.now(),
    action: AuditAction.update,
    entityType: 'TestEntity',
    entityId: 'test-1',
    actorId: 'system',
  );
}
