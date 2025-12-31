import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptionConfig', () {
    group('none', () {
      test('should create none encryption config', () {
        const config = EncryptionConfig.none();
        expect(config, isA<EncryptionNone>());
      });

      test('should have isEnabled false', () {
        const config = EncryptionConfig.none();
        expect(config.isEnabled, isFalse);
      });

      test('should have isSqlCipher false', () {
        const config = EncryptionConfig.none();
        expect(config.isSqlCipher, isFalse);
      });

      test('should have isFieldLevel false', () {
        const config = EncryptionConfig.none();
        expect(config.isFieldLevel, isFalse);
      });
    });

    group('sqlCipher', () {
      test('should create sqlCipher encryption config', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
        );
        expect(config, isA<EncryptionSqlCipher>());
      });

      test('should have isEnabled true', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
        );
        expect(config.isEnabled, isTrue);
      });

      test('should have isSqlCipher true', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
        );
        expect(config.isSqlCipher, isTrue);
      });

      test('should have isFieldLevel false', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
        );
        expect(config.isFieldLevel, isFalse);
      });

      test('should have default kdfIterations of 256000', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
        );
        final sqlCipherConfig = config as EncryptionSqlCipher;
        expect(sqlCipherConfig.kdfIterations, equals(256000));
      });

      test('should allow custom kdfIterations', () {
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'test-key',
          kdfIterations: 100000,
        );
        final sqlCipherConfig = config as EncryptionSqlCipher;
        expect(sqlCipherConfig.kdfIterations, equals(100000));
      });

      test('should call keyProvider correctly', () async {
        var called = false;
        final config = EncryptionConfig.sqlCipher(
          keyProvider: () async {
            called = true;
            return 'test-key';
          },
        );
        final sqlCipherConfig = config as EncryptionSqlCipher;

        final key = await sqlCipherConfig.keyProvider();

        expect(called, isTrue);
        expect(key, equals('test-key'));
      });
    });

    group('fieldLevel', () {
      test('should create fieldLevel encryption config', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn', 'email'},
          keyProvider: () async => 'test-key',
        );
        expect(config, isA<EncryptionFieldLevel>());
      });

      test('should have isEnabled true', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        expect(config.isEnabled, isTrue);
      });

      test('should have isSqlCipher false', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        expect(config.isSqlCipher, isFalse);
      });

      test('should have isFieldLevel true', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        expect(config.isFieldLevel, isTrue);
      });

      test('should store encryptedFields', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn', 'email', 'phone'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(
          fieldLevelConfig.encryptedFields,
          equals({'ssn', 'email', 'phone'}),
        );
      });

      test('should have default algorithm of aes256Gcm', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(
          fieldLevelConfig.algorithm,
          equals(EncryptionAlgorithm.aes256Gcm),
        );
      });

      test('should allow custom algorithm', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          algorithm: EncryptionAlgorithm.chaCha20Poly1305,
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(
          fieldLevelConfig.algorithm,
          equals(EncryptionAlgorithm.chaCha20Poly1305),
        );
      });

      test('should have default version of v1', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.version, equals('v1'));
      });

      test('should allow custom version', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          version: 'v2',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.version, equals('v2'));
      });

      test('should have null keyDerivation by default', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.keyDerivation, isNull);
      });

      test('should accept keyDerivation config', () {
        const kdfConfig = KeyDerivationConfig.pbkdf2(iterations: 310000);
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          keyDerivation: kdfConfig,
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.keyDerivation, equals(kdfConfig));
      });

      test('should have null saltStorage by default', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.saltStorage, isNull);
      });

      test('should accept saltStorage', () {
        final storage = InMemorySaltStorage();
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          saltStorage: storage,
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.saltStorage, equals(storage));
      });

      test('should accept both keyDerivation and saltStorage', () {
        const kdfConfig = KeyDerivationConfig.pbkdf2();
        final storage = InMemorySaltStorage();
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          keyDerivation: kdfConfig,
          saltStorage: storage,
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.keyDerivation, equals(kdfConfig));
        expect(fieldLevelConfig.saltStorage, equals(storage));
      });

      test('hasKeyDerivation should return true when keyDerivation is set', () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
          keyDerivation: const KeyDerivationConfig.pbkdf2(),
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.hasKeyDerivation, isTrue);
      });

      test('hasKeyDerivation should return false when keyDerivation is null',
          () {
        final config = EncryptionConfig.fieldLevel(
          encryptedFields: {'ssn'},
          keyProvider: () async => 'test-key',
        );
        final fieldLevelConfig = config as EncryptionFieldLevel;
        expect(fieldLevelConfig.hasKeyDerivation, isFalse);
      });
    });

    group('freezed sealed class matching', () {
      test('should support pattern matching', () {
        const config1 = EncryptionConfig.none();
        final config2 = EncryptionConfig.sqlCipher(
          keyProvider: () async => 'key',
        );
        final config3 = EncryptionConfig.fieldLevel(
          encryptedFields: {'field'},
          keyProvider: () async => 'key',
        );

        String getType(EncryptionConfig config) => switch (config) {
              EncryptionNone() => 'none',
              EncryptionSqlCipher() => 'sqlCipher',
              EncryptionFieldLevel() => 'fieldLevel',
            };

        expect(getType(config1), equals('none'));
        expect(getType(config2), equals('sqlCipher'));
        expect(getType(config3), equals('fieldLevel'));
      });
    });
  });
}
