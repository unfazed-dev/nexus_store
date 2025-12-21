import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:nexus_store/src/compliance/audit_service.dart';
import 'package:nexus_store/src/compliance/retention_policy.dart';
import 'package:nexus_store/src/core/store_backend.dart';

/// Service for implementing GDPR data minimization through retention policies.
///
/// Automatically processes entities based on configured retention policies,
/// applying actions (nullify, anonymize, delete, archive) when data expires.
///
/// ## Example
///
/// ```dart
/// final service = DataMinimizationService<User, String>(
///   backend: backend,
///   policies: [
///     RetentionPolicy(
///       field: 'ipAddress',
///       duration: Duration(days: 30),
///       action: RetentionAction.nullify,
///     ),
///   ],
///   timestampExtractor: (user) => user.createdAt,
///   idExtractor: (user) => user.id,
///   fieldNullifier: (user, field) {
///     if (field == 'ipAddress') return user.copyWith(ipAddress: null);
///     return user;
///   },
/// );
///
/// final result = await service.processRetention();
/// print('Processed ${result.totalProcessed} items');
/// ```
class DataMinimizationService<T, ID> {
  /// Creates a data minimization service.
  ///
  /// - [backend]: The storage backend containing entities to process
  /// - [policies]: List of retention policies to apply
  /// - [timestampExtractor]: Function to extract creation timestamp from entity
  /// - [idExtractor]: Function to extract ID from entity
  /// - [auditService]: Optional audit service for logging actions
  /// - [fieldNullifier]: Function to nullify a specific field on an entity
  /// - [fieldAnonymizer]: Function to anonymize a specific field on an entity
  DataMinimizationService({
    required this.backend,
    required this.policies,
    required this.timestampExtractor,
    required this.idExtractor,
    this.auditService,
    this.fieldNullifier,
    this.fieldAnonymizer,
  });

  /// The storage backend containing entities.
  final StoreBackend<T, ID> backend;

  /// List of retention policies to apply.
  final List<RetentionPolicy> policies;

  /// Function to extract the creation timestamp from an entity.
  final DateTime Function(T entity) timestampExtractor;

  /// Function to extract the ID from an entity.
  final ID Function(T entity) idExtractor;

  /// Optional audit service for logging retention actions.
  final AuditService? auditService;

  /// Function to nullify a specific field on an entity.
  /// Returns a new entity with the field set to null.
  final T Function(T entity, String field)? fieldNullifier;

  /// Function to anonymize a specific field on an entity.
  /// Returns a new entity with the field anonymized.
  final T Function(T entity, String field)? fieldAnonymizer;

  /// Processes all retention policies on all entities.
  ///
  /// Returns a [RetentionResult] with counts of actions taken.
  Future<RetentionResult> processRetention() async {
    final now = DateTime.now();
    var nullifiedCount = 0;
    var anonymizedCount = 0;
    var deletedCount = 0;
    var archivedCount = 0;
    final errors = <RetentionError>[];

    // Get all entities
    final entities = await backend.getAll();

    // Process each policy
    for (final policy in policies) {
      for (final entity in entities) {
        final entityId = idExtractor(entity);
        final createdAt = timestampExtractor(entity);
        final expirationDate = createdAt.add(policy.duration);

        // Check if this entity's field has expired
        if (now.isAfter(expirationDate)) {
          try {
            switch (policy.action) {
              case RetentionAction.nullify:
                if (fieldNullifier != null) {
                  final updated = fieldNullifier!(entity, policy.field);
                  await backend.save(updated);
                  nullifiedCount++;
                  await _logRetentionAction(
                    entityId: entityId.toString(),
                    field: policy.field,
                    action: 'nullify',
                  );
                }
                break;

              case RetentionAction.anonymize:
                if (fieldAnonymizer != null) {
                  final updated = fieldAnonymizer!(entity, policy.field);
                  await backend.save(updated);
                  anonymizedCount++;
                  await _logRetentionAction(
                    entityId: entityId.toString(),
                    field: policy.field,
                    action: 'anonymize',
                  );
                }
                break;

              case RetentionAction.deleteRecord:
                await backend.delete(entityId);
                deletedCount++;
                await _logRetentionAction(
                  entityId: entityId.toString(),
                  field: policy.field,
                  action: 'delete',
                  isDelete: true,
                );
                break;

              case RetentionAction.archive:
                // Archive action would typically move to archive storage
                // For now, just count it
                archivedCount++;
                await _logRetentionAction(
                  entityId: entityId.toString(),
                  field: policy.field,
                  action: 'archive',
                );
                break;
            }
          } catch (e) {
            errors.add(RetentionError(
              entityId: entityId.toString(),
              field: policy.field,
              message: e.toString(),
            ));
          }
        }
      }
    }

    return RetentionResult(
      processedAt: now,
      nullifiedCount: nullifiedCount,
      anonymizedCount: anonymizedCount,
      deletedCount: deletedCount,
      archivedCount: archivedCount,
      errors: errors,
    );
  }

  /// Gets all entities that have expired according to the given policy.
  Future<List<T>> getExpiredItems(RetentionPolicy policy) async {
    final now = DateTime.now();
    final entities = await backend.getAll();

    return entities.where((entity) {
      final createdAt = timestampExtractor(entity);
      final expirationDate = createdAt.add(policy.duration);
      return now.isAfter(expirationDate);
    }).toList();
  }

  Future<void> _logRetentionAction({
    required String entityId,
    required String field,
    required String action,
    bool isDelete = false,
  }) async {
    await auditService?.log(
      action: isDelete ? AuditAction.delete : AuditAction.update,
      entityType: T.toString(),
      entityId: entityId,
      fields: [field],
      success: true,
      metadata: {
        'operation': 'data_minimization',
        'retentionAction': action,
        'field': field,
      },
    );
  }
}
