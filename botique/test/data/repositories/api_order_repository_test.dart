import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_order_repository.dart';
import 'package:botique/data/repositories/commerce_repository.dart';
import 'package:botique/models/order.dart';

void main() {
  const orderJson = '{"success": true, "data": {'
      '"id": "o1", "orderNumber": "QT-123", "customerId": "u1", "customerName": "Amara",'
      '"customerPhone": "080", "customerEmail": "a@b.c", "shippingAddress": "12 Broad St, Lagos",'
      '"subtotal": 50000, "discount": 0, "shippingFee": 2500, "total": 52500, "status": "pending",'
      '"paymentStatus": "pending", "paymentMethod": "bank_transfer", "installmentRequested": false,'
      '"createdAt": "2026-01-01T00:00:00Z",'
      '"items": [{"id": "oi1", "orderId": "o1", "productId": "p1", "variantId": "v1",'
      '"productName": "Dress", "variantLabel": null, "unitPrice": 50000, "quantity": 1, "lineTotal": 50000}],'
      '"payment": {"id": "pay1", "orderId": "o1", "customerId": "u1", "amount": 52500,'
      '"method": "bank_transfer", "status": "pending", "reference": "PAY-123", "createdAt": "2026-01-01T00:00:00Z"}}}';

  const orderJson2 = '{"id": "o1", "orderNumber": "QT-123", "customerId": "u1", "customerName": "Amara",'
      '"customerPhone": "080", "customerEmail": "a@b.c", "shippingAddress": "12 Broad St, Lagos",'
      '"subtotal": 50000, "discount": 0, "shippingFee": 2500, "total": 52500, "status": "pending",'
      '"paymentStatus": "pending", "paymentMethod": "bank_transfer", "installmentRequested": false,'
      '"createdAt": "2026-01-01T00:00:00Z", "items": [], "payment": null}';

  test('placeOrder posts checkout payload and maps the order', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/orders');
      expect(request.method, 'POST');
      final body = request.body;
      expect(body, contains('"paymentMethod":"bank_transfer"'));
      expect(body, contains('"variantId":"v1"'));
      expect(body, isNot(contains('"promotionCode"')));
      return http.Response(orderJson, 201, headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final order = await repo.placeOrder(CheckoutPayload(
      customerName: 'Amara',
      customerPhone: '080',
      customerEmail: 'a@b.c',
      shippingAddress: '12 Broad St, Lagos',
      paymentMethod: PaymentMethod.bankTransfer,
      items: [OrderItem(productId: 'p1', variantId: 'v1', productName: 'Dress', price: 50000, quantity: 1)],
    ));
    expect(order.id, 'o1');
    expect(order.total, 52500);
    expect(order.status, OrderStatus.pending);
  });

  test('getOrders maps the list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/orders');
      return http.Response('{"success": true, "data": [$orderJson2]}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final orders = await repo.getOrders();
    expect(orders, hasLength(1));
    expect(orders.first.id, 'o1');
  });
}