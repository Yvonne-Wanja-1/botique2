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
      expect(request.url.path, '/api/products/p1/reviews');
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
}