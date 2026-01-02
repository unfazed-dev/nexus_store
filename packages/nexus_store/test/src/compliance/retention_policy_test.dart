import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/compliance/retention_policy.dart';

void main() {
  group('RetentionAction', () {
    test('has all required values', () {
      expect(
          RetentionAction.values,
          containsAll([
            RetentionAction.nullify,
            RetentionAction.anonymize,
            RetentionAction.deleteRecord,
            RetentionAction.archive,
          ]));
    });

    test('has exactly 4 values', () {
      expect(RetentionAction.values.length, equals(4));
    });
  });

  group('RetentionPolicy', () {
    test('creates with required fields', () {
      final policy = RetentionPolicy(
        field: 'ipAddress',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
      );

      expect(policy.field, equals('ipAddress'));
      expect(policy.duration, equals(const Duration(days: 30)));
      expect(policy.action, equals(RetentionAction.nullify));
      expect(policy.condition, isNull);
    });

    test('creates with optional condition', () {
      final policy = RetentionPolicy(
        field: 'loginHistory',
        duration: const Duration(days: 90),
        action: RetentionAction.deleteRecord,
        condition: 'status == inactive',
      );

      expect(policy.condition, equals('status == inactive'));
    });

    test('supports equality', () {
      final policy1 = RetentionPolicy(
        field: 'ipAddress',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
      );

      final policy2 = RetentionPolicy(
        field: 'ipAddress',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
      );

      final policy3 = RetentionPolicy(
        field: 'email',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
      );

      expect(policy1, equals(policy2));
      expect(policy1, isNot(equals(policy3)));
    });

    test('supports copyWith', () {
      final original = RetentionPolicy(
        field: 'ipAddress',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
      );

      final modified = original.copyWith(
        duration: const Duration(days: 60),
        action: RetentionAction.anonymize,
      );

      expect(modified.field, equals('ipAddress'));
      expect(modified.duration, equals(const Duration(days: 60)));
      expect(modified.action, equals(RetentionAction.anonymize));
      expect(original.duration, equals(const Duration(days: 30)));
    });

    test('serializes to JSON', () {
      final policy = RetentionPolicy(
        field: 'ipAddress',
        duration: const Duration(days: 30),
        action: RetentionAction.nullify,
        condition: 'active == false',
      );

      final json = policy.toJson();

      expect(json['field'], equals('ipAddress'));
      expect(json['duration'],
          equals(30 * 24 * 60 * 60 * 1000000)); // microseconds
      expect(json['action'], equals('nullify'));
      expect(json['condition'], equals('active == false'));
    });

    test('deserializes from JSON', () {
      final json = {
        'field': 'loginHistory',
        'duration': 90 * 24 * 60 * 60 * 1000000, // 90 days in microseconds
        'action': 'deleteRecord',
        'condition': null,
      };

      final policy = RetentionPolicy.fromJson(json);

      expect(policy.field, equals('loginHistory'));
      expect(policy.duration, equals(const Duration(days: 90)));
      expect(policy.action, equals(RetentionAction.deleteRecord));
      expect(policy.condition, isNull);
    });

    group('retention scenarios', () {
      test('nullify action for IP addresses', () {
        final policy = RetentionPolicy(
          field: 'ipAddress',
          duration: const Duration(days: 30),
          action: RetentionAction.nullify,
        );

        expect(policy.action, equals(RetentionAction.nullify));
      });

      test('anonymize action for sensitive data', () {
        final policy = RetentionPolicy(
          field: 'email',
          duration: const Duration(days: 365),
          action: RetentionAction.anonymize,
        );

        expect(policy.action, equals(RetentionAction.anonymize));
      });

      test('deleteRecord action for full cleanup', () {
        final policy = RetentionPolicy(
          field: 'loginHistory',
          duration: const Duration(days: 90),
          action: RetentionAction.deleteRecord,
        );

        expect(policy.action, equals(RetentionAction.deleteRecord));
      });

      test('archive action for compliance preservation', () {
        final policy = RetentionPolicy(
          field: 'transactionData',
          duration: const Duration(days: 2555), // ~7 years
          action: RetentionAction.archive,
        );

        expect(policy.action, equals(RetentionAction.archive));
      });
    });
  });

  group('RetentionResult', () {
    test('creates with processed counts', () {
      final result = RetentionResult(
        processedAt: DateTime.utc(2024, 1, 15),
        nullifiedCount: 10,
        anonymizedCount: 5,
        deletedCount: 2,
        archivedCount: 3,
        errors: [],
      );

      expect(result.nullifiedCount, equals(10));
      expect(result.anonymizedCount, equals(5));
      expect(result.deletedCount, equals(2));
      expect(result.archivedCount, equals(3));
      expect(result.totalProcessed, equals(20));
      expect(result.hasErrors, isFalse);
    });

    test('calculates totalProcessed correctly', () {
      final result = RetentionResult(
        processedAt: DateTime.utc(2024, 1, 15),
        nullifiedCount: 100,
        anonymizedCount: 50,
        deletedCount: 25,
        archivedCount: 25,
        errors: [],
      );

      expect(result.totalProcessed, equals(200));
    });

    test('tracks errors', () {
      final result = RetentionResult(
        processedAt: DateTime.utc(2024, 1, 15),
        nullifiedCount: 10,
        anonymizedCount: 5,
        deletedCount: 2,
        archivedCount: 3,
        errors: [
          RetentionError(
            entityId: 'user-123',
            field: 'email',
            message: 'Failed to anonymize',
          ),
        ],
      );

      expect(result.hasErrors, isTrue);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.entityId, equals('user-123'));
    });

    test('serializes to JSON', () {
      final result = RetentionResult(
        processedAt: DateTime.utc(2024, 1, 15, 10, 30),
        nullifiedCount: 10,
        anonymizedCount: 5,
        deletedCount: 2,
        archivedCount: 3,
        errors: [],
      );

      final json = result.toJson();

      expect(json['nullifiedCount'], equals(10));
      expect(json['anonymizedCount'], equals(5));
      expect(json['deletedCount'], equals(2));
      expect(json['archivedCount'], equals(3));
    });

    test('deserializes from JSON with all fields', () {
      final json = {
        'processedAt': '2024-01-15T10:30:00.000Z',
        'nullifiedCount': 10,
        'anonymizedCount': 5,
        'deletedCount': 2,
        'archivedCount': 3,
        'errors': <Map<String, dynamic>>[],
      };

      final result = RetentionResult.fromJson(json);

      expect(result.processedAt, equals(DateTime.utc(2024, 1, 15, 10, 30)));
      expect(result.nullifiedCount, equals(10));
      expect(result.anonymizedCount, equals(5));
      expect(result.deletedCount, equals(2));
      expect(result.archivedCount, equals(3));
      expect(result.errors, isEmpty);
      expect(result.totalProcessed, equals(20));
      expect(result.hasErrors, isFalse);
    });

    test('deserializes from JSON with errors', () {
      final json = {
        'processedAt': '2024-01-15T14:00:00.000Z',
        'nullifiedCount': 5,
        'anonymizedCount': 2,
        'deletedCount': 0,
        'archivedCount': 1,
        'errors': [
          {
            'entityId': 'user-123',
            'field': 'email',
            'message': 'Failed to anonymize',
          },
          {
            'entityId': 'user-456',
            'field': 'ipAddress',
            'message': 'Record locked',
          },
        ],
      };

      final result = RetentionResult.fromJson(json);

      expect(result.errors.length, equals(2));
      expect(result.errors[0].entityId, equals('user-123'));
      expect(result.errors[0].field, equals('email'));
      expect(result.errors[0].message, equals('Failed to anonymize'));
      expect(result.errors[1].entityId, equals('user-456'));
      expect(result.hasErrors, isTrue);
    });

    test('round-trips through JSON', () {
      final original = RetentionResult(
        processedAt: DateTime.utc(2024, 1, 15, 12, 0),
        nullifiedCount: 100,
        anonymizedCount: 50,
        deletedCount: 25,
        archivedCount: 25,
        errors: [
          RetentionError(
            entityId: 'user-999',
            field: 'ssn',
            message: 'Compliance hold',
          ),
        ],
      );

      final json = original.toJson();
      // Note: toJson doesn't recursively convert nested objects
      // So we manually convert errors for round-trip test
      json['errors'] =
          original.errors.map((e) => e.toJson()).toList();
      final restored = RetentionResult.fromJson(json);

      expect(restored.processedAt, equals(original.processedAt));
      expect(restored.nullifiedCount, equals(original.nullifiedCount));
      expect(restored.anonymizedCount, equals(original.anonymizedCount));
      expect(restored.deletedCount, equals(original.deletedCount));
      expect(restored.archivedCount, equals(original.archivedCount));
      expect(restored.errors.length, equals(original.errors.length));
    });
  });

  group('RetentionError', () {
    test('creates with required fields', () {
      final error = RetentionError(
        entityId: 'user-456',
        field: 'ipAddress',
        message: 'Record locked',
      );

      expect(error.entityId, equals('user-456'));
      expect(error.field, equals('ipAddress'));
      expect(error.message, equals('Record locked'));
    });

    test('supports equality', () {
      final error1 = RetentionError(
        entityId: 'user-456',
        field: 'ipAddress',
        message: 'Record locked',
      );

      final error2 = RetentionError(
        entityId: 'user-456',
        field: 'ipAddress',
        message: 'Record locked',
      );

      expect(error1, equals(error2));
    });

    test('serializes to JSON', () {
      final error = RetentionError(
        entityId: 'user-789',
        field: 'email',
        message: 'Anonymization failed',
      );

      final json = error.toJson();

      expect(json['entityId'], equals('user-789'));
      expect(json['field'], equals('email'));
      expect(json['message'], equals('Anonymization failed'));
    });

    test('deserializes from JSON', () {
      final json = {
        'entityId': 'user-123',
        'field': 'ipAddress',
        'message': 'Record locked for legal hold',
      };

      final error = RetentionError.fromJson(json);

      expect(error.entityId, equals('user-123'));
      expect(error.field, equals('ipAddress'));
      expect(error.message, equals('Record locked for legal hold'));
    });

    test('round-trips through JSON', () {
      final original = RetentionError(
        entityId: 'user-888',
        field: 'ssn',
        message: 'Compliance requirement prevents deletion',
      );

      final json = original.toJson();
      final restored = RetentionError.fromJson(json);

      expect(restored, equals(original));
    });
  });
}
