import 'package:test/test.dart';
import 'package:nexus_store/src/compliance/gdpr_config.dart';
import 'package:nexus_store/src/compliance/retention_policy.dart';

void main() {
  group('GdprConfig', () {
    test('creates with default values', () {
      const config = GdprConfig();

      expect(config.enabled, isTrue);
      expect(config.pseudonymizeFields, isEmpty);
      expect(config.retainedFields, isEmpty);
      expect(config.retentionPolicies, isEmpty);
      expect(config.autoProcessRetention, isFalse);
      expect(config.retentionCheckInterval, isNull);
      expect(config.consentTracking, isFalse);
      expect(config.requiredPurposes, isEmpty);
      expect(config.breachSupport, isFalse);
      expect(config.notificationWebhooks, isNull);
    });

    test('creates with existing behavior fields', () {
      const config = GdprConfig(
        enabled: true,
        pseudonymizeFields: ['email', 'phone'],
        retainedFields: ['id', 'createdAt'],
      );

      expect(config.enabled, isTrue);
      expect(config.pseudonymizeFields, containsAll(['email', 'phone']));
      expect(config.retainedFields, containsAll(['id', 'createdAt']));
    });

    test('creates with data minimization settings (REQ-026)', () {
      final policies = [
        RetentionPolicy(
          field: 'email',
          duration: const Duration(days: 365),
          action: RetentionAction.anonymize,
        ),
        RetentionPolicy(
          field: 'loginHistory',
          duration: const Duration(days: 90),
          action: RetentionAction.deleteRecord,
        ),
      ];

      final config = GdprConfig(
        retentionPolicies: policies,
        autoProcessRetention: true,
        retentionCheckInterval: const Duration(hours: 24),
      );

      expect(config.retentionPolicies.length, equals(2));
      expect(config.autoProcessRetention, isTrue);
      expect(config.retentionCheckInterval, equals(const Duration(hours: 24)));
    });

    test('creates with consent tracking settings (REQ-027)', () {
      const config = GdprConfig(
        consentTracking: true,
        requiredPurposes: {'marketing', 'analytics', 'personalization'},
      );

      expect(config.consentTracking, isTrue);
      expect(config.requiredPurposes.length, equals(3));
      expect(config.requiredPurposes, contains('marketing'));
    });

    test('creates with breach support settings (REQ-028)', () {
      const config = GdprConfig(
        breachSupport: true,
        notificationWebhooks: [
          'https://example.com/webhook1',
          'https://example.com/webhook2',
        ],
      );

      expect(config.breachSupport, isTrue);
      expect(config.notificationWebhooks?.length, equals(2));
    });

    test('creates with all settings combined', () {
      final config = GdprConfig(
        enabled: true,
        pseudonymizeFields: const ['email'],
        retainedFields: const ['id'],
        retentionPolicies: [
          RetentionPolicy(
            field: 'password',
            duration: const Duration(days: 30),
            action: RetentionAction.nullify,
          ),
        ],
        autoProcessRetention: true,
        retentionCheckInterval: const Duration(hours: 12),
        consentTracking: true,
        requiredPurposes: const {'marketing'},
        breachSupport: true,
        notificationWebhooks: const ['https://example.com/notify'],
      );

      expect(config.enabled, isTrue);
      expect(config.pseudonymizeFields.length, equals(1));
      expect(config.retainedFields.length, equals(1));
      expect(config.retentionPolicies.length, equals(1));
      expect(config.autoProcessRetention, isTrue);
      expect(config.retentionCheckInterval, isNotNull);
      expect(config.consentTracking, isTrue);
      expect(config.requiredPurposes.length, equals(1));
      expect(config.breachSupport, isTrue);
      expect(config.notificationWebhooks?.length, equals(1));
    });

    test('supports equality', () {
      const config1 = GdprConfig(
        enabled: true,
        consentTracking: true,
      );

      const config2 = GdprConfig(
        enabled: true,
        consentTracking: true,
      );

      expect(config1, equals(config2));
    });

    test('supports copyWith', () {
      const original = GdprConfig(
        enabled: true,
        consentTracking: false,
      );

      final updated = original.copyWith(
        consentTracking: true,
        breachSupport: true,
      );

      expect(original.consentTracking, isFalse);
      expect(updated.consentTracking, isTrue);
      expect(updated.breachSupport, isTrue);
      expect(updated.enabled, isTrue);
    });

    test('serializes to JSON', () {
      final config = GdprConfig(
        enabled: true,
        pseudonymizeFields: const ['email'],
        retentionPolicies: [
          RetentionPolicy(
            field: 'password',
            duration: const Duration(days: 30),
            action: RetentionAction.nullify,
          ),
        ],
        consentTracking: true,
        requiredPurposes: const {'marketing'},
      );

      final json = config.toJson();

      expect(json['enabled'], isTrue);
      expect(json['pseudonymizeFields'], contains('email'));
      expect(json['consentTracking'], isTrue);
      expect(json['requiredPurposes'], contains('marketing'));
    });

    test('deserializes from JSON', () {
      final json = {
        'enabled': true,
        'pseudonymizeFields': ['email', 'phone'],
        'retainedFields': <String>[],
        'retentionPolicies': [
          {
            'field': 'password',
            'duration': 2592000000000, // 30 days in microseconds
            'action': 'nullify',
          },
        ],
        'autoProcessRetention': true,
        'retentionCheckInterval': null,
        'consentTracking': false,
        'requiredPurposes': <String>[],
        'breachSupport': true,
        'notificationWebhooks': null,
      };

      final config = GdprConfig.fromJson(json);

      expect(config.enabled, isTrue);
      expect(config.pseudonymizeFields, contains('email'));
      expect(config.retentionPolicies.length, equals(1));
      expect(config.autoProcessRetention, isTrue);
      expect(config.breachSupport, isTrue);
    });

    test('deserializes from JSON with Duration and webhooks', () {
      final json = {
        'enabled': true,
        'pseudonymizeFields': <String>[],
        'retainedFields': <String>[],
        'retentionPolicies': <Map<String, dynamic>>[],
        'autoProcessRetention': true,
        'retentionCheckInterval': 86400000000, // 24 hours in microseconds
        'consentTracking': true,
        'requiredPurposes': ['marketing', 'analytics'],
        'breachSupport': true,
        'notificationWebhooks': [
          'https://example.com/webhook1',
          'https://example.com/webhook2',
        ],
      };

      final config = GdprConfig.fromJson(json);

      expect(config.retentionCheckInterval, equals(const Duration(hours: 24)));
      expect(config.notificationWebhooks?.length, equals(2));
      expect(config.notificationWebhooks,
          contains('https://example.com/webhook1'));
      expect(config.notificationWebhooks,
          contains('https://example.com/webhook2'));
      expect(config.requiredPurposes, containsAll(['marketing', 'analytics']));
    });

    test('round-trips through JSON', () {
      final original = GdprConfig(
        enabled: true,
        pseudonymizeFields: const ['email', 'phone'],
        retainedFields: const ['id'],
        retentionPolicies: [
          RetentionPolicy(
            field: 'loginHistory',
            duration: const Duration(days: 90),
            action: RetentionAction.deleteRecord,
          ),
        ],
        autoProcessRetention: true,
        retentionCheckInterval: const Duration(hours: 12),
        consentTracking: true,
        requiredPurposes: const {'marketing'},
        breachSupport: true,
        notificationWebhooks: const ['https://notify.example.com'],
      );

      final json = original.toJson();
      // Manually convert nested RetentionPolicy for round-trip
      json['retentionPolicies'] =
          original.retentionPolicies.map((p) => p.toJson()).toList();
      final restored = GdprConfig.fromJson(json);

      expect(restored.enabled, equals(original.enabled));
      expect(restored.pseudonymizeFields, equals(original.pseudonymizeFields));
      expect(restored.retainedFields, equals(original.retainedFields));
      expect(restored.retentionPolicies.length,
          equals(original.retentionPolicies.length));
      expect(
          restored.autoProcessRetention, equals(original.autoProcessRetention));
      expect(restored.retentionCheckInterval,
          equals(original.retentionCheckInterval));
      expect(restored.consentTracking, equals(original.consentTracking));
      expect(restored.requiredPurposes, equals(original.requiredPurposes));
      expect(restored.breachSupport, equals(original.breachSupport));
      expect(
          restored.notificationWebhooks, equals(original.notificationWebhooks));
    });

    group('disabled mode', () {
      test('can be disabled', () {
        const config = GdprConfig(enabled: false);
        expect(config.enabled, isFalse);
      });

      test('disabled config ignores other settings semantically', () {
        const config = GdprConfig(
          enabled: false,
          consentTracking: true,
          breachSupport: true,
        );

        // Settings are stored but service should check enabled flag
        expect(config.enabled, isFalse);
        expect(config.consentTracking, isTrue);
        expect(config.breachSupport, isTrue);
      });
    });

    group('hasDataMinimization', () {
      test('returns false when no retention policies', () {
        const config = GdprConfig();
        expect(config.hasDataMinimization, isFalse);
      });

      test('returns true when retention policies exist', () {
        final config = GdprConfig(
          retentionPolicies: [
            RetentionPolicy(
              field: 'email',
              duration: const Duration(days: 30),
              action: RetentionAction.nullify,
            ),
          ],
        );
        expect(config.hasDataMinimization, isTrue);
      });
    });

    group('hasConsentTracking', () {
      test('returns false when consent tracking disabled', () {
        const config = GdprConfig(consentTracking: false);
        expect(config.hasConsentTracking, isFalse);
      });

      test('returns true when consent tracking enabled', () {
        const config = GdprConfig(consentTracking: true);
        expect(config.hasConsentTracking, isTrue);
      });
    });

    group('hasBreachSupport', () {
      test('returns false when breach support disabled', () {
        const config = GdprConfig(breachSupport: false);
        expect(config.hasBreachSupport, isFalse);
      });

      test('returns true when breach support enabled', () {
        const config = GdprConfig(breachSupport: true);
        expect(config.hasBreachSupport, isTrue);
      });
    });
  });
}
