# TRACKER: Key Derivation

## Status: PENDING

## Overview

Implement secure key derivation from passwords/passphrases using PBKDF2 and Argon2id, completing the encryption story for nexus_store.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-024, Task 23
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `KeyDerivationConfig` sealed class
  - [ ] `KeyDerivationConfig.pbkdf2({iterations, hashAlgorithm})`
  - [ ] `KeyDerivationConfig.argon2id({memoryCost, timeCost, parallelism})`
  - [ ] `KeyDerivationConfig.raw()` - For pre-derived keys

- [ ] Create `DerivedKey` class
  - [ ] `keyBytes: Uint8List` - The derived key
  - [ ] `salt: Uint8List` - Salt used for derivation
  - [ ] `algorithm: String` - Algorithm identifier
  - [ ] `params: Map<String, dynamic>` - Algorithm parameters

- [ ] Create `KeyDerivationParams` for each algorithm
  - [ ] `Pbkdf2Params` - iterations, hashAlgorithm
  - [ ] `Argon2Params` - memoryCost, timeCost, parallelism, version

### PBKDF2 Implementation
- [ ] Implement `Pbkdf2KeyDeriver` class
  - [ ] Use `cryptography` package
  - [ ] Support HMAC-SHA256 (default)
  - [ ] Support HMAC-SHA512 (optional)
  - [ ] Configurable iterations (min 100,000)

- [ ] Implement `deriveKey(password, salt)` method
  - [ ] Returns DerivedKey with 256-bit key
  - [ ] Validates iteration count minimum

- [ ] Implement `generateSalt()` method
  - [ ] Secure random 16+ bytes
  - [ ] Uses SecureRandom

### Argon2id Implementation
- [ ] Implement `Argon2KeyDeriver` class
  - [ ] Use `argon2` package or pure Dart impl
  - [ ] Argon2id variant (recommended for passwords)

- [ ] Implement `deriveKey(password, salt)` method
  - [ ] Configurable memory cost (default 64MB)
  - [ ] Configurable time cost (default 3)
  - [ ] Configurable parallelism (default 4)
  - [ ] Returns DerivedKey with 256-bit key

- [ ] Benchmark default parameters
  - [ ] Target ~500ms derivation time on mobile
  - [ ] Document recommended settings

### Key Derivation Service
- [ ] Create `KeyDerivationService` class
  - [ ] Factory for creating derivers
  - [ ] Caches derived keys (with caution)
  - [ ] Validates parameters

- [ ] Implement key caching (optional)
  - [ ] Time-limited cache
  - [ ] Secure memory handling
  - [ ] Clear on app background

### Salt Management
- [ ] Create `SaltStorage` interface
  - [ ] `Future<Uint8List?> getSalt(String keyId)`
  - [ ] `Future<void> storeSalt(String keyId, Uint8List salt)`

- [ ] Create `SecureStorageSaltProvider` (Flutter)
  - [ ] Uses flutter_secure_storage
  - [ ] Persists salt securely

- [ ] Create `InMemorySaltProvider` (testing)
  - [ ] For unit tests
  - [ ] Non-persistent

### Integration with EncryptionConfig
- [ ] Update `EncryptionConfig.fieldLevel`
  - [ ] Accept `KeyDerivationConfig` instead of raw key
  - [ ] Derive key on first use

- [ ] Update encryption flow
  - [ ] Derive key before encrypt/decrypt
  - [ ] Cache derived key for session

### Security Considerations
- [ ] Document security best practices
  - [ ] Never store password or derived key
  - [ ] Salt must be unique per user/key
  - [ ] Use constant-time comparison

- [ ] Implement secure memory clearing
  - [ ] Zero-fill key bytes when done
  - [ ] Prevent key from appearing in logs

### Unit Tests
- [ ] `test/src/security/key_derivation_test.dart`
  - [ ] PBKDF2 produces consistent output
  - [ ] Argon2id produces consistent output
  - [ ] Different passwords produce different keys
  - [ ] Different salts produce different keys
  - [ ] Salt generation is random
  - [ ] Minimum iteration validation

- [ ] `test/src/security/integration_test.dart`
  - [ ] End-to-end: password → derived key → encryption → decryption

## Files

**Source Files:**
```
packages/nexus_store/lib/src/security/
├── key_derivation.dart           # KeyDerivationConfig sealed class
├── key_derivation_service.dart   # KeyDerivationService
├── derived_key.dart              # DerivedKey model
├── pbkdf2_key_deriver.dart       # PBKDF2 implementation
├── argon2_key_deriver.dart       # Argon2id implementation
├── salt_storage.dart             # SaltStorage interface
└── encryption_config.dart        # Update to use key derivation
```

**Test Files:**
```
packages/nexus_store/test/src/security/
├── key_derivation_test.dart
├── pbkdf2_key_deriver_test.dart
├── argon2_key_deriver_test.dart
└── integration_test.dart
```

## Dependencies

- `cryptography: ^2.7.0` - For PBKDF2 (already in core)
- `argon2: ^1.0.0` or pure Dart - For Argon2id (new dependency)

## API Preview

```dart
// PBKDF2 key derivation
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn', 'medicalRecord'},
  keyDerivation: KeyDerivationConfig.pbkdf2(
    iterations: 310000, // OWASP 2023 recommendation
    hashAlgorithm: HashAlgorithm.sha256,
  ),
  passwordProvider: () => getUserPassword(),
  saltProvider: SecureStorageSaltProvider(),
);

// Argon2id (stronger, but slower)
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn', 'medicalRecord'},
  keyDerivation: KeyDerivationConfig.argon2id(
    memoryCost: 65536, // 64 MB
    timeCost: 3,
    parallelism: 4,
  ),
  passwordProvider: () => getUserPassword(),
  saltProvider: SecureStorageSaltProvider(),
);

// Raw key (for testing or when key is pre-derived)
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn'},
  keyDerivation: KeyDerivationConfig.raw(),
  keyProvider: () => getPreDerivedKey(),
);

// Manual key derivation
final service = KeyDerivationService();
final derivedKey = await service.deriveKey(
  password: userPassword,
  config: KeyDerivationConfig.pbkdf2(iterations: 310000),
);
// Store derivedKey.salt securely
// Use derivedKey.keyBytes for encryption

// First-time setup
if (!await saltStorage.hasSalt('field-encryption')) {
  final salt = KeyDerivationService.generateSalt();
  await saltStorage.storeSalt('field-encryption', salt);
}
```

## Notes

- OWASP 2023 recommends 310,000 iterations for PBKDF2-HMAC-SHA256
- Argon2id is more resistant to GPU attacks but slower
- Salt must be stored; losing salt = losing access to data
- Consider biometric unlock to avoid repeated password entry
- Key derivation should happen off the main isolate for large datasets
- Document migration path if changing derivation parameters
- Argon2 may need platform-specific implementations for performance
