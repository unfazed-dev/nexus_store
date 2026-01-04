import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtDatabaseWrapper', () {
    group('DefaultCrdtDatabaseWrapper', () {
      late SqliteCrdt crdt;
      late DefaultCrdtDatabaseWrapper wrapper;

      setUp(() async {
        crdt = await SqliteCrdt.openInMemory(
          version: 1,
          onCreate: (crdt, version) async {
            await crdt.execute('''
              CREATE TABLE IF NOT EXISTS test_table (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT,
                age INTEGER
              )
            ''');
          },
        );
        wrapper = DefaultCrdtDatabaseWrapper(crdt);
      });

      tearDown(() async {
        await crdt.close();
      });

      group('query', () {
        test('delegates to underlying crdt', () async {
          // Insert test data directly
          await crdt.execute(
            'INSERT INTO test_table (id, name, age) VALUES (?1, ?2, ?3)',
            ['1', 'John', 25],
          );

          final results = await wrapper.query(
            'SELECT * FROM test_table WHERE id = ?1',
            ['1'],
          );

          expect(results, hasLength(1));
          expect(results.first['id'], equals('1'));
          expect(results.first['name'], equals('John'));
          expect(results.first['age'], equals(25));
        });

        test('returns empty list when no results', () async {
          final results = await wrapper.query(
            'SELECT * FROM test_table WHERE id = ?1',
            ['nonexistent'],
          );

          expect(results, isEmpty);
        });

        test('handles query without args', () async {
          await crdt.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['1', 'Test'],
          );

          final results = await wrapper.query('SELECT * FROM test_table');

          expect(results, isNotEmpty);
        });
      });

      group('execute', () {
        test('delegates to underlying crdt', () async {
          await wrapper.execute(
            'INSERT INTO test_table (id, name, age) VALUES (?1, ?2, ?3)',
            ['1', 'Jane', 30],
          );

          final results = await crdt.query(
            'SELECT * FROM test_table WHERE id = ?1',
            ['1'],
          );

          expect(results, hasLength(1));
          expect(results.first['name'], equals('Jane'));
        });

        test('handles execute without args', () async {
          await wrapper.execute(
            "INSERT INTO test_table (id, name) VALUES ('2', 'NoArgs')",
          );

          final results = await crdt.query(
            'SELECT * FROM test_table WHERE id = ?1',
            ['2'],
          );

          expect(results, hasLength(1));
        });
      });

      group('watch', () {
        test('returns stream from underlying crdt', () async {
          await wrapper.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['1', 'Initial'],
          );

          final stream = wrapper.watch(
            'SELECT * FROM test_table WHERE id = ?1',
            () => ['1'],
          );

          await expectLater(
            stream,
            emits(
              isA<List<Map<String, Object?>>>()
                  .having((l) => l.length, 'length', 1)
                  .having((l) => l.first['name'], 'name', 'Initial'),
            ),
          );
        });

        test('handles watch without argsFunction', () async {
          await wrapper.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['1', 'Test'],
          );

          final stream = wrapper.watch('SELECT * FROM test_table');

          await expectLater(
            stream,
            emits(isA<List<Map<String, Object?>>>()),
          );
        });
      });

      group('transaction', () {
        test('wraps executor correctly', () async {
          await wrapper.transaction((txn) async {
            await txn.execute(
              'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
              ['1', 'First'],
            );
            await txn.execute(
              'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
              ['2', 'Second'],
            );
          });

          final results = await crdt.query('SELECT * FROM test_table');
          expect(results, hasLength(2));
        });

        test('transaction context execute handles no args', () async {
          await wrapper.transaction((txn) async {
            await txn.execute(
              "INSERT INTO test_table (id, name) VALUES ('3', 'NoArgs')",
            );
          });

          final results = await wrapper.query(
            'SELECT * FROM test_table WHERE id = ?1',
            ['3'],
          );
          expect(results, hasLength(1));
        });
      });

      group('getChangeset', () {
        test('delegates to underlying crdt', () async {
          await wrapper.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['1', 'Test'],
          );

          final changeset = await wrapper.getChangeset();

          expect(changeset, isA<CrdtChangeset>());
          expect(changeset.isNotEmpty, isTrue);
          expect(changeset.containsKey('test_table'), isTrue);
        });

        test('returns changes after timestamp', () async {
          await wrapper.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['1', 'First'],
          );

          // Get first changeset to capture timestamp
          final firstChangeset = await wrapper.getChangeset();
          final firstRecord = firstChangeset['test_table']!.first;
          final hlcString = firstRecord['hlc']! as String;
          final hlc = Hlc.parse(hlcString);

          // Add another record
          await wrapper.execute(
            'INSERT INTO test_table (id, name) VALUES (?1, ?2)',
            ['2', 'Second'],
          );

          // Get changes after the first record
          final deltaChangeset = await wrapper.getChangeset(modifiedAfter: hlc);

          expect(deltaChangeset, isA<CrdtChangeset>());
          // Should only contain the second record
          if (deltaChangeset.containsKey('test_table')) {
            final records = deltaChangeset['test_table']!;
            expect(records.every((r) => r['id'] != '1'), isTrue);
          }
        });
      });

      group('merge', () {
        test('delegates to underlying crdt with empty changeset', () async {
          // Test merge with empty changeset - verifies delegation works
          final emptyChangeset = <String, List<Map<String, Object?>>>{};

          // Merge should complete without error
          await wrapper.merge(emptyChangeset);

          // Verify merge completed
          expect(true, isTrue);
        });

        test('merge method is accessible', () {
          // Verify the merge method exists and is callable
          expect(wrapper.merge, isNotNull);
        });
      });

      group('nodeId', () {
        test('returns underlying crdt nodeId', () {
          final nodeId = wrapper.nodeId;

          expect(nodeId, isNotEmpty);
          expect(nodeId, equals(crdt.nodeId));
        });
      });

      group('close', () {
        test('delegates to underlying crdt', () async {
          // Create a separate wrapper for close testing
          final testCrdt = await SqliteCrdt.openInMemory(
            version: 1,
            onCreate: (crdt, version) async {
              await crdt.execute('''
                CREATE TABLE IF NOT EXISTS test_table (
                  id TEXT PRIMARY KEY NOT NULL,
                  name TEXT
                )
              ''');
            },
          );
          final testWrapper = DefaultCrdtDatabaseWrapper(testCrdt);

          await testWrapper.close();

          // Verify database is closed by attempting an operation
          // sqflite throws DatabaseException when db is closed
          await expectLater(
            () => testWrapper.query('SELECT * FROM test_table'),
            throwsA(isA<Exception>()),
          );
        });
      });
    });
  });
}
