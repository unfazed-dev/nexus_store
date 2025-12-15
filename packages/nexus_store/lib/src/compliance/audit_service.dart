import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:nexus_store/src/compliance/audit_log_entry.dart';
import 'package:rxdart/rxdart.dart';

/// Service for audit logging with HIPAA-compliant features.
///
/// Provides:
/// - Immutable append-only log
/// - Cryptographic hash chain for tamper detection
/// - Configurable retention policies
/// - Query capabilities for compliance reporting
///
/// ## Example
///
/// ```dart
/// final auditService = AuditService(
///   storage: MyAuditStorage(),
///   actorProvider: () => currentUser.id,
/// );
///
/// // Log is automatically recorded for store operations
/// await store.get('patient-123');
///
/// // Query audit logs
/// final logs = await auditService.query(
///   entityType: 'Patient',
///   startDate: DateTime(2024, 1, 1),
/// );
/// ```
class AuditService {
  /// Creates an audit service.
  AuditService({
    required this.storage,
    required this.actorProvider,
    this.metadataProvider,
    this.enabled = true,
    this.hashChainEnabled = true,
  }) {
    _entriesSubject = BehaviorSubject<List<AuditLogEntry>>.seeded([]);
  }

  /// Storage backend for persisting audit logs.
  final AuditStorage storage;

  /// Provider for the current actor ID.
  final Future<String> Function() actorProvider;

  /// Optional provider for additional metadata.
  final Future<Map<String, dynamic>> Function()? metadataProvider;

  /// Whether audit logging is enabled.
  final bool enabled;

  /// Whether to compute hash chains for tamper detection.
  final bool hashChainEnabled;

  late final BehaviorSubject<List<AuditLogEntry>> _entriesSubject;

  String? _lastHash;

  /// Stream of audit log entries.
  Stream<List<AuditLogEntry>> get entries => _entriesSubject.stream;

  /// Records an audit log entry.
  ///
  /// Returns the created entry with computed hash.
  Future<AuditLogEntry> log({
    required AuditAction action,
    required String entityType,
    required String entityId,
    List<String>? fields,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    if (!enabled) {
      return AuditLogEntry(
        id: '',
        timestamp: DateTime.now(),
        action: action,
        entityType: entityType,
        entityId: entityId,
        actorId: '',
      );
    }

    final actorId = await actorProvider();
    final extraMetadata = await metadataProvider?.call() ?? {};

    var entry = AuditLogEntry(
      id: _generateId(),
      timestamp: DateTime.now().toUtc(),
      action: action,
      entityType: entityType,
      entityId: entityId,
      actorId: actorId,
      fields: fields ?? [],
      previousValues: previousValues,
      newValues: newValues,
      success: success,
      errorMessage: errorMessage,
      metadata: {...extraMetadata, ...?metadata},
      previousHash: hashChainEnabled ? _lastHash : null,
    );

    // Compute hash for this entry
    if (hashChainEnabled) {
      final hash = _computeHash(entry);
      entry = entry.copyWith(hash: hash);
      _lastHash = hash;
    }

    // Persist the entry
    await storage.append(entry);

    // Update stream
    final current = _entriesSubject.value;
    _entriesSubject.add([...current, entry]);

    return entry;
  }

  /// Queries audit logs with optional filters.
  Future<List<AuditLogEntry>> query({
    String? entityType,
    String? entityId,
    String? actorId,
    AuditAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) =>
      storage.query(
        entityType: entityType,
        entityId: entityId,
        actorId: actorId,
        action: action,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );

  /// Verifies the integrity of the audit log hash chain.
  ///
  /// Returns `true` if all hashes are valid and no tampering is detected.
  Future<bool> verifyIntegrity({DateTime? startDate, DateTime? endDate}) async {
    if (!hashChainEnabled) return true;

    final entries = await storage.query(
      startDate: startDate,
      endDate: endDate,
    );

    String? previousHash;
    for (final entry in entries) {
      // Verify this entry links to previous
      if (entry.previousHash != previousHash) {
        return false;
      }

      // Verify hash is correct
      final computed = _computeHash(entry.copyWith(hash: null));
      if (entry.hash != computed) {
        return false;
      }

      previousHash = entry.hash;
    }

    return true;
  }

  /// Exports audit logs for the specified period.
  ///
  /// Returns JSON-formatted export suitable for compliance reporting.
  Future<String> export({
    required DateTime startDate,
    required DateTime endDate,
    String? entityType,
  }) async {
    final entries = await storage.query(
      startDate: startDate,
      endDate: endDate,
      entityType: entityType,
    );

    return jsonEncode({
      'exportDate': DateTime.now().toUtc().toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'entryCount': entries.length,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      (1000 + (DateTime.now().millisecond * 999 ~/ 1000)).toRadixString(36);

  String _computeHash(AuditLogEntry entry) {
    final data = jsonEncode({
      'id': entry.id,
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action.name,
      'entityType': entry.entityType,
      'entityId': entry.entityId,
      'actorId': entry.actorId,
      'previousHash': entry.previousHash,
    });

    return crypto.sha256.convert(utf8.encode(data)).toString();
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _entriesSubject.close();
  }
}

/// Abstract interface for audit log storage.
abstract interface class AuditStorage {
  /// Appends an entry to the audit log.
  Future<void> append(AuditLogEntry entry);

  /// Queries audit log entries.
  Future<List<AuditLogEntry>> query({
    String? entityType,
    String? entityId,
    String? actorId,
    AuditAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Returns the last entry in the log.
  Future<AuditLogEntry?> getLastEntry();
}

/// In-memory implementation of [AuditStorage] for testing.
class InMemoryAuditStorage implements AuditStorage {
  final List<AuditLogEntry> _entries = [];

  @override
  Future<void> append(AuditLogEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<AuditLogEntry>> query({
    String? entityType,
    String? entityId,
    String? actorId,
    AuditAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    var results = _entries.where((e) {
      if (entityType != null && e.entityType != entityType) return false;
      if (entityId != null && e.entityId != entityId) return false;
      if (actorId != null && e.actorId != actorId) return false;
      if (action != null && e.action != action) return false;
      if (startDate != null && e.timestamp.isBefore(startDate)) return false;
      if (endDate != null && e.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();

    if (offset != null) {
      results = results.skip(offset).toList();
    }

    if (limit != null) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<AuditLogEntry?> getLastEntry() async =>
      _entries.isEmpty ? null : _entries.last;
}
