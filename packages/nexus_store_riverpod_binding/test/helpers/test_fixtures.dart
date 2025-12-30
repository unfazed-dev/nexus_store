/// Test entities for Riverpod binding tests.

/// A simple test entity for testing store operations.
class TestUser {
  /// Creates a test user.
  const TestUser({
    required this.id,
    required this.name,
    this.email,
    this.age,
  });

  /// The unique identifier.
  final String id;

  /// The user's name.
  final String name;

  /// The user's email address.
  final String? email;

  /// The user's age.
  final int? age;

  /// Creates a copy of this user with the given fields replaced.
  TestUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
  }) {
    return TestUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, email, age);

  @override
  String toString() =>
      'TestUser(id: $id, name: $name, email: $email, age: $age)';
}

/// Factory methods for creating test users.
class TestFixtures {
  TestFixtures._();

  /// Creates a single test user with optional overrides.
  static TestUser createUser({
    String id = 'user-1',
    String name = 'John Doe',
    String? email = 'john@example.com',
    int? age = 30,
  }) =>
      TestUser(id: id, name: name, email: email, age: age);

  /// Creates a list of test users.
  static List<TestUser> createUsers(int count) => List.generate(
        count,
        (i) => createUser(
          id: 'user-$i',
          name: 'User $i',
          email: 'user$i@example.com',
          age: 20 + i,
        ),
      );

  /// A sample user for quick tests.
  static TestUser get sampleUser => createUser();

  /// A list of sample users for quick tests.
  static List<TestUser> get sampleUsers => createUsers(3);

  /// An empty list for testing empty states.
  static List<TestUser> get emptyUsers => [];
}
