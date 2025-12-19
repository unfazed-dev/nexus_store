# Encryption

nexus_store provides two levels of encryption: database-level (SQLCipher) and field-level (AES-256-GCM).

## Overview

| Level | Coverage | Algorithm | Use Case |
|-------|----------|-----------|----------|
| Database | Entire database | SQLCipher (AES-256) | Full data-at-rest encryption |
| Field | Specific fields | AES-256-GCM | Selective PII encryption |

## Database-Level Encryption (SQLCipher)

SQLCipher encrypts the entire SQLite database file.

### Configuration

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.sqlCipher(
    keyProvider: () async => await secureStorage.read(key: 'db_key'),
    kdfIterations: 256000,  // PBKDF2 iterations
  ),
);
```

### How It Works

1. **Key Derivation** - Your key is processed through PBKDF2
2. **Page Encryption** - Each database page is encrypted with AES-256
3. **MAC Verification** - HMAC-SHA256 ensures integrity

### Backend Support

SQLCipher is supported by:
- PowerSync (via powersync_sqlcipher)
- Drift (via encrypted sqlite)
- CRDT (via sqlite_crdt with encryption)

### Key Management

```dart
class SecureKeyProvider implements EncryptionKeyProvider {
  final FlutterSecureStorage _storage;

  SecureKeyProvider(this._storage);

  @override
  Future<String> getKey() async {
    var key = await _storage.read(key: 'db_encryption_key');
    if (key == null) {
      // Generate new key on first use
      key = generateSecureKey();
      await _storage.write(key: 'db_encryption_key', value: key);
    }
    return key;
  }

  String generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
```

## Field-Level Encryption

Encrypt specific sensitive fields while keeping other data queryable.

### Configuration

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.fieldLevel(
    encryptedFields: {'ssn', 'email', 'phone'},
    keyProvider: () async => await secureStorage.read(key: 'field_key'),
    algorithm: EncryptionAlgorithm.aes256Gcm,
    version: 'v1',  // For key rotation
  ),
);
```

### Supported Algorithms

| Algorithm | Description | Recommendation |
|-----------|-------------|----------------|
| `aes256Gcm` | AES-256 with GCM (AEAD) | **Recommended** - provides integrity |
| `aes256Cbc` | AES-256 with CBC | Legacy - requires separate MAC |
| `chaCha20Poly1305` | ChaCha20 with Poly1305 | Mobile-optimized |

### How It Works

1. **Before Save** - Encrypt specified fields
2. **After Read** - Decrypt specified fields
3. **Format** - `enc:<version>:<nonce>:<ciphertext>:<tag>`

### EncryptionService

The service handles encryption/decryption:

```dart
final service = EncryptionService(
  encryptedFields: {'ssn', 'email'},
  keyProvider: () => secureStorage.read(key: 'key'),
);

// Encrypt before saving
final encrypted = await service.encryptFields({
  'name': 'Alice',
  'ssn': '123-45-6789',
  'email': 'alice@example.com',
});
// Result: {name: 'Alice', ssn: 'enc:v1:...', email: 'enc:v1:...'}

// Decrypt after reading
final decrypted = await service.decryptFields(encrypted);
// Result: {name: 'Alice', ssn: '123-45-6789', email: 'alice@example.com'}
```

### DefaultFieldEncryptor

The default implementation:

```dart
class DefaultFieldEncryptor implements FieldEncryptor {
  final Future<String> Function() keyProvider;
  final EncryptionAlgorithm algorithm;
  final String version;

  @override
  Future<String> encrypt(String plaintext) async {
    final key = await keyProvider();
    final nonce = generateNonce();
    final ciphertext = await aesGcmEncrypt(plaintext, key, nonce);
    return 'enc:$version:${base64Encode(nonce)}:${base64Encode(ciphertext)}';
  }

  @override
  Future<String> decrypt(String ciphertext) async {
    if (!ciphertext.startsWith('enc:')) {
      return ciphertext;  // Not encrypted
    }
    // Parse and decrypt...
  }
}
```

## Key Rotation

### Field-Level Key Rotation

1. **Add new version**
```dart
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn', 'email'},
  keyProvider: () => getKeyForVersion('v2'),
  version: 'v2',
);
```

2. **Migrate data**
```dart
Future<void> rotateKeys() async {
  final items = await store.getAll();
  for (final item in items) {
    // Re-save triggers re-encryption with new key
    await store.save(item);
  }
}
```

3. **Remove old key** after migration

### Database Key Rotation

SQLCipher supports rekeying:

```sql
PRAGMA rekey = 'new_key';
```

Implementation varies by backend.

## Security Considerations

### Key Storage

- **Use secure storage** - Flutter Secure Storage, iOS Keychain, Android Keystore
- **Never hardcode keys** - Keys in code can be extracted
- **Consider key derivation** - Derive from user password with PBKDF2/Argon2

### Algorithm Selection

- **Use AEAD** - AES-GCM provides both encryption and authentication
- **Unique nonces** - Never reuse a nonce with the same key
- **Sufficient iterations** - Use at least 100,000 PBKDF2 iterations

### Attack Mitigation

| Attack | Mitigation |
|--------|------------|
| Brute force | High KDF iterations |
| Key extraction | Secure key storage |
| Replay attack | Unique nonces per encryption |
| Tampering | AEAD (GCM, Poly1305) |

## Performance Impact

### Database-Level

- **Startup** - Key derivation adds ~100-500ms
- **Operations** - ~5-10% overhead for page encryption
- **Database size** - ~10% larger (MAC per page)

### Field-Level

- **Per field** - ~0.1-0.5ms per encrypt/decrypt
- **Batch operations** - Consider parallel encryption
- **Caching** - Avoid decrypting unchanged data

## Combining Both Levels

You can use both database and field-level encryption:

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.fieldLevel(
    encryptedFields: {'ssn'},  // Extra protection for PII
    keyProvider: () => getFieldKey(),
  ),
);

// Backend uses SQLCipher
final backend = PowerSyncEncryptedBackend<User, String>(
  keyProvider: SqlCipherKeyProvider(),
  // ...
);
```

This provides:
- Full database encryption for all data
- Additional field encryption for highly sensitive data
- Defense in depth

## Compliance

### HIPAA

- Use database-level encryption for PHI
- Encrypt specific PHI fields for extra protection
- Implement audit logging alongside encryption

### GDPR

- Encrypt PII fields (email, phone, etc.)
- Enable encryption for right-to-be-forgotten data
- Document encryption in your privacy policy

## See Also

- [Compliance](compliance.md)
- [Architecture Overview](overview.md)
