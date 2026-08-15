import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_cart_repository.dart';
import 'package:botique/models/product.dart';
import 'package:botique/models/cart.dart';

void main() {
  const cartJson = '{"success": true, "data": {"items": [{'
      '"id": "ci1", "productId": "p1", "variantId": "v1", "name": "Dress",'
      '"size": "M", "color": null, "shade": null, "imageUrl": "http://i/x.jpg",'
      '"quantity": 2, "unitPrice": 25000}], "subtotal": 50000, "total": 50000}}';

  test('getItems maps cart view', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/cart');
      return http.Response(cartJson, 200, headers: {'content-type': 'application/json'});
    });
    final repo = ApiCartRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final items = await repo.getItems();
    expect(items, hasLength(1));
    expect(items.first.quantity, 2);
    expect(items.first.product.name, 'Dress');
    expect(items.first.variant?.id, 'v1');
    expect(items.first.lineTotal, 50000);
  });

  test('add posts the correct body', () async {
    final mock = MockClient((request) async {
      if (request.url.path == '/api/cart/items') {
        expect(request.method, 'POST');
        expect(request.body, contains('"variantId":"v1"'));
        return http.Response(cartJson, 201, headers: {'content-type': 'application/json'});
      }
      return http.Response(cartJson, 200, headers: {'content-type': 'application/json'});
    });
    final repo = ApiCartRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.add(CartItem(
      product: const Product(id: 'p1', name: 'Dress', description: 'd', price: 25000, categoryId: 'c', brandId: 'b', images: []),
      variant: const ProductVariant(id: 'v1', quantity: 5),
      quantity: 1,
    ));
  });

  test('updateQuantity looks up cache and patches the item', () async {
    var called = false;
    final mock = MockClient((request) async {
      if (request.url.path == '/api/cart' && request.method == 'GET') {
        return http.Response(cartJson, 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path == '/api/cart/items/ci1' && request.method == 'PATCH') {
        called = true;
        expect(request.body, contains('"quantity":5'));
        return http.Response(cartJson, 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('{"success": true, "data": {"items": []}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiCartRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.getItems();
    await repo.updateQuantity('p1', 5, variantId: 'v1');
    expect(called, isTrue);
  });

  test('remove looks up cache and deletes the item', () async {
    var called = false;
    final mock = MockClient((request) async {
      if (request.url.path == '/api/cart' && request.method == 'GET') {
        return http.Response(cartJson, 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path == '/api/cart/items/ci1' && request.method == 'DELETE') {
        called = true;
        return http.Response('{"success": true, "data": {"items": []}}', 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{"success": true, "data": {"items": []}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiCartRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.getItems();
    await repo.remove('p1', variantId: 'v1');
    expect(called, isTrue);
  });

  test('clear deletes the cart', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/cart');
      expect(request.method, 'DELETE');
      return http.Response('{"success": true, "data": {"items": []}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiCartRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.clear();
  });
}