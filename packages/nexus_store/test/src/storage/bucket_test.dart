import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Bucket', () {
    test('constructs with required fields', () {
      final bucket = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      expect(bucket.id, 'avatars');
      expect(bucket.name, 'avatars');
      expect(bucket.public, true);
      expect(bucket.createdAt, DateTime.utc(2026, 1, 1));
      expect(bucket.updatedAt, DateTime.utc(2026, 1, 2));
      expect(bucket.fileSizeLimit, isNull);
      expect(bucket.allowedMimeTypes, isEmpty);
    });

    test('constructs with all fields', () {
      final bucket = Bucket(
        id: 'documents',
        name: 'documents',
        public: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        fileSizeLimit: 10485760,
        allowedMimeTypes: ['application/pdf', 'image/png'],
      );

      expect(bucket.fileSizeLimit, 10485760);
      expect(bucket.allowedMimeTypes, ['application/pdf', 'image/png']);
    });

    test('equality compares all fields', () {
      final a = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      final b = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      final c = Bucket(
        id: 'other',
        name: 'other',
        public: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality detected on later fields', () {
      final a = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      // Same id/name but different public
      final diffPublic = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      expect(a, isNot(equals(diffPublic)));
    });

    test('copyWith preserves unspecified fields', () {
      final original = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        fileSizeLimit: 1024,
        allowedMimeTypes: ['image/png'],
      );
      final copied = original.copyWith(id: 'new-id');

      expect(copied.name, 'avatars');
      expect(copied.public, true);
      expect(copied.fileSizeLimit, 1024);
    });

    test('identical returns true for same instance', () {
      final bucket = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      expect(bucket == bucket, isTrue);
    });

    test('copyWith replaces specified fields', () {
      final original = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      final copied = original.copyWith(public: false, name: 'new-name');

      expect(copied.id, 'avatars');
      expect(copied.name, 'new-name');
      expect(copied.public, false);
      expect(copied.createdAt, DateTime.utc(2026, 1, 1));
    });

    test('toString includes all fields', () {
      final bucket = Bucket(
        id: 'avatars',
        name: 'avatars',
        public: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final str = bucket.toString();
      expect(str, contains('Bucket'));
      expect(str, contains('avatars'));
      expect(str, contains('true'));
    });
  });

  group('BucketOptions', () {
    test('constructs with defaults', () {
      const options = BucketOptions();

      expect(options.public, false);
      expect(options.fileSizeLimit, isNull);
      expect(options.allowedMimeTypes, isEmpty);
    });

    test('constructs with all fields', () {
      const options = BucketOptions(
        public: true,
        fileSizeLimit: 5242880,
        allowedMimeTypes: ['image/jpeg'],
      );

      expect(options.public, true);
      expect(options.fileSizeLimit, 5242880);
      expect(options.allowedMimeTypes, ['image/jpeg']);
    });

    test('equality compares all fields', () {
      const a = BucketOptions(public: true, fileSizeLimit: 1024);
      const b = BucketOptions(public: true, fileSizeLimit: 1024);
      const c = BucketOptions(public: false, fileSizeLimit: 1024);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on later fields', () {
      const a = BucketOptions(
        public: true,
        fileSizeLimit: 1024,
        allowedMimeTypes: ['image/png'],
      );
      // Same public but different fileSizeLimit
      const diffLimit = BucketOptions(
        public: true,
        fileSizeLimit: 2048,
        allowedMimeTypes: ['image/png'],
      );
      // Same public + limit but different mimeTypes
      const diffMime = BucketOptions(
        public: true,
        fileSizeLimit: 1024,
        allowedMimeTypes: ['image/jpeg'],
      );
      expect(a, isNot(equals(diffLimit)));
      expect(a, isNot(equals(diffMime)));
    });

    test('toString includes all fields', () {
      const options = BucketOptions(public: true, fileSizeLimit: 1024);
      final str = options.toString();
      expect(str, contains('BucketOptions'));
      expect(str, contains('true'));
    });
  });
}
