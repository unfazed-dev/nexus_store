/// Test entities for bloc binding tests.

class TestUser {
  const TestUser({
    required this.id,
    required this.name,
    this.email,
    this.age,
  });

  final String id;
  final String name;
  final String? email;
  final int? age;

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

  static TestUser createUser({
    String id = 'user-1',
    String name = 'John Doe',
    String? email = 'john@example.com',
    int? age = 30,
  }) =>
      TestUser(id: id, name: name, email: email, age: age);

  static List<TestUser> createUsers(int count) => List.generate(
        count,
        (i) => createUser(
          id: 'user-$i',
          name: 'User $i',
          email: 'user$i@example.com',
          age: 20 + i,
        ),
      );

  static TestUser get sampleUser => createUser();

  static List<TestUser> get sampleUsers => createUsers(3);
}
