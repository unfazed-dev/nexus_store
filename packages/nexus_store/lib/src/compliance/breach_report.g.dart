// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breach_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BreachEvent _$BreachEventFromJson(Map<String, dynamic> json) => _BreachEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      actor: json['actor'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$BreachEventToJson(_BreachEvent instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'action': instance.action,
      'actor': instance.actor,
      'notes': instance.notes,
    };

_AffectedUserInfo _$AffectedUserInfoFromJson(Map<String, dynamic> json) =>
    _AffectedUserInfo(
      userId: json['userId'] as String,
      affectedFields: (json['affectedFields'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      accessedAt: json['accessedAt'] == null
          ? null
          : DateTime.parse(json['accessedAt'] as String),
      notified: json['notified'] as bool? ?? false,
    );

Map<String, dynamic> _$AffectedUserInfoToJson(_AffectedUserInfo instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'affectedFields': instance.affectedFields.toList(),
      'accessedAt': instance.accessedAt?.toIso8601String(),
      'notified': instance.notified,
    };

_BreachReport _$BreachReportFromJson(Map<String, dynamic> json) =>
    _BreachReport(
      id: json['id'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      affectedUsers: (json['affectedUsers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      affectedDataCategories: (json['affectedDataCategories'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      description: json['description'] as String,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => BreachEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BreachReportToJson(_BreachReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'affectedUsers': instance.affectedUsers,
      'affectedDataCategories': instance.affectedDataCategories.toList(),
      'description': instance.description,
      'timeline': instance.timeline,
    };
