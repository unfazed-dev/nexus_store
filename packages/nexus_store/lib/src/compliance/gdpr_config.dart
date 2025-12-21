import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/compliance/retention_policy.dart';

part 'gdpr_config.freezed.dart';
part 'gdpr_config.g.dart';

/// Configuration for GDPR compliance features.
///
/// Provides centralized configuration for:
/// - Data minimization (REQ-026)
/// - Consent tracking (REQ-027)
/// - Breach notification (REQ-028)
///
/// ## Example
///
/// ```dart
/// final config = GdprConfig(
///   enabled: true,
///   pseudonymizeFields: ['email', 'phone'],
///   retentionPolicies: [
///     RetentionPolicy(
///       field: 'loginHistory',
///       duration: Duration(days: 90),
///       action: RetentionAction.deleteRecord,
///     ),
///   ],
///   consentTracking: true,
///   requiredPurposes: {'marketing', 'analytics'},
///   breachSupport: true,
/// );
/// ```
@freezed
abstract class GdprConfig with _$GdprConfig {
  const factory GdprConfig({
    /// Whether GDPR compliance is enabled.
    @Default(true) bool enabled,

    /// Fields to pseudonymize instead of delete (for analytics).
    @Default([]) List<String> pseudonymizeFields,

    /// Fields to retain even after erasure (for legal compliance).
    @Default([]) List<String> retainedFields,

    // Data Minimization (REQ-026)

    /// Retention policies for automatic data minimization.
    @Default([]) List<RetentionPolicy> retentionPolicies,

    /// Whether to automatically process retention policies.
    @Default(false) bool autoProcessRetention,

    /// Interval between automatic retention checks.
    Duration? retentionCheckInterval,

    // Consent Tracking (REQ-027)

    /// Whether consent tracking is enabled.
    @Default(false) bool consentTracking,

    /// Required consent purposes that must be granted.
    @Default({}) Set<String> requiredPurposes,

    // Breach Support (REQ-028)

    /// Whether breach notification support is enabled.
    @Default(false) bool breachSupport,

    /// Webhook URLs for breach notifications.
    List<String>? notificationWebhooks,
  }) = _GdprConfig;

  const GdprConfig._();

  factory GdprConfig.fromJson(Map<String, dynamic> json) =>
      _$GdprConfigFromJson(json);

  /// Whether data minimization is configured.
  bool get hasDataMinimization => retentionPolicies.isNotEmpty;

  /// Whether consent tracking is configured.
  bool get hasConsentTracking => consentTracking;

  /// Whether breach support is configured.
  bool get hasBreachSupport => breachSupport;
}
