import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/api/api_exception.dart';
import 'package:botique/models/user.dart';
import 'package:botique/services/auth_service.dart';

const _userJson = {
  'id': 'u-1',
  'fullName': 'Amara Okafor',
  'email': 'amara@example.com',
  'phone': '+234 801 234 5678',
  'role': 'customer',
  'isActive': true,
};

ApiClient _api(MockClient mock) => ApiClient(baseUrl: 'http://localhost:8080', client: mock);

String _authPayload() =>
    '{"success": true, "data": {"token": "tok-abc", "user": ${jsonEncode(_userJson)}}}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('restoreSession', () {
    test('mock mode (no api) starts unauthenticated', () async {
      final auth = AuthService(storage: InMemoryTokenStorage());
      expect(auth.status, AuthStatus.checking);
      await auth.restoreSession();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.currentUser, isNull);
    });

    test('restores persisted token and validates against the server', () async {
      var meCalled = false;
      final mock = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer tok-abc');
        meCalled = true;
        return http.Response('{"success": true, "data": ${jsonEncode(_userJson)}}', 200,
            headers: {'content-type': 'application/json'});
      });
      final storage = InMemoryTokenStorage()
        ..token = 'tok-abc'
        ..userJson = jsonEncode(_userJson);
      final auth = AuthService(apiClient: _api(mock), storage: storage);

      await auth.restoreSession();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.currentUser!.email, 'amara@example.com');
      expect(meCalled, isTrue);
    });

    test('clears session when the restored token is rejected with 401', () async {
      final mock = MockClient((request) async {
        return http.Response(
            '{"success": false, "error": {"code": "UNAUTHORIZED", "message": "expired"}}', 401,
            headers: {'content-type': 'application/json'});
      });
      final storage = InMemoryTokenStorage()
        ..token = 'expired-token'
        ..userJson = jsonEncode(_userJson);
      final auth = AuthService(apiClient: _api(mock), storage: storage);

      await auth.restoreSession();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.currentUser, isNull);
      expect(storage.token, isNull);
    });

    test('keeps the cached session on network failure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('offline');
      });
      final storage = InMemoryTokenStorage()
        ..token = 'tok-abc'
        ..userJson = jsonEncode(_userJson);
      final auth = AuthService(apiClient: _api(mock), storage: storage);

      await auth.restoreSession();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.currentUser!.email, 'amara@example.com');
      expect(storage.token, 'tok-abc');
    });
  });

  group('login', () {
    test('stores the token and user and authenticates the client', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.headers['authorization'], isNull);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'amara@example.com');
        expect(body['password'], 'secret');
        return http.Response(_authPayload(), 200,
            headers: {'content-type': 'application/json'});
      });
      final storage = InMemoryTokenStorage();
      final auth = AuthService(apiClient: _api(mock), storage: storage);

      await auth.login(email: 'amara@example.com', password: 'secret');

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser!.name, 'Amara Okafor');
      expect(storage.token, 'tok-abc');
      expect(storage.userJson, isNotNull);
    });

    test('propagates ApiException for bad credentials', () async {
      final mock = MockClient((request) async {
        return http.Response(
            '{"success": false, "error": {"code": "UNAUTHORIZED", "message": "Incorrect email or password"}}',
            401,
            headers: {'content-type': 'application/json'});
      });
      final auth = AuthService(apiClient: _api(mock), storage: InMemoryTokenStorage());

      await expectLater(
        auth.login(email: 'amara@example.com', password: 'wrong'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.code, 'code', 'UNAUTHORIZED')),
      );
      expect(auth.isLoggedIn, isFalse);
    });
  });

  group('register', () {
    test('creates a customer account and logs the user in', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/register');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fullName'], 'Ngozi Eze');
        expect(body['role'], isNull);
        return http.Response(_authPayload(), 200,
            headers: {'content-type': 'application/json'});
      });
      final auth = AuthService(apiClient: _api(mock), storage: InMemoryTokenStorage());

      await auth.register(
        fullName: 'Ngozi Eze',
        email: 'ngozi@example.com',
        phone: '+234 900 000 0000',
        password: 'password123',
      );

      expect(auth.isLoggedIn, isTrue);
    });
  });

  group('logout', () {
    test('clears the local session', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/logout');
        return http.Response('{"success": true, "data": null}', 200,
            headers: {'content-type': 'application/json'});
      });
      final storage = InMemoryTokenStorage()
        ..token = 'tok-abc'
        ..userJson = jsonEncode(_userJson);
      final auth = AuthService(apiClient: _api(mock), storage: storage);
      auth.restoreSession();

      await auth.logout();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.currentUser, isNull);
      expect(storage.token, isNull);
    });
  });

  group('demo mode', () {
    test('loginAs switches user without a backend', () async {
      final auth = AuthService(storage: InMemoryTokenStorage());
      await auth.loginAs(DemoAccounts.accounts.first);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.role, Role.customer);
    });

    test('loginAs is a no-op when a backend is configured', () async {
      final mock = MockClient((request) async {
        return http.Response('{"success": true, "data": null}', 200,
            headers: {'content-type': 'application/json'});
      });
      final auth = AuthService(apiClient: _api(mock), storage: InMemoryTokenStorage());
      await auth.loginAs(DemoAccounts.accounts.first);
      expect(auth.isLoggedIn, isFalse);
    });

    test('login form matches a demo account by email', () async {
      final auth = AuthService(storage: InMemoryTokenStorage());
      await auth.login(email: 'admin@queenstouch.com', password: 'anything');
      expect(auth.isLoggedIn, isTrue);
      expect(auth.role, Role.superAdmin);
    });

    test('login form rejects an unknown email', () async {
      final auth = AuthService(storage: InMemoryTokenStorage());
      await expectLater(
        auth.login(email: 'nobody@example.com', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('register creates a local customer without a backend', () async {
      final auth = AuthService(storage: InMemoryTokenStorage());
      await auth.register(
        fullName: 'Ngozi Eze',
        email: 'ngozi@example.com',
        phone: '+234 900 000 0000',
        password: 'password123',
      );
      expect(auth.isLoggedIn, isTrue);
      expect(auth.role, Role.customer);
      expect(auth.currentUser!.name, 'Ngozi Eze');
    });
  });

  group('updateProfile', () {
    test('updates name and phone locally and persists when authenticated', () async {
      final storage = InMemoryTokenStorage()
        ..token = 'tok-abc'
        ..userJson = jsonEncode(_userJson);
      final auth = AuthService(apiClient: _api(MockClient((request) async {
        return http.Response('{"success": true, "data": null}', 200,
            headers: {'content-type': 'application/json'});
      })), storage: storage);
      await auth.restoreSession();

      await auth.updateProfile(name: 'Amara Okafor II', phone: '+234 000 000 0000');

      expect(auth.currentUser!.name, 'Amara Okafor II');
      expect(auth.currentUser!.phone, '+234 000 000 0000');
      final persisted = jsonDecode(storage.userJson!) as Map<String, dynamic>;
      expect(persisted['fullName'], 'Amara Okafor II');
    });
  });

  group('friendlyAuthError', () {
    test('returns server message for API errors', () {
      const e = ApiException(statusCode: 401, code: 'UNAUTHORIZED', message: 'Incorrect email or password');
      expect(friendlyAuthError(e), 'Incorrect email or password');
    });

    test('returns a connect hint for network failures', () {
      const e = ApiException(statusCode: 0, code: 'NETWORK', message: 'refused');
      expect(friendlyAuthError(e), contains('Unable to connect'));
    });
  });
}
