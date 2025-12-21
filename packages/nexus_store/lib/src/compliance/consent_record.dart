import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent_record.freezed.dart';
part 'consent_record.g.dart';

/// Actions that can be taken on consent.
enum ConsentAction {
  /// Consent was granted.
  granted,

  /// Consent was withdrawn.
  withdrawn,
}

/// Predefined consent purpose constants.
///
/// These are common GDPR-compliant purposes. Custom purposes can also be used.
class ConsentPurpose {
  ConsentPurpose._();

  /// Marketing communications.
  static const String marketing = 'marketing';

  /// Analytics and usage tracking.
  static const String analytics = 'analytics';

  /// Personalization of content and experience.
  static const String personalization = 'personalization';

  /// Sharing data with third parties.
  static const String thirdPartySharing = 'third_party_sharing';

  /// User profiling for targeted content.
  static const String profiling = 'profiling';
}

/// Status of consent for a specific purpose.
@freezed
abstract class ConsentStatus with _$ConsentStatus {
  const factory ConsentStatus({
    /// Whether consent is currently granted.
    required bool granted,

    /// When consent was granted.
    DateTime? grantedAt,

    /// When consent was withdrawn.
    DateTime? withdrawnAt,

    /// Source of the consent (e.g., 'signup-form', 'settings-page').
    String? source,
  }) = _ConsentStatus;

  const ConsentStatus._();

  factory ConsentStatus.fromJson(Map<String, dynamic> json) =>
      _$ConsentStatusFromJson(json);
}

/// A single consent event in the history.
@freezed
abstract class ConsentEvent with _$ConsentEvent {
  const factory ConsentEvent({
    /// The purpose this event relates to.
    required String purpose,

    /// The action taken (granted or withdrawn).
    required ConsentAction action,

    /// When this event occurred.
    required DateTime timestamp,

    /// Source of the consent action.
    String? source,

    /// IP address of the user when action was taken.
    String? ipAddress,
  }) = _ConsentEvent;

  const ConsentEvent._();

  factory ConsentEvent.fromJson(Map<String, dynamic> json) =>
      _$ConsentEventFromJson(json);
}

/// Complete consent record for a user.
///
/// Contains current consent status for each purpose and full history.
@freezed
abstract class ConsentRecord with _$ConsentRecord {
  const factory ConsentRecord({
    /// Unique identifier for the data subject.
    required String userId,

    /// Map of purpose to current consent status.
    required Map<String, ConsentStatus> purposes,

    /// Full history of all consent events.
    required List<ConsentEvent> history,

    /// When this record was last updated.
    required DateTime lastUpdated,
  }) = _ConsentRecord;

  const ConsentRecord._();

  factory ConsentRecord.fromJson(Map<String, dynamic> json) =>
      _$ConsentRecordFromJson(json);
}
