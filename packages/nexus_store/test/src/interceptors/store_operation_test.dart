import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:test/test.dart';

void main() {
  group('StoreOperation', () {
    test('should have all expected operations', () {
      expect(StoreOperation.values, hasLength(9));
      expect(StoreOperation.values, contains(StoreOperation.get));
      expect(StoreOperation.values, contains(StoreOperation.getAll));
      expect(StoreOperation.values, contains(StoreOperation.save));
      expect(StoreOperation.values, contains(StoreOperation.saveAll));
      expect(StoreOperation.values, contains(StoreOperation.delete));
      expect(StoreOperation.values, contains(StoreOperation.deleteAll));
      expect(StoreOperation.values, contains(StoreOperation.watch));
      expect(StoreOperation.values, contains(StoreOperation.watchAll));
      expect(StoreOperation.values, contains(StoreOperation.sync));
    });

    test('should be iterable', () {
      final operations = <StoreOperation>[];
      for (final op in StoreOperation.values) {
        operations.add(op);
      }
      expect(operations, hasLength(9));
    });

    group('name property', () {
      test('get should have name "get"', () {
        expect(StoreOperation.get.name, equals('get'));
      });

      test('getAll should have name "getAll"', () {
        expect(StoreOperation.getAll.name, equals('getAll'));
      });

      test('save should have name "save"', () {
        expect(StoreOperation.save.name, equals('save'));
      });

      test('saveAll should have name "saveAll"', () {
        expect(StoreOperation.saveAll.name, equals('saveAll'));
      });

      test('delete should have name "delete"', () {
        expect(StoreOperation.delete.name, equals('delete'));
      });

      test('deleteAll should have name "deleteAll"', () {
        expect(StoreOperation.deleteAll.name, equals('deleteAll'));
      });

      test('watch should have name "watch"', () {
        expect(StoreOperation.watch.name, equals('watch'));
      });

      test('watchAll should have name "watchAll"', () {
        expect(StoreOperation.watchAll.name, equals('watchAll'));
      });

      test('sync should have name "sync"', () {
        expect(StoreOperation.sync.name, equals('sync'));
      });
    });

    group('categorization', () {
      test('read operations should include get, getAll, watch, watchAll', () {
        final readOps = {
          StoreOperation.get,
          StoreOperation.getAll,
          StoreOperation.watch,
          StoreOperation.watchAll,
        };
        expect(readOps, hasLength(4));
      });

      test('write operations should include save, saveAll, delete, deleteAll',
          () {
        final writeOps = {
          StoreOperation.save,
          StoreOperation.saveAll,
          StoreOperation.delete,
          StoreOperation.deleteAll,
        };
        expect(writeOps, hasLength(4));
      });

      test('sync operation should be singular', () {
        final syncOps = {StoreOperation.sync};
        expect(syncOps, hasLength(1));
      });
    });

    test('should be usable in switch expressions', () {
      String categorize(StoreOperation op) {
        return switch (op) {
          StoreOperation.get || StoreOperation.getAll => 'read',
          StoreOperation.watch || StoreOperation.watchAll => 'stream',
          StoreOperation.save || StoreOperation.saveAll => 'write',
          StoreOperation.delete || StoreOperation.deleteAll => 'delete',
          StoreOperation.sync => 'sync',
        };
      }

      expect(categorize(StoreOperation.get), equals('read'));
      expect(categorize(StoreOperation.save), equals('write'));
      expect(categorize(StoreOperation.watch), equals('stream'));
      expect(categorize(StoreOperation.delete), equals('delete'));
      expect(categorize(StoreOperation.sync), equals('sync'));
    });

    test('should be usable in Set', () {
      final ops = <StoreOperation>{
        StoreOperation.get,
        StoreOperation.save,
      };
      // Adding duplicate should not increase size (set semantics)
      final opsWithDuplicate = {...ops, StoreOperation.get};
      expect(opsWithDuplicate, hasLength(2));
      expect(ops, contains(StoreOperation.get));
      expect(ops, contains(StoreOperation.save));
    });
  });

  group('StoreOperationExtension', () {
    group('isRead', () {
      test('returns true for get operation', () {
        expect(StoreOperation.get.isRead, isTrue);
      });

      test('returns true for getAll operation', () {
        expect(StoreOperation.getAll.isRead, isTrue);
      });

      test('returns false for save operation', () {
        expect(StoreOperation.save.isRead, isFalse);
      });

      test('returns false for watch operation', () {
        expect(StoreOperation.watch.isRead, isFalse);
      });

      test('returns false for sync operation', () {
        expect(StoreOperation.sync.isRead, isFalse);
      });
    });

    group('isStream', () {
      test('returns true for watch operation', () {
        expect(StoreOperation.watch.isStream, isTrue);
      });

      test('returns true for watchAll operation', () {
        expect(StoreOperation.watchAll.isStream, isTrue);
      });

      test('returns false for get operation', () {
        expect(StoreOperation.get.isStream, isFalse);
      });

      test('returns false for save operation', () {
        expect(StoreOperation.save.isStream, isFalse);
      });
    });

    group('isWrite', () {
      test('returns true for save operation', () {
        expect(StoreOperation.save.isWrite, isTrue);
      });

      test('returns true for saveAll operation', () {
        expect(StoreOperation.saveAll.isWrite, isTrue);
      });

      test('returns false for get operation', () {
        expect(StoreOperation.get.isWrite, isFalse);
      });

      test('returns false for delete operation', () {
        expect(StoreOperation.delete.isWrite, isFalse);
      });
    });

    group('isDelete', () {
      test('returns true for delete operation', () {
        expect(StoreOperation.delete.isDelete, isTrue);
      });

      test('returns true for deleteAll operation', () {
        expect(StoreOperation.deleteAll.isDelete, isTrue);
      });

      test('returns false for save operation', () {
        expect(StoreOperation.save.isDelete, isFalse);
      });

      test('returns false for get operation', () {
        expect(StoreOperation.get.isDelete, isFalse);
      });
    });

    group('isSync', () {
      test('returns true for sync operation', () {
        expect(StoreOperation.sync.isSync, isTrue);
      });

      test('returns false for other operations', () {
        expect(StoreOperation.get.isSync, isFalse);
        expect(StoreOperation.save.isSync, isFalse);
        expect(StoreOperation.delete.isSync, isFalse);
        expect(StoreOperation.watch.isSync, isFalse);
      });
    });

    group('modifiesData', () {
      test('returns true for save operations', () {
        expect(StoreOperation.save.modifiesData, isTrue);
        expect(StoreOperation.saveAll.modifiesData, isTrue);
      });

      test('returns true for delete operations', () {
        expect(StoreOperation.delete.modifiesData, isTrue);
        expect(StoreOperation.deleteAll.modifiesData, isTrue);
      });

      test('returns true for sync operation', () {
        expect(StoreOperation.sync.modifiesData, isTrue);
      });

      test('returns false for read operations', () {
        expect(StoreOperation.get.modifiesData, isFalse);
        expect(StoreOperation.getAll.modifiesData, isFalse);
      });

      test('returns false for stream operations', () {
        expect(StoreOperation.watch.modifiesData, isFalse);
        expect(StoreOperation.watchAll.modifiesData, isFalse);
      });
    });
  });
}
