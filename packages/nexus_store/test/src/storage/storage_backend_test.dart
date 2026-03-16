import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

class MockStorageBackend extends Mock implements StorageBackend {}

void main() {
  group('StorageBackend', () {
    late MockStorageBackend backend;

    setUp(() {
      backend = MockStorageBackend();
    });

    test('interface defines listBuckets', () async {
      when(() => backend.listBuckets()).thenAnswer((_) async => <Bucket>[]);
      final result = await backend.listBuckets();
      expect(result, isEmpty);
    });

    test('interface defines getBucket', () async {
      when(() => backend.getBucket('avatars')).thenAnswer(
        (_) async => Bucket(
          id: 'avatars',
          name: 'avatars',
          public: true,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final result = await backend.getBucket('avatars');
      expect(result.id, 'avatars');
    });

    test('interface defines createBucket', () async {
      when(() => backend.createBucket('test', options: any(named: 'options')))
          .thenAnswer((_) async => 'test');
      final result = await backend.createBucket('test');
      expect(result, 'test');
    });

    test('interface defines updateBucket', () async {
      when(() =>
              backend.updateBucket('test', const BucketOptions(public: true)))
          .thenAnswer((_) async {
        // void return
      });
      await backend.updateBucket('test', const BucketOptions(public: true));
      verify(() =>
              backend.updateBucket('test', const BucketOptions(public: true)))
          .called(1);
    });

    test('interface defines deleteBucket', () async {
      when(() => backend.deleteBucket('test')).thenAnswer((_) async {
        // void return
      });
      await backend.deleteBucket('test');
      verify(() => backend.deleteBucket('test')).called(1);
    });

    test('interface defines emptyBucket', () async {
      when(() => backend.emptyBucket('test')).thenAnswer((_) async {
        // void return
      });
      await backend.emptyBucket('test');
      verify(() => backend.emptyBucket('test')).called(1);
    });

    test('interface defines upload', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => backend.upload('bucket', 'path', bytes,
              options: any(named: 'options')))
          .thenAnswer((_) async => 'bucket/path');
      final result = await backend.upload('bucket', 'path', bytes);
      expect(result, 'bucket/path');
    });

    test('interface defines download', () async {
      final expected = Uint8List.fromList([1, 2, 3]);
      when(() => backend.download('bucket', 'path',
              transform: any(named: 'transform')))
          .thenAnswer((_) async => expected);
      final result = await backend.download('bucket', 'path');
      expect(result, expected);
    });

    test('interface defines update', () async {
      final bytes = Uint8List.fromList([4, 5, 6]);
      when(() => backend.update('bucket', 'path', bytes,
              options: any(named: 'options')))
          .thenAnswer((_) async => 'bucket/path');
      final result = await backend.update('bucket', 'path', bytes);
      expect(result, 'bucket/path');
    });

    test('interface defines remove', () async {
      when(() => backend.remove('bucket', ['a.jpg', 'b.jpg']))
          .thenAnswer((_) async {
        // void return
      });
      await backend.remove('bucket', ['a.jpg', 'b.jpg']);
      verify(() => backend.remove('bucket', ['a.jpg', 'b.jpg'])).called(1);
    });

    test('interface defines move', () async {
      when(() => backend.move('bucket', 'old/path', 'new/path'))
          .thenAnswer((_) async => 'new/path');
      final result = await backend.move('bucket', 'old/path', 'new/path');
      expect(result, 'new/path');
    });

    test('interface defines copy', () async {
      when(() => backend.copy('bucket', 'src/path', 'dst/path'))
          .thenAnswer((_) async => 'dst/path');
      final result = await backend.copy('bucket', 'src/path', 'dst/path');
      expect(result, 'dst/path');
    });

    test('interface defines createSignedUrl', () async {
      when(() => backend.createSignedUrl('bucket', 'path', 3600))
          .thenAnswer((_) async => 'https://signed-url');
      final result = await backend.createSignedUrl('bucket', 'path', 3600);
      expect(result, 'https://signed-url');
    });

    test('interface defines createSignedUrls', () async {
      when(() => backend.createSignedUrls('bucket', ['a.jpg'], 3600))
          .thenAnswer((_) async => [
                const SignedUrl(path: 'a.jpg', signedUrl: 'https://signed'),
              ]);
      final result = await backend.createSignedUrls('bucket', ['a.jpg'], 3600);
      expect(result, hasLength(1));
    });

    test('interface defines getPublicUrl', () {
      when(() => backend.getPublicUrl('bucket', 'path',
          transform: any(named: 'transform'))).thenReturn('https://public-url');
      final result = backend.getPublicUrl('bucket', 'path');
      expect(result, 'https://public-url');
    });

    test('interface defines list', () async {
      when(() => backend.list('bucket',
              path: any(named: 'path'), options: any(named: 'options')))
          .thenAnswer((_) async => <StorageFile>[]);
      final result = await backend.list('bucket');
      expect(result, isEmpty);
    });
  });
}
