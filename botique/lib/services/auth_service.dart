import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/user.dart';

class DemoAccounts {
  DemoAccounts._();

  static final List<User> accounts = [
    User(
      id: 'u-customer',
      name: 'Amara Okafor',
      email: 'amara@example.com',
      phone: '+234 801 234 5678',
      role: Role.customer,
      createdAt: DateTime(2026, 3, 15),
    ),
    User(
      id: 'u-admin',
      name: 'Queen Ebele',
      email: 'admin@queenstouch.com',
      phone: '+234 802 000 0001',
      role: Role.superAdmin,
      createdAt: DateTime(2026, 1, 1),
    ),
    User(
      id: 'u-manager',
      name: 'Sarah Mensah',
      email: 'manager@queenstouch.com',
      phone: '+234 802 000 0002',
      role: Role.storeManager,
      createdAt: DateTime(2026, 1, 5),
    ),
    User(
      id: 'u-sales',
      name: 'Doris Achebe',
      email: 'sales@queenstouch.com',
      phone: '+234 802 000 0003',
      role: Role.salesStaff,
      createdAt: DateTime(2026, 1, 8),
    ),
    User(
      id: 'u-inventory',
      name: 'Chidi Nwosu',
      email: 'inventory@queenstouch.com',
      phone: '+234 802 000 0004',
      role: Role.inventoryStaff,
      createdAt: DateTime(2026, 1, 10),
    ),
  ];
}

class AuthService extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get isStaff => _currentUser?.role.isStaff ?? false;

  Role get role => _currentUser?.role ?? Role.customer;

  Future<void> restoreSession() async {
    // UI-first: session is reset on restart until backend exists.
    _currentUser = null;
  }

  Future<void> loginAs(User user) async {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loginAsRole(Role role) async {
    final account = DemoAccounts.accounts.firstWhere((u) => u.role == role);
    await loginAs(account);
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(name: name, phone: phone);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
