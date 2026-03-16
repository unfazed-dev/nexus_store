import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:storage_client/storage_client.dart';
import 'package:test/test.dart';

class MockStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  late MockStorageClient mockClient;
  late MockStorageFileApi mockFileApi;
  late DefaultSupabaseStorageWrapper wrapper;

  setUpAll(() {
    registerFallbackValue(const FileOptions());
    registerFallbackValue(const TransformOptions());
    registerFallbackValue(const SearchOptions());
    registerFallbackValue(const BucketOptions(public: false));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockClient = MockStorageClient();
    mockFileApi = MockStorageFileApi();
    wrapper = DefaultSupabaseStorageWrapper(mockClient);
    when(() => mockClient.from(any())).thenReturn(mockFileApi);
  });

  group('DefaultSupabaseStorageWrapper', () {
    group('bucket management', () {
      test('listBuckets delegates', () async {
        when(() => mockClient.listBuckets()).thenAnswer((_) async => []);
        await wrapper.listBuckets();
        verify(() => mockClient.listBuckets()).called(1);
      });

      test('getBucket delegates', () async {
        when(() => mockClient.getBucket('test')).thenAnswer(
          (_) async => const Bucket(
            id: 'test',
            name: 'test',
            owner: '',
            createdAt: '',
            updatedAt: '',
            public: false,
          ),
        );
        await wrapper.getBucket('test');
        verify(() => mockClient.getBucket('test')).called(1);
      });

      test('createBucket delegates', () async {
        when(() => mockClient.createBucket('test', any()))
            .thenAnswer((_) async => 'test');
        await wrapper.createBucket(
          'test',
          const BucketOptions(public: true),
        );
        verify(() => mockClient.createBucket('test', any())).called(1);
      });

      test('updateBucket delegates', () async {
        when(() => mockClient.updateBucket('test', any()))
            .thenAnswer((_) async => 'test');
        await wrapper.updateBucket(
          'test',
          const BucketOptions(public: true),
        );
        verify(() => mockClient.updateBucket('test', any())).called(1);
      });

      test('deleteBucket delegates', () async {
        when(() => mockClient.deleteBucket('test'))
            .thenAnswer((_) async => 'test');
        await wrapper.deleteBucket('test');
        verify(() => mockClient.deleteBucket('test')).called(1);
      });

      test('emptyBucket delegates', () async {
        when(() => mockClient.emptyBucket('test'))
            .thenAnswer((_) async => 'test');
        await wrapper.emptyBucket('test');
        verify(() => mockClient.emptyBucket('test')).called(1);
      });
    });

    group('file operations', () {
      test('uploadBinary delegates to from().uploadBinary', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        when(
          () => mockFileApi.uploadBinary(
            'path',
            data,
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'bucket/path');

        await wrapper.uploadBinary('bucket', 'path', data);

        verify(() => mockClient.from('bucket')).called(1);
        verify(
          () => mockFileApi.uploadBinary(
            'path',
            data,
            fileOptions: any(named: 'fileOptions'),
          ),
        ).called(1);
      });

      test('download delegates to from().download', () async {
        when(
          () => mockFileApi.download(
            'path',
            transform: any(named: 'transform'),
          ),
        ).thenAnswer((_) async => Uint8List(0));

        await wrapper.download('bucket', 'path');

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('updateBinary delegates to from().updateBinary', () async {
        final data = Uint8List.fromList([4, 5]);
        when(
          () => mockFileApi.updateBinary(
            'path',
            data,
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'bucket/path');

        await wrapper.updateBinary('bucket', 'path', data);

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('remove delegates to from().remove', () async {
        when(() => mockFileApi.remove(['a.jpg'])).thenAnswer((_) async => []);

        await wrapper.remove('bucket', ['a.jpg']);

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('move delegates to from().move', () async {
        when(() => mockFileApi.move('a', 'b')).thenAnswer((_) async => 'b');

        await wrapper.move('bucket', 'a', 'b');

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('copy delegates to from().copy', () async {
        when(() => mockFileApi.copy('a', 'b')).thenAnswer((_) async => 'b');

        await wrapper.copy('bucket', 'a', 'b');

        verify(() => mockClient.from('bucket')).called(1);
      });
    });

    group('URL generation', () {
      test('createSignedUrl delegates', () async {
        when(() => mockFileApi.createSignedUrl('path', 3600))
            .thenAnswer((_) async => 'https://signed');

        await wrapper.createSignedUrl('bucket', 'path', 3600);

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('createSignedUrls delegates', () async {
        when(() => mockFileApi.createSignedUrls(['a'], 3600))
            .thenAnswer((_) async => []);

        await wrapper.createSignedUrls('bucket', ['a'], 3600);

        verify(() => mockClient.from('bucket')).called(1);
      });

      test('getPublicUrl delegates', () {
        when(
          () => mockFileApi.getPublicUrl(
            'path',
            transform: any(named: 'transform'),
          ),
        ).thenReturn('https://public');

        wrapper.getPublicUrl('bucket', 'path');

        verify(() => mockClient.from('bucket')).called(1);
      });
    });

    group('listing', () {
      test('list delegates to from().list', () async {
        when(
          () => mockFileApi.list(
            path: any(named: 'path'),
            searchOptions: any(named: 'searchOptions'),
          ),
        ).thenAnswer((_) async => []);

        await wrapper.list('bucket', path: 'folder');

        verify(() => mockClient.from('bucket')).called(1);
      });
    });
  });
}
