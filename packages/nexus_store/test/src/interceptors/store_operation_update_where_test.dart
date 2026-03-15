import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('StoreOperation.updateWhere', () {
    test('updateWhere is a valid StoreOperation', () {
      expect(StoreOperation.updateWhere, isNotNull);
    });

    test('updateWhere is classified as a write operation', () {
      expect(StoreOperation.updateWhere.isWrite, isTrue);
    });

    test('updateWhere modifies data', () {
      expect(StoreOperation.updateWhere.modifiesData, isTrue);
    });

    test('updateWhere is not a read operation', () {
      expect(StoreOperation.updateWhere.isRead, isFalse);
    });

    test('updateWhere is not a delete operation', () {
      expect(StoreOperation.updateWhere.isDelete, isFalse);
    });

    test('updateWhere is not a stream operation', () {
      expect(StoreOperation.updateWhere.isStream, isFalse);
    });

    test('updateWhere is not a sync operation', () {
      expect(StoreOperation.updateWhere.isSync, isFalse);
    });
  });
}
