import 'dart:typed_data';

import 'package:nexus_store/src/storage/bucket.dart';
import 'package:nexus_store/src/storage/file_options.dart';
import 'package:nexus_store/src/storage/search_options.dart';
import 'package:nexus_store/src/storage/signed_url.dart';
import 'package:nexus_store/src/storage/storage_file.dart';
import 'package:nexus_store/src/storage/transform_options.dart';

/// Backend-agnostic interface for file storage operations.
///
/// Provides bucket management, file CRUD, URL generation, and file listing.
/// Implementations translate these operations to their specific storage
/// provider (e.g., Supabase Storage, S3, GCS).
///
/// ## Example
///
/// ```dart
/// final backend = SupabaseStorageBackend(client: supabaseClient);
///
/// // Upload a file
/// final path = await backend.upload(
///   'avatars',
///   'user-123/photo.jpg',
///   imageBytes,
///   options: FileOptions(contentType: 'image/jpeg'),
/// );
///
/// // Get a public URL with image transform
/// final url = backend.getPublicUrl(
///   'avatars',
///   'user-123/photo.jpg',
///   transform: TransformOptions(width: 200, height: 200),
/// );
/// ```
abstract interface class StorageBackend {
  // -- Bucket management --

  /// Lists all buckets.
  Future<List<Bucket>> listBuckets();

  /// Gets a bucket by its [id].
  Future<Bucket> getBucket(String id);

  /// Creates a new bucket with the given [id].
  ///
  /// Returns the bucket ID on success.
  Future<String> createBucket(String id, {BucketOptions? options});

  /// Updates an existing bucket's [options].
  Future<void> updateBucket(String id, BucketOptions options);

  /// Deletes a bucket by its [id].
  ///
  /// The bucket must be empty before deletion.
  Future<void> deleteBucket(String id);

  /// Removes all files from a bucket without deleting the bucket itself.
  Future<void> emptyBucket(String id);

  // -- File operations --

  /// Uploads [bytes] to [path] within [bucket].
  ///
  /// Returns the full path of the uploaded file.
  Future<String> upload(
    String bucket,
    String path,
    Uint8List bytes, {
    FileOptions? options,
  });

  /// Downloads a file from [path] within [bucket].
  ///
  /// Optionally applies image [transform] on supported file types.
  Future<Uint8List> download(
    String bucket,
    String path, {
    TransformOptions? transform,
  });

  /// Replaces an existing file at [path] within [bucket] with [bytes].
  ///
  /// Returns the full path of the updated file.
  Future<String> update(
    String bucket,
    String path,
    Uint8List bytes, {
    FileOptions? options,
  });

  /// Removes files at the given [paths] within [bucket].
  Future<void> remove(String bucket, List<String> paths);

  /// Moves a file from [from] to [to] within [bucket].
  ///
  /// Returns the new path.
  Future<String> move(String bucket, String from, String to);

  /// Copies a file from [from] to [to] within [bucket].
  ///
  /// Returns the destination path.
  Future<String> copy(String bucket, String from, String to);

  // -- URL generation --

  /// Creates a signed URL for temporary access to a file.
  ///
  /// [expiresIn] is the duration in seconds until the URL expires.
  Future<String> createSignedUrl(String bucket, String path, int expiresIn);

  /// Creates signed URLs for multiple files in batch.
  ///
  /// [expiresIn] is the duration in seconds until each URL expires.
  Future<List<SignedUrl>> createSignedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  );

  /// Returns a public URL for a file in a public bucket.
  ///
  /// Optionally applies image [transform] on supported file types.
  String getPublicUrl(
    String bucket,
    String path, {
    TransformOptions? transform,
  });

  // -- Listing --

  /// Lists files in [bucket], optionally within a [path] prefix.
  Future<List<StorageFile>> list(
    String bucket, {
    String? path,
    SearchOptions? options,
  });
}
