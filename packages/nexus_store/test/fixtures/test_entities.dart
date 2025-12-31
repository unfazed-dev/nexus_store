/// Test entities for unit tests.
///
/// Provides sample data models for testing NexusStore operations.
library;

/// Test user entity for testing store operations.
class TestUser {
  const TestUser({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.createdAt,
    this.isActive = true,
  });

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        age: json['age'] as int?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String email;
  final int? age;
  final DateTime? createdAt;
  final bool isActive;

  TestUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    DateTime? createdAt,
    bool? isActive,
  }) =>
      TestUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        age: age ?? this.age,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'createdAt': createdAt?.toIso8601String(),
        'isActive': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      age.hashCode ^
      isActive.hashCode;

  @override
  String toString() => 'TestUser(id: $id, name: $name, email: $email, '
      'age: $age, isActive: $isActive)';
}

/// Test product entity for testing store operations.
class TestProduct {
  const TestProduct({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.inStock = true,
  });

  final int id;
  final String name;
  final double price;
  final String? category;
  final bool inStock;

  TestProduct copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    bool? inStock,
  }) =>
      TestProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        category: category ?? this.category,
        inStock: inStock ?? this.inStock,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'inStock': inStock,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          category == other.category &&
          inStock == other.inStock;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      price.hashCode ^
      category.hashCode ^
      inStock.hashCode;

  @override
  String toString() => 'TestProduct(id: $id, name: $name, price: $price, '
      'category: $category, inStock: $inStock)';
}

/// Factory methods for creating test data.
class TestFixtures {
  TestFixtures._();

  /// Creates a sample test user.
  static TestUser createUser({
    String id = 'user-1',
    String name = 'John Doe',
    String email = 'john@example.com',
    int? age = 30,
    bool isActive = true,
  }) =>
      TestUser(
        id: id,
        name: name,
        email: email,
        age: age,
        createdAt: DateTime(2024),
        isActive: isActive,
      );

  /// Creates a list of sample test users.
  static List<TestUser> createUsers(int count) => List.generate(
        count,
        (i) => createUser(
          id: 'user-$i',
          name: 'User $i',
          email: 'user$i@example.com',
          age: 20 + i,
        ),
      );

  /// Creates a sample test product.
  static TestProduct createProduct({
    int id = 1,
    String name = 'Test Product',
    double price = 9.99,
    String? category = 'Electronics',
    bool inStock = true,
  }) =>
      TestProduct(
        id: id,
        name: name,
        price: price,
        category: category,
        inStock: inStock,
      );

  /// Creates a list of sample test products.
  static List<TestProduct> createProducts(int count) => List.generate(
        count,
        (i) => createProduct(
          id: i,
          name: 'Product $i',
          price: 9.99 + i,
          category: i.isEven ? 'Electronics' : 'Books',
        ),
      );

  /// Sample user for basic tests.
  static TestUser get sampleUser => createUser();

  /// Sample product for basic tests.
  static TestProduct get sampleProduct => createProduct();

  /// Sample users list for batch tests.
  static List<TestUser> get sampleUsers => createUsers(5);

  /// Sample products list for batch tests.
  static List<TestProduct> get sampleProducts => createProducts(5);
}
