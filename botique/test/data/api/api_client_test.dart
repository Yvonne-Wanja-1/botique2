import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/api/api_exception.dart';

void main() {
  test('returns data from a successful envelope', () async {
    final mock = MockClient((request) async {
      expect(request.headers['x-user-id'], 'u1');
      expect(request.headers['x-user-role'], 'customer');
      return http.Response('{"success": true, "data": {"name": "Dress"}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', userId: 'u1', role: 'customer', client: mock);
    final data = await client.get('/api/categories');
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['name'], 'Dress');
  });

  test('throws ApiException on error envelope', () async {
    final mock = MockClient((request) async {
      return http.Response('{"success": false, "error": {"code": "CONFLICT", "message": "no"}}', 409,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', client: mock);
    expect(
      () => client.get('/api/x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT').having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  test('throws ApiException on network failure', () async {
    final mock = MockClient((request) async {
      throw http.ClientException('connection refused');
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', client: mock);
    expect(
      () => client.get('/api/x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK')),
    );
  });

  test('setPrincipal updates auth headers', () async {
    final mock = MockClient((request) async {
      expect(request.headers['x-user-id'], 'u2');
      expect(request.headers['x-user-role'], 'staff');
      return http.Response('{"success": true, "data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', client: mock);
    client.setPrincipal(userId: 'u2', role: 'staff');
    await client.get('/api/things');
  });
}