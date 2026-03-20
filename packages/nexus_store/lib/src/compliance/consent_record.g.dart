// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConsentStatus _$ConsentStatusFromJson(Map<String, dynamic> json) =>
    _ConsentStatus(
      granted: json['granted'] as bool,
      grantedAt: json['grantedAt'] == null
          ? null
          : DateTime.parse(json['grantedAt'] as String),
      withdrawnAt: json['withdrawnAt'] == null
          ? null
          : DateTime.parse(json['withdrawnAt'] as String),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$ConsentStatusToJson(_ConsentStatus instance) =>
    <String, dynamic>{
      'granted': instance.granted,
      'grantedAt': instance.grantedAt?.toIso8601String(),
      'withdrawnAt': instance.withdrawnAt?.toIso8601String(),
      'source': instance.source,
    };

_ConsentEvent _$ConsentEventFromJson(Map<String, dynamic> json) =>
    _ConsentEvent(
      purpose: json['purpose'] as String,
      action: $enumDecode(_$ConsentActionEnumMap, json['action']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String?,
      ipAddress: json['ipAddress'] as String?,
    );

Map<String, dynamic> _$ConsentEventToJson(_ConsentEvent instance) =>
    <String, dynamic>{
      'purpose': instance.purpose,
      'action': _$ConsentActionEnumMap[instance.action]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'source': instance.source,
      'ipAddress': instance.ipAddress,
    };

const _$ConsentActionEnumMap = {
  ConsentAction.granted: 'granted',
  ConsentAction.withdrawn: 'withdrawn',
};

_ConsentRecord _$ConsentRecordFromJson(Map<String, dynamic> json) =>
    _ConsentRecord(
      userId: json['userId'] as String,
      purposes: (json['purposes'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, ConsentStatus.fromJson(e as Map<String, dynamic>)),
      ),
      history: (json['history'] as List<dynamic>)
          .map((e) => ConsentEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$ConsentRecordToJson(_ConsentRecord instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'purposes': instance.purposes,
      'history': instance.history,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
