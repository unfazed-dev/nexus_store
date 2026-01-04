# Encryption & Compliance Reference

Security features including database encryption, field-level encryption, HIPAA audit logging, and GDPR compliance.

## Encryption Overview

| Level | Method | Scope | Use Case |
|-------|--------|-------|----------|
| Database | SQLCipher | Entire database | Mobile apps, at-rest protection |
| Field | AES-256-GCM | Specific fields | PII, PHI, sensitive data |
| Combined | Both | Full protection | HIPAA, high-security apps |

---

## Database-Level Encryption (SQLCipher)

Encrypt the entire SQLite database at rest.

### Configuration

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorage = FlutterSecureStorage();

final config = StoreConfig(
  encryption: EncryptionConfig.sqlCipher(
    keyProvider: () async {
      // Retrieve or generate encryption key
      var key = await secureStorage.read(key: 'db_encryption_key');
      if (key == null) {
        key = generateSecureKey();  // Your key generation logic
        await secureStorage.write(key: 'db_encryption_key', value: key);
      }
      return key;
    },
    kdfIterations: 256000,  // PBKDF2 iterations (higher = more secure, slower)
  ),
);
```

### With PowerSync

```dart
import 'package:powersync_sqlcipher/powersync_sqlcipher.dart';

final encryptionKey = await getEncryptionKey();

final powerSync = PowerSyncDatabase.withFactory(
  SqlCipherOpenFactory(
    path: dbPath,
    key: encryptionKey,
  ),
  schema: schema,
);
```

### Key Derivation

```dart
// Derive key from user password
final keyDerivationService = KeyDerivationService(
  config: KeyDerivationConfig(
    algorithm: KeyDerivationAlgorithm.pbkdf2,
    iterations: 600000,  // OWASP recommendation for PBKDF2-SHA256
    keyLength: 32,       // 256 bits
  ),
);

final derivedKey = await keyDerivationService.deriveKey(
  password: userPassword,
  salt: await getSalt(),
);
```

### Salt Storage

```dart
// Store salt securely (separate from encrypted data)
final saltStorage = SecureSaltStorage(
  storage: FlutterSecureStorage(),
  keyPrefix: 'nexus_salt_',
);

// Get or create salt for a store
final salt = await saltStorage.getOrCreateSalt('users');
```

---

## Field-Level Encryption (AES-256-GCM)

Encrypt specific sensitive fields while keeping other data queryable.

### Configuration

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.fieldLevel(
    encryptedFields: {'ssn', 'email', 'phone', 'medicalRecordNumber'},
    keyProvider: () async => await secureStorage.read(key: 'field_key'),
    algorithm: EncryptionAlgorithm.aes256Gcm,
  ),
);
```

### How It Works

1. Specified fields are encrypted before storage
2. Encrypted values include authentication tag (GCM)
3. Each encryption uses unique nonce/IV
4. Decryption happens transparently on read

### Combined Encryption

```dart
// Use both database and field-level encryption
final config = StoreConfig(
  encryption: EncryptionConfig(
    sqlCipher: SqlCipherConfig(
      keyProvider: () async => await getDbKey(),
      kdfIterations: 256000,
    ),
    fieldLevel: FieldLevelConfig(
      encryptedFields: {'ssn', 'medicalRecordNumber'},
      keyProvider: () async => await getFieldKey(),
      algorithm: EncryptionAlgorithm.aes256Gcm,
    ),
  ),
);
```

### Field Encryptor Direct Usage

```dart
final encryptor = FieldEncryptor(
  keyProvider: () async => encryptionKey,
  algorithm: EncryptionAlgorithm.aes256Gcm,
);

// Encrypt
final encrypted = await encryptor.encrypt('sensitive-data');

// Decrypt
final decrypted = await encryptor.decrypt(encrypted);
```

---

## HIPAA Audit Logging

Track all data access and modifications with tamper-evident logging.

### Enable Audit Logging

```dart
import 'package:nexus_store/nexus_store.dart';

final auditStorage = InMemoryAuditStorage();  // Or custom implementation

final store = NexusStore<Patient, String>(
  backend: backend,
  config: StoreConfig(enableAuditLogging: true),
  auditService: AuditService(
    storage: auditStorage,
    actorProvider: () async => getCurrentUserId(),
    hashChainEnabled: true,  // Tamper-evident chain
  ),
);
```

### Audit Actions

| Action | Triggered By |
|--------|-------------|
| `AuditAction.create` | `store.save()` for new entity |
| `AuditAction.read` | `store.get()`, `store.getAll()` |
| `AuditAction.update` | `store.save()` for existing entity |
| `AuditAction.delete` | `store.delete()` |
| `AuditAction.export` | GDPR export operations |
| `AuditAction.erase` | GDPR erasure operations |

### Query Audit Logs

```dart
// Get recent access logs
final logs = await store.audit!.query(
  entityType: 'Patient',
  action: AuditAction.read,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
  actorId: 'nurse-123',  // Optional: filter by user
);

for (final log in logs) {
  print('${log.timestamp}: ${log.actorId} ${log.action} ${log.entityId}');
}
```

### Verify Log Integrity

```dart
// Check hash chain integrity (detects tampering)
final isValid = await store.audit!.verifyIntegrity();

if (!isValid) {
  // Log tampering detected - trigger security alert
  await securityService.reportTampering();
}
```

### Export Audit Logs

```dart
// Export for compliance reporting
final export = await store.audit!.export(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
  format: AuditExportFormat.json,
);

// Save to file or send to compliance system
await File('audit_2024.json').writeAsString(export.toJson());
```

### Custom Audit Storage

```dart
class PostgresAuditStorage implements AuditStorage {
  @override
  Future<void> write(AuditLogEntry entry) async {
    await db.execute('''
      INSERT INTO audit_logs (id, timestamp, actor_id, action, entity_type, entity_id, hash)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [entry.id, entry.timestamp, entry.actorId, entry.action, ...]);
  }

  @override
  Future<List<AuditLogEntry>> query(AuditQuery query) async {
    // Implement query logic
  }

  @override
  Future<bool> verifyIntegrity() async {
    // Verify hash chain
  }
}
```

---

## GDPR Compliance

Data portability, erasure, and access rights.

### Enable GDPR Features

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableGdpr: true),
  subjectIdField: 'userId',  // Field identifying the data subject
);
```

### Data Portability (Article 20)

```dart
// Export all data for a subject in machine-readable format
final export = await store.gdpr!.exportSubjectData('user-123');

// Get JSON export
final jsonData = export.toJson();
// {
//   "subjectId": "user-123",
//   "exportDate": "2024-01-15T10:30:00Z",
//   "entities": [...],
//   "categories": ["profile", "preferences", "orders"]
// }

// Send to subject or third party
await sendToUser(jsonData);
```

### Right to Erasure (Article 17)

```dart
// Delete all data for a subject
final summary = await store.gdpr!.eraseSubjectData('user-123');

print('Deleted ${summary.deletedCount} records');
print('From tables: ${summary.affectedTables}');
print('Completed at: ${summary.timestamp}');

// Audit log automatically records erasure
```

### Right of Access (Article 15)

```dart
// Get access report without full data export
final report = await store.gdpr!.accessSubjectData('user-123');

print('Data categories: ${report.categories}');
print('Record count: ${report.recordCount}');
print('First collected: ${report.firstCollectedDate}');
print('Last updated: ${report.lastUpdatedDate}');
print('Processing purposes: ${report.processingPurposes}');
```

### Data Minimization

```dart
// Configure retention policies
final minimizationService = DataMinimizationService(
  policies: [
    RetentionPolicy(
      entityType: 'LoginLog',
      maxAge: Duration(days: 90),
      action: RetentionAction.delete,
    ),
    RetentionPolicy(
      entityType: 'Order',
      maxAge: Duration(days: 365 * 7),  // 7 years for legal
      action: RetentionAction.anonymize,
    ),
  ],
);

// Run cleanup
await minimizationService.enforce();
```

### Consent Management

```dart
final consentService = ConsentService(storage: consentStorage);

// Record consent
await consentService.recordConsent(ConsentRecord(
  subjectId: 'user-123',
  purpose: 'marketing',
  granted: true,
  timestamp: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(days: 365)),
));

// Check consent
final hasConsent = await consentService.hasValidConsent(
  subjectId: 'user-123',
  purpose: 'marketing',
);

// Withdraw consent
await consentService.withdrawConsent(
  subjectId: 'user-123',
  purpose: 'marketing',
);
```

### Breach Notification

```dart
final breachService = BreachService(storage: breachStorage);

// Report a breach
await breachService.report(BreachReport(
  discoveredAt: DateTime.now(),
  description: 'Unauthorized access detected',
  affectedSubjects: ['user-123', 'user-456'],
  dataCategories: ['email', 'phone'],
  severity: BreachSeverity.high,
  containmentActions: ['Revoked access tokens', 'Reset passwords'],
));

// Get breach history
final breaches = await breachService.getReports(
  startDate: DateTime.now().subtract(Duration(days: 365)),
);
```

---

## Security Best Practices

### Key Management

1. **Never hardcode keys** - Always use secure storage
2. **Rotate keys periodically** - Implement key rotation strategy
3. **Use unique keys** - Separate keys for database and field encryption
4. **Secure key derivation** - Use PBKDF2 with high iteration count

### Audit Logging

1. **Enable hash chain** - Detect log tampering
2. **Immutable storage** - Use append-only log storage
3. **Regular verification** - Schedule integrity checks
4. **Secure export** - Encrypt audit log exports

### GDPR Implementation

1. **Document data flows** - Know where subject data is stored
2. **Test erasure** - Verify complete data removal
3. **Maintain consent records** - Keep proof of consent
4. **Automate minimization** - Schedule retention enforcement
