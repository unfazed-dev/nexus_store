import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('AuditLogEntry', () {
    group('constructor', () {
      test('should create entry with required properties', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime(2024),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry.id, equals('entry-1'));
        expect(entry.timestamp, equals(DateTime(2024)));
        expect(entry.action, equals(AuditAction.read));
        expect(entry.entityType, equals('User'));
        expect(entry.entityId, equals('user-123'));
        expect(entry.actorId, equals('actor-1'));
      });

      test('should have default actorType of user', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry.actorType, equals(ActorType.user));
      });

      test('should have default empty fields list', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry.fields, isEmpty);
      });

      test('should have default success as true', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry.success, isTrue);
      });

      test('should have default empty metadata', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry.metadata, isEmpty);
      });

      test('should accept optional properties', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.now(),
          action: AuditAction.update,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
          actorType: ActorType.service,
          fields: ['name', 'email'],
          previousValues: {'name': 'Old'},
          newValues: {'name': 'New'},
          ipAddress: '192.168.1.1',
          userAgent: 'TestAgent',
          sessionId: 'session-1',
          requestId: 'req-1',
          success: false,
          errorMessage: 'Failed',
          metadata: {'key': 'value'},
          previousHash: 'abc123',
          hash: 'def456',
        );

        expect(entry.actorType, equals(ActorType.service));
        expect(entry.fields, equals(['name', 'email']));
        expect(entry.previousValues, equals({'name': 'Old'}));
        expect(entry.newValues, equals({'name': 'New'}));
        expect(entry.ipAddress, equals('192.168.1.1'));
        expect(entry.userAgent, equals('TestAgent'));
        expect(entry.sessionId, equals('session-1'));
        expect(entry.requestId, equals('req-1'));
        expect(entry.success, isFalse);
        expect(entry.errorMessage, equals('Failed'));
        expect(entry.metadata, equals({'key': 'value'}));
        expect(entry.previousHash, equals('abc123'));
        expect(entry.hash, equals('def456'));
      });
    });

    group('copyWith', () {
      test('should create copy with changed properties', () {
        final original = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime(2024),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        final modified = original.copyWith(action: AuditAction.update);

        expect(original.action, equals(AuditAction.read));
        expect(modified.action, equals(AuditAction.update));
        expect(modified.id, equals('entry-1'));
      });
    });

    group('toJson/fromJson', () {
      test('should serialize to JSON', () {
        final entry = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime.utc(2024),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        final json = entry.toJson();

        expect(json['id'], equals('entry-1'));
        expect(json['entityType'], equals('User'));
        expect(json['entityId'], equals('user-123'));
        expect(json['action'], equals('read'));
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'entry-1',
          'timestamp': '2024-01-01T00:00:00.000Z',
          'action': 'read',
          'entityType': 'User',
          'entityId': 'user-123',
          'actorId': 'actor-1',
          'actorType': 'user',
          'fields': <String>[],
          'success': true,
          'metadata': <String, dynamic>{},
        };

        final entry = AuditLogEntry.fromJson(json);

        expect(entry.id, equals('entry-1'));
        expect(entry.action, equals(AuditAction.read));
        expect(entry.entityType, equals('User'));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final entry1 = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime(2024),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );
        final entry2 = AuditLogEntry(
          id: 'entry-1',
          timestamp: DateTime(2024),
          action: AuditAction.read,
          entityType: 'User',
          entityId: 'user-123',
          actorId: 'actor-1',
        );

        expect(entry1, equals(entry2));
      });
    });
  });

  group('AuditAction', () {
    test('should have all expected values', () {
      expect(AuditAction.values, hasLength(12));
      expect(AuditAction.values, contains(AuditAction.create));
      expect(AuditAction.values, contains(AuditAction.read));
      expect(AuditAction.values, contains(AuditAction.update));
      expect(AuditAction.values, contains(AuditAction.delete));
      expect(AuditAction.values, contains(AuditAction.list));
      expect(AuditAction.values, contains(AuditAction.export_));
      expect(AuditAction.values, contains(AuditAction.import_));
      expect(AuditAction.values, contains(AuditAction.accessDenied));
      expect(AuditAction.values, contains(AuditAction.login));
      expect(AuditAction.values, contains(AuditAction.logout));
      expect(AuditAction.values, contains(AuditAction.keyAccess));
      expect(AuditAction.values, contains(AuditAction.decrypt));
    });
  });

  group('ActorType', () {
    test('should have all expected values', () {
      expect(ActorType.values, hasLength(5));
      expect(ActorType.values, contains(ActorType.user));
      expect(ActorType.values, contains(ActorType.service));
      expect(ActorType.values, contains(ActorType.system));
      expect(ActorType.values, contains(ActorType.apiClient));
      expect(ActorType.values, contains(ActorType.anonymous));
    });
  });
}
