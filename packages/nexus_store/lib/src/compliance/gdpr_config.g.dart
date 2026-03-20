// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gdpr_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GdprConfig _$GdprConfigFromJson(Map<String, dynamic> json) => _GdprConfig(
      enabled: json['enabled'] as bool? ?? true,
      pseudonymizeFields: (json['pseudonymizeFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      retainedFields: (json['retainedFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      retentionPolicies: (json['retentionPolicies'] as List<dynamic>?)
              ?.map((e) => RetentionPolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      autoProcessRetention: json['autoProcessRetention'] as bool? ?? false,
      retentionCheckInterval: json['retentionCheckInterval'] == null
          ? null
          : Duration(
              microseconds: (json['retentionCheckInterval'] as num).toInt()),
      consentTracking: json['consentTracking'] as bool? ?? false,
      requiredPurposes: (json['requiredPurposes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      breachSupport: json['breachSupport'] as bool? ?? false,
      notificationWebhooks: (json['notificationWebhooks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GdprConfigToJson(_GdprConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'pseudonymizeFields': instance.pseudonymizeFields,
      'retainedFields': instance.retainedFields,
      'retentionPolicies': instance.retentionPolicies,
      'autoProcessRetention': instance.autoProcessRetention,
      'retentionCheckInterval': instance.retentionCheckInterval?.inMicroseconds,
      'consentTracking': instance.consentTracking,
      'requiredPurposes': instance.requiredPurposes.toList(),
      'breachSupport': instance.breachSupport,
      'notificationWebhooks': instance.notificationWebhooks,
    };
