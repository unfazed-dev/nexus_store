import 'dart:typed_data';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Key Derivation Integration Tests', () {
    group('End-to-end encryption with PBKDF2', () {
      test('password → derived key → encrypt → decrypt roundtrip', () async {
        final saltStorage = InMemorySaltStorage();

        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'user-password-123',
            encryptedFields: {'ssn', 'creditCard'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000, // Lower for test speed
            ),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        // Encrypt sensitive data
        const ssnValue = '123-45-6789';
        const creditCardValue = '4111-1111-1111-1111';
        const plainName = 'John Doe';

        final encryptedSsn = await encryptor.encrypt(ssnValue, 'ssn');
        final encryptedCard =
            await encryptor.encrypt(creditCardValue, 'creditCard');
        final name = await encryptor.encrypt(plainName, 'name');

        // Verify encryption happened
        expect(encryptedSsn, startsWith('enc:'));
        expect(encryptedCard, startsWith('enc:'));
        expect(name, equals(plainName)); // Not in encryptedFields

        // Decrypt and verify
        final decryptedSsn = await encryptor.decrypt(encryptedSsn, 'ssn');
        final decryptedCard =
            await encryptor.decrypt(encryptedCard, 'creditCard');

        expect(decryptedSsn, equals(ssnValue));
        expect(decryptedCard, equals(creditCardValue));
      });

      test('same password with persisted salt produces same key', () async {
        final saltStorage = InMemorySaltStorage();

        // First encryptor instance
        final encryptor1 = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'my-secret-password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
            ),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        const original = 'sensitive data here';
        final encrypted = await encryptor1.encrypt(original, 'field');

        // Simulate app restart - create new encryptor with same password
        final encryptor2 = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'my-secret-password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
            ),
            saltStorage: saltStorage, // Same salt storage
          ) as EncryptionFieldLevel,
        );

        // Should decrypt successfully with persisted salt
        final decrypted = await encryptor2.decrypt(encrypted, 'field');
        expect(decrypted, equals(original));
      });

      test('different passwords cannot decrypt each others data', () async {
        final saltStorage = InMemorySaltStorage();

        // Pre-seed salt to ensure both encryptors use same salt
        final salt = Uint8List.fromList(List.generate(16, (i) => i * 17));
        await saltStorage.storeSalt('field-encryption', salt);

        final encryptor1 = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password-one',
            encryptedFields: {'secret'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
            ),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        final encryptor2 = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password-two',
            encryptedFields: {'secret'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
            ),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        const original = 'top secret data';
        final encrypted = await encryptor1.encrypt(original, 'secret');

        // Wrong password should fail decryption
        expect(
          () => encryptor2.decrypt(encrypted, 'secret'),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('Key derivation with different algorithms', () {
      test('PBKDF2 with SHA-256 (default)', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'test-password',
            encryptedFields: {'data'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
              hashAlgorithm: KdfHashAlgorithm.sha256,
            ),
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await encryptor.encrypt(original, 'data');
        final decrypted = await encryptor.decrypt(encrypted, 'data');

        expect(decrypted, equals(original));
      });

      test('PBKDF2 with SHA-512', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'test-password',
            encryptedFields: {'data'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(
              iterations: 100000,
              hashAlgorithm: KdfHashAlgorithm.sha512,
            ),
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await encryptor.encrypt(original, 'data');
        final decrypted = await encryptor.decrypt(encrypted, 'data');

        expect(decrypted, equals(original));
      });

      test('raw key derivation (no PBKDF2)', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'raw-key-32-bytes-for-aes-256!!',
            encryptedFields: {'data'},
            keyDerivation: const KeyDerivationConfig.raw(),
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await encryptor.encrypt(original, 'data');
        final decrypted = await encryptor.decrypt(encrypted, 'data');

        expect(decrypted, equals(original));
      });
    });

    group('Key derivation with different encryption algorithms', () {
      test('PBKDF2 + AES-256-GCM', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'data'},
            algorithm: EncryptionAlgorithm.aes256Gcm,
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        const original = 'AES-GCM test data';
        final encrypted = await encryptor.encrypt(original, 'data');
        final decrypted = await encryptor.decrypt(encrypted, 'data');

        expect(decrypted, equals(original));
      });

      test('PBKDF2 + ChaCha20-Poly1305', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'data'},
            algorithm: EncryptionAlgorithm.chaCha20Poly1305,
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        const original = 'ChaCha20 test data';
        final encrypted = await encryptor.encrypt(original, 'data');
        final decrypted = await encryptor.decrypt(encrypted, 'data');

        expect(decrypted, equals(original));
      });
    });

    group('Salt management', () {
      test('salt is persisted to storage', () async {
        final saltStorage = InMemorySaltStorage();

        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        // Before encryption, no salt
        expect(await saltStorage.hasSalt('field-encryption'), isFalse);

        // Encrypt to trigger key derivation
        await encryptor.encrypt('data', 'field');

        // After encryption, salt is stored
        expect(await saltStorage.hasSalt('field-encryption'), isTrue);

        final salt = await saltStorage.getSalt('field-encryption');
        expect(salt, isNotNull);
        expect(salt!.length, greaterThanOrEqualTo(16));
      });

      test('salt is reused across multiple encryptions', () async {
        final saltStorage = InMemorySaltStorage();

        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        await encryptor.encrypt('data1', 'field');
        final salt1 = await saltStorage.getSalt('field-encryption');

        await encryptor.encrypt('data2', 'field');
        final salt2 = await saltStorage.getSalt('field-encryption');

        // Salt should be the same
        expect(salt1, equals(salt2));
      });
    });

    group('Key rotation scenarios', () {
      test('clearCache allows new key derivation', () async {
        var password = 'old-password';
        final saltStorage = InMemorySaltStorage();

        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => password,
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
            saltStorage: saltStorage,
          ) as EncryptionFieldLevel,
        );

        // Encrypt with old password
        const original = 'secret data';
        final encrypted = await encryptor.encrypt(original, 'field');

        // Verify decryption works
        expect(await encryptor.decrypt(encrypted, 'field'), equals(original));

        // Clear cache and delete salt for password rotation
        encryptor.clearCache();
        await saltStorage.deleteSalt('field-encryption');

        // Change password
        password = 'new-password';

        // New encryption with new password
        final newEncrypted = await encryptor.encrypt(original, 'field');

        // Should decrypt with new key
        expect(
            await encryptor.decrypt(newEncrypted, 'field'), equals(original));

        // Old encrypted data cannot be decrypted (different key now)
        expect(
          () => encryptor.decrypt(encrypted, 'field'),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('Backward compatibility', () {
      test('no keyDerivation uses legacy SHA-256 hashing', () async {
        // Without keyDerivation, falls back to simple SHA-256 hash
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'short-key',
            encryptedFields: {'field'},
            // No keyDerivation - uses legacy behavior
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });

      test('encryptor without keyDerivation still works with 32-byte keys',
          () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'exactly-32-bytes-for-aes-256!!',
            encryptedFields: {'field'},
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });
    });

    group('Edge cases', () {
      test('empty plaintext encryption and decryption', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        const original = '';
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });

      test('unicode and emoji in plaintext', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        const original = 'Hello \u{1F512}\u{1F4BB} \u65E5\u672C\u8A9E';
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });

      test('large data encryption and decryption', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'password',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        final original = 'Large data block ' * 1000; // ~17KB
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });

      test('password with unicode characters', () async {
        final encryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => '\u5BC6\u7801\u{1F511}password\u{1F512}',
            encryptedFields: {'field'},
            keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          ) as EncryptionFieldLevel,
        );

        const original = 'secret data';
        final encrypted = await encryptor.encrypt(original, 'field');
        final decrypted = await encryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });
    });
  });
}
