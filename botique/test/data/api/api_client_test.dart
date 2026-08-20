import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/api/api_exception.dart';
import 'package:botique/models/product.dart';

void main() {
  test('returns data from a successful envelope', () async {
    final mock = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer tok-1');
      return http.Response('{"success": true, "data": {"name": "Dress"}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', token: 'tok-1', client: mock);
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

  test('setToken updates the authorization header', () async {
    final mock = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer tok-2');
      return http.Response('{"success": true, "data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', client: mock);
    client.setToken('tok-2');
    await client.get('/api/things');
  });

  test('clearToken removes the authorization header', () async {
    final mock = MockClient((request) async {
      expect(request.headers.containsKey('authorization'), isFalse);
      return http.Response('{"success": true, "data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', token: 'tok-3', client: mock);
    client.clearToken();
    await client.get('/api/things');
  });

  test('invokes onUnauthorized when the backend returns 401', () async {
    var called = 0;
    final mock = MockClient((request) async {
      return http.Response('{"success": false, "error": {"code": "UNAUTHORIZED", "message": "expired"}}', 401,
          headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', client: mock);
    client.onUnauthorized = () => called++;
    await expectLater(client.get('/api/x'), throwsA(isA<ApiException>()));
    expect(called, 1);
  });

  test('postMultipart uploads fields and images', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/products/p1/images');
      expect(request.headers['authorization'], 'Bearer tok-4');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      final body = utf8.decode(request.bodyBytes);
      expect(body, contains('name="field1"'));
      expect(body, contains('filename="dress.png"'));
      return http.Response(
        '{"success": true, "data": [{"id": "img1", "url": "/images/dress.png", "position": 0, "isPrimary": true}]}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = ApiClient(baseUrl: 'http://localhost:8080', token: 'tok-4', client: mock);
    final data = await client.postMultipart(
      '/api/products/p1/images',
      fields: {'field1': 'v1'},
      images: const [
        UploadImage(bytes: [1, 2, 3], filename: 'dress.png', mimeType: 'image/png'),
      ],
    );
    expect(data, isA<List<dynamic>>());
    expect((data as List<dynamic>).single['url'], '/images/dress.png');
  });

  test('resolveImageUrl resolves relative and leaves absolute untouched', () {
    final client = ApiClient(baseUrl: 'http://localhost:8080');
    expect(client.resolveImageUrl('/images/a.png'), 'http://localhost:8080/images/a.png');
    expect(client.resolveImageUrl('images/a.png'), 'http://localhost:8080/images/a.png');
    expect(client.resolveImageUrl('https://cdn.x/a.png'), 'https://cdn.x/a.png');
    expect(client.resolveImageUrl(''), '');
  });
}