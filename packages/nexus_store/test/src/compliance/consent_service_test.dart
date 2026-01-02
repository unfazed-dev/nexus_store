import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/consent_record.dart';
import 'package:nexus_store/src/compliance/consent_service.dart';
import 'package:nexus_store/src/compliance/consent_storage.dart';

class MockAuditService extends Mock implements AuditService {}

class MockConsentStorage extends Mock implements ConsentStorage {}

void main() {
  late MockAuditService mockAuditService;
  late InMemoryConsentStorage storage;

  setUpAll(() {
    registerFallbackValue(AuditAction.create);
    registerFallbackValue(ConsentRecord(
      userId: 'test',
      purposes: {},
      history: [],
      lastUpdated: DateTime.now(),
    ));
  });

  setUp(() {
    mockAuditService = MockAuditService();
    storage = InMemoryConsentStorage();

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

  group('ConsentAction', () {
    test('has all required values', () {
      expect(
          ConsentAction.values,
          containsAll([
            ConsentAction.granted,
            ConsentAction.withdrawn,
          ]));
    });

    test('has exactly 2 values', () {
      expect(ConsentAction.values.length, equals(2));
    });
  });

  group('ConsentStatus', () {
    test('creates with required fields', () {
      final status = ConsentStatus(granted: true);

      expect(status.granted, isTrue);
      expect(status.grantedAt, isNull);
      expect(status.withdrawnAt, isNull);
      expect(status.source, isNull);
    });

    test('creates with all fields', () {
      final grantedAt = DateTime.utc(2024, 1, 15);
      final status = ConsentStatus(
        granted: true,
        grantedAt: grantedAt,
        source: 'signup-form',
      );

      expect(status.granted, isTrue);
      expect(status.grantedAt, equals(grantedAt));
      expect(status.source, equals('signup-form'));
    });

    test('serializes to JSON', () {
      final status = ConsentStatus(
        granted: true,
        grantedAt: DateTime.utc(2024, 1, 15),
        source: 'web',
      );

      final json = status.toJson();

      expect(json['granted'], isTrue);
      expect(json['source'], equals('web'));
    });

    test('deserializes from JSON with required fields', () {
      final json = {
        'granted': true,
      };

      final status = ConsentStatus.fromJson(json);

      expect(status.granted, isTrue);
      expect(status.grantedAt, isNull);
      expect(status.withdrawnAt, isNull);
      expect(status.source, isNull);
    });

    test('deserializes from JSON with all fields', () {
      final json = {
        'granted': true,
        'grantedAt': '2024-01-15T00:00:00.000Z',
        'withdrawnAt': '2024-02-01T12:00:00.000Z',
        'source': 'signup-form',
      };

      final status = ConsentStatus.fromJson(json);

      expect(status.granted, isTrue);
      expect(status.grantedAt, equals(DateTime.utc(2024, 1, 15)));
      expect(status.withdrawnAt, equals(DateTime.utc(2024, 2, 1, 12)));
      expect(status.source, equals('signup-form'));
    });

    test('round-trips through JSON', () {
      final original = ConsentStatus(
        granted: false,
        grantedAt: DateTime.utc(2024, 1, 15),
        withdrawnAt: DateTime.utc(2024, 2, 1),
        source: 'settings-page',
      );

      final json = original.toJson();
      final restored = ConsentStatus.fromJson(json);

      expect(restored, equals(original));
    });
  });

  group('ConsentEvent', () {
    test('creates with required fields', () {
      final event = ConsentEvent(
        purpose: 'marketing',
        action: ConsentAction.granted,
        timestamp: DateTime.utc(2024, 1, 15),
      );

      expect(event.purpose, equals('marketing'));
      expect(event.action, equals(ConsentAction.granted));
      expect(event.source, isNull);
      expect(event.ipAddress, isNull);
    });

    test('creates with all fields', () {
      final event = ConsentEvent(
        purpose: 'analytics',
        action: ConsentAction.withdrawn,
        timestamp: DateTime.utc(2024, 1, 15),
        source: 'settings-page',
        ipAddress: '192.168.1.1',
      );

      expect(event.purpose, equals('analytics'));
      expect(event.action, equals(ConsentAction.withdrawn));
      expect(event.source, equals('settings-page'));
      expect(event.ipAddress, equals('192.168.1.1'));
    });

    test('serializes to JSON', () {
      final event = ConsentEvent(
        purpose: 'marketing',
        action: ConsentAction.granted,
        timestamp: DateTime.utc(2024, 1, 15),
      );

      final json = event.toJson();

      expect(json['purpose'], equals('marketing'));
      expect(json['action'], equals('granted'));
    });

    test('deserializes from JSON with required fields', () {
      final json = {
        'purpose': 'marketing',
        'action': 'granted',
        'timestamp': '2024-01-15T00:00:00.000Z',
      };

      final event = ConsentEvent.fromJson(json);

      expect(event.purpose, equals('marketing'));
      expect(event.action, equals(ConsentAction.granted));
      expect(event.timestamp, equals(DateTime.utc(2024, 1, 15)));
      expect(event.source, isNull);
      expect(event.ipAddress, isNull);
    });

    test('deserializes from JSON with all fields', () {
      final json = {
        'purpose': 'analytics',
        'action': 'withdrawn',
        'timestamp': '2024-01-15T14:30:00.000Z',
        'source': 'settings-page',
        'ipAddress': '192.168.1.1',
      };

      final event = ConsentEvent.fromJson(json);

      expect(event.purpose, equals('analytics'));
      expect(event.action, equals(ConsentAction.withdrawn));
      expect(event.timestamp, equals(DateTime.utc(2024, 1, 15, 14, 30)));
      expect(event.source, equals('settings-page'));
      expect(event.ipAddress, equals('192.168.1.1'));
    });

    test('round-trips through JSON', () {
      final original = ConsentEvent(
        purpose: 'personalization',
        action: ConsentAction.granted,
        timestamp: DateTime.utc(2024, 1, 15, 10, 30),
        source: 'mobile-app',
        ipAddress: '10.0.0.1',
      );

      final json = original.toJson();
      final restored = ConsentEvent.fromJson(json);

      expect(restored, equals(original));
    });
  });

  group('ConsentRecord', () {
    test('creates with required fields', () {
      final record = ConsentRecord(
        userId: 'user-123',
        purposes: {},
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      expect(record.userId, equals('user-123'));
      expect(record.purposes, isEmpty);
      expect(record.history, isEmpty);
    });

    test('creates with purposes', () {
      final record = ConsentRecord(
        userId: 'user-123',
        purposes: {
          'marketing': ConsentStatus(granted: true),
          'analytics': ConsentStatus(granted: false),
        },
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      expect(record.purposes['marketing']?.granted, isTrue);
      expect(record.purposes['analytics']?.granted, isFalse);
    });

    test('supports equality', () {
      final record1 = ConsentRecord(
        userId: 'user-123',
        purposes: {},
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      final record2 = ConsentRecord(
        userId: 'user-123',
        purposes: {},
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      expect(record1, equals(record2));
    });

    test('serializes to JSON', () {
      final record = ConsentRecord(
        userId: 'user-456',
        purposes: {
          'marketing': ConsentStatus(granted: true),
        },
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      final json = record.toJson();

      expect(json['userId'], equals('user-456'));
      expect(json['purposes'], isNotEmpty);
    });

    test('deserializes from JSON with required fields', () {
      final json = {
        'userId': 'user-123',
        'purposes': {
          'marketing': {'granted': true},
        },
        'history': <Map<String, dynamic>>[],
        'lastUpdated': '2024-01-15T00:00:00.000Z',
      };

      final record = ConsentRecord.fromJson(json);

      expect(record.userId, equals('user-123'));
      expect(record.purposes['marketing']?.granted, isTrue);
      expect(record.history, isEmpty);
      expect(record.lastUpdated, equals(DateTime.utc(2024, 1, 15)));
    });

    test('deserializes from JSON with nested purposes', () {
      final json = {
        'userId': 'user-456',
        'purposes': {
          'marketing': {
            'granted': true,
            'grantedAt': '2024-01-15T10:00:00.000Z',
            'source': 'signup-form',
          },
          'analytics': {
            'granted': false,
            'withdrawnAt': '2024-02-01T00:00:00.000Z',
          },
        },
        'history': <Map<String, dynamic>>[],
        'lastUpdated': '2024-02-01T00:00:00.000Z',
      };

      final record = ConsentRecord.fromJson(json);

      expect(record.purposes.length, equals(2));
      expect(record.purposes['marketing']?.granted, isTrue);
      expect(record.purposes['marketing']?.source, equals('signup-form'));
      expect(record.purposes['analytics']?.granted, isFalse);
    });

    test('deserializes from JSON with history', () {
      final json = {
        'userId': 'user-789',
        'purposes': <String, dynamic>{},
        'history': [
          {
            'purpose': 'marketing',
            'action': 'granted',
            'timestamp': '2024-01-15T10:00:00.000Z',
            'source': 'signup',
          },
          {
            'purpose': 'marketing',
            'action': 'withdrawn',
            'timestamp': '2024-02-01T14:30:00.000Z',
            'ipAddress': '192.168.1.1',
          },
        ],
        'lastUpdated': '2024-02-01T14:30:00.000Z',
      };

      final record = ConsentRecord.fromJson(json);

      expect(record.history.length, equals(2));
      expect(record.history[0].purpose, equals('marketing'));
      expect(record.history[0].action, equals(ConsentAction.granted));
      expect(record.history[0].source, equals('signup'));
      expect(record.history[1].action, equals(ConsentAction.withdrawn));
      expect(record.history[1].ipAddress, equals('192.168.1.1'));
    });
  });

  group('ConsentPurpose', () {
    test('has marketing constant', () {
      expect(ConsentPurpose.marketing, equals('marketing'));
    });

    test('has analytics constant', () {
      expect(ConsentPurpose.analytics, equals('analytics'));
    });

    test('has personalization constant', () {
      expect(ConsentPurpose.personalization, equals('personalization'));
    });

    test('has thirdPartySharing constant', () {
      expect(ConsentPurpose.thirdPartySharing, equals('third_party_sharing'));
    });

    test('has profiling constant', () {
      expect(ConsentPurpose.profiling, equals('profiling'));
    });
  });

  group('InMemoryConsentStorage', () {
    test('saves and retrieves consent record', () async {
      final record = ConsentRecord(
        userId: 'user-123',
        purposes: {'marketing': ConsentStatus(granted: true)},
        history: [],
        lastUpdated: DateTime.utc(2024, 1, 15),
      );

      await storage.save(record);
      final retrieved = await storage.get('user-123');

      expect(retrieved, equals(record));
    });

    test('returns null for non-existent user', () async {
      final retrieved = await storage.get('non-existent');
      expect(retrieved, isNull);
    });

    test('returns all records', () async {
      await storage.save(ConsentRecord(
        userId: 'user-1',
        purposes: {},
        history: [],
        lastUpdated: DateTime.now(),
      ));
      await storage.save(ConsentRecord(
        userId: 'user-2',
        purposes: {},
        history: [],
        lastUpdated: DateTime.now(),
      ));

      final all = await storage.getAll();

      expect(all.length, equals(2));
    });
  });

  group('ConsentService', () {
    late ConsentService service;

    setUp(() {
      service = ConsentService(
        storage: storage,
        auditService: mockAuditService,
      );
    });

    group('recordConsent', () {
      test('records consent for single purpose', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
          source: 'signup-form',
        );

        final consent = await service.getConsent('user-123');

        expect(consent, isNotNull);
        expect(consent!.purposes['marketing']?.granted, isTrue);
      });

      test('records consent for multiple purposes', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing', 'analytics', 'personalization'},
          source: 'settings',
        );

        final consent = await service.getConsent('user-123');

        expect(consent!.purposes['marketing']?.granted, isTrue);
        expect(consent.purposes['analytics']?.granted, isTrue);
        expect(consent.purposes['personalization']?.granted, isTrue);
      });

      test('adds event to history', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final consent = await service.getConsent('user-123');

        expect(consent!.history.length, equals(1));
        expect(consent.history.first.purpose, equals('marketing'));
        expect(consent.history.first.action, equals(ConsentAction.granted));
      });

      test('logs to audit service', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        verify(() => mockAuditService.log(
              action: AuditAction.create,
              entityType: any(named: 'entityType'),
              entityId: 'user-123',
              fields: any(named: 'fields'),
              previousValues: any(named: 'previousValues'),
              newValues: any(named: 'newValues'),
              success: true,
              errorMessage: any(named: 'errorMessage'),
              metadata: any(named: 'metadata'),
            )).called(1);
      });

      test('stores IP address if provided', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
          ipAddress: '192.168.1.1',
        );

        final consent = await service.getConsent('user-123');

        expect(consent!.history.first.ipAddress, equals('192.168.1.1'));
      });
    });

    group('withdrawConsent', () {
      test('withdraws consent for purpose', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing', 'analytics'},
        );

        await service.withdrawConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final consent = await service.getConsent('user-123');

        expect(consent!.purposes['marketing']?.granted, isFalse);
        expect(consent.purposes['analytics']?.granted, isTrue);
      });

      test('adds withdrawal event to history', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        await service.withdrawConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final consent = await service.getConsent('user-123');

        expect(consent!.history.length, equals(2));
        expect(consent.history.last.action, equals(ConsentAction.withdrawn));
      });

      test('logs withdrawal to audit service', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        await service.withdrawConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        verify(() => mockAuditService.log(
              action: AuditAction.update,
              entityType: any(named: 'entityType'),
              entityId: 'user-123',
              fields: any(named: 'fields'),
              previousValues: any(named: 'previousValues'),
              newValues: any(named: 'newValues'),
              success: true,
              errorMessage: any(named: 'errorMessage'),
              metadata: any(named: 'metadata'),
            )).called(1);
      });
    });

    group('hasConsent', () {
      test('returns true when consent is granted', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final hasConsent = await service.hasConsent('user-123', 'marketing');

        expect(hasConsent, isTrue);
      });

      test('returns false when consent is not granted', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'analytics'},
        );

        final hasConsent = await service.hasConsent('user-123', 'marketing');

        expect(hasConsent, isFalse);
      });

      test('returns false for non-existent user', () async {
        final hasConsent =
            await service.hasConsent('non-existent', 'marketing');

        expect(hasConsent, isFalse);
      });

      test('returns false after withdrawal', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        await service.withdrawConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final hasConsent = await service.hasConsent('user-123', 'marketing');

        expect(hasConsent, isFalse);
      });
    });

    group('getConsentHistory', () {
      test('returns full history', () async {
        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        await service.withdrawConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        await service.recordConsent(
          userId: 'user-123',
          purposes: {'marketing'},
        );

        final history = await service.getConsentHistory('user-123');

        expect(history.length, equals(3));
        expect(history[0].action, equals(ConsentAction.granted));
        expect(history[1].action, equals(ConsentAction.withdrawn));
        expect(history[2].action, equals(ConsentAction.granted));
      });

      test('returns empty list for non-existent user', () async {
        final history = await service.getConsentHistory('non-existent');

        expect(history, isEmpty);
      });
    });
  });
}

AuditLogEntry _createMockAuditEntry() {
  return AuditLogEntry(
    id: 'audit-1',
    timestamp: DateTime.now(),
    action: AuditAction.create,
    entityType: 'ConsentRecord',
    entityId: 'test-1',
    actorId: 'system',
  );
}
