import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:test/test.dart';

void main() {
  group('KeyDerivationConfig', () {
    group('pbkdf2', () {
      test('should create pbkdf2 config with defaults', () {
        const config = KeyDerivationConfig.pbkdf2();
        expect(config, isA<KeyDerivationPbkdf2>());
      });

      test('should have default iterations of 310000 (OWASP 2023)', () {
        const config = KeyDerivationConfig.pbkdf2();
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.iterations, equals(310000));
      });

      test('should have default hashAlgorithm of sha256', () {
        const config = KeyDerivationConfig.pbkdf2();
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.hashAlgorithm, equals(KdfHashAlgorithm.sha256));
      });

      test('should have default keyLength of 32 bytes', () {
        const config = KeyDerivationConfig.pbkdf2();
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.keyLength, equals(32));
      });

      test('should have default saltLength of 16 bytes', () {
        const config = KeyDerivationConfig.pbkdf2();
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.saltLength, equals(16));
      });

      test('should allow custom iterations', () {
        const config = KeyDerivationConfig.pbkdf2(iterations: 500000);
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.iterations, equals(500000));
      });

      test('should allow sha512 hash algorithm', () {
        const config = KeyDerivationConfig.pbkdf2(
          hashAlgorithm: KdfHashAlgorithm.sha512,
        );
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.hashAlgorithm, equals(KdfHashAlgorithm.sha512));
      });

      test('should allow custom key length', () {
        const config = KeyDerivationConfig.pbkdf2(keyLength: 64);
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.keyLength, equals(64));
      });

      test('should allow custom salt length', () {
        const config = KeyDerivationConfig.pbkdf2(saltLength: 32);
        final pbkdf2Config = config as KeyDerivationPbkdf2;
        expect(pbkdf2Config.saltLength, equals(32));
      });

      test('isPbkdf2 should return true', () {
        const config = KeyDerivationConfig.pbkdf2();
        expect(config.isPbkdf2, isTrue);
      });

      test('isRaw should return false', () {
        const config = KeyDerivationConfig.pbkdf2();
        expect(config.isRaw, isFalse);
      });
    });

    group('raw', () {
      test('should create raw config', () {
        const config = KeyDerivationConfig.raw();
        expect(config, isA<KeyDerivationRaw>());
      });

      test('isPbkdf2 should return false', () {
        const config = KeyDerivationConfig.raw();
        expect(config.isPbkdf2, isFalse);
      });

      test('isRaw should return true', () {
        const config = KeyDerivationConfig.raw();
        expect(config.isRaw, isTrue);
      });
    });

    group('freezed sealed class matching', () {
      test('should support pattern matching', () {
        const config1 = KeyDerivationConfig.pbkdf2();
        const config2 = KeyDerivationConfig.raw();

        String getType(KeyDerivationConfig config) => switch (config) {
              KeyDerivationPbkdf2() => 'pbkdf2',
              KeyDerivationRaw() => 'raw',
            };

        expect(getType(config1), equals('pbkdf2'));
        expect(getType(config2), equals('raw'));
      });
    });

    group('validation', () {
      test('minimumIterations should return 100000', () {
        expect(KeyDerivationConfig.minimumIterations, equals(100000));
      });

      test('recommendedIterations should return 310000', () {
        expect(KeyDerivationConfig.recommendedIterations, equals(310000));
      });

      test('minimumSaltLength should return 16', () {
        expect(KeyDerivationConfig.minimumSaltLength, equals(16));
      });
    });
  });

  group('KdfHashAlgorithm', () {
    test('should have sha256 value', () {
      expect(KdfHashAlgorithm.sha256, isNotNull);
    });

    test('should have sha512 value', () {
      expect(KdfHashAlgorithm.sha512, isNotNull);
    });

    test('sha256 and sha512 should be different', () {
      expect(KdfHashAlgorithm.sha256, isNot(equals(KdfHashAlgorithm.sha512)));
    });
  });
}
