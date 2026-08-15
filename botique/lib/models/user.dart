enum Role {
  superAdmin,
  storeManager,
  salesStaff,
  inventoryStaff,
  customer;

  String get label => switch (this) {
        Role.superAdmin => 'Super Admin',
        Role.storeManager => 'Store Manager',
        Role.salesStaff => 'Sales Staff',
        Role.inventoryStaff => 'Inventory Staff',
        Role.customer => 'Customer',
      };

  bool get isStaff => this != Role.customer;
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final Role role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  User copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isActive,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
