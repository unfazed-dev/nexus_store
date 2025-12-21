import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/consent_record.dart';
import 'package:nexus_store/src/compliance/consent_storage.dart';

/// Service for managing user consent tracking.
///
/// Implements GDPR Article 7 requirements for consent management:
/// - Granular consent per purpose
/// - Full audit trail of consent changes
/// - Easy withdrawal mechanism
///
/// ## Example
///
/// ```dart
/// final service = ConsentService(
///   storage: InMemoryConsentStorage(),
///   auditService: auditService,
/// );
///
/// // Record consent
/// await service.recordConsent(
///   userId: 'user-123',
///   purposes: {'marketing', 'analytics'},
///   source: 'signup-form',
/// );
///
/// // Check consent
/// if (await service.hasConsent('user-123', 'marketing')) {
///   sendMarketingEmail(user);
/// }
///
/// // Withdraw consent
/// await service.withdrawConsent(
///   userId: 'user-123',
///   purposes: {'marketing'},
/// );
/// ```
class ConsentService {
  /// Creates a consent service.
  ///
  /// - [storage]: Storage backend for consent records
  /// - [auditService]: Optional audit service for logging
  ConsentService({
    required this.storage,
    this.auditService,
  });

  /// Storage backend for consent records.
  final ConsentStorage storage;

  /// Optional audit service for logging consent changes.
  final AuditService? auditService;

  /// Records consent for the specified purposes.
  ///
  /// Creates a new consent record or updates an existing one.
  Future<void> recordConsent({
    required String userId,
    required Set<String> purposes,
    String? source,
    String? ipAddress,
  }) async {
    final now = DateTime.now();
    final existing = await storage.get(userId);

    final newPurposes = Map<String, ConsentStatus>.from(
      existing?.purposes ?? {},
    );
    final newHistory = List<ConsentEvent>.from(existing?.history ?? []);

    for (final purpose in purposes) {
      newPurposes[purpose] = ConsentStatus(
        granted: true,
        grantedAt: now,
        source: source,
      );

      newHistory.add(ConsentEvent(
        purpose: purpose,
        action: ConsentAction.granted,
        timestamp: now,
        source: source,
        ipAddress: ipAddress,
      ));
    }

    final record = ConsentRecord(
      userId: userId,
      purposes: newPurposes,
      history: newHistory,
      lastUpdated: now,
    );

    await storage.save(record);

    await auditService?.log(
      action: AuditAction.create,
      entityType: 'ConsentRecord',
      entityId: userId,
      fields: purposes.toList(),
      newValues: {'purposes': purposes.toList(), 'source': source},
      success: true,
      metadata: {
        'operation': 'consent_granted',
        'purposes': purposes.toList(),
      },
    );
  }

  /// Withdraws consent for the specified purposes.
  Future<void> withdrawConsent({
    required String userId,
    required Set<String> purposes,
    String? source,
    String? ipAddress,
  }) async {
    final now = DateTime.now();
    final existing = await storage.get(userId);

    if (existing == null) return;

    final newPurposes = Map<String, ConsentStatus>.from(existing.purposes);
    final newHistory = List<ConsentEvent>.from(existing.history);

    for (final purpose in purposes) {
      if (newPurposes.containsKey(purpose)) {
        final previousStatus = newPurposes[purpose]!;
        newPurposes[purpose] = ConsentStatus(
          granted: false,
          grantedAt: previousStatus.grantedAt,
          withdrawnAt: now,
          source: source ?? previousStatus.source,
        );

        newHistory.add(ConsentEvent(
          purpose: purpose,
          action: ConsentAction.withdrawn,
          timestamp: now,
          source: source,
          ipAddress: ipAddress,
        ));
      }
    }

    final record = ConsentRecord(
      userId: userId,
      purposes: newPurposes,
      history: newHistory,
      lastUpdated: now,
    );

    await storage.save(record);

    await auditService?.log(
      action: AuditAction.update,
      entityType: 'ConsentRecord',
      entityId: userId,
      fields: purposes.toList(),
      previousValues: {'purposes': purposes.toList()},
      newValues: {'withdrawn': true},
      success: true,
      metadata: {
        'operation': 'consent_withdrawn',
        'purposes': purposes.toList(),
      },
    );
  }

  /// Gets the current consent record for a user.
  Future<ConsentRecord?> getConsent(String userId) async {
    return storage.get(userId);
  }

  /// Checks if a user has granted consent for a specific purpose.
  Future<bool> hasConsent(String userId, String purpose) async {
    final record = await storage.get(userId);
    if (record == null) return false;

    final status = record.purposes[purpose];
    return status?.granted ?? false;
  }

  /// Gets the full consent history for a user.
  Future<List<ConsentEvent>> getConsentHistory(String userId) async {
    final record = await storage.get(userId);
    return record?.history ?? [];
  }
}
