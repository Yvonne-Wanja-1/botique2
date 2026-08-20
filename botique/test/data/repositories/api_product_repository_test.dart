import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_product_repository.dart';
import 'package:botique/data/repositories/catalog_repository.dart';
import 'package:botique/models/product.dart';

void main() {
  test('getFeatured maps envelope products', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/products');
      expect(request.url.queryParameters['featured'], 'true');
      return http.Response(
        '{"success": true, "data": {"products": [{'
        '"id": "p1", "name": "Dress", "description": "d", "basePrice": 25000, "discountPrice": null,'
        '"categoryId": "c1", "brandId": "b1", "images": ["http://i/x.jpg"], "variants": [],'
        '"isFeatured": true, "isNewArrival": false, "isBestSeller": false, "isTrending": false,'
        '"rating": 4.5, "reviewCount": 3, "soldCount": 10, "stockThreshold": 5, "status": "active"'
        '}], "total": 1}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final products = await repo.getFeatured();
    expect(products, hasLength(1));
    expect(products.first.name, 'Dress');
    expect(products.first.price, 25000);
  });

  test('search passes sort and pagination params', () async {
    final mock = MockClient((request) async {
      expect(request.url.queryParameters['sort'], 'price_low_high');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['pageSize'], '10');
      return http.Response(
        '{"success": true, "data": {"products": [], "total": 0}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final result = await repo.search(
      const ProductFilter(),
      ProductSort.priceLowHigh,
      page: 2,
      pageSize: 10,
    );
    expect(result.total, 0);
  });

  test('getById returns null when data is null', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/products/missing');
      return http.Response('{"success": true, "data": null}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final product = await repo.getById('missing');
    expect(product, isNull);
  });

  test('getReviews maps reviews', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reviews/products/p1/reviews');
      return http.Response(
        '{"success": true, "data": [{'
        '"id": "r1", "productId": "p1", "customerId": "u1", "customerName": "Amara",'
        '"rating": 5, "comment": "great", "isVerifiedPurchase": true, "isApproved": true, "isReported": false,'
        '"createdAt": "2026-01-01T00:00:00Z"}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final reviews = await repo.getReviews('p1');
    expect(reviews.single.rating, 5);
    expect(reviews.single.isVerifiedPurchase, true);
  });

  test('getAll hits /all and includes inactive', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/products/all');
      return http.Response(
        '{"success": true, "data": {"products": ['
        '{"id": "p1", "name": "Dress", "description": "d", "basePrice": 10, "discountPrice": null,'
        '"categoryId": "c1", "brandId": "b1", "images": [], "variants": [], "status": "inactive",'
        '"rating": 0, "reviewCount": 0, "soldCount": 0, "stockThreshold": 5}'
        '], "total": 1}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final products = await repo.getAll();
    expect(products.single.status, ProductStatus.inactive);
  });

  test('create posts draft and maps created product', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/products');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['name'], 'Silk Dress');
      expect(body['slug'], 'silk-dress');
      expect(body['basePrice'], 99.5);
      return http.Response(
        '{"success": true, "data": {"id": "p9", "name": "Silk Dress", "description": "",'
        '"basePrice": 99.5, "discountPrice": null, "categoryId": "c1", "brandId": "b1", "images": [],'
        '"variants": [], "rating": 0, "reviewCount": 0, "soldCount": 0, "stockThreshold": 5, "status": "active"}}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final product = await repo.create(const ProductDraft(
      name: 'Silk Dress',
      categoryId: 'c1',
      brandId: 'b1',
      basePrice: 99.5,
    ));
    expect(product.id, 'p9');
    expect(product.price, 99.5);
  });

  test('update strips slug from the payload', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/products/p1');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('slug'), isFalse);
      return http.Response(
        '{"success": true, "data": {"id": "p1", "name": "Renamed", "description": "",'
        '"basePrice": 20, "discountPrice": null, "categoryId": "c1", "brandId": "b1", "images": [],'
        '"variants": [], "rating": 0, "reviewCount": 0, "soldCount": 0, "stockThreshold": 5, "status": "active"}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final product = await repo.update(
      'p1',
      const ProductDraft(name: 'Renamed', categoryId: 'c1', brandId: 'b1', basePrice: 20),
    );
    expect(product.name, 'Renamed');
  });

  test('deactivate sends DELETE to product', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/products/p1');
      return http.Response('{"success": true, "data": {"id": "p1", "status": "inactive"}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.deactivate('p1');
  });

  test('uploadImages sends multipart with auth headers', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/products/p1/images');
      expect(request.headers['authorization'], 'Bearer tok-sm');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      final body = utf8.decode(request.bodyBytes);
      expect(body, contains('filename="dress.png"'));
      return http.Response(
        '{"success": true, "data": [{"id": "img1", "url": "/images/dress.png", "position": 0, "isPrimary": true}]}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(
      baseUrl: 'http://localhost:8080',
      token: 'tok-sm',
      client: mock,
    ));
    final images = await repo.uploadImages('p1', [
      UploadImage(bytes: [1, 2, 3, 4], filename: 'dress.png', mimeType: 'image/png'),
    ]);
    expect(images.single.isPrimary, true);
    expect(images.single.url, '/images/dress.png');
  });

  test('getImages maps image records', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/products/p1/images');
      return http.Response(
        '{"success": true, "data": [{"id": "img1", "url": "/images/a.png", "position": 0, "isPrimary": true}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final images = await repo.getImages('p1');
    expect(images.single.position, 0);
    expect(images.single.isPrimary, true);
  });

  test('setPrimaryImage patches isPrimary true', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/products/p1/images/img1');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['isPrimary'], true);
      return http.Response(
        '{"success": true, "data": {"id": "img1", "url": "/images/a.png", "position": 0, "isPrimary": true}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final image = await repo.setPrimaryImage('p1', 'img1');
    expect(image.id, 'img1');
    expect(image.isPrimary, true);
  });

  test('deleteImage sends DELETE to image record', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/products/p1/images/img1');
      return http.Response('{"success": true, "data": {"removed": true}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiProductRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.deleteImage('p1', 'img1');
  });
}