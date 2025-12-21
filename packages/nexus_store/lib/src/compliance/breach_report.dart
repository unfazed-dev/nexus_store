import 'package:freezed_annotation/freezed_annotation.dart';

part 'breach_report.freezed.dart';
part 'breach_report.g.dart';

/// A single event in the breach timeline.
@freezed
abstract class BreachEvent with _$BreachEvent {
  const factory BreachEvent({
    /// When this event occurred.
    required DateTime timestamp,

    /// The action taken (e.g., 'detected', 'contained', 'notified').
    required String action,

    /// Who performed this action.
    required String actor,

    /// Additional notes about this event.
    String? notes,
  }) = _BreachEvent;

  const BreachEvent._();

  factory BreachEvent.fromJson(Map<String, dynamic> json) =>
      _$BreachEventFromJson(json);
}

/// Information about a user affected by a breach.
@freezed
abstract class AffectedUserInfo with _$AffectedUserInfo {
  const factory AffectedUserInfo({
    /// The user's identifier.
    required String userId,

    /// The fields/data categories that were affected.
    required Set<String> affectedFields,

    /// When the user's data was accessed (if known).
    DateTime? accessedAt,

    /// Whether the user has been notified of the breach.
    @Default(false) bool notified,
  }) = _AffectedUserInfo;

  const AffectedUserInfo._();

  factory AffectedUserInfo.fromJson(Map<String, dynamic> json) =>
      _$AffectedUserInfoFromJson(json);
}

/// A complete breach report.
///
/// Contains all information needed for GDPR breach notification
/// to supervisory authorities and affected individuals.
@freezed
abstract class BreachReport with _$BreachReport {
  const factory BreachReport({
    /// Unique identifier for this breach.
    required String id,

    /// When the breach was detected.
    required DateTime detectedAt,

    /// List of affected user IDs.
    required List<String> affectedUsers,

    /// Categories of data that were affected.
    required Set<String> affectedDataCategories,

    /// Description of the breach.
    required String description,

    /// Timeline of events related to this breach.
    @Default([]) List<BreachEvent> timeline,
  }) = _BreachReport;

  const BreachReport._();

  factory BreachReport.fromJson(Map<String, dynamic> json) =>
      _$BreachReportFromJson(json);
}
