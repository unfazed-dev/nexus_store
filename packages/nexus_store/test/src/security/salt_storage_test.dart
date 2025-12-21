import 'dart:typed_data';

import 'package:nexus_store/src/security/salt_storage.dart';
import 'package:test/test.dart';

void main() {
  group('SaltStorage interface', () {
    test('InMemorySaltStorage should implement SaltStorage', () {
      final storage = InMemorySaltStorage();
      expect(storage, isA<SaltStorage>());
    });
  });

  group('InMemorySaltStorage', () {
    late InMemorySaltStorage storage;

    setUp(() {
      storage = InMemorySaltStorage();
    });

    group('storeSalt and getSalt', () {
      test('should store and retrieve salt', () async {
        final salt = Uint8List.fromList([1, 2, 3, 4, 5]);

        await storage.storeSalt('test-key', salt);
        final retrieved = await storage.getSalt('test-key');

        expect(retrieved, equals(salt));
      });

      test('should return null for non-existent key', () async {
        final result = await storage.getSalt('non-existent');
        expect(result, isNull);
      });

      test('should overwrite existing salt', () async {
        final salt1 = Uint8List.fromList([1, 2, 3]);
        final salt2 = Uint8List.fromList([4, 5, 6]);

        await storage.storeSalt('test-key', salt1);
        await storage.storeSalt('test-key', salt2);

        final retrieved = await storage.getSalt('test-key');
        expect(retrieved, equals(salt2));
      });

      test('should store multiple salts independently', () async {
        final salt1 = Uint8List.fromList([1, 2, 3]);
        final salt2 = Uint8List.fromList([4, 5, 6]);
        final salt3 = Uint8List.fromList([7, 8, 9]);

        await storage.storeSalt('key1', salt1);
        await storage.storeSalt('key2', salt2);
        await storage.storeSalt('key3', salt3);

        expect(await storage.getSalt('key1'), equals(salt1));
        expect(await storage.getSalt('key2'), equals(salt2));
        expect(await storage.getSalt('key3'), equals(salt3));
      });
    });

    group('hasSalt', () {
      test('should return true when salt exists', () async {
        await storage.storeSalt('test-key', Uint8List.fromList([1, 2, 3]));

        final result = await storage.hasSalt('test-key');

        expect(result, isTrue);
      });

      test('should return false when salt does not exist', () async {
        final result = await storage.hasSalt('non-existent');

        expect(result, isFalse);
      });
    });

    group('deleteSalt', () {
      test('should delete existing salt', () async {
        await storage.storeSalt('test-key', Uint8List.fromList([1, 2, 3]));

        await storage.deleteSalt('test-key');

        expect(await storage.hasSalt('test-key'), isFalse);
        expect(await storage.getSalt('test-key'), isNull);
      });

      test('should not throw when deleting non-existent key', () async {
        // Should complete without throwing
        await storage.deleteSalt('non-existent');
      });
    });

    group('clear', () {
      test('should remove all stored salts', () async {
        await storage.storeSalt('key1', Uint8List.fromList([1]));
        await storage.storeSalt('key2', Uint8List.fromList([2]));
        await storage.storeSalt('key3', Uint8List.fromList([3]));

        await storage.clear();

        expect(await storage.hasSalt('key1'), isFalse);
        expect(await storage.hasSalt('key2'), isFalse);
        expect(await storage.hasSalt('key3'), isFalse);
      });

      test('should not throw when storage is already empty', () async {
        await storage.clear();
        // Should complete without throwing
      });
    });

    group('keys', () {
      test('should return all stored key IDs', () async {
        await storage.storeSalt('key1', Uint8List.fromList([1]));
        await storage.storeSalt('key2', Uint8List.fromList([2]));
        await storage.storeSalt('key3', Uint8List.fromList([3]));

        final keys = await storage.keys;

        expect(keys, containsAll(['key1', 'key2', 'key3']));
        expect(keys.length, equals(3));
      });

      test('should return empty list when storage is empty', () async {
        final keys = await storage.keys;

        expect(keys, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle empty key ID', () async {
        final salt = Uint8List.fromList([1, 2, 3]);

        await storage.storeSalt('', salt);
        final retrieved = await storage.getSalt('');

        expect(retrieved, equals(salt));
      });

      test('should handle empty salt', () async {
        final salt = Uint8List(0);

        await storage.storeSalt('test-key', salt);
        final retrieved = await storage.getSalt('test-key');

        expect(retrieved, equals(salt));
        expect(retrieved!.length, equals(0));
      });

      test('should handle long key ID', () async {
        final longKeyId = 'a' * 1000;
        final salt = Uint8List.fromList([1, 2, 3]);

        await storage.storeSalt(longKeyId, salt);
        final retrieved = await storage.getSalt(longKeyId);

        expect(retrieved, equals(salt));
      });

      test('should handle large salt', () async {
        final largeSalt = Uint8List(10000);
        for (var i = 0; i < largeSalt.length; i++) {
          largeSalt[i] = i % 256;
        }

        await storage.storeSalt('test-key', largeSalt);
        final retrieved = await storage.getSalt('test-key');

        expect(retrieved, equals(largeSalt));
      });
    });
  });
}
