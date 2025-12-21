import 'dart:typed_data';

import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:nexus_store/src/security/salt_storage.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultFieldEncryptor', () {
    late DefaultFieldEncryptor encryptor;

    setUp(() {
      encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'test-key-32-bytes-for-aes-256!',
          encryptedFields: {'ssn', 'creditCard', 'password'},
        ) as EncryptionFieldLevel,
      );
    });

    group('constructor', () {
      test('should create encryptor with config', () {
        expect(encryptor.config, isNotNull);
        expect(encryptor.config.encryptedFields, contains('ssn'));
      });
    });

    group('shouldEncrypt', () {
      test('should return true for fields in encryptedFields', () {
        expect(encryptor.shouldEncrypt('ssn'), isTrue);
        expect(encryptor.shouldEncrypt('creditCard'), isTrue);
        expect(encryptor.shouldEncrypt('password'), isTrue);
      });

      test('should return false for fields not in encryptedFields', () {
        expect(encryptor.shouldEncrypt('name'), isFalse);
        expect(encryptor.shouldEncrypt('email'), isFalse);
        expect(encryptor.shouldEncrypt('age'), isFalse);
      });
    });

    group('isEncrypted', () {
      test('should return true for values with encryption prefix', () {
        expect(encryptor.isEncrypted('enc:v1:base64data'), isTrue);
        expect(encryptor.isEncrypted('enc:v2:someotherdata'), isTrue);
      });

      test('should return false for plain values', () {
        expect(encryptor.isEncrypted('plaintext'), isFalse);
        expect(encryptor.isEncrypted('123-45-6789'), isFalse);
        expect(encryptor.isEncrypted(''), isFalse);
      });
    });

    group('encrypt', () {
      test('should encrypt field in encryptedFields', () async {
        final encrypted = await encryptor.encrypt('123-45-6789', 'ssn');

        expect(encrypted, startsWith('enc:'));
        expect(encrypted, isNot(equals('123-45-6789')));
      });

      test('should return plaintext for fields not in encryptedFields',
          () async {
        final result = await encryptor.encrypt('John Doe', 'name');

        expect(result, equals('John Doe'));
      });

      test('should produce different ciphertexts for same plaintext', () async {
        final encrypted1 = await encryptor.encrypt('secret', 'ssn');
        final encrypted2 = await encryptor.encrypt('secret', 'ssn');

        // Due to random nonces, ciphertexts should differ
        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('should include version in encrypted format', () async {
        final encrypted = await encryptor.encrypt('test', 'ssn');
        final parts = encrypted.split(':');

        expect(parts[0], equals('enc'));
        expect(parts[1], equals('v1')); // Default version
        expect(parts.length, equals(3));
      });
    });

    group('decrypt', () {
      test('should decrypt previously encrypted value', () async {
        const original = '123-45-6789';
        final encrypted = await encryptor.encrypt(original, 'ssn');
        final decrypted = await encryptor.decrypt(encrypted, 'ssn');

        expect(decrypted, equals(original));
      });

      test('should return plaintext for non-encrypted values', () async {
        final result = await encryptor.decrypt('plaintext', 'ssn');

        expect(result, equals('plaintext'));
      });

      test('should decrypt various data types', () async {
        final testCases = [
          'Hello, World!',
          '12345',
          r'Special chars: !@#$%^&*()',
          'Unicode: \u{1F4BB} \u{1F512}',
          '',
          'A very long string ' * 100,
        ];

        for (final original in testCases) {
          final encrypted = await encryptor.encrypt(original, 'ssn');
          final decrypted = await encryptor.decrypt(encrypted, 'ssn');
          expect(decrypted, equals(original));
        }
      });

      test('should throw for invalid encrypted format', () async {
        expect(
          () => encryptor.decrypt('enc:invalid', 'ssn'),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should throw for version mismatch', () async {
        expect(
          () => encryptor.decrypt('enc:v999:somedata', 'ssn'),
          throwsA(
            isA<EncryptionException>().having(
              (e) => e.message,
              'message',
              contains('Version mismatch'),
            ),
          ),
        );
      });

      test('should throw for invalid data length', () async {
        // Very short base64 data that won't have enough bytes
        expect(
          () => encryptor.decrypt('enc:v1:YWJj', 'ssn'),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('clearCache', () {
      test('should clear cached cipher and key', () async {
        // First encryption to populate cache
        await encryptor.encrypt('test', 'ssn');

        // Clear cache
        encryptor.clearCache();

        // Should still work after clearing (will recreate cache)
        final encrypted = await encryptor.encrypt('test2', 'ssn');
        expect(encrypted, startsWith('enc:'));
      });
    });

    group('with ChaCha20-Poly1305', () {
      late DefaultFieldEncryptor chachaEncryptor;

      setUp(() {
        chachaEncryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'chacha-test-key-32-bytes-long!!',
            encryptedFields: {'secret'},
            algorithm: EncryptionAlgorithm.chaCha20Poly1305,
          ) as EncryptionFieldLevel,
        );
      });

      test('should encrypt and decrypt with ChaCha20', () async {
        const original = 'sensitive data';
        final encrypted = await chachaEncryptor.encrypt(original, 'secret');
        final decrypted = await chachaEncryptor.decrypt(encrypted, 'secret');

        expect(encrypted, startsWith('enc:'));
        expect(decrypted, equals(original));
      });
    });

    group('key derivation', () {
      test('should handle short keys by deriving 32-byte key', () async {
        final shortKeyEncryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'short',
            encryptedFields: {'field'},
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await shortKeyEncryptor.encrypt(original, 'field');
        final decrypted = await shortKeyEncryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });

      test('should truncate long keys to 32 bytes', () async {
        final longKeyEncryptor = DefaultFieldEncryptor(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'a' * 100,
            encryptedFields: {'field'},
          ) as EncryptionFieldLevel,
        );

        const original = 'test data';
        final encrypted = await longKeyEncryptor.encrypt(original, 'field');
        final decrypted = await longKeyEncryptor.decrypt(encrypted, 'field');

        expect(decrypted, equals(original));
      });
    });
  });

  group('EncryptionException', () {
    test('should create with message only', () {
      const exception = EncryptionException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('EncryptionException: Test error'));
    });

    test('should create with message and cause', () {
      const cause = FormatException('bad format');
      const exception = EncryptionException('Decryption failed', cause);

      expect(exception.message, equals('Decryption failed'));
      expect(exception.cause, equals(cause));
      expect(
        exception.toString(),
        contains('Decryption failed'),
      );
      expect(exception.toString(), contains('bad format'));
    });
  });

  group('EncryptionAlgorithm', () {
    test('should have all expected values', () {
      expect(EncryptionAlgorithm.values, hasLength(3));
      expect(
        EncryptionAlgorithm.values,
        contains(EncryptionAlgorithm.aes256Gcm),
      );
      expect(
        EncryptionAlgorithm.values,
        contains(EncryptionAlgorithm.aes256Cbc),
      );
      expect(
        EncryptionAlgorithm.values,
        contains(EncryptionAlgorithm.chaCha20Poly1305),
      );
    });
  });

  group('DefaultFieldEncryptor with PBKDF2 key derivation', () {
    late InMemorySaltStorage saltStorage;

    setUp(() {
      saltStorage = InMemorySaltStorage();
    });

    test('should encrypt and decrypt with PBKDF2 key derivation', () async {
      final encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'user-password',
          encryptedFields: {'ssn'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(
            iterations: 100000, // Lower for testing speed
          ),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      const original = '123-45-6789';
      final encrypted = await encryptor.encrypt(original, 'ssn');
      final decrypted = await encryptor.decrypt(encrypted, 'ssn');

      expect(encrypted, startsWith('enc:'));
      expect(decrypted, equals(original));
    });

    test('should store salt when using key derivation', () async {
      final encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      await encryptor.encrypt('data', 'field');

      // Salt should be stored
      final storedSalt = await saltStorage.getSalt('field-encryption');
      expect(storedSalt, isNotNull);
      expect(storedSalt!.length, greaterThanOrEqualTo(16));
    });

    test('should reuse stored salt for consistent key derivation', () async {
      final encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      // Encrypt with first instance
      const original = 'secret data';
      final encrypted = await encryptor.encrypt(original, 'field');

      // Create new encryptor (simulating app restart)
      final newEncryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      // Should still decrypt with same password and stored salt
      final decrypted = await newEncryptor.decrypt(encrypted, 'field');
      expect(decrypted, equals(original));
    });

    test('should derive different keys for different passwords', () async {
      // Pre-store a salt so both encryptors use the same salt
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      await saltStorage.storeSalt('field-encryption', salt);

      final encryptor1 = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password1',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      final encryptor2 = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password2',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      const original = 'secret';
      final encrypted = await encryptor1.encrypt(original, 'field');

      // Different password should fail to decrypt
      expect(
        () => encryptor2.decrypt(encrypted, 'field'),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('should work with raw key derivation (no derivation)', () async {
      final encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'raw-key-32-bytes-for-aes-256!!',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.raw(),
        ) as EncryptionFieldLevel,
      );

      const original = 'test data';
      final encrypted = await encryptor.encrypt(original, 'field');
      final decrypted = await encryptor.decrypt(encrypted, 'field');

      expect(decrypted, equals(original));
    });

    test('should clear derived key cache on clearCache', () async {
      final encryptor = DefaultFieldEncryptor(
        config: EncryptionConfig.fieldLevel(
          keyProvider: () async => 'password',
          encryptedFields: {'field'},
          keyDerivation: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: saltStorage,
        ) as EncryptionFieldLevel,
      );

      const original = 'test data';
      final encrypted = await encryptor.encrypt(original, 'field');

      encryptor.clearCache();

      // Should still work after clearing cache
      final decrypted = await encryptor.decrypt(encrypted, 'field');
      expect(decrypted, equals(original));
    });
  });
}
