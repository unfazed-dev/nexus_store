import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureSaltStorage', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureSaltStorage saltStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      saltStorage = SecureSaltStorage(
        storage: mockStorage,
        keyPrefix: 'test_salt_',
      );
    });

    group('getSalt', () {
      test('returns null when salt does not exist', () async {
        when(() => mockStorage.read(key: 'test_salt_user-123'))
            .thenAnswer((_) async => null);

        final result = await saltStorage.getSalt('user-123');

        expect(result, isNull);
        verify(() => mockStorage.read(key: 'test_salt_user-123')).called(1);
      });

      test('returns null when salt is empty string', () async {
        when(() => mockStorage.read(key: 'test_salt_user-123'))
            .thenAnswer((_) async => '');

        final result = await saltStorage.getSalt('user-123');

        expect(result, isNull);
      });

      test('returns bytes when salt exists', () async {
        // Hex for bytes [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
        when(() => mockStorage.read(key: 'test_salt_user-123'))
            .thenAnswer((_) async => '0102030405060708090a0b0c0d0e0f10');

        final result = await saltStorage.getSalt('user-123');

        expect(result, isNotNull);
        expect(result!.length, 16);
        expect(result[0], 1);
        expect(result[15], 16);
      });

      test('returns null on storage exception', () async {
        when(() => mockStorage.read(key: 'test_salt_user-123'))
            .thenThrow(Exception('Storage error'));

        final result = await saltStorage.getSalt('user-123');

        expect(result, isNull);
      });
    });

    group('storeSalt', () {
      test('stores salt as hex string', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final salt = Uint8List.fromList([1, 2, 3, 4, 255]);
        await saltStorage.storeSalt('user-123', salt);

        verify(() => mockStorage.write(
              key: 'test_salt_user-123',
              value: '01020304ff',
            ),).called(1);
      });
    });

    group('hasSalt', () {
      test('returns true when salt exists', () async {
        when(() => mockStorage.containsKey(key: 'test_salt_user-123'))
            .thenAnswer((_) async => true);

        final result = await saltStorage.hasSalt('user-123');

        expect(result, isTrue);
      });

      test('returns false when salt does not exist', () async {
        when(() => mockStorage.containsKey(key: 'test_salt_user-123'))
            .thenAnswer((_) async => false);

        final result = await saltStorage.hasSalt('user-123');

        expect(result, isFalse);
      });

      test('returns false on storage exception', () async {
        when(() => mockStorage.containsKey(key: 'test_salt_user-123'))
            .thenThrow(Exception('Storage error'));

        final result = await saltStorage.hasSalt('user-123');

        expect(result, isFalse);
      });
    });

    group('deleteSalt', () {
      test('deletes salt from storage', () async {
        when(() => mockStorage.delete(key: 'test_salt_user-123'))
            .thenAnswer((_) async {});

        await saltStorage.deleteSalt('user-123');

        verify(() => mockStorage.delete(key: 'test_salt_user-123')).called(1);
      });
    });

    group('deleteAllSalts', () {
      test('deletes only prefixed keys', () async {
        when(() => mockStorage.readAll()).thenAnswer((_) async => {
              'test_salt_user-123': 'abc123',
              'test_salt_user-456': 'def456',
              'other_key': 'value',
            },);
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await saltStorage.deleteAllSalts();

        verify(() => mockStorage.delete(key: 'test_salt_user-123')).called(1);
        verify(() => mockStorage.delete(key: 'test_salt_user-456')).called(1);
        verifyNever(() => mockStorage.delete(key: 'other_key'));
      });
    });

    group('listSaltKeyIds', () {
      test('returns key IDs without prefix', () async {
        when(() => mockStorage.readAll()).thenAnswer((_) async => {
              'test_salt_user-123': 'abc123',
              'test_salt_user-456': 'def456',
              'other_key': 'value',
            },);

        final result = await saltStorage.listSaltKeyIds();

        expect(result, containsAll(['user-123', 'user-456']));
        expect(result, isNot(contains('other_key')));
        expect(result.length, 2);
      });
    });

    group('hex conversion', () {
      test('round-trips bytes correctly', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            ),).thenAnswer((_) async {});

        final originalSalt = Uint8List.fromList(
          List.generate(16, (i) => i * 16 + i),
        );
        await saltStorage.storeSalt('test', originalSalt);

        final captured = verify(() => mockStorage.write(
              key: 'test_salt_test',
              value: captureAny(named: 'value'),
            ),).captured.single as String;

        when(() => mockStorage.read(key: 'test_salt_test'))
            .thenAnswer((_) async => captured);

        final retrieved = await saltStorage.getSalt('test');

        expect(retrieved, equals(originalSalt));
      });
    });

    group('keyPrefix', () {
      test('uses custom prefix', () async {
        final customStorage = SecureSaltStorage(
          storage: mockStorage,
          keyPrefix: 'custom_prefix_',
        );

        when(() => mockStorage.read(key: 'custom_prefix_my-key'))
            .thenAnswer((_) async => null);

        await customStorage.getSalt('my-key');

        verify(() => mockStorage.read(key: 'custom_prefix_my-key')).called(1);
      });

      test('uses default prefix when not specified', () {
        final defaultStorage = SecureSaltStorage(storage: mockStorage);

        expect(defaultStorage.keyPrefix, 'nexus_salt_');
      });
    });
  });
}
