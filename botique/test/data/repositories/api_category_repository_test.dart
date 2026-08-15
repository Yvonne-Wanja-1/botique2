import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_category_repository.dart';
import 'package:botique/models/category.dart';

void main() {
  test('getRootCategories maps category list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/categories');
      return http.Response(
        '{"success": true, "data": [{'
        '"id": "c1", "name": "Dresses", "parentId": null, "description": "x", "imageUrl": "http://i/c.jpg", "isActive": true'
        '}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiCategoryRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final categories = await repo.getRootCategories();
    expect(categories, hasLength(1));
    expect(categories.first.name, 'Dresses');
    expect(categories.first.isSubcategory, isFalse);
  });

  test('getSubcategories uses parent path', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/categories/p1/subcategories');
      return http.Response('{"success": true, "data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiCategoryRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final sub = await repo.getSubcategories('p1');
    expect(sub, isEmpty);
  });

  test('getById filters list client-side', () async {
    final mock = MockClient((request) async {
      if (request.url.path == '/api/categories') {
        return http.Response(
          '{"success": true, "data": [{'
          '"id": "c1", "name": "Dresses", "parentId": null, "description": "x", "imageUrl": "http://i/c.jpg", "isActive": true'
          '}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"success": true, "data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiCategoryRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final found = await repo.getById('c1');
    expect(found?.id, 'c1');
    final missing = await repo.getById('nope');
    expect(missing, isNull);
  });
}