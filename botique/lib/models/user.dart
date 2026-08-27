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

  String get apiValue => switch (this) {
        Role.superAdmin => 'super_admin',
        Role.storeManager => 'store_manager',
        Role.salesStaff => 'sales_staff',
        Role.inventoryStaff => 'inventory_staff',
        Role.customer => 'customer',
      };

  bool get isStaff => this != Role.customer;

  static Role fromApi(String value) => switch (value) {
        'super_admin' => Role.superAdmin,
        'store_manager' => Role.storeManager,
        'sales_staff' => Role.salesStaff,
        'inventory_staff' => Role.inventoryStaff,
        _ => Role.customer,
      };
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: (json['fullName'] as String?) ?? (json['full_name'] as String?) ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: Role.fromApi(json['role'] as String? ?? 'customer'),
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': name,
        'email': email,
        'phone': phone,
        'role': role.apiValue,
        'avatarUrl': avatarUrl,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

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
    String? avatarUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
