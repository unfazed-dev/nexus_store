import 'dart:io' as io;

import 'package:nexus_store_crdt_adapter/src/crdt_column.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_database_wrapper.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_manager.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_peer_connector.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_table_config.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:test/test.dart';

class _TestUser {
  _TestUser({required this.id, required this.name, this.email});

  factory _TestUser.fromJson(Map<String, dynamic> json) => _TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );

  final String id;
  final String name;
  final String? email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
      };
}

class _TestPost {
  _TestPost({required this.id, required this.title, required this.authorId});

  factory _TestPost.fromJson(Map<String, dynamic> json) => _TestPost(
        id: json['id'] as String,
        title: json['title'] as String,
        authorId: json['author_id'] as String,
      );

  final String id;
  final String title;
  final String authorId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author_id': authorId,
      };
}

void main() {
  group('CrdtManager', () {
    late CrdtManager manager;
    late CrdtTableConfig<_TestUser, String> userConfig;
    late CrdtTableConfig<_TestPost, String> postConfig;

    setUp(() {
      userConfig = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );

      postConfig = CrdtTableConfig<_TestPost, String>(
        tableName: 'posts',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('title', nullable: false),
          CrdtColumn.text('author_id', nullable: false),
        ],
        fromJson: _TestPost.fromJson,
        toJson: (p) => p.toJson(),
        getId: (p) => p.id,
      );
    });

    tearDown(() async {
      if (manager.isInitialized) {
        await manager.dispose();
      }
    });

    group('initialization', () {
      test('starts uninitialized', () {
        manager = CrdtManager.withDatabase(tables: [userConfig]);

        expect(manager.isInitialized, false);
      });

      test('initializes with in-memory database', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);

        await manager.initialize();

        expect(manager.isInitialized, true);
        expect(manager.nodeId, isNotNull);
      });

      test('returns table names', () async {
        manager = CrdtManager.withDatabase(
          tables: [userConfig, postConfig],
        );

        expect(manager.tableNames, ['users', 'posts']);
      });

      test('initialize is idempotent', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);

        await manager.initialize();
        final nodeId = manager.nodeId;

        await manager.initialize(); // Second call should be no-op

        expect(manager.nodeId, nodeId);
      });
    });

    group('getBackend', () {
      test('returns backend for valid table name', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final backend = manager.getBackend('users');

        expect(backend, isNotNull);
      });

      test('throws StateError when not initialized', () {
        manager = CrdtManager.withDatabase(tables: [userConfig]);

        expect(
          () => manager.getBackend('users'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for unknown table', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        expect(
          () => manager.getBackend('unknown'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('backend operations', () {
      test('can save and retrieve data through backend', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final backend = manager.getBackend('users');
        final user = _TestUser(id: '1', name: 'Alice', email: 'alice@test.com');

        await backend.save(user);
        final retrieved = await backend.get('1');

        expect(retrieved, isNotNull);
        expect((retrieved as _TestUser).name, 'Alice');
        expect(retrieved.email, 'alice@test.com');
      });

      test('multiple tables can operate independently', () async {
        manager = CrdtManager.withDatabase(
          tables: [userConfig, postConfig],
        );
        await manager.initialize();

        final userBackend = manager.getBackend('users');
        final postBackend = manager.getBackend('posts');

        await userBackend.save(_TestUser(id: '1', name: 'Bob'));
        await postBackend.save(
          _TestPost(id: 'p1', title: 'Hello', authorId: '1'),
        );

        final users = await userBackend.getAll();
        final posts = await postBackend.getAll();

        expect(users, hasLength(1));
        expect(posts, hasLength(1));
      });
    });

    group('changeset operations', () {
      test('getChangesetForAll returns changes', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final backend = manager.getBackend('users');
        await backend.save(_TestUser(id: '1', name: 'Carol'));

        final changeset = await manager.getChangesetForAll();

        expect(changeset, isNotNull);
        expect(changeset.isNotEmpty, true);
      });

      test('changeset contains table data', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final backend = manager.getBackend('users');
        await backend.save(_TestUser(id: '1', name: 'Dave'));

        // Get changeset to verify format
        final changeset = await manager.getChangesetForAll();

        expect(changeset, isNotNull);
        expect(changeset.containsKey('users'), true);
        expect(changeset['users'], isNotEmpty);

        // Verify the record contains expected data
        final records = changeset['users']!.toList();
        expect(records.first['id'], '1');
        expect(records.first['name'], 'Dave');
      });
    });

    group('peer connector', () {
      test('attachConnector stores connector', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final connector = CrdtMemoryConnector();
        manager.attachConnector(connector);

        expect(manager.connector, connector);
      });

      test('detachConnector removes connector', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final connector = CrdtMemoryConnector();
        manager
          ..attachConnector(connector)
          ..detachConnector();

        expect(manager.connector, isNull);
      });

      test('attaching new connector replaces existing', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final connector1 = CrdtMemoryConnector(peerId: 'conn1');
        final connector2 = CrdtMemoryConnector(peerId: 'conn2');

        manager
          ..attachConnector(connector1)
          ..attachConnector(connector2);

        expect(manager.connector, connector2);
      });
    });

    group('dispose', () {
      test('disposes all backends and database', () async {
        manager = CrdtManager.withDatabase(
          tables: [userConfig, postConfig],
        );
        await manager.initialize();

        await manager.dispose();

        expect(manager.isInitialized, false);
      });

      test('detaches connector on dispose', () async {
        manager = CrdtManager.withDatabase(tables: [userConfig]);
        await manager.initialize();

        final connector = CrdtMemoryConnector();
        manager.attachConnector(connector);

        await manager.dispose();

        expect(manager.connector, isNull);
      });
    });
  });

  group('CrdtManager.withWrapper', () {
    test('uses provided wrapper', () async {
      // Create a real wrapper for testing
      final crdt = await SqliteCrdt.openInMemory(
        version: 1,
        onCreate: (crdt, version) async {
          await crdt.execute('''
            CREATE TABLE IF NOT EXISTS "users" (
              "id" TEXT NOT NULL,
              "name" TEXT NOT NULL,
              "email" TEXT,
              PRIMARY KEY ("id")
            )
          ''');
        },
      );
      final wrapper = DefaultCrdtDatabaseWrapper(crdt);

      final config = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );

      final manager = CrdtManager.withWrapper(
        db: wrapper,
        tables: [config],
      );

      await manager.initialize();

      expect(manager.isInitialized, true);
      expect(manager.nodeId, crdt.nodeId);

      await manager.dispose();
      await crdt.close();
    });
  });

  group('CrdtManager file-based database', () {
    late CrdtManager manager;
    late String tempDbPath;

    setUp(() {
      tempDbPath = '/tmp/crdt_test_${DateTime.now().millisecondsSinceEpoch}.db';
    });

    tearDown(() async {
      if (manager.isInitialized) {
        await manager.dispose();
      }
      // Clean up temp file
      try {
        final file = io.File(tempDbPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
    });

    test('initializes with file-based database', () async {
      final config = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );

      manager = CrdtManager.withDatabase(
        tables: [config],
        databasePath: tempDbPath,
      );

      await manager.initialize();

      expect(manager.isInitialized, true);
      expect(manager.nodeId, isNotNull);
    });
  });

  group('CrdtManager with indexes', () {
    late CrdtManager manager;

    tearDown(() async {
      if (manager.isInitialized) {
        await manager.dispose();
      }
    });

    test('creates tables with indexes', () async {
      final config = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        indexes: [
          const CrdtIndex(name: 'idx_users_email', columns: ['email']),
          const CrdtIndex(
            name: 'idx_users_name',
            columns: ['name'],
            unique: true,
          ),
        ],
      );

      manager = CrdtManager.withDatabase(tables: [config]);

      await manager.initialize();

      expect(manager.isInitialized, true);

      // Verify by using the backend
      final backend = manager.getBackend('users');
      await backend.save(_TestUser(id: '1', name: 'Alice', email: 'a@test.com'));
      final result = await backend.get('1');
      expect(result, isNotNull);
    });
  });

  group('CrdtManager changeset sync', () {
    late CrdtManager manager;
    late CrdtTableConfig<_TestUser, String> userConfig;

    setUp(() {
      userConfig = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );
    });

    tearDown(() async {
      if (manager.isInitialized) {
        await manager.dispose();
      }
    });

    test('applyChangesetToAll handles empty changeset', () async {
      manager = CrdtManager.withDatabase(tables: [userConfig]);
      await manager.initialize();

      // Apply empty changeset - should not throw
      await manager.applyChangesetToAll({});

      // Verify no data was added
      final backend = manager.getBackend('users');
      final all = await backend.getAll();
      expect(all, isEmpty);
    });

    test('sendChangeset sends to connector', () async {
      manager = CrdtManager.withDatabase(tables: [userConfig]);
      await manager.initialize();

      final backend = manager.getBackend('users');
      await backend.save(_TestUser(id: '1', name: 'Local User'));

      final connector = CrdtMemoryConnector();
      manager.attachConnector(connector);

      final changeset = await manager.sendChangeset();

      expect(changeset, isNotEmpty);
      expect(changeset.containsKey('users'), true);
    });

    test('sendChangeset without connector still returns changeset', () async {
      manager = CrdtManager.withDatabase(tables: [userConfig]);
      await manager.initialize();

      final backend = manager.getBackend('users');
      await backend.save(_TestUser(id: '1', name: 'Test User'));

      // No connector attached
      final changeset = await manager.sendChangeset();

      expect(changeset, isNotEmpty);
    });

    test('sendChangeset with connector converts payload', () async {
      manager = CrdtManager.withDatabase(tables: [userConfig]);
      await manager.initialize();

      final backend = manager.getBackend('users');
      await backend.save(_TestUser(id: 'conv1', name: 'Convert User'));

      final connector = CrdtMemoryConnector();
      manager.attachConnector(connector);

      // Listen to outgoing changesets to verify conversion
      CrdtChangesetMessage? sentMessage;
      connector.outgoingChangesets.listen((msg) {
        sentMessage = msg;
      });

      await manager.sendChangeset();

      // Allow async to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentMessage, isNotNull);
      expect(sentMessage!.payload, isNotEmpty);
      expect(sentMessage!.payload.containsKey('users'), true);
    });

    test('attachConnector requires initialization', () async {
      manager = CrdtManager.withDatabase(tables: [userConfig]);

      // attachConnector calls _ensureInitialized
      expect(
        () => manager.attachConnector(CrdtMemoryConnector()),
        throwsA(isA<StateError>()),
      );
    });

    test('peer-to-peer sync via connector pair', () async {
      // Create two managers with connected connectors
      final manager1 = CrdtManager.withDatabase(tables: [userConfig]);
      final manager2 = CrdtManager.withDatabase(tables: [userConfig]);

      await manager1.initialize();
      await manager2.initialize();

      // Create connected pair
      final pair = CrdtPeerConnectorPair.create();
      manager1.attachConnector(pair.nodeA);
      manager2.attachConnector(pair.nodeB);

      await pair.nodeA.connect();
      await pair.nodeB.connect();

      // Save in manager1
      final backend1 = manager1.getBackend('users');
      await backend1.save(_TestUser(id: 'p2p1', name: 'P2P User'));

      // Send changeset from manager1 - this flows to manager2 via pair
      await manager1.sendChangeset();

      // Allow stream to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify data arrived in manager2
      final backend2 = manager2.getBackend('users');
      final user = await backend2.get('p2p1');
      expect(user, isNotNull);
      expect((user as _TestUser).name, 'P2P User');

      await pair.dispose();
      await manager1.dispose();
      await manager2.dispose();

      // Set manager for tearDown
      manager = CrdtManager.withDatabase(tables: [userConfig]);
    });

    test('throws StateError when calling methods before initialize', () {
      manager = CrdtManager.withDatabase(tables: [userConfig]);

      expect(
        () => manager.sendChangeset(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => manager.getChangesetForAll(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => manager.applyChangesetToAll({}),
        throwsA(isA<StateError>()),
      );
    });
  });
}
