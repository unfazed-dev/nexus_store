import 'dart:typed_data';

import 'package:nexus_store/src/security/derived_key.dart';
import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:nexus_store/src/security/key_deriver.dart';
import 'package:nexus_store/src/security/pbkdf2_key_deriver.dart';
import 'package:test/test.dart';

void main() {
  group('KeyDeriver interface', () {
    test('Pbkdf2KeyDeriver should implement KeyDeriver', () {
      final deriver = Pbkdf2KeyDeriver();
      expect(deriver, isA<KeyDeriver>());
    });
  });

  group('Pbkdf2KeyDeriver', () {
    late Pbkdf2KeyDeriver deriver;

    setUp(() {
      deriver = Pbkdf2KeyDeriver();
    });

    group('construction', () {
      test('should create with default config', () {
        final deriver = Pbkdf2KeyDeriver();
        expect(deriver.config.iterations, equals(310000));
        expect(deriver.config.hashAlgorithm, equals(KdfHashAlgorithm.sha256));
        expect(deriver.config.keyLength, equals(32));
        expect(deriver.config.saltLength, equals(16));
      });

      test('should accept custom config', () {
        const config = KeyDerivationConfig.pbkdf2(
          iterations: 500000,
          hashAlgorithm: KdfHashAlgorithm.sha512,
          keyLength: 64,
          saltLength: 32,
        );
        final deriver = Pbkdf2KeyDeriver(config: config as KeyDerivationPbkdf2);

        expect(deriver.config.iterations, equals(500000));
        expect(deriver.config.hashAlgorithm, equals(KdfHashAlgorithm.sha512));
        expect(deriver.config.keyLength, equals(64));
        expect(deriver.config.saltLength, equals(32));
      });
    });

    group('generateSalt', () {
      test('should generate salt of default length (16 bytes)', () {
        final salt = deriver.generateSalt();
        expect(salt.length, equals(16));
      });

      test('should generate salt of custom length', () {
        final salt = deriver.generateSalt(32);
        expect(salt.length, equals(32));
      });

      test('should generate different salts each time', () {
        final salt1 = deriver.generateSalt();
        final salt2 = deriver.generateSalt();
        final salt3 = deriver.generateSalt();

        // It's technically possible but extremely unlikely for these to be equal
        expect(salt1, isNot(equals(salt2)));
        expect(salt2, isNot(equals(salt3)));
        expect(salt1, isNot(equals(salt3)));
      });

      test('should generate cryptographically random bytes', () {
        final salts = List.generate(10, (_) => deriver.generateSalt());

        // Check that salts have good entropy (not all zeros, not predictable)
        for (final salt in salts) {
          // At least some bytes should be non-zero
          expect(salt.any((b) => b != 0), isTrue);
        }
      });
    });

    group('deriveKey', () {
      test('should derive key with provided salt', () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result = await deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result, isA<DerivedKey>());
        expect(result.keyBytes.length, equals(32));
        expect(result.salt, equals(salt));
        expect(result.algorithm, equals('pbkdf2-sha256'));
      });

      test('should generate salt when not provided', () async {
        final result = await deriver.deriveKey(
          password: 'test-password',
        );

        expect(result.keyBytes.length, equals(32));
        expect(result.salt.length, equals(16));
        expect(result.algorithm, equals('pbkdf2-sha256'));
      });

      test('should produce consistent output for same password and salt',
          () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result1 = await deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );
        final result2 = await deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result1.keyBytes, equals(result2.keyBytes));
      });

      test('should produce different keys for different passwords', () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result1 = await deriver.deriveKey(
          password: 'password1',
          salt: salt,
        );
        final result2 = await deriver.deriveKey(
          password: 'password2',
          salt: salt,
        );

        expect(result1.keyBytes, isNot(equals(result2.keyBytes)));
      });

      test('should produce different keys for different salts', () async {
        final salt1 = Uint8List.fromList(List.generate(16, (i) => i));
        final salt2 = Uint8List.fromList(List.generate(16, (i) => i + 100));

        final result1 = await deriver.deriveKey(
          password: 'same-password',
          salt: salt1,
        );
        final result2 = await deriver.deriveKey(
          password: 'same-password',
          salt: salt2,
        );

        expect(result1.keyBytes, isNot(equals(result2.keyBytes)));
      });

      test('should include iterations in params', () async {
        final result = await deriver.deriveKey(
          password: 'test-password',
        );

        expect(result.params['iterations'], equals(310000));
      });

      test('should include hash algorithm in params', () async {
        final result = await deriver.deriveKey(
          password: 'test-password',
        );

        expect(result.params['hashAlgorithm'], equals('sha256'));
      });
    });

    group('SHA-512 support', () {
      test('should derive key with SHA-512', () async {
        const config = KeyDerivationConfig.pbkdf2(
          hashAlgorithm: KdfHashAlgorithm.sha512,
          iterations: 100000,
        );
        final sha512Deriver = Pbkdf2KeyDeriver(
          config: config as KeyDerivationPbkdf2,
        );
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result = await sha512Deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result.keyBytes.length, equals(32));
        expect(result.algorithm, equals('pbkdf2-sha512'));
        expect(result.params['hashAlgorithm'], equals('sha512'));
      });

      test('SHA-256 and SHA-512 should produce different keys', () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        const sha256Config = KeyDerivationConfig.pbkdf2(
          hashAlgorithm: KdfHashAlgorithm.sha256,
          iterations: 100000,
        );
        const sha512Config = KeyDerivationConfig.pbkdf2(
          hashAlgorithm: KdfHashAlgorithm.sha512,
          iterations: 100000,
        );

        final sha256Deriver = Pbkdf2KeyDeriver(
          config: sha256Config as KeyDerivationPbkdf2,
        );
        final sha512Deriver = Pbkdf2KeyDeriver(
          config: sha512Config as KeyDerivationPbkdf2,
        );

        final result256 = await sha256Deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );
        final result512 = await sha512Deriver.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result256.keyBytes, isNot(equals(result512.keyBytes)));
      });
    });

    group('iteration count', () {
      test('should use configured iterations', () async {
        const config = KeyDerivationConfig.pbkdf2(iterations: 100000);
        final customDeriver = Pbkdf2KeyDeriver(
          config: config as KeyDerivationPbkdf2,
        );

        final result = await customDeriver.deriveKey(
          password: 'test-password',
        );

        expect(result.params['iterations'], equals(100000));
      });

      test('different iteration counts should produce different keys',
          () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        const config100k = KeyDerivationConfig.pbkdf2(iterations: 100000);
        const config200k = KeyDerivationConfig.pbkdf2(iterations: 200000);

        final deriver100k = Pbkdf2KeyDeriver(
          config: config100k as KeyDerivationPbkdf2,
        );
        final deriver200k = Pbkdf2KeyDeriver(
          config: config200k as KeyDerivationPbkdf2,
        );

        final result100k = await deriver100k.deriveKey(
          password: 'test-password',
          salt: salt,
        );
        final result200k = await deriver200k.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result100k.keyBytes, isNot(equals(result200k.keyBytes)));
      });
    });

    group('key length', () {
      test('should produce key of configured length', () async {
        const config = KeyDerivationConfig.pbkdf2(
          keyLength: 64,
          iterations: 100000,
        );
        final customDeriver = Pbkdf2KeyDeriver(
          config: config as KeyDerivationPbkdf2,
        );

        final result = await customDeriver.deriveKey(
          password: 'test-password',
        );

        expect(result.keyBytes.length, equals(64));
      });
    });

    group('edge cases', () {
      test('should handle empty password', () async {
        final result = await deriver.deriveKey(
          password: '',
        );

        expect(result.keyBytes.length, equals(32));
      });

      test('should handle unicode password', () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result = await deriver.deriveKey(
          password: '密码🔐パスワード',
          salt: salt,
        );

        expect(result.keyBytes.length, equals(32));
      });

      test('should handle very long password', () async {
        // Use lower iterations for this edge case test to avoid CI timeout
        const config = KeyDerivationConfig.pbkdf2(iterations: 1000);
        final fastDeriver = Pbkdf2KeyDeriver(
          config: config as KeyDerivationPbkdf2,
        );
        final longPassword = 'a' * 10000;

        final result = await fastDeriver.deriveKey(
          password: longPassword,
        );

        expect(result.keyBytes.length, equals(32));
      });
    });
  });
}
