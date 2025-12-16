import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptionService', () {
    group('constructor', () {
      test('should create service with field-level config', () {
        final service = EncryptionService(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'test-key-32-bytes-for-aes-256!',
            encryptedFields: {'ssn', 'email'},
          ),
        );

        expect(service.isEnabled, isTrue);
        expect(service.isFieldLevel, isTrue);
        expect(service.encryptor, isNotNull);
      });

      test('should create service with none config', () {
        final service = EncryptionService(
          config: const EncryptionConfig.none(),
        );

        expect(service.isEnabled, isFalse);
        expect(service.isFieldLevel, isFalse);
        expect(service.encryptor, isNull);
      });

      test('should create service with sqlCipher config', () {
        final service = EncryptionService(
          config: EncryptionConfig.sqlCipher(
            keyProvider: () async => 'database-key',
          ),
        );

        expect(service.isEnabled, isTrue);
        expect(service.isFieldLevel, isFalse);
        expect(service.encryptor, isNull);
      });
    });

    group('with field-level encryption', () {
      late EncryptionService service;

      setUp(() {
        service = EncryptionService(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'test-key-32-bytes-for-aes-256!',
            encryptedFields: {'ssn', 'email', 'phone'},
          ),
        );
      });

      group('encryptFields', () {
        test('should encrypt configured fields', () async {
          final data = {
            'name': 'John Doe',
            'ssn': '123-45-6789',
            'email': 'john@example.com',
            'age': 30,
          };

          final encrypted = await service.encryptFields(data);

          expect(encrypted['name'], equals('John Doe'));
          expect(encrypted['ssn'], startsWith('enc:'));
          expect(encrypted['email'], startsWith('enc:'));
          expect(encrypted['age'], equals(30));
        });

        test('should handle null values', () async {
          final data = {
            'name': 'John',
            'ssn': null,
          };

          final encrypted = await service.encryptFields(data);

          expect(encrypted['name'], equals('John'));
          expect(encrypted['ssn'], isNull);
        });

        test('should convert non-string values to string before encryption',
            () async {
          final data = {
            'phone': 1234567890,
          };

          final encrypted = await service.encryptFields(data);
          expect(encrypted['phone'], startsWith('enc:'));

          // Verify it can be decrypted
          final decrypted = await service.decryptFields(encrypted);
          expect(decrypted['phone'], equals('1234567890'));
        });

        test('should return original map when no fields to encrypt', () async {
          final data = {
            'name': 'John',
            'age': 30,
          };

          final encrypted = await service.encryptFields(data);

          expect(encrypted['name'], equals('John'));
          expect(encrypted['age'], equals(30));
        });
      });

      group('decryptFields', () {
        test('should decrypt encrypted fields', () async {
          final original = {
            'name': 'John Doe',
            'ssn': '123-45-6789',
            'email': 'john@example.com',
          };

          final encrypted = await service.encryptFields(original);
          final decrypted = await service.decryptFields(encrypted);

          expect(decrypted['name'], equals('John Doe'));
          expect(decrypted['ssn'], equals('123-45-6789'));
          expect(decrypted['email'], equals('john@example.com'));
        });

        test('should skip non-encrypted values', () async {
          final data = {
            'name': 'John Doe',
            'ssn': 'not-encrypted',
          };

          final decrypted = await service.decryptFields(data);

          expect(decrypted['name'], equals('John Doe'));
          expect(decrypted['ssn'], equals('not-encrypted'));
        });

        test('should handle non-string values', () async {
          final data = {
            'name': 'John',
            'age': 30,
            'active': true,
          };

          final decrypted = await service.decryptFields(data);

          expect(decrypted['name'], equals('John'));
          expect(decrypted['age'], equals(30));
          expect(decrypted['active'], isTrue);
        });
      });

      group('encryptField', () {
        test('should encrypt single field value', () async {
          final encrypted = await service.encryptField('ssn', '123-45-6789');

          expect(encrypted, startsWith('enc:'));
          expect(encrypted, isNot(equals('123-45-6789')));
        });

        test('should return original for non-configured field', () async {
          final result = await service.encryptField('name', 'John Doe');

          expect(result, equals('John Doe'));
        });

        test('should return null for null value', () async {
          final result = await service.encryptField('ssn', null);

          expect(result, isNull);
        });
      });

      group('decryptField', () {
        test('should decrypt single field value', () async {
          final encrypted = await service.encryptField('ssn', '123-45-6789');
          final decrypted = await service.decryptField('ssn', encrypted);

          expect(decrypted, equals('123-45-6789'));
        });

        test('should return original for non-encrypted value', () async {
          final result = await service.decryptField('ssn', 'plaintext');

          expect(result, equals('plaintext'));
        });

        test('should return null for null value', () async {
          final result = await service.decryptField('ssn', null);

          expect(result, isNull);
        });
      });

      group('clearCache', () {
        test('should clear encryption cache', () async {
          // Encrypt something to populate cache
          await service.encryptField('ssn', 'test');

          // Clear cache - should not throw
          service.clearCache();

          // Should still work after clearing
          final encrypted = await service.encryptField('ssn', 'test2');
          expect(encrypted, startsWith('enc:'));
        });
      });
    });

    group('with no encryption', () {
      late EncryptionService service;

      setUp(() {
        service = EncryptionService(
          config: const EncryptionConfig.none(),
        );
      });

      test('encryptFields should return original data', () async {
        final data = {'ssn': '123-45-6789', 'name': 'John'};

        final result = await service.encryptFields(data);

        expect(result, equals(data));
      });

      test('decryptFields should return original data', () async {
        final data = {'ssn': '123-45-6789', 'name': 'John'};

        final result = await service.decryptFields(data);

        expect(result, equals(data));
      });

      test('encryptField should return original value', () async {
        final result = await service.encryptField('ssn', '123-45-6789');

        expect(result, equals('123-45-6789'));
      });

      test('decryptField should return original value', () async {
        final result = await service.decryptField('ssn', 'some-value');

        expect(result, equals('some-value'));
      });

      test('clearCache should not throw', () {
        expect(() => service.clearCache(), returnsNormally);
      });
    });

    group('with sqlCipher encryption', () {
      late EncryptionService service;

      setUp(() {
        service = EncryptionService(
          config: EncryptionConfig.sqlCipher(
            keyProvider: () async => 'database-key',
          ),
        );
      });

      test('should not have field encryptor', () {
        expect(service.encryptor, isNull);
      });

      test('encryptFields should return original data', () async {
        final data = {'ssn': '123-45-6789'};

        final result = await service.encryptFields(data);

        expect(result, equals(data));
      });

      test('decryptFields should return original data', () async {
        final data = {'ssn': '123-45-6789'};

        final result = await service.decryptFields(data);

        expect(result, equals(data));
      });
    });

    group('roundtrip', () {
      late EncryptionService service;

      setUp(() {
        service = EncryptionService(
          config: EncryptionConfig.fieldLevel(
            keyProvider: () async => 'roundtrip-test-key-32-bytes!!',
            encryptedFields: {'secret'},
          ),
        );
      });

      test('should encrypt and decrypt complex data', () async {
        final original = {
          'id': 'user-123',
          'name': 'John Doe',
          'secret': 'my-secret-data',
          'metadata': {'key': 'value'},
          'tags': ['a', 'b', 'c'],
          'count': 42,
          'active': true,
        };

        final encrypted = await service.encryptFields(original);

        // Only 'secret' should be encrypted
        expect(encrypted['id'], equals('user-123'));
        expect(encrypted['name'], equals('John Doe'));
        expect(encrypted['secret'], startsWith('enc:'));
        expect(encrypted['metadata'], equals({'key': 'value'}));
        expect(encrypted['tags'], equals(['a', 'b', 'c']));
        expect(encrypted['count'], equals(42));
        expect(encrypted['active'], isTrue);

        final decrypted = await service.decryptFields(encrypted);

        expect(decrypted['secret'], equals('my-secret-data'));
      });
    });
  });
}
