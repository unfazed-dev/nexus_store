import 'dart:typed_data';

import 'package:nexus_store/src/security/derived_key.dart';
import 'package:test/test.dart';

void main() {
  group('DerivedKey', () {
    late Uint8List testKeyBytes;
    late Uint8List testSalt;

    setUp(() {
      testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i));
      testSalt = Uint8List.fromList(List.generate(16, (i) => i + 100));
    });

    group('construction', () {
      test('should create with required parameters', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        expect(key.keyBytes, equals(testKeyBytes));
        expect(key.salt, equals(testSalt));
        expect(key.algorithm, equals('pbkdf2-sha256'));
      });

      test('should have empty params by default', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        expect(key.params, isEmpty);
      });

      test('should allow custom params', () {
        final params = {'iterations': 310000, 'hashAlgorithm': 'sha256'};
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
          params: params,
        );

        expect(key.params, equals(params));
        expect(key.params['iterations'], equals(310000));
      });
    });

    group('properties', () {
      test('keyLength should return the key length in bytes', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        expect(key.keyLength, equals(32));
      });

      test('saltLength should return the salt length in bytes', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        expect(key.saltLength, equals(16));
      });
    });

    group('dispose', () {
      test('should zero-fill keyBytes after dispose', () {
        final keyBytes = Uint8List.fromList(List.generate(32, (i) => i + 1));
        final key = DerivedKey(
          keyBytes: keyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        key.dispose();

        // After dispose, key bytes should be zeroed
        expect(key.keyBytes.every((b) => b == 0), isTrue);
      });

      test('isDisposed should return true after dispose', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        expect(key.isDisposed, isFalse);

        key.dispose();

        expect(key.isDisposed, isTrue);
      });

      test('calling dispose multiple times should be safe', () {
        final key = DerivedKey(
          keyBytes: testKeyBytes,
          salt: testSalt,
          algorithm: 'pbkdf2-sha256',
        );

        key.dispose();
        key.dispose(); // Should not throw

        expect(key.isDisposed, isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final key1 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
          params: {'iterations': 100000},
        );
        final key2 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
          params: {'iterations': 100000},
        );

        expect(key1, equals(key2));
        expect(key1.hashCode, equals(key2.hashCode));
      });

      test('should not be equal when keyBytes differ', () {
        final key1 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
        );
        final key2 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 4]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should not be equal when salt differs', () {
        final key1 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
        );
        final key2 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 7]),
          algorithm: 'pbkdf2-sha256',
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should not be equal when algorithm differs', () {
        final key1 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha256',
        );
        final key2 = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3]),
          salt: Uint8List.fromList([4, 5, 6]),
          algorithm: 'pbkdf2-sha512',
        );

        expect(key1, isNot(equals(key2)));
      });
    });

    group('toString', () {
      test('should not expose key bytes in toString', () {
        final key = DerivedKey(
          keyBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          salt: Uint8List.fromList([6, 7, 8]),
          algorithm: 'pbkdf2-sha256',
        );

        final str = key.toString();

        // Should not contain the actual key bytes
        expect(str.contains('1, 2, 3, 4, 5'), isFalse);
        // Should contain algorithm info
        expect(str.contains('pbkdf2-sha256'), isTrue);
        // Should indicate key length
        expect(str.contains('5'), isTrue); // keyLength
      });
    });
  });
}
