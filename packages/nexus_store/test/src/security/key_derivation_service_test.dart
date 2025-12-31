import 'dart:typed_data';

import 'package:nexus_store/src/security/derived_key.dart';
import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:nexus_store/src/security/key_derivation_service.dart';
import 'package:nexus_store/src/security/salt_storage.dart';
import 'package:test/test.dart';

void main() {
  group('KeyDerivationService', () {
    group('factory creation', () {
      test('should create service with PBKDF2 config', () {
        const config = KeyDerivationConfig.pbkdf2();
        final service = KeyDerivationService(config: config);

        expect(service, isA<KeyDerivationService>());
        expect(service.config, equals(config));
      });

      test('should create service with raw config', () {
        const config = KeyDerivationConfig.raw();
        final service = KeyDerivationService(config: config);

        expect(service.config, equals(config));
      });

      test('should accept salt storage', () {
        const config = KeyDerivationConfig.pbkdf2();
        final storage = InMemorySaltStorage();
        final service = KeyDerivationService(
          config: config,
          saltStorage: storage,
        );

        expect(service.saltStorage, equals(storage));
      });
    });

    group('deriveKey with PBKDF2', () {
      late KeyDerivationService service;

      setUp(() {
        service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(iterations: 100000),
        );
      });

      test('should derive key from password', () async {
        final result = await service.deriveKey(password: 'test-password');

        expect(result, isA<DerivedKey>());
        expect(result.keyBytes.length, equals(32));
        expect(result.salt.length, equals(16));
        expect(result.algorithm, contains('pbkdf2'));
      });

      test('should use provided salt', () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result = await service.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result.salt, equals(salt));
      });

      test('should produce consistent keys for same password and salt',
          () async {
        final salt = Uint8List.fromList(List.generate(16, (i) => i));

        final result1 = await service.deriveKey(
          password: 'test-password',
          salt: salt,
        );
        final result2 = await service.deriveKey(
          password: 'test-password',
          salt: salt,
        );

        expect(result1.keyBytes, equals(result2.keyBytes));
      });
    });

    group('deriveKey with raw config', () {
      test('should pass through raw key as-is', () async {
        final service = KeyDerivationService(
          config: const KeyDerivationConfig.raw(),
        );

        final result = await service.deriveKey(
          password: 'raw-key-32-bytes-exactly!!!!!!!', // 32 chars
        );

        // For raw config, the password is used directly as the key
        expect(result.keyBytes.length, equals(32));
        expect(result.algorithm, equals('raw'));
      });
    });

    group('salt storage integration', () {
      late KeyDerivationService service;
      late InMemorySaltStorage storage;

      setUp(() {
        storage = InMemorySaltStorage();
        service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(iterations: 100000),
          saltStorage: storage,
        );
      });

      test('should store generated salt with keyId', () async {
        await service.deriveKey(
          password: 'test-password',
          keyId: 'my-encryption-key',
        );

        final storedSalt = await storage.getSalt('my-encryption-key');
        expect(storedSalt, isNotNull);
        expect(storedSalt!.length, equals(16));
      });

      test('should reuse stored salt when keyId provided', () async {
        // First derivation - generates and stores salt
        final result1 = await service.deriveKey(
          password: 'test-password',
          keyId: 'my-encryption-key',
        );

        // Second derivation - should use stored salt
        final result2 = await service.deriveKey(
          password: 'test-password',
          keyId: 'my-encryption-key',
        );

        expect(result1.salt, equals(result2.salt));
        expect(result1.keyBytes, equals(result2.keyBytes));
      });

      test('should use provided salt over stored salt', () async {
        // Store a salt
        final storedSalt = Uint8List.fromList(List.generate(16, (i) => 100));
        await storage.storeSalt('my-key', storedSalt);

        // Derive with explicit salt
        final explicitSalt = Uint8List.fromList(List.generate(16, (i) => 200));
        final result = await service.deriveKey(
          password: 'test-password',
          keyId: 'my-key',
          salt: explicitSalt,
        );

        expect(result.salt, equals(explicitSalt));
        expect(result.salt, isNot(equals(storedSalt)));
      });
    });

    group('generateSalt', () {
      test('should generate random salt of configured length', () {
        final service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(saltLength: 32),
        );

        final salt = service.generateSalt();

        expect(salt.length, equals(32));
      });

      test('should generate salt of custom length', () {
        final service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(),
        );

        final salt = service.generateSalt(24);

        expect(salt.length, equals(24));
      });

      test('should generate different salts each time', () {
        final service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(),
        );

        final salt1 = service.generateSalt();
        final salt2 = service.generateSalt();

        expect(salt1, isNot(equals(salt2)));
      });
    });

    group('dispose', () {
      test('should clear cached keys on dispose', () async {
        final service = KeyDerivationService(
          config: const KeyDerivationConfig.pbkdf2(iterations: 100000),
        );

        await service.deriveKey(password: 'test-password');

        // Should not throw
        service.dispose();
      });
    });

    group('static utilities', () {
      test('generateSecureRandomSalt should generate random bytes', () {
        final salt1 = KeyDerivationService.generateSecureRandomSalt();
        final salt2 = KeyDerivationService.generateSecureRandomSalt();

        expect(salt1.length, equals(16));
        expect(salt2.length, equals(16));
        expect(salt1, isNot(equals(salt2)));
      });

      test('generateSecureRandomSalt should accept custom length', () {
        final salt = KeyDerivationService.generateSecureRandomSalt(32);
        expect(salt.length, equals(32));
      });
    });
  });
}
