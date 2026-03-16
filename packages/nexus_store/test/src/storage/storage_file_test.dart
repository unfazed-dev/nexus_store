import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('StorageFile', () {
    test('constructs with required fields', () {
      final file = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
      );

      expect(file.name, 'photo.jpg');
      expect(file.bucketId, 'avatars');
      expect(file.id, isNull);
      expect(file.createdAt, isNull);
      expect(file.updatedAt, isNull);
      expect(file.lastAccessedAt, isNull);
      expect(file.metadata, isEmpty);
      expect(file.size, isNull);
      expect(file.mimeType, isNull);
    });

    test('constructs with all fields', () {
      final file = StorageFile(
        name: 'document.pdf',
        bucketId: 'documents',
        id: 'file-123',
        createdAt: DateTime.utc(2026, 3, 1),
        updatedAt: DateTime.utc(2026, 3, 2),
        lastAccessedAt: DateTime.utc(2026, 3, 3),
        metadata: {'author': 'test'},
        size: 1048576,
        mimeType: 'application/pdf',
      );

      expect(file.id, 'file-123');
      expect(file.size, 1048576);
      expect(file.mimeType, 'application/pdf');
      expect(file.metadata, {'author': 'test'});
      expect(file.lastAccessedAt, DateTime.utc(2026, 3, 3));
    });

    test('equality compares all fields', () {
      final a = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
        id: 'file-1',
        size: 1024,
      );
      final b = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
        id: 'file-1',
        size: 1024,
      );
      final c = StorageFile(
        name: 'other.jpg',
        bucketId: 'avatars',
        id: 'file-2',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith preserves all unspecified fields', () {
      final original = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
        id: 'file-1',
        size: 1024,
        mimeType: 'image/jpeg',
      );
      final copied = original.copyWith(bucketId: 'docs');

      expect(copied.name, 'photo.jpg');
      expect(copied.bucketId, 'docs');
      expect(copied.id, 'file-1');
      expect(copied.size, 1024);
      expect(copied.mimeType, 'image/jpeg');
    });

    test('copyWith replaces specified fields', () {
      final original = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
        size: 1024,
      );
      final copied = original.copyWith(name: 'renamed.jpg', size: 2048);

      expect(copied.name, 'renamed.jpg');
      expect(copied.bucketId, 'avatars');
      expect(copied.size, 2048);
    });

    test('toString includes key fields', () {
      final file = StorageFile(
        name: 'photo.jpg',
        bucketId: 'avatars',
      );

      final str = file.toString();
      expect(str, contains('StorageFile'));
      expect(str, contains('photo.jpg'));
      expect(str, contains('avatars'));
    });
  });
}
