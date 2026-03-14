# Compliance

nexus_store provides built-in support for HIPAA audit logging and GDPR data management.

## Overview

| Regulation | Features |
|------------|----------|
| HIPAA | Audit logging, hash chain integrity, access tracking |
| GDPR | Data export, erasure, access reports, consent tracking |

## Enabling Compliance Features

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    enableAuditLogging: true,  // HIPAA
    enableGdpr: true,          // GDPR
  ),
  auditService: AuditService(
    storage: InMemoryAuditStorage(),  // Or your implementation
    actorProvider: () async => currentUser.id,
  ),
  subjectIdField: 'userId',  // Required for GDPR
);
```

## HIPAA Audit Logging

### AuditService

Tracks all data access and modifications:

```dart
final auditService = AuditService(
  storage: auditStorage,
  actorProvider: () async => currentUser.id,
  metadataProvider: () async => {
    'sessionId': session.id,
    'ipAddress': request.ip,
  },
  enabled: true,
  hashChainEnabled: true,  // Tamper-evident logging
);
```

### Logged Actions

| Action | Trigger |
|--------|---------|
| `create` | New entity saved |
| `read` | Entity retrieved |
| `update` | Entity modified |
| `delete` | Entity deleted |
| `list` | Multiple entities retrieved |
| `export_` | Data exported |
| `accessDenied` | Access attempt blocked |
| `login` | User authenticated |
| `logout` | User session ended |
| `keyAccess` | Encryption key accessed |
| `decrypt` | Data decrypted |

### Audit Log Entry

```dart
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final String actorId;
  final ActorType actorType;
  final List<String> fields;           // Fields accessed/modified
  final Map<String, dynamic>? previousValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final String? requestId;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final String? previousHash;          // Hash chain link
  final String? hash;                   // Entry hash
}
```

### Querying Audit Logs

```dart
// Get logs for a specific entity
final logs = await auditService.query(
  entityType: 'User',
  entityId: 'user-123',
);

// Get logs by actor
final userLogs = await auditService.query(
  actorId: 'admin-1',
  action: AuditAction.update,
);

// Get logs for date range
final recentLogs = await auditService.query(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
  limit: 100,
);
```

### Hash Chain Integrity

Each log entry contains a hash of its contents plus the previous entry's hash:

```
Entry 1: hash = SHA256(content + null)
Entry 2: hash = SHA256(content + Entry1.hash)
Entry 3: hash = SHA256(content + Entry2.hash)
```

Verify integrity:

```dart
final isValid = await auditService.verifyIntegrity(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);

if (!isValid) {
  // Logs may have been tampered with
  notifySecurityTeam();
}
```

### Exporting Audit Logs

```dart
final export = await auditService.export(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
  entityType: 'User',
);

// Save to file for compliance review
await File('audit_2024.json').writeAsString(export);
```

## GDPR Compliance

### GdprService

Implements GDPR Articles 15, 17, and 20:

```dart
final gdprService = store.gdpr!;
```

### Article 20 - Right to Data Portability

Export all data for a subject:

```dart
final export = await gdprService.exportSubjectData('user-123');

print(export.subjectId);     // 'user-123'
print(export.exportDate);    // DateTime
print(export.entityType);    // 'User'
print(export.entityCount);   // 5
print(export.data);          // List of user's data

// Convert to JSON for download
final json = export.toJson();
await File('user_data.json').writeAsString(json);
```

### Article 17 - Right to Erasure

Delete all data for a subject:

```dart
// Complete erasure
final summary = await gdprService.eraseSubjectData('user-123');
print('Deleted ${summary.deletedCount} records');

// Pseudonymization (partial erasure)
final summary = await gdprService.eraseSubjectData(
  'user-123',
  pseudonymize: true,  // Anonymize instead of delete
);
print('Pseudonymized ${summary.pseudonymizedCount} records');
```

Pseudonymization replaces identifying fields with anonymous values while preserving data structure for analytics.

### Article 15 - Right of Access

Generate an access report:

```dart
final report = await gdprService.accessSubjectData('user-123');

print(report.subjectId);        // 'user-123'
print(report.entityType);       // 'User'
print(report.entityCount);      // 5
print(report.categories);       // ['personal', 'payment', 'activity']
print(report.retentionPeriod);  // '7 years'
print(report.purposes);         // ['service provision', 'analytics']
```

### Configuration Options

```dart
final gdprService = GdprService<User, String>(
  backend: backend,
  subjectIdField: 'userId',            // Field containing subject ID
  auditService: auditService,          // Log all GDPR operations
  pseudonymizeFields: ['name', 'email', 'phone'],  // Fields to anonymize
  retainedFields: ['id', 'createdAt'],  // Fields to keep after erasure
);
```

## Audit Storage Implementation

### In-Memory (Development)

```dart
class InMemoryAuditStorage implements AuditStorage {
  final List<AuditLogEntry> _entries = [];

  @override
  Future<void> store(AuditLogEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<AuditLogEntry>> query({...}) async {
    return _entries.where((e) => /* filter */).toList();
  }
}
```

### SQLite (Production)

```dart
class SqliteAuditStorage implements AuditStorage {
  final Database _db;

  @override
  Future<void> store(AuditLogEntry entry) async {
    await _db.insert('audit_logs', entry.toMap());
  }

  @override
  Future<List<AuditLogEntry>> query({...}) async {
    final results = await _db.query('audit_logs', where: ...);
    return results.map(AuditLogEntry.fromMap).toList();
  }
}
```

### Remote (Enterprise)

```dart
class RemoteAuditStorage implements AuditStorage {
  final HttpClient _client;
  final String _endpoint;

  @override
  Future<void> store(AuditLogEntry entry) async {
    await _client.post(_endpoint, body: entry.toJson());
  }
}
```

## Best Practices

### HIPAA

1. **Enable hash chain** - Ensures tamper-evident logging
2. **Secure audit storage** - Store logs in a protected location
3. **Regular verification** - Periodically verify hash chain integrity
4. **Retention policy** - Keep logs for required period (typically 6 years)
5. **Access control** - Restrict who can view audit logs

### GDPR

1. **Map data flows** - Know where subject data exists
2. **Test erasure** - Verify erasure removes all data
3. **Pseudonymization** - Use when complete erasure isn't possible
4. **Audit GDPR operations** - Log all export/erasure requests
5. **Response timeline** - Comply within 30 days

## Testing Compliance

```dart
group('HIPAA Audit', () {
  test('logs data access', () async {
    await store.get('user-1');

    final logs = await auditService.query(
      entityId: 'user-1',
      action: AuditAction.read,
    );

    expect(logs.length, equals(1));
    expect(logs.first.actorId, equals(currentUser.id));
  });

  test('maintains hash chain', () async {
    await store.save(user1);
    await store.save(user2);

    final isValid = await auditService.verifyIntegrity();
    expect(isValid, isTrue);
  });
});

group('GDPR', () {
  test('exports all subject data', () async {
    final export = await gdprService.exportSubjectData('user-1');

    expect(export.entityCount, greaterThan(0));
    expect(export.data.every((d) => d['userId'] == 'user-1'), isTrue);
  });

  test('erases all subject data', () async {
    await gdprService.eraseSubjectData('user-1');

    final remaining = await store.getAll(
      query: Query<User>().where('userId', isEqualTo: 'user-1'),
    );

    expect(remaining, isEmpty);
  });
});
```

## See Also

- [Encryption](encryption.md)
- [Architecture Overview](overview.md)
