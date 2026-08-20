import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api/api_client.dart';
import '../data/api/api_exception.dart';
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

enum AuthStatus { checking, unauthenticated, authenticated }

/// Persists the session. [SecureTokenStorage] uses the platform keychain/
/// keystore; tests can inject [InMemoryTokenStorage].
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<String?> readUserJson();
  Future<void> writeUserJson(String json);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readUserJson() => _storage.read(key: _userKey);

  @override
  Future<void> writeUserJson(String json) => _storage.write(key: _userKey, value: json);

  @override
  Future<void> clear() => _storage.deleteAll();
}

@visibleForTesting
class InMemoryTokenStorage implements TokenStorage {
  String? token;
  String? userJson;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> writeUserJson(String value) async => userJson = value;

  @override
  Future<void> clear() async {
    token = null;
    userJson = null;
  }
}

/// Maps an [ApiException] to a message a customer can act on.
String friendlyAuthError(ApiException e) {
  if (e.statusCode == 0) {
    if (e.code == 'TIMEOUT') return 'The server took too long to respond. Please try again.';
    return 'Unable to connect. Please check your internet connection and try again.';
  }
  if (e.message.isEmpty) return 'Something went wrong. Please try again.';
  return e.message;
}

class AuthService extends ChangeNotifier {
  AuthService({ApiClient? apiClient, TokenStorage? storage})
      : _api = apiClient,
        _storage = storage ?? SecureTokenStorage() {
    _api?.onUnauthorized = handleUnauthorized;
  }

  final ApiClient? _api;
  final TokenStorage _storage;

  User? _currentUser;
  AuthStatus _status = AuthStatus.checking;

  User? get currentUser => _currentUser;

  AuthStatus get status => _status;

  bool get isLoggedIn => _currentUser != null;

  bool get isStaff => _currentUser?.role.isStaff ?? false;

  Role get role => _currentUser?.role ?? Role.customer;

  bool get usesRemoteApi => _api != null;

  /// Restores a persisted session on startup. In mock mode there is no backend,
  /// so the app starts signed out (matching the previous demo behavior).
  Future<void> restoreSession() async {
    _status = AuthStatus.checking;
    notifyListeners();
    if (_api == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final token = await _storage.readToken();
      final userJson = await _storage.readUserJson();
      if (token == null || token.isEmpty || userJson == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      _api.setToken(token);
      _currentUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      notifyListeners();
      // Validate against the server; expired sessions are cleared, network
      // failures keep the cached session so offline users are not locked out.
      await _validateSession();
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _validateSession() async {
    if (_api == null) return;
    try {
      final data = await _api.get('/auth/me');
      if (data is Map<String, dynamic>) {
        final user = User.fromJson(data);
        _currentUser = user;
        await _storage.writeUserJson(jsonEncode(user.toJson()));
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _clearSession();
      }
    } catch (_) {
      // Network errors: keep the restored session.
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (_api == null) {
      // Demo build: authenticate against the seeded demo accounts so the
      // real login form stays functional without a backend.
      final match = DemoAccounts.accounts
          .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
          .toList();
      if (match.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          code: 'UNAUTHORIZED',
          message: 'Unknown demo account. Use one of the demo emails shown below.',
        );
      }
      await loginAs(match.first);
      return;
    }
    final data = await _api.post('/auth/login', body: {'email': email, 'password': password});
    await _applyAuthPayload(data);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (_api == null) {
      // Demo build: create a local customer so the register screen works
      // without a backend.
      _currentUser = User(
        id: 'u-demo-${DateTime.now().millisecondsSinceEpoch}',
        name: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: Role.customer,
        createdAt: DateTime.now(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }
    final data = await _api.post('/auth/register', body: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await _applyAuthPayload(data);
  }

  Future<void> _applyAuthPayload(Object? data) async {
    final map = data as Map<String, dynamic>;
    final token = map['token'] as String;
    final user = User.fromJson(map['user'] as Map<String, dynamic>);
    _api!.setToken(token);
    await _storage.writeToken(token);
    await _storage.writeUserJson(jsonEncode(user.toJson()));
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api?.post('/auth/logout');
    } catch (_) {
      // Best-effort: the session is discarded locally regardless.
    }
    await _clearSession();
  }

  /// Called by [ApiClient] when the backend returns 401 — clears the session
  /// and returns the user to the login screen via the router.
  Future<void> handleUnauthorized() => _clearSession();

  Future<void> _clearSession() async {
    _api?.clearToken();
    await _storage.clear();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Demo quick-login for mock builds (no backend). In API mode demo tiles only
  /// pre-fill the login form and must still authenticate against the backend.
  Future<void> loginAs(User user) async {
    if (_api != null) return;
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> loginAsRole(Role role) async {
    final account = DemoAccounts.accounts.firstWhere((u) => u.role == role);
    await loginAs(account);
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(name: name, phone: phone);
    if (_api != null) {
      await _storage.writeUserJson(jsonEncode(_currentUser!.toJson()));
    }
    notifyListeners();
  }
}