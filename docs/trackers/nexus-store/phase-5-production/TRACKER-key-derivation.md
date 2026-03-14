# TRACKER: Key Derivation

## Status: COMPLETE

## Overview

Implement secure key derivation from passwords/passphrases using PBKDF2, completing the encryption story for nexus_store.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-024, Task 23
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Implementation Summary

**Completed**: December 2024
**Tests**: 117 unit tests + 17 integration tests = 134 total tests
**Approach**: PBKDF2-only implementation using existing `cryptography` package (no new dependencies)

### Scope Decision
- Implemented **PBKDF2 only** (no Argon2id) to avoid FFI/platform dependencies
- Uses existing `cryptography: ^2.7.0` package
- `KeyDeriver` interface allows custom Argon2 implementations if needed

## Tasks

### Data Models
- [x] Create `KeyDerivationConfig` sealed class
  - [x] `KeyDerivationConfig.pbkdf2({iterations, hashAlgorithm, keyLength, saltLength})`
  - [x] `KeyDerivationConfig.raw()` - For pre-derived keys
  - [x] Helper getters: `effectiveIterations`, `effectiveKeyLength`, `effectiveSaltLength`
  - [x] Static constants: `owasp2023Iterations = 310000`

- [x] Create `DerivedKey` class
  - [x] `keyBytes: Uint8List` - The derived key
  - [x] `salt: Uint8List` - Salt used for derivation
  - [x] `algorithm: String` - Algorithm identifier
  - [x] `params: Map<String, dynamic>` - Algorithm parameters
  - [x] `dispose()` method for secure memory clearing

- [x] Create `KdfHashAlgorithm` enum
  - [x] `sha256` (default)
  - [x] `sha512`

### PBKDF2 Implementation
- [x] Implement `KeyDeriver` abstract interface
  - [x] `deriveKey(password, salt)` method
  - [x] `generateSalt(length)` method

- [x] Implement `Pbkdf2KeyDeriver` class
  - [x] Uses `cryptography` package's Pbkdf2
  - [x] Support HMAC-SHA256 (default)
  - [x] Support HMAC-SHA512
  - [x] Configurable iterations (min 100,000)
  - [x] Returns 256-bit (32 byte) keys
  - [x] Generates 16+ byte secure random salts

- [x] Validation
  - [x] Minimum iteration count validation (100,000)
  - [x] Consistent output for same password/salt
  - [x] Different passwords produce different keys
  - [x] Different salts produce different keys

### Key Derivation Service
- [x] Create `KeyDerivationService` class
  - [x] Factory for creating derivers based on config type
  - [x] Coordinates key derivation with salt storage
  - [x] `deriveKey(password, salt?, keyId?)` method
  - [x] Salt resolution: explicit > stored > generated
  - [x] `generateSalt()` method
  - [x] `dispose()` method for cleanup

- [x] Handle raw key mode
  - [x] No derivation, just encoding
  - [x] Normalize to 32 bytes for AES-256

### Salt Management
- [x] Create `SaltStorage` interface
  - [x] `Future<Uint8List?> getSalt(String keyId)`
  - [x] `Future<void> storeSalt(String keyId, Uint8List salt)`
  - [x] `Future<bool> hasSalt(String keyId)`
  - [x] `Future<void> deleteSalt(String keyId)`

- [x] Create `InMemorySaltStorage` (testing)
  - [x] For unit tests
  - [x] Non-persistent

### Integration with EncryptionConfig
- [x] Update `EncryptionConfig.fieldLevel`
  - [x] Accept `KeyDerivationConfig? keyDerivation` parameter
  - [x] Accept `SaltStorage? saltStorage` parameter
  - [x] Extension: `hasKeyDerivation` getter

- [x] Update `DefaultFieldEncryptor`
  - [x] Use `KeyDerivationService` when `keyDerivation` is configured
  - [x] Derive key on first use
  - [x] Cache derived key for session
  - [x] Clear derived key on `clearCache()`
  - [x] Backward compatible: falls back to SHA-256 hash when no keyDerivation

### Security Considerations
- [x] Secure memory clearing via `dispose()` method
- [x] Zero-fill key bytes when done
- [x] `DerivedKey.toString()` does not expose key bytes
- [x] Salt stored separately from encrypted data

### Unit Tests
- [x] `key_derivation_config_test.dart` - 21 tests
- [x] `derived_key_test.dart` - 13 tests
- [x] `pbkdf2_key_deriver_test.dart` - 22 tests
- [x] `salt_storage_test.dart` - 17 tests
- [x] `key_derivation_service_test.dart` - 16 tests
- [x] `encryption_config_test.dart` - 8 new tests (28 total)
- [x] `field_encryptor_test.dart` - 6 new tests (28 total)

### Integration Tests
- [x] `key_derivation_integration_test.dart` - 17 tests
  - [x] Password -> derived key -> encrypt -> decrypt roundtrip
  - [x] Same password with persisted salt produces same key
  - [x] Different passwords cannot decrypt each other's data
  - [x] PBKDF2 with SHA-256 and SHA-512
  - [x] Raw key derivation (no PBKDF2)
  - [x] Integration with AES-256-GCM and ChaCha20-Poly1305
  - [x] Salt persistence and reuse
  - [x] Key rotation scenarios
  - [x] Backward compatibility
  - [x] Edge cases (empty plaintext, unicode, large data)

## Files

**Source Files (Created):**
```
packages/nexus_store/lib/src/security/
├── key_derivation_config.dart      # KeyDerivationConfig sealed class
├── key_derivation_config.freezed.dart  # Generated
├── derived_key.dart                # DerivedKey model
├── key_deriver.dart                # Abstract KeyDeriver interface
├── pbkdf2_key_deriver.dart         # PBKDF2 implementation
├── key_derivation_service.dart     # Factory and coordination service
└── salt_storage.dart               # SaltStorage interface + InMemory impl
```

**Source Files (Updated):**
```
packages/nexus_store/lib/src/security/encryption_config.dart
packages/nexus_store/lib/src/security/field_encryptor.dart
packages/nexus_store/lib/nexus_store.dart (exports)
```

**Test Files (Created):**
```
packages/nexus_store/test/src/security/
├── key_derivation_config_test.dart
├── derived_key_test.dart
├── pbkdf2_key_deriver_test.dart
├── salt_storage_test.dart
├── key_derivation_service_test.dart
└── key_derivation_integration_test.dart
```

**Test Files (Updated):**
```
packages/nexus_store/test/src/security/
├── encryption_config_test.dart
└── field_encryptor_test.dart
```

## Dependencies

No new dependencies required - `cryptography: ^2.7.0` already has PBKDF2 support.

## API Examples

```dart
// PBKDF2 key derivation with salt storage
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn', 'medicalRecord'},
  keyProvider: () async => getUserPassword(),
  keyDerivation: KeyDerivationConfig.pbkdf2(
    iterations: 310000, // OWASP 2023 recommendation
    hashAlgorithm: KdfHashAlgorithm.sha256,
  ),
  saltStorage: SecureStorageSaltProvider(), // Your implementation
);

// PBKDF2 with SHA-512 (for extra security margin)
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn'},
  keyProvider: () async => getUserPassword(),
  keyDerivation: KeyDerivationConfig.pbkdf2(
    iterations: 310000,
    hashAlgorithm: KdfHashAlgorithm.sha512,
  ),
);

// Raw key (for testing or pre-derived keys)
final config = EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn'},
  keyProvider: () async => preGeneratedKey,
  keyDerivation: KeyDerivationConfig.raw(),
);

// Manual key derivation
final service = KeyDerivationService(
  config: KeyDerivationConfig.pbkdf2(iterations: 310000),
  saltStorage: saltStorage,
);

final derivedKey = await service.deriveKey(
  password: userPassword,
  keyId: 'user-123-encryption',
);
// derivedKey.keyBytes for encryption
// derivedKey.salt is auto-stored via saltStorage
```

## Notes

- OWASP 2023 recommends 310,000 iterations for PBKDF2-HMAC-SHA256
- Salt is stored via `SaltStorage` interface - losing salt = losing access to data
- `KeyDeriver` interface allows custom Argon2 implementations if needed later
- Key derivation is lazy - happens on first encrypt/decrypt call
- Cached derived key is cleared via `clearCache()` for key rotation
- Backward compatible - works without `keyDerivation` config (uses legacy SHA-256 hash)
