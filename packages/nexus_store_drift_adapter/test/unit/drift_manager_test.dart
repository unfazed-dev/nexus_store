import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

// Test models
class User {
  const User({required this.id, required this.name, this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );

  final String id;
  final String name;
  final String? email;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, email);
}

class Post {
  const Post({required this.id, required this.title, this.userId});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        title: json['title'] as String,
        userId: json['userId'] as String?,
      );

  final String id;
  final String title;
  final String? userId;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'userId': userId};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, title, userId);
}

void main() {
  group('DriftManager', () {
    late DriftManager manager;
    late LazyDatabase lazyDb;

    setUp(() {
      lazyDb = LazyDatabase(() async => NativeDatabase.memory());
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('creates manager with multiple tables', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
          DriftTableConfig<Post, String>(
            tableName: 'posts',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('title', nullable: false),
              DriftColumn.text('userId'),
            ],
            fromJson: Post.fromJson,
            toJson: (p) => p.toJson(),
            getId: (p) => p.id,
          ),
        ],
        executor: lazyDb,
      );

      expect(manager.isInitialized, isFalse);
      await manager.initialize();
      expect(manager.isInitialized, isTrue);
    });

    test('returns table names', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
          DriftTableConfig<Post, String>(
            tableName: 'posts',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('title', nullable: false),
              DriftColumn.text('userId'),
            ],
            fromJson: Post.fromJson,
            toJson: (p) => p.toJson(),
            getId: (p) => p.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();
      expect(manager.tableNames, containsAll(['users', 'posts']));
    });

    test('getBackend returns backend for table', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();

      final userBackend = manager.getBackend('users');
      expect(userBackend, isNotNull);
      expect(userBackend.name, equals('drift'));
    });

    test('getBackend throws StateError for unknown table', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();

      expect(
        () => manager.getBackend('posts'),
        throwsA(isA<StateError>()),
      );
    });

    test('getBackend throws StateError before initialize', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
        ],
        executor: lazyDb,
      );

      expect(
        () => manager.getBackend('users'),
        throwsA(isA<StateError>()),
      );
    });

    test('backends share same database connection', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
          DriftTableConfig<Post, String>(
            tableName: 'posts',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('title', nullable: false),
              DriftColumn.text('userId'),
            ],
            fromJson: Post.fromJson,
            toJson: (p) => p.toJson(),
            getId: (p) => p.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();

      final userBackend = manager.getBackend('users');
      final postBackend = manager.getBackend('posts');

      // Both backends should work with the same connection
      // Use User/Post objects - the config's toJson handles conversion
      const user = User(id: '1', name: 'John');
      const post = Post(id: '1', title: 'Hello', userId: '1');
      await userBackend.save(user);
      await postBackend.save(post);

      expect(await userBackend.get('1'), isNotNull);
      expect(await postBackend.get('1'), isNotNull);
    });

    test('CRUD operations work on multiple tables', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
          DriftTableConfig<Post, String>(
            tableName: 'posts',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('title', nullable: false),
              DriftColumn.text('userId'),
            ],
            fromJson: Post.fromJson,
            toJson: (p) => p.toJson(),
            getId: (p) => p.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();

      final userBackend = manager.getBackend('users');
      final postBackend = manager.getBackend('posts');

      // Create
      const user1 = User(id: '1', name: 'Alice', email: 'alice@test.com');
      const user2 = User(id: '2', name: 'Bob');
      await userBackend.save(user1);
      await userBackend.save(user2);

      const post1 = Post(id: '1', title: 'First Post', userId: '1');
      const post2 = Post(id: '2', title: 'Second Post', userId: '1');
      await postBackend.save(post1);
      await postBackend.save(post2);

      // Read
      expect(await userBackend.getAll(), hasLength(2));
      expect(await postBackend.getAll(), hasLength(2));

      // Update
      const updatedUser = User(id: '1', name: 'Alice Updated');
      await userBackend.save(updatedUser);
      final updated = await userBackend.get('1');
      expect((updated as User).name, equals('Alice Updated'));

      // Delete
      await userBackend.delete('2');
      expect(await userBackend.getAll(), hasLength(1));
      expect(await postBackend.getAll(), hasLength(2)); // Posts unaffected
    });

    test('dispose closes all backends', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();
      expect(manager.isInitialized, isTrue);

      await manager.dispose();
      expect(manager.isInitialized, isFalse);
    });

    test('creates indexes during initialization', () async {
      manager = DriftManager.withDatabase(
        tables: [
          DriftTableConfig<User, String>(
            tableName: 'users',
            columns: [
              DriftColumn.text('id', nullable: false),
              DriftColumn.text('name', nullable: false),
              DriftColumn.text('email'),
            ],
            fromJson: User.fromJson,
            toJson: (u) => u.toJson(),
            getId: (u) => u.id,
            indexes: [
              const DriftIndex(name: 'idx_users_email', columns: ['email']),
              const DriftIndex(
                name: 'idx_users_name',
                columns: ['name'],
                unique: true,
              ),
            ],
          ),
        ],
        executor: lazyDb,
      );

      await manager.initialize();

      // Indexes are created during initialization - verify backend works
      final userBackend = manager.getBackend('users');
      const user = User(id: '1', name: 'Alice', email: 'alice@test.com');
      await userBackend.save(user);

      final retrieved = await userBackend.get('1');
      expect(retrieved, isNotNull);
    });

    test('throws UnsupportedError when no executor provided', () {
      // DriftManager.withDatabase without executor calls _createInMemoryExecutor
      // which throws UnsupportedError
      expect(
        () => DriftManager.withDatabase(
          tables: [
            DriftTableConfig<User, String>(
              tableName: 'users',
              columns: [
                DriftColumn.text('id', nullable: false),
                DriftColumn.text('name', nullable: false),
              ],
              fromJson: User.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
