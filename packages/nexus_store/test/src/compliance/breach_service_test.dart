import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/breach_report.dart';
import 'package:nexus_store/src/compliance/breach_service.dart';
import 'package:nexus_store/src/compliance/breach_storage.dart';

class MockAuditService extends Mock implements AuditService {}

void main() {
  late MockAuditService mockAuditService;
  late InMemoryBreachStorage storage;

  setUpAll(() {
    registerFallbackValue(AuditAction.create);
    registerFallbackValue(BreachReport(
      id: 'test',
      detectedAt: DateTime.now(),
      affectedUsers: [],
      affectedDataCategories: {},
      description: 'test',
    ));
  });

  setUp(() {
    mockAuditService = MockAuditService();
    storage = InMemoryBreachStorage();

    when(() => mockAuditService.query(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          actorId: any(named: 'actorId'),
          action: any(named: 'action'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => []);
  });

  group('BreachEvent', () {
    test('creates with required fields', () {
      final event = BreachEvent(
        timestamp: DateTime.utc(2024, 1, 15),
        action: 'detected',
        actor: 'security-team',
      );

      expect(event.timestamp, equals(DateTime.utc(2024, 1, 15)));
      expect(event.action, equals('detected'));
      expect(event.actor, equals('security-team'));
      expect(event.notes, isNull);
    });

    test('creates with all fields', () {
      final event = BreachEvent(
        timestamp: DateTime.utc(2024, 1, 15),
        action: 'contained',
        actor: 'incident-response',
        notes: 'Access revoked for compromised accounts',
      );

      expect(event.notes, equals('Access revoked for compromised accounts'));
    });

    test('serializes to JSON', () {
      final event = BreachEvent(
        timestamp: DateTime.utc(2024, 1, 15),
        action: 'detected',
        actor: 'system',
      );

      final json = event.toJson();

      expect(json['action'], equals('detected'));
      expect(json['actor'], equals('system'));
    });
  });

  group('AffectedUserInfo', () {
    test('creates with required fields', () {
      final info = AffectedUserInfo(
        userId: 'user-123',
        affectedFields: {'email', 'password'},
      );

      expect(info.userId, equals('user-123'));
      expect(info.affectedFields, containsAll(['email', 'password']));
      expect(info.accessedAt, isNull);
      expect(info.notified, isFalse);
    });

    test('creates with all fields', () {
      final accessTime = DateTime.utc(2024, 1, 15);
      final info = AffectedUserInfo(
        userId: 'user-456',
        affectedFields: {'name', 'address'},
        accessedAt: accessTime,
        notified: true,
      );

      expect(info.accessedAt, equals(accessTime));
      expect(info.notified, isTrue);
    });

    test('supports equality', () {
      final info1 = AffectedUserInfo(
        userId: 'user-123',
        affectedFields: {'email'},
      );

      final info2 = AffectedUserInfo(
        userId: 'user-123',
        affectedFields: {'email'},
      );

      expect(info1, equals(info2));
    });

    test('serializes to JSON', () {
      final info = AffectedUserInfo(
        userId: 'user-789',
        affectedFields: {'ssn'},
        notified: true,
      );

      final json = info.toJson();

      expect(json['userId'], equals('user-789'));
      expect(json['notified'], isTrue);
    });
  });

  group('BreachReport', () {
    test('creates with required fields', () {
      final report = BreachReport(
        id: 'breach-001',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: ['user-1', 'user-2'],
        affectedDataCategories: {'email', 'password'},
        description: 'Unauthorized access detected',
      );

      expect(report.id, equals('breach-001'));
      expect(report.affectedUsers, hasLength(2));
      expect(report.affectedDataCategories, contains('email'));
      expect(report.timeline, isEmpty);
    });

    test('creates with timeline events', () {
      final report = BreachReport(
        id: 'breach-002',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: ['user-1'],
        affectedDataCategories: {'name'},
        description: 'Data leak',
        timeline: [
          BreachEvent(
            timestamp: DateTime.utc(2024, 1, 15, 10, 0),
            action: 'detected',
            actor: 'monitoring-system',
          ),
          BreachEvent(
            timestamp: DateTime.utc(2024, 1, 15, 10, 30),
            action: 'contained',
            actor: 'security-team',
          ),
        ],
      );

      expect(report.timeline.length, equals(2));
    });

    test('supports equality', () {
      final report1 = BreachReport(
        id: 'breach-001',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'Test',
      );

      final report2 = BreachReport(
        id: 'breach-001',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'Test',
      );

      expect(report1, equals(report2));
    });

    test('serializes to JSON', () {
      final report = BreachReport(
        id: 'breach-003',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: ['user-1'],
        affectedDataCategories: {'email'},
        description: 'Breach occurred',
      );

      final json = report.toJson();

      expect(json['id'], equals('breach-003'));
      expect(json['description'], equals('Breach occurred'));
    });
  });

  group('InMemoryBreachStorage', () {
    test('saves and retrieves breach report', () async {
      final report = BreachReport(
        id: 'breach-001',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'Test breach',
      );

      await storage.save(report);
      final retrieved = await storage.get('breach-001');

      expect(retrieved, equals(report));
    });

    test('returns null for non-existent breach', () async {
      final retrieved = await storage.get('non-existent');
      expect(retrieved, isNull);
    });

    test('returns all reports', () async {
      await storage.save(BreachReport(
        id: 'breach-1',
        detectedAt: DateTime.now(),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'First',
      ));
      await storage.save(BreachReport(
        id: 'breach-2',
        detectedAt: DateTime.now(),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'Second',
      ));

      final all = await storage.getAll();

      expect(all.length, equals(2));
    });

    test('updates existing report', () async {
      final original = BreachReport(
        id: 'breach-001',
        detectedAt: DateTime.utc(2024, 1, 15),
        affectedUsers: [],
        affectedDataCategories: {},
        description: 'Original',
      );

      await storage.save(original);

      final updated = original.copyWith(
        description: 'Updated description',
        affectedUsers: ['user-1'],
      );

      await storage.update(updated);
      final retrieved = await storage.get('breach-001');

      expect(retrieved?.description, equals('Updated description'));
      expect(retrieved?.affectedUsers, contains('user-1'));
    });
  });

  group('BreachService', () {
    late BreachService service;

    setUp(() {
      service = BreachService(
        auditService: mockAuditService,
        storage: storage,
      );
    });

    group('identifyAffectedUsers', () {
      test('returns empty list when no audit entries exist', () async {
        final affected = await service.identifyAffectedUsers(
          timeRange: DateTimeRange(
            start: DateTime.utc(2024, 1, 1),
            end: DateTime.utc(2024, 1, 31),
          ),
        );

        expect(affected, isEmpty);
      });

      test('returns affected users from audit logs', () async {
        when(() => mockAuditService.query(
              entityType: any(named: 'entityType'),
              entityId: any(named: 'entityId'),
              actorId: any(named: 'actorId'),
              action: any(named: 'action'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => [
              AuditLogEntry(
                id: 'audit-1',
                timestamp: DateTime.utc(2024, 1, 15),
                action: AuditAction.read,
                entityType: 'User',
                entityId: 'user-123',
                actorId: 'attacker',
                fields: ['email', 'password'],
              ),
              AuditLogEntry(
                id: 'audit-2',
                timestamp: DateTime.utc(2024, 1, 15),
                action: AuditAction.read,
                entityType: 'User',
                entityId: 'user-456',
                actorId: 'attacker',
                fields: ['name'],
              ),
            ]);

        final affected = await service.identifyAffectedUsers(
          timeRange: DateTimeRange(
            start: DateTime.utc(2024, 1, 1),
            end: DateTime.utc(2024, 1, 31),
          ),
        );

        expect(affected.length, equals(2));
        expect(affected.any((u) => u.userId == 'user-123'), isTrue);
        expect(affected.any((u) => u.userId == 'user-456'), isTrue);
      });

      test('aggregates affected fields per user', () async {
        when(() => mockAuditService.query(
              entityType: any(named: 'entityType'),
              entityId: any(named: 'entityId'),
              actorId: any(named: 'actorId'),
              action: any(named: 'action'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => [
              AuditLogEntry(
                id: 'audit-1',
                timestamp: DateTime.utc(2024, 1, 15),
                action: AuditAction.read,
                entityType: 'User',
                entityId: 'user-123',
                actorId: 'attacker',
                fields: ['email'],
              ),
              AuditLogEntry(
                id: 'audit-2',
                timestamp: DateTime.utc(2024, 1, 16),
                action: AuditAction.read,
                entityType: 'User',
                entityId: 'user-123',
                actorId: 'attacker',
                fields: ['password', 'ssn'],
              ),
            ]);

        final affected = await service.identifyAffectedUsers(
          timeRange: DateTimeRange(
            start: DateTime.utc(2024, 1, 1),
            end: DateTime.utc(2024, 1, 31),
          ),
        );

        expect(affected.length, equals(1));
        expect(affected.first.affectedFields, containsAll(['email', 'password', 'ssn']));
      });
    });

    group('generateBreachReport', () {
      test('creates report with affected user data', () async {
        final affectedUsers = [
          AffectedUserInfo(
            userId: 'user-1',
            affectedFields: {'email'},
          ),
          AffectedUserInfo(
            userId: 'user-2',
            affectedFields: {'name', 'address'},
          ),
        ];

        final report = await service.generateBreachReport(
          affectedUsers: affectedUsers,
          description: 'Unauthorized database access',
        );

        expect(report.id, isNotEmpty);
        expect(report.affectedUsers, containsAll(['user-1', 'user-2']));
        expect(report.affectedDataCategories, containsAll(['email', 'name', 'address']));
        expect(report.description, equals('Unauthorized database access'));
      });

      test('stores report in storage', () async {
        final affectedUsers = [
          AffectedUserInfo(
            userId: 'user-1',
            affectedFields: {'email'},
          ),
        ];

        final report = await service.generateBreachReport(
          affectedUsers: affectedUsers,
          description: 'Test breach',
        );

        final stored = await storage.get(report.id);
        expect(stored, isNotNull);
        expect(stored?.description, equals('Test breach'));
      });

      test('adds detection event to timeline', () async {
        final report = await service.generateBreachReport(
          affectedUsers: [],
          description: 'Empty breach',
        );

        expect(report.timeline.length, equals(1));
        expect(report.timeline.first.action, equals('detected'));
      });
    });

    group('recordBreachEvent', () {
      test('adds event to existing report', () async {
        final report = await service.generateBreachReport(
          affectedUsers: [],
          description: 'Test',
        );

        await service.recordBreachEvent(
          breachId: report.id,
          event: BreachEvent(
            timestamp: DateTime.utc(2024, 1, 15, 12, 0),
            action: 'contained',
            actor: 'security-team',
            notes: 'Blocked attacker IP',
          ),
        );

        final updated = await storage.get(report.id);
        expect(updated?.timeline.length, equals(2));
        expect(updated?.timeline.last.action, equals('contained'));
      });
    });

    group('getBreachReport', () {
      test('retrieves stored report', () async {
        final created = await service.generateBreachReport(
          affectedUsers: [],
          description: 'Test',
        );

        final retrieved = await service.getBreachReport(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals(created.id));
      });

      test('returns null for non-existent report', () async {
        final retrieved = await service.getBreachReport('non-existent');
        expect(retrieved, isNull);
      });
    });

    group('getAllBreachReports', () {
      test('returns all stored reports', () async {
        await service.generateBreachReport(
          affectedUsers: [],
          description: 'First',
        );
        await service.generateBreachReport(
          affectedUsers: [],
          description: 'Second',
        );

        final all = await service.getAllBreachReports();

        expect(all.length, equals(2));
      });
    });
  });
}
