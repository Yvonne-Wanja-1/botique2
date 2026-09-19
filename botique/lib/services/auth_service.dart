import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api/api_client.dart';
import '../data/api/api_exception.dart';
import '../models/product.dart';
import '../models/user.dart';

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
  AuthService({required ApiClient apiClient, TokenStorage? storage})
      : _api = apiClient,
        _storage = storage ?? SecureTokenStorage() {
    _api.onUnauthorized = handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStorage _storage;

  User? _currentUser;
  AuthStatus _status = AuthStatus.checking;

  User? get currentUser => _currentUser;

  AuthStatus get status => _status;

  bool get isLoggedIn => _currentUser != null;

  bool get isStaff => _currentUser?.role.isStaff ?? false;

  Role get role => _currentUser?.role ?? Role.customer;

  bool get usesRemoteApi => true;

  /// Restores a persisted session on startup.
  Future<void> restoreSession() async {
    _status = AuthStatus.checking;
    notifyListeners();
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
    // Temporarily suppress the 401 handler during startup validation.
    final previousHandler = _api.onUnauthorized;
    _api.onUnauthorized = null;
    try {
      final data = await _api.get('/api/auth/me');
      if (data is Map<String, dynamic>) {
        final user = User.fromJson(data);
        _currentUser = user;
        await _storage.writeUserJson(jsonEncode(user.toJson()));
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode != 401 && e.statusCode != 403) {
        debugPrint('Auth: validation error ${e.statusCode}: ${e.message}');
      }
    } catch (_) {
      // Network errors: keep the restored session.
    } finally {
      _api.onUnauthorized = previousHandler;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _api.post('/api/auth/login', body: {'email': email, 'password': password});
    await _applyAuthPayload(data);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _api.post('/api/auth/register', body: {
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
    _api.setToken(token);
    await _storage.writeToken(token);
    await _storage.writeUserJson(jsonEncode(user.toJson()));
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Best-effort: the session is discarded locally regardless.
    }
    await _clearSession();
  }

  /// Called by [ApiClient] when the backend returns 401 — clears the session
  /// and returns the user to the login screen via the router.
  Future<void> handleUnauthorized() => _clearSession();

  Future<void> _clearSession() async {
    _api.clearToken();
    await _storage.clear();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(name: name, phone: phone);
    await _storage.writeUserJson(jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.put('/api/auth/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Uploads a new profile picture from the device gallery. Returns the new
  /// avatar URL once persisted by the backend.
  Future<String?> uploadAvatar({required Uint8List bytes, required String filename, required String mimeType}) async {
    final data = await _api.postMultipart(
      '/api/auth/avatar',
      images: [UploadImage(bytes: bytes, filename: filename, mimeType: mimeType)],
      fileField: 'avatar',
    );
    if (data is Map<String, dynamic>) {
      final avatarUrl = data['avatarUrl'] as String?;
      _currentUser = _currentUser?.copyWith(avatarUrl: avatarUrl);
      if (_currentUser != null) {
        await _storage.writeUserJson(jsonEncode(_currentUser!.toJson()));
      }
      notifyListeners();
      return avatarUrl;
    }
    return null;
  }
}