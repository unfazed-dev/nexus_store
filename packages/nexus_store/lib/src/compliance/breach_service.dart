import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/breach_report.dart';
import 'package:nexus_store/src/compliance/breach_storage.dart';
import 'package:uuid/uuid.dart';

/// Date range for breach investigation.
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});
}

/// Service for managing breach notifications.
///
/// Implements GDPR Article 33 and 34 requirements for breach notification:
/// - Identification of affected data subjects
/// - Report generation for supervisory authorities
/// - Timeline tracking for breach response
///
/// ## Example
///
/// ```dart
/// final service = BreachService(
///   auditService: auditService,
///   storage: InMemoryBreachStorage(),
/// );
///
/// // Identify affected users
/// final affected = await service.identifyAffectedUsers(
///   timeRange: DateTimeRange(
///     start: breachStartTime,
///     end: breachEndTime,
///   ),
/// );
///
/// // Generate report
/// final report = await service.generateBreachReport(
///   affectedUsers: affected,
///   description: 'Unauthorized database access',
/// );
///
/// // Track response
/// await service.recordBreachEvent(
///   breachId: report.id,
///   event: BreachEvent(
///     timestamp: DateTime.now(),
///     action: 'notified_authority',
///     actor: 'dpo@company.com',
///   ),
/// );
/// ```
class BreachService {
  /// Creates a breach service.
  BreachService({
    required this.auditService,
    required this.storage,
  });

  /// Audit service for identifying affected users.
  final AuditService auditService;

  /// Storage for breach reports.
  final BreachStorage storage;

  static const _uuid = Uuid();

  /// Identifies users affected during a time range.
  ///
  /// Queries audit logs to find all data access during the breach window
  /// and aggregates affected fields per user.
  Future<List<AffectedUserInfo>> identifyAffectedUsers({
    required DateTimeRange timeRange,
    String? entityType,
  }) async {
    final entries = await auditService.query(
      startDate: timeRange.start,
      endDate: timeRange.end,
      entityType: entityType,
    );

    // Aggregate affected fields per user
    final userMap = <String, Set<String>>{};
    final accessTimes = <String, DateTime>{};

    for (final entry in entries) {
      final userId = entry.entityId;
      userMap.putIfAbsent(userId, () => {});
      userMap[userId]!.addAll(entry.fields);

      // Track earliest access time
      if (!accessTimes.containsKey(userId) ||
          entry.timestamp.isBefore(accessTimes[userId]!)) {
        accessTimes[userId] = entry.timestamp;
      }
    }

    return userMap.entries.map((entry) {
      return AffectedUserInfo(
        userId: entry.key,
        affectedFields: entry.value,
        accessedAt: accessTimes[entry.key],
      );
    }).toList();
  }

  /// Generates a breach report from affected user data.
  ///
  /// Creates a comprehensive report suitable for regulatory notification.
  Future<BreachReport> generateBreachReport({
    required List<AffectedUserInfo> affectedUsers,
    required String description,
  }) async {
    final now = DateTime.now();

    // Aggregate all affected data categories
    final allCategories = <String>{};
    for (final user in affectedUsers) {
      allCategories.addAll(user.affectedFields);
    }

    final report = BreachReport(
      id: _uuid.v4(),
      detectedAt: now,
      affectedUsers: affectedUsers.map((u) => u.userId).toList(),
      affectedDataCategories: allCategories,
      description: description,
      timeline: [
        BreachEvent(
          timestamp: now,
          action: 'detected',
          actor: 'system',
        ),
      ],
    );

    await storage.save(report);

    return report;
  }

  /// Records an event in the breach timeline.
  Future<void> recordBreachEvent({
    required String breachId,
    required BreachEvent event,
  }) async {
    final report = await storage.get(breachId);
    if (report == null) return;

    final updatedTimeline = [...report.timeline, event];
    final updated = report.copyWith(timeline: updatedTimeline);

    await storage.update(updated);
  }

  /// Retrieves a breach report by ID.
  Future<BreachReport?> getBreachReport(String breachId) async {
    return storage.get(breachId);
  }

  /// Retrieves all breach reports.
  Future<List<BreachReport>> getAllBreachReports() async {
    return storage.getAll();
  }
}
