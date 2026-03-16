import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:storage_client/storage_client.dart' as supa;
import 'package:test/test.dart';

class MockSupabaseStorageWrapper extends Mock
    implements SupabaseStorageWrapper {}

void main() {
  late MockSupabaseStorageWrapper mockWrapper;
  late SupabaseStorageBackend backend;

  setUpAll(() {
    registerFallbackValue(
      const supa.BucketOptions(public: false),
    );
    registerFallbackValue(
      const supa.FileOptions(),
    );
    registerFallbackValue(
      const supa.TransformOptions(),
    );
    registerFallbackValue(
      const supa.SearchOptions(),
    );
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockWrapper = MockSupabaseStorageWrapper();
    backend = SupabaseStorageBackend.withWrapper(mockWrapper);
  });

  group('SupabaseStorageBackend', () {
    group('bucket management', () {
      test('listBuckets delegates and maps results', () async {
        when(() => mockWrapper.listBuckets()).thenAnswer(
          (_) async => [
            const supa.Bucket(
              id: 'avatars',
              name: 'avatars',
              owner: 'owner',
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-02T00:00:00.000Z',
              public: true,
            ),
          ],
        );

        final result = await backend.listBuckets();

        expect(result, hasLength(1));
        expect(result.first.id, 'avatars');
        expect(result.first.name, 'avatars');
        expect(result.first.public, true);
      });

      test('getBucket delegates and maps result', () async {
        when(() => mockWrapper.getBucket('avatars')).thenAnswer(
          (_) async => const supa.Bucket(
            id: 'avatars',
            name: 'avatars',
            owner: 'owner',
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-02T00:00:00.000Z',
            public: false,
            fileSizeLimit: 5242880,
            allowedMimeTypes: ['image/png'],
          ),
        );

        final result = await backend.getBucket('avatars');

        expect(result.id, 'avatars');
        expect(result.public, false);
        expect(result.fileSizeLimit, 5242880);
        expect(result.allowedMimeTypes, ['image/png']);
      });

      test('createBucket delegates with options', () async {
        when(
          () => mockWrapper.createBucket(
            'test',
            any(),
          ),
        ).thenAnswer((_) async => 'test');

        final result = await backend.createBucket(
          'test',
          options: const nexus.BucketOptions(
            public: true,
            fileSizeLimit: 1048576,
          ),
        );

        expect(result, 'test');
        final captured = verify(
          () => mockWrapper.createBucket('test', captureAny()),
        ).captured.single as supa.BucketOptions;
        expect(captured.public, true);
      });

      test('createBucket delegates without options', () async {
        when(() => mockWrapper.createBucket('test', any()))
            .thenAnswer((_) async => 'test');

        await backend.createBucket('test');

        verify(() => mockWrapper.createBucket('test', any())).called(1);
      });

      test('updateBucket delegates with mapped options', () async {
        when(() => mockWrapper.updateBucket('test', any()))
            .thenAnswer((_) async => 'test');

        await backend.updateBucket(
          'test',
          const nexus.BucketOptions(public: true),
        );

        final captured = verify(
          () => mockWrapper.updateBucket('test', captureAny()),
        ).captured.single as supa.BucketOptions;
        expect(captured.public, true);
      });

      test('deleteBucket delegates', () async {
        when(() => mockWrapper.deleteBucket('test'))
            .thenAnswer((_) async => 'test');

        await backend.deleteBucket('test');

        verify(() => mockWrapper.deleteBucket('test')).called(1);
      });

      test('emptyBucket delegates', () async {
        when(() => mockWrapper.emptyBucket('test'))
            .thenAnswer((_) async => 'test');

        await backend.emptyBucket('test');

        verify(() => mockWrapper.emptyBucket('test')).called(1);
      });
    });

    group('file operations', () {
      test('upload delegates with binary data', () async {
        final bytes = Uint8List.fromList([1, 2, 3]);
        when(
          () => mockWrapper.uploadBinary(
            'avatars',
            'photo.jpg',
            bytes,
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'avatars/photo.jpg');

        final result = await backend.upload(
          'avatars',
          'photo.jpg',
          bytes,
          options: const nexus.FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

        expect(result, 'avatars/photo.jpg');
        final captured = verify(
          () => mockWrapper.uploadBinary(
            'avatars',
            'photo.jpg',
            bytes,
            fileOptions: captureAny(named: 'fileOptions'),
          ),
        ).captured.single as supa.FileOptions;
        expect(captured.contentType, 'image/jpeg');
        expect(captured.upsert, true);
      });

      test('download delegates and returns bytes', () async {
        final expected = Uint8List.fromList([4, 5, 6]);
        when(
          () => mockWrapper.download(
            'avatars',
            'photo.jpg',
            transform: any(named: 'transform'),
          ),
        ).thenAnswer((_) async => expected);

        final result = await backend.download('avatars', 'photo.jpg');

        expect(result, expected);
      });

      test('download with transform options', () async {
        final expected = Uint8List.fromList([7, 8]);
        when(
          () => mockWrapper.download(
            'avatars',
            'photo.jpg',
            transform: any(named: 'transform'),
          ),
        ).thenAnswer((_) async => expected);

        await backend.download(
          'avatars',
          'photo.jpg',
          transform: const nexus.TransformOptions(
            width: 200,
            height: 200,
            format: nexus.ImageFormat.origin,
            resize: nexus.ResizeMode.cover,
          ),
        );

        final captured = verify(
          () => mockWrapper.download(
            'avatars',
            'photo.jpg',
            transform: captureAny(named: 'transform'),
          ),
        ).captured.single as supa.TransformOptions;
        expect(captured.width, 200);
        expect(captured.height, 200);
      });

      test('update delegates with binary data', () async {
        final bytes = Uint8List.fromList([10, 20]);
        when(
          () => mockWrapper.updateBinary(
            'avatars',
            'photo.jpg',
            bytes,
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'avatars/photo.jpg');

        final result = await backend.update('avatars', 'photo.jpg', bytes);

        expect(result, 'avatars/photo.jpg');
      });

      test('remove delegates with paths', () async {
        when(() => mockWrapper.remove('avatars', ['a.jpg', 'b.jpg']))
            .thenAnswer((_) async => []);

        await backend.remove('avatars', ['a.jpg', 'b.jpg']);

        verify(() => mockWrapper.remove('avatars', ['a.jpg', 'b.jpg']))
            .called(1);
      });

      test('move delegates correctly', () async {
        when(() => mockWrapper.move('avatars', 'old/path', 'new/path'))
            .thenAnswer((_) async => 'new/path');

        final result = await backend.move('avatars', 'old/path', 'new/path');

        expect(result, 'new/path');
      });

      test('copy delegates correctly', () async {
        when(() => mockWrapper.copy('avatars', 'src', 'dst'))
            .thenAnswer((_) async => 'dst');

        final result = await backend.copy('avatars', 'src', 'dst');

        expect(result, 'dst');
      });
    });

    group('URL generation', () {
      test('createSignedUrl delegates', () async {
        when(() => mockWrapper.createSignedUrl('avatars', 'photo.jpg', 3600))
            .thenAnswer((_) async => 'https://signed-url');

        final result =
            await backend.createSignedUrl('avatars', 'photo.jpg', 3600);

        expect(result, 'https://signed-url');
      });

      test('createSignedUrls delegates and maps results', () async {
        when(() => mockWrapper.createSignedUrls('avatars', ['a.jpg'], 3600))
            .thenAnswer(
          (_) async => [
            const supa.SignedUrl(
              path: 'a.jpg',
              signedUrl: 'https://signed-a',
            ),
          ],
        );

        final result =
            await backend.createSignedUrls('avatars', ['a.jpg'], 3600);

        expect(result, hasLength(1));
        expect(result.first.path, 'a.jpg');
        expect(result.first.signedUrl, 'https://signed-a');
      });

      test('getPublicUrl delegates', () {
        when(
          () => mockWrapper.getPublicUrl(
            'avatars',
            'photo.jpg',
            transform: any(named: 'transform'),
          ),
        ).thenReturn('https://public-url');

        final result = backend.getPublicUrl('avatars', 'photo.jpg');

        expect(result, 'https://public-url');
      });

      test('getPublicUrl with transform', () {
        when(
          () => mockWrapper.getPublicUrl(
            'avatars',
            'photo.jpg',
            transform: any(named: 'transform'),
          ),
        ).thenReturn('https://public-url?width=100');

        backend.getPublicUrl(
          'avatars',
          'photo.jpg',
          transform: const nexus.TransformOptions(width: 100),
        );

        verify(
          () => mockWrapper.getPublicUrl(
            'avatars',
            'photo.jpg',
            transform: any(named: 'transform'),
          ),
        ).called(1);
      });
    });

    group('listing', () {
      test('list delegates and maps results', () async {
        when(
          () => mockWrapper.list(
            'avatars',
            path: any(named: 'path'),
            searchOptions: any(named: 'searchOptions'),
          ),
        ).thenAnswer(
          (_) async => [
            const supa.FileObject(
              name: 'photo.jpg',
              bucketId: 'avatars',
              owner: 'owner',
              id: 'file-1',
              updatedAt: '2026-03-01T00:00:00.000Z',
              createdAt: '2026-03-01T00:00:00.000Z',
              lastAccessedAt: '2026-03-01T00:00:00.000Z',
              metadata: {'size': 1024},
              buckets: null,
            ),
          ],
        );

        final result = await backend.list('avatars');

        expect(result, hasLength(1));
        expect(result.first.name, 'photo.jpg');
        expect(result.first.bucketId, 'avatars');
        expect(result.first.id, 'file-1');
      });

      test('list with search options', () async {
        when(
          () => mockWrapper.list(
            'avatars',
            path: any(named: 'path'),
            searchOptions: any(named: 'searchOptions'),
          ),
        ).thenAnswer((_) async => <supa.FileObject>[]);

        await backend.list(
          'avatars',
          path: 'subfolder',
          options: const nexus.SearchOptions(
            limit: 50,
            offset: 10,
            search: 'photo',
          ),
        );

        final captured = verify(
          () => mockWrapper.list(
            'avatars',
            path: 'subfolder',
            searchOptions: captureAny(named: 'searchOptions'),
          ),
        ).captured.single as supa.SearchOptions;
        expect(captured.limit, 50);
        expect(captured.offset, 10);
        expect(captured.search, 'photo');
      });
    });

    group('error handling', () {
      test('wraps StorageException as StoreError', () async {
        when(() => mockWrapper.listBuckets()).thenThrow(
          const supa.StorageException('Not found', statusCode: '404'),
        );

        expect(
          () => backend.listBuckets(),
          throwsA(isA<nexus.StoreError>()),
        );
      });

      test('wraps StorageException with 401 as AuthenticationError', () async {
        when(() => mockWrapper.getBucket('x')).thenThrow(
          const supa.StorageException('Unauthorized', statusCode: '401'),
        );

        expect(
          () => backend.getBucket('x'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('wraps StorageException with 403 as AuthorizationError', () async {
        when(() => mockWrapper.getBucket('x')).thenThrow(
          const supa.StorageException('Forbidden', statusCode: '403'),
        );

        expect(
          () => backend.getBucket('x'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('wraps StorageException with 404 as NotFoundError', () async {
        when(() => mockWrapper.getBucket('x')).thenThrow(
          const supa.StorageException('Not found', statusCode: '404'),
        );

        expect(
          () => backend.getBucket('x'),
          throwsA(isA<nexus.NotFoundError>()),
        );
      });

      test('passes through existing StoreError', () async {
        when(() => mockWrapper.listBuckets()).thenThrow(
          const nexus.NetworkError(message: 'timeout'),
        );

        expect(
          () => backend.listBuckets(),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('wraps generic StorageException as SyncError', () async {
        when(() => mockWrapper.deleteBucket('x')).thenThrow(
          const supa.StorageException('Server error', statusCode: '500'),
        );

        expect(
          () => backend.deleteBucket('x'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps non-StorageException as SyncError', () async {
        when(() => mockWrapper.emptyBucket('x'))
            .thenThrow(Exception('unexpected'));

        expect(
          () => backend.emptyBucket('x'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps upload errors', () async {
        when(
          () => mockWrapper.uploadBinary(
            any(),
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenThrow(
          const supa.StorageException('Upload failed', statusCode: '413'),
        );

        expect(
          () => backend.upload('bucket', 'path', Uint8List(0)),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps download errors', () async {
        when(
          () => mockWrapper.download(
            any(),
            any(),
            transform: any(named: 'transform'),
          ),
        ).thenThrow(
          const supa.StorageException('Not found', statusCode: '404'),
        );

        expect(
          () => backend.download('bucket', 'path'),
          throwsA(isA<nexus.NotFoundError>()),
        );
      });

      test('wraps update errors', () async {
        when(
          () => mockWrapper.updateBinary(
            any(),
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenThrow(
          const supa.StorageException('Forbidden', statusCode: '403'),
        );

        expect(
          () => backend.update('bucket', 'path', Uint8List(0)),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('wraps remove errors', () async {
        when(() => mockWrapper.remove(any(), any())).thenThrow(
          const supa.StorageException('Unauthorized', statusCode: '401'),
        );

        expect(
          () => backend.remove('bucket', ['a']),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('wraps move errors', () async {
        when(() => mockWrapper.move(any(), any(), any())).thenThrow(
          const supa.StorageException('Error'),
        );

        expect(
          () => backend.move('bucket', 'a', 'b'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps copy errors', () async {
        when(() => mockWrapper.copy(any(), any(), any())).thenThrow(
          const supa.StorageException('Error'),
        );

        expect(
          () => backend.copy('bucket', 'a', 'b'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps createSignedUrl errors', () async {
        when(() => mockWrapper.createSignedUrl(any(), any(), any())).thenThrow(
          const supa.StorageException('Error'),
        );

        expect(
          () => backend.createSignedUrl('bucket', 'path', 3600),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps createSignedUrls errors', () async {
        when(() => mockWrapper.createSignedUrls(any(), any(), any())).thenThrow(
          const supa.StorageException('Error'),
        );

        expect(
          () => backend.createSignedUrls('bucket', ['a'], 3600),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('wraps list errors', () async {
        when(
          () => mockWrapper.list(
            any(),
            path: any(named: 'path'),
            searchOptions: any(named: 'searchOptions'),
          ),
        ).thenThrow(
          const supa.StorageException('Error'),
        );

        expect(
          () => backend.list('bucket'),
          throwsA(isA<nexus.SyncError>()),
        );
      });
    });

    group('mapper branches', () {
      test('maps ResizeMode.contain and ResizeMode.fill', () async {
        final bytes = Uint8List.fromList([1]);
        when(
          () => mockWrapper.download(
            any(),
            any(),
            transform: any(named: 'transform'),
          ),
        ).thenAnswer((_) async => bytes);

        // Test contain
        await backend.download(
          'bucket',
          'path',
          transform: const nexus.TransformOptions(
            resize: nexus.ResizeMode.contain,
          ),
        );
        // Test fill
        await backend.download(
          'bucket',
          'path',
          transform: const nexus.TransformOptions(
            resize: nexus.ResizeMode.fill,
          ),
        );

        verify(
          () => mockWrapper.download(
            any(),
            any(),
            transform: any(named: 'transform'),
          ),
        ).called(2);
      });

      test('maps SearchOptions with sortBy', () async {
        when(
          () => mockWrapper.list(
            any(),
            path: any(named: 'path'),
            searchOptions: any(named: 'searchOptions'),
          ),
        ).thenAnswer((_) async => <supa.FileObject>[]);

        await backend.list(
          'bucket',
          options: const nexus.SearchOptions(
            sortBy: nexus.SortBy(
              column: 'created_at',
              order: nexus.SortOrder.desc,
            ),
          ),
        );

        final captured = verify(
          () => mockWrapper.list(
            any(),
            path: any(named: 'path'),
            searchOptions: captureAny(named: 'searchOptions'),
          ),
        ).captured.single as supa.SearchOptions;
        expect(captured.sortBy?.column, 'created_at');
        expect(captured.sortBy?.order, 'desc');
      });

      test('maps update with FileOptions', () async {
        final bytes = Uint8List.fromList([1]);
        when(
          () => mockWrapper.updateBinary(
            any(),
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'path');

        await backend.update(
          'bucket',
          'path',
          bytes,
          options: const nexus.FileOptions(
            contentType: 'text/plain',
            upsert: true,
          ),
        );

        final captured = verify(
          () => mockWrapper.updateBinary(
            any(),
            any(),
            any(),
            fileOptions: captureAny(named: 'fileOptions'),
          ),
        ).captured.single as supa.FileOptions;
        expect(captured.contentType, 'text/plain');
        expect(captured.upsert, true);
      });
    });
  });
}
