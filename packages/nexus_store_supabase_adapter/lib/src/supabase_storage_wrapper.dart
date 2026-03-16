import 'dart:typed_data';

import 'package:storage_client/storage_client.dart';

/// Testable wrapper around Supabase storage operations.
///
/// Abstracts [SupabaseStorageClient] and [StorageFileApi] into a single
/// interface that can be mocked in tests.
abstract class SupabaseStorageWrapper {
  // -- Bucket management --

  /// Lists all buckets.
  Future<List<Bucket>> listBuckets();

  /// Gets a bucket by its [id].
  Future<Bucket> getBucket(String id);

  /// Creates a new bucket.
  Future<String> createBucket(String id, BucketOptions options);

  /// Updates an existing bucket.
  Future<String> updateBucket(String id, BucketOptions options);

  /// Deletes a bucket.
  Future<String> deleteBucket(String id);

  /// Empties a bucket.
  Future<String> emptyBucket(String id);

  // -- File operations --

  /// Uploads binary data to a bucket.
  Future<String> uploadBinary(
    String bucket,
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  });

  /// Downloads a file from a bucket.
  Future<Uint8List> download(
    String bucket,
    String path, {
    TransformOptions? transform,
  });

  /// Updates an existing file with binary data.
  Future<String> updateBinary(
    String bucket,
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  });

  /// Removes files from a bucket.
  Future<List<FileObject>> remove(String bucket, List<String> paths);

  /// Moves a file within a bucket.
  Future<String> move(String bucket, String from, String to);

  /// Copies a file within a bucket.
  Future<String> copy(String bucket, String from, String to);

  // -- URL generation --

  /// Creates a signed URL for temporary access.
  Future<String> createSignedUrl(String bucket, String path, int expiresIn);

  /// Creates signed URLs for multiple files.
  Future<List<SignedUrl>> createSignedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  );

  /// Returns a public URL for a file.
  String getPublicUrl(
    String bucket,
    String path, {
    TransformOptions? transform,
  });

  // -- Listing --

  /// Lists files in a bucket.
  Future<List<FileObject>> list(
    String bucket, {
    String? path,
    SearchOptions? searchOptions,
  });
}

/// Default implementation that delegates to a real [SupabaseStorageClient].
class DefaultSupabaseStorageWrapper implements SupabaseStorageWrapper {
  /// Creates a wrapper around the given [storage] client.
  const DefaultSupabaseStorageWrapper(this._storage);

  final SupabaseStorageClient _storage;

  @override
  Future<List<Bucket>> listBuckets() => _storage.listBuckets();

  @override
  Future<Bucket> getBucket(String id) => _storage.getBucket(id);

  @override
  Future<String> createBucket(String id, BucketOptions options) =>
      _storage.createBucket(id, options);

  @override
  Future<String> updateBucket(String id, BucketOptions options) =>
      _storage.updateBucket(id, options);

  @override
  Future<String> deleteBucket(String id) => _storage.deleteBucket(id);

  @override
  Future<String> emptyBucket(String id) => _storage.emptyBucket(id);

  @override
  Future<String> uploadBinary(
    String bucket,
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  }) =>
      _storage.from(bucket).uploadBinary(
            path,
            data,
            fileOptions: fileOptions ?? const FileOptions(),
          );

  @override
  Future<Uint8List> download(
    String bucket,
    String path, {
    TransformOptions? transform,
  }) =>
      _storage.from(bucket).download(path, transform: transform);

  @override
  Future<String> updateBinary(
    String bucket,
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  }) =>
      _storage.from(bucket).updateBinary(
            path,
            data,
            fileOptions: fileOptions ?? const FileOptions(),
          );

  @override
  Future<List<FileObject>> remove(String bucket, List<String> paths) =>
      _storage.from(bucket).remove(paths);

  @override
  Future<String> move(String bucket, String from, String to) =>
      _storage.from(bucket).move(from, to);

  @override
  Future<String> copy(String bucket, String from, String to) =>
      _storage.from(bucket).copy(from, to);

  @override
  Future<String> createSignedUrl(String bucket, String path, int expiresIn) =>
      _storage.from(bucket).createSignedUrl(path, expiresIn);

  @override
  Future<List<SignedUrl>> createSignedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  ) =>
      _storage.from(bucket).createSignedUrls(paths, expiresIn);

  @override
  String getPublicUrl(
    String bucket,
    String path, {
    TransformOptions? transform,
  }) =>
      _storage.from(bucket).getPublicUrl(path, transform: transform);

  @override
  Future<List<FileObject>> list(
    String bucket, {
    String? path,
    SearchOptions? searchOptions,
  }) =>
      _storage.from(bucket).list(
            path: path,
            searchOptions: searchOptions ?? const SearchOptions(),
          );
}
