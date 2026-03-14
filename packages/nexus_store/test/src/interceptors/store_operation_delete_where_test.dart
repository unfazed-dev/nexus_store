import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

void main() {
  group('StoreOperation.deleteWhere', () {
    test('deleteWhere enum value exists', () {
      expect(StoreOperation.deleteWhere, isNotNull);
      expect(
        StoreOperation.values,
        contains(StoreOperation.deleteWhere),
      );
    });

    test('isDelete includes deleteWhere', () {
      expect(StoreOperation.deleteWhere.isDelete, isTrue);
    });

    test('isRead is false for deleteWhere', () {
      expect(StoreOperation.deleteWhere.isRead, isFalse);
    });

    test('isWrite is false for deleteWhere', () {
      expect(StoreOperation.deleteWhere.isWrite, isFalse);
    });

    test('isStream is false for deleteWhere', () {
      expect(StoreOperation.deleteWhere.isStream, isFalse);
    });

    test('isSync is false for deleteWhere', () {
      expect(StoreOperation.deleteWhere.isSync, isFalse);
    });

    test('modifiesData is true for deleteWhere', () {
      expect(StoreOperation.deleteWhere.modifiesData, isTrue);
    });
  });
}
