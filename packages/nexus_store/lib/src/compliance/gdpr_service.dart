import 'dart:convert';

import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/query/query.dart';

/// GDPR compliance service for right to erasure and data portability.
///
/// Implements:
/// - **Article 17**: Right to erasure ("right to be forgotten")
/// - **Article 20**: Right to data portability
/// - **Article 15**: Right of access
///
/// ## Example
///
/// ```dart
/// final gdprService = GdprService<User, String>(
///   backend: userBackend,
///   subjectIdField: 'userId',
///   auditService: auditService,
/// );
///
/// // Export user data (Article 20)
/// final export = await gdprService.exportSubjectData('user-123');
///
/// // Erase user data (Article 17)
/// await gdprService.eraseSubjectData('user-123');
/// ```
class GdprService<T, ID> {
  /// Creates a GDPR service.
  GdprService({
    required this.backend,
    required this.subjectIdField,
    this.auditService,
    this.pseudonymizeFields = const [],
    this.retainedFields = const [],
  });

  /// The storage backend.
  final StoreBackend<T, ID> backend;

  /// Field name that contains the data subject identifier.
  final String subjectIdField;

  /// Optional audit service for logging GDPR operations.
  final AuditService? auditService;

  /// Fields to pseudonymize instead of delete (for analytics).
  final List<String> pseudonymizeFields;

  /// Fields to retain even after erasure (for legal compliance).
  final List<String> retainedFields;

  /// Exports all data for a data subject (Article 20).
  ///
  /// Returns JSON-formatted export in a machine-readable format.
  Future<GdprExport> exportSubjectData(String subjectId) async {
    final entities = await _findSubjectEntities(subjectId);

    await auditService?.log(
      action: AuditAction.export_,
      entityType: T.toString(),
      entityId: subjectId,
      metadata: {'operation': 'gdpr_export', 'entityCount': entities.length},
    );

    return GdprExport(
      subjectId: subjectId,
      exportDate: DateTime.now().toUtc(),
      entityType: T.toString(),
      entityCount: entities.length,
      data: entities,
    );
  }

  /// Erases all data for a data subject (Article 17).
  ///
  /// Returns summary of the erasure operation.
  Future<ErasureSummary> eraseSubjectData(
    String subjectId, {
    bool pseudonymize = false,
  }) async {
    final entities = await _findSubjectEntities(subjectId);
    var deletedCount = 0;
    var pseudonymizedCount = 0;

    for (final entity in entities) {
      if (entity is Map<String, dynamic>) {
        final id = entity['id'] as ID?;
        if (id != null) {
          if (pseudonymize && pseudonymizeFields.isNotEmpty) {
            // Pseudonymize instead of delete
            await _pseudonymizeEntity(entity, subjectId);
            pseudonymizedCount++;
          } else {
            // Full deletion
            await backend.delete(id);
            deletedCount++;
          }
        }
      }
    }

    await auditService?.log(
      action: AuditAction.delete,
      entityType: T.toString(),
      entityId: subjectId,
      metadata: {
        'operation': 'gdpr_erasure',
        'deletedCount': deletedCount,
        'pseudonymizedCount': pseudonymizedCount,
      },
    );

    return ErasureSummary(
      subjectId: subjectId,
      erasureDate: DateTime.now().toUtc(),
      deletedCount: deletedCount,
      pseudonymizedCount: pseudonymizedCount,
    );
  }

  /// Returns all data held about a data subject (Article 15).
  Future<AccessReport> accessSubjectData(String subjectId) async {
    final entities = await _findSubjectEntities(subjectId);

    await auditService?.log(
      action: AuditAction.read,
      entityType: T.toString(),
      entityId: subjectId,
      metadata: {'operation': 'gdpr_access', 'entityCount': entities.length},
    );

    return AccessReport(
      subjectId: subjectId,
      reportDate: DateTime.now().toUtc(),
      entityType: T.toString(),
      entityCount: entities.length,
      categories: _categorizeFields(entities),
      retentionPeriod: _getRetentionPeriod(),
      purposes: _getProcessingPurposes(),
    );
  }

  /// Finds all entities belonging to a data subject.
  Future<List<T>> _findSubjectEntities(String subjectId) async {
    final query = Query<T>().where(subjectIdField, isEqualTo: subjectId);
    return backend.getAll(query: query);
  }

  Future<void> _pseudonymizeEntity(
    Map<String, dynamic> entity,
    String subjectId,
  ) async {
    final updated = Map<String, dynamic>.from(entity);

    for (final field in pseudonymizeFields) {
      if (updated.containsKey(field) && !retainedFields.contains(field)) {
        updated[field] = _pseudonymizeValue(field, subjectId);
      }
    }

    // Re-save with pseudonymized data
    await backend.save(updated as T);
  }

  String _pseudonymizeValue(String field, String subjectId) {
    // Generate consistent pseudonym based on field and subject
    final hash = subjectId.hashCode.abs().toRadixString(16);
    return 'REDACTED-$hash-$field';
  }

  List<String> _categorizeFields(List<T> entities) {
    final categories = <String>{};
    for (final entity in entities) {
      if (entity is Map<String, dynamic>) {
        categories.addAll(entity.keys);
      }
    }
    return categories.toList();
  }

  String _getRetentionPeriod() => 'As per data retention policy';

  List<String> _getProcessingPurposes() => [
        'Service provision',
        'Legal compliance',
      ];
}

/// Result of a GDPR data export operation.
class GdprExport {
  /// Creates an export result.
  const GdprExport({
    required this.subjectId,
    required this.exportDate,
    required this.entityType,
    required this.entityCount,
    required this.data,
  });

  /// The data subject identifier.
  final String subjectId;

  /// When the export was generated.
  final DateTime exportDate;

  /// Type of entities exported.
  final String entityType;

  /// Number of entities exported.
  final int entityCount;

  /// The exported data.
  final List<dynamic> data;

  /// Converts to JSON string.
  String toJson() => jsonEncode({
        'subjectId': subjectId,
        'exportDate': exportDate.toIso8601String(),
        'entityType': entityType,
        'entityCount': entityCount,
        'data': data,
      });
}

/// Summary of a GDPR erasure operation.
class ErasureSummary {
  /// Creates an erasure summary.
  const ErasureSummary({
    required this.subjectId,
    required this.erasureDate,
    required this.deletedCount,
    required this.pseudonymizedCount,
  });

  /// The data subject identifier.
  final String subjectId;

  /// When the erasure was performed.
  final DateTime erasureDate;

  /// Number of entities fully deleted.
  final int deletedCount;

  /// Number of entities pseudonymized.
  final int pseudonymizedCount;

  /// Total entities affected.
  int get totalAffected => deletedCount + pseudonymizedCount;
}

/// Report of data held about a subject (Article 15).
class AccessReport {
  /// Creates an access report.
  const AccessReport({
    required this.subjectId,
    required this.reportDate,
    required this.entityType,
    required this.entityCount,
    required this.categories,
    required this.retentionPeriod,
    required this.purposes,
  });

  /// The data subject identifier.
  final String subjectId;

  /// When the report was generated.
  final DateTime reportDate;

  /// Type of entities found.
  final String entityType;

  /// Number of entities found.
  final int entityCount;

  /// Categories of data held.
  final List<String> categories;

  /// Data retention period.
  final String retentionPeriod;

  /// Purposes of data processing.
  final List<String> purposes;
}
