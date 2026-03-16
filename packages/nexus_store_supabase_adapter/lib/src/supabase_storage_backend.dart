import 'dart:typed_data';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/src/supabase_storage_wrapper.dart';
import 'package:storage_client/storage_client.dart' as supa;
import 'package:supabase/supabase.dart';

/// Supabase implementation of [nexus.StorageBackend].
///
/// Delegates all storage operations to Supabase Storage via
/// [SupabaseStorageWrapper] for testability.
///
/// ## Example
///
/// ```dart
/// final backend = SupabaseStorageBackend(client: supabaseClient);
///
/// // Upload a file
/// await backend.upload('avatars', 'photo.jpg', imageBytes);
///
/// // Get public URL with transform
/// final url = backend.getPublicUrl(
///   'avatars', 'photo.jpg',
///   transform: TransformOptions(width: 200),
/// );
/// ```
class SupabaseStorageBackend implements nexus.StorageBackend {
  /// Creates a storage backend using the given Supabase [client].
  SupabaseStorageBackend({required SupabaseClient client})
      : _wrapper = DefaultSupabaseStorageWrapper(client.storage);

  /// Creates a storage backend with a custom [wrapper] for testing.
  SupabaseStorageBackend.withWrapper(this._wrapper);

  final SupabaseStorageWrapper _wrapper;

  // -- Bucket management --

  @override
  Future<List<nexus.Bucket>> listBuckets() async {
    try {
      final buckets = await _wrapper.listBuckets();
      return buckets.map(_mapBucket).toList();
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<nexus.Bucket> getBucket(String id) async {
    try {
      final bucket = await _wrapper.getBucket(id);
      return _mapBucket(bucket);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<String> createBucket(String id, {nexus.BucketOptions? options}) async {
    try {
      return await _wrapper.createBucket(id, _mapBucketOptions(options));
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<void> updateBucket(String id, nexus.BucketOptions options) async {
    try {
      await _wrapper.updateBucket(id, _mapBucketOptions(options));
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<void> deleteBucket(String id) async {
    try {
      await _wrapper.deleteBucket(id);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<void> emptyBucket(String id) async {
    try {
      await _wrapper.emptyBucket(id);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  // -- File operations --

  @override
  Future<String> upload(
    String bucket,
    String path,
    Uint8List bytes, {
    nexus.FileOptions? options,
  }) async {
    try {
      return await _wrapper.uploadBinary(
        bucket,
        path,
        bytes,
        fileOptions: options != null ? _mapFileOptions(options) : null,
      );
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<Uint8List> download(
    String bucket,
    String path, {
    nexus.TransformOptions? transform,
  }) async {
    try {
      return await _wrapper.download(
        bucket,
        path,
        transform: transform != null ? _mapTransformOptions(transform) : null,
      );
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<String> update(
    String bucket,
    String path,
    Uint8List bytes, {
    nexus.FileOptions? options,
  }) async {
    try {
      return await _wrapper.updateBinary(
        bucket,
        path,
        bytes,
        fileOptions: options != null ? _mapFileOptions(options) : null,
      );
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<void> remove(String bucket, List<String> paths) async {
    try {
      await _wrapper.remove(bucket, paths);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<String> move(String bucket, String from, String to) async {
    try {
      return await _wrapper.move(bucket, from, to);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<String> copy(String bucket, String from, String to) async {
    try {
      return await _wrapper.copy(bucket, from, to);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  // -- URL generation --

  @override
  Future<String> createSignedUrl(
    String bucket,
    String path,
    int expiresIn,
  ) async {
    try {
      return await _wrapper.createSignedUrl(bucket, path, expiresIn);
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  Future<List<nexus.SignedUrl>> createSignedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  ) async {
    try {
      final urls = await _wrapper.createSignedUrls(bucket, paths, expiresIn);
      return urls
          .map((u) => nexus.SignedUrl(path: u.path, signedUrl: u.signedUrl))
          .toList();
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  @override
  String getPublicUrl(
    String bucket,
    String path, {
    nexus.TransformOptions? transform,
  }) =>
      _wrapper.getPublicUrl(
        bucket,
        path,
        transform: transform != null ? _mapTransformOptions(transform) : null,
      );

  // -- Listing --

  @override
  Future<List<nexus.StorageFile>> list(
    String bucket, {
    String? path,
    nexus.SearchOptions? options,
  }) async {
    try {
      final files = await _wrapper.list(
        bucket,
        path: path,
        searchOptions: options != null ? _mapSearchOptions(options) : null,
      );
      return files.map((f) => _mapFileObject(f, bucket)).toList();
    } on Object catch (e, stackTrace) {
      throw _mapException(e, stackTrace);
    }
  }

  // -- Mappers --

  static nexus.Bucket _mapBucket(supa.Bucket b) => nexus.Bucket(
        id: b.id,
        name: b.name,
        public: b.public,
        createdAt: DateTime.parse(b.createdAt),
        updatedAt: DateTime.parse(b.updatedAt),
        fileSizeLimit: b.fileSizeLimit,
        allowedMimeTypes: b.allowedMimeTypes ?? const [],
      );

  static supa.BucketOptions _mapBucketOptions(nexus.BucketOptions? options) {
    if (options == null) {
      return const supa.BucketOptions(public: false);
    }
    return supa.BucketOptions(
      public: options.public,
      fileSizeLimit: options.fileSizeLimit?.toString(),
      allowedMimeTypes:
          options.allowedMimeTypes.isEmpty ? null : options.allowedMimeTypes,
    );
  }

  static supa.FileOptions _mapFileOptions(nexus.FileOptions options) =>
      supa.FileOptions(
        contentType: options.contentType,
        cacheControl: options.cacheControl,
        upsert: options.upsert,
      );

  static supa.TransformOptions _mapTransformOptions(
    nexus.TransformOptions options,
  ) =>
      supa.TransformOptions(
        width: options.width,
        height: options.height,
        quality: options.quality,
        format:
            options.format != null ? _mapImageFormat(options.format!) : null,
        resize: options.resize != null ? _mapResizeMode(options.resize!) : null,
      );

  static supa.RequestImageFormat _mapImageFormat(
    nexus.ImageFormat format,
  ) =>
      switch (format) {
        nexus.ImageFormat.origin => supa.RequestImageFormat.origin,
        nexus.ImageFormat.avif ||
        nexus.ImageFormat.webp =>
          throw UnsupportedError(
            'ImageFormat.$format is not supported by '
            'storage_client ${supa.RequestImageFormat.values}',
          ),
      };

  static supa.ResizeMode _mapResizeMode(nexus.ResizeMode mode) =>
      switch (mode) {
        nexus.ResizeMode.cover => supa.ResizeMode.cover,
        nexus.ResizeMode.contain => supa.ResizeMode.contain,
        nexus.ResizeMode.fill => supa.ResizeMode.fill,
      };

  static supa.SearchOptions _mapSearchOptions(nexus.SearchOptions options) =>
      supa.SearchOptions(
        limit: options.limit,
        offset: options.offset,
        sortBy: options.sortBy != null
            ? supa.SortBy(
                column: options.sortBy!.column,
                order: options.sortBy!.order == nexus.SortOrder.asc
                    ? 'asc'
                    : 'desc',
              )
            : null,
        search: options.search,
      );

  static nexus.StorageFile _mapFileObject(supa.FileObject f, String bucket) =>
      nexus.StorageFile(
        name: f.name,
        bucketId: f.bucketId ?? bucket,
        id: f.id,
        createdAt: f.createdAt != null ? DateTime.tryParse(f.createdAt!) : null,
        updatedAt: f.updatedAt != null ? DateTime.tryParse(f.updatedAt!) : null,
        lastAccessedAt: f.lastAccessedAt != null
            ? DateTime.tryParse(f.lastAccessedAt!)
            : null,
        metadata: f.metadata ?? const {},
      );

  static nexus.StoreError _mapException(Object e, StackTrace stackTrace) {
    if (e is nexus.StoreError) return e;

    if (e is supa.StorageException) {
      final statusCode = int.tryParse(e.statusCode ?? '');

      if (statusCode == 401) {
        return nexus.AuthenticationError(
          message: e.message,
          cause: e,
          stackTrace: stackTrace,
        );
      }
      if (statusCode == 403) {
        return nexus.AuthorizationError(
          message: e.message,
          cause: e,
          stackTrace: stackTrace,
        );
      }
      if (statusCode == 404) {
        return nexus.NotFoundError(
          id: '',
          entityType: 'StorageFile',
          cause: e,
          stackTrace: stackTrace,
        );
      }

      return nexus.SyncError(
        message: e.message,
        cause: e,
        stackTrace: stackTrace,
      );
    }

    return nexus.SyncError(
      message: e.toString(),
      cause: e,
      stackTrace: stackTrace,
    );
  }
}
