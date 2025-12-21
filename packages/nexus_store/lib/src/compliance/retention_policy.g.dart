// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retention_policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RetentionPolicy _$RetentionPolicyFromJson(Map<String, dynamic> json) =>
    _RetentionPolicy(
      field: json['field'] as String,
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      action: $enumDecode(_$RetentionActionEnumMap, json['action']),
      condition: json['condition'] as String?,
    );

Map<String, dynamic> _$RetentionPolicyToJson(_RetentionPolicy instance) =>
    <String, dynamic>{
      'field': instance.field,
      'duration': instance.duration.inMicroseconds,
      'action': _$RetentionActionEnumMap[instance.action]!,
      'condition': instance.condition,
    };

const _$RetentionActionEnumMap = {
  RetentionAction.nullify: 'nullify',
  RetentionAction.anonymize: 'anonymize',
  RetentionAction.deleteRecord: 'deleteRecord',
  RetentionAction.archive: 'archive',
};

_RetentionResult _$RetentionResultFromJson(Map<String, dynamic> json) =>
    _RetentionResult(
      processedAt: DateTime.parse(json['processedAt'] as String),
      nullifiedCount: (json['nullifiedCount'] as num).toInt(),
      anonymizedCount: (json['anonymizedCount'] as num).toInt(),
      deletedCount: (json['deletedCount'] as num).toInt(),
      archivedCount: (json['archivedCount'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => RetentionError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RetentionResultToJson(_RetentionResult instance) =>
    <String, dynamic>{
      'processedAt': instance.processedAt.toIso8601String(),
      'nullifiedCount': instance.nullifiedCount,
      'anonymizedCount': instance.anonymizedCount,
      'deletedCount': instance.deletedCount,
      'archivedCount': instance.archivedCount,
      'errors': instance.errors,
    };

_RetentionError _$RetentionErrorFromJson(Map<String, dynamic> json) =>
    _RetentionError(
      entityId: json['entityId'] as String,
      field: json['field'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$RetentionErrorToJson(_RetentionError instance) =>
    <String, dynamic>{
      'entityId': instance.entityId,
      'field': instance.field,
      'message': instance.message,
    };
