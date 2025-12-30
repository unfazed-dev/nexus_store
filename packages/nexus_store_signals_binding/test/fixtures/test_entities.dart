/// Test entity for signals binding tests.
class TestUser {
  const TestUser({
    required this.id,
    required this.name,
    this.age = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int age;
  final bool isActive;

  TestUser copyWith({
    String? id,
    String? name,
    int? age,
    bool? isActive,
  }) =>
      TestUser(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, name, age, isActive);

  @override
  String toString() =>
      'TestUser(id: $id, name: $name, age: $age, isActive: $isActive)';
}

// Sample test data
const testUser1 = TestUser(id: '1', name: 'Alice', age: 25, isActive: true);
const testUser2 = TestUser(id: '2', name: 'Bob', age: 30, isActive: false);
const testUser3 = TestUser(id: '3', name: 'Charlie', age: 22, isActive: true);
const testUsers = [testUser1, testUser2, testUser3];
