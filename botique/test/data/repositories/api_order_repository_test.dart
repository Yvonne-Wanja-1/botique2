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

  const paymentJson = '{"id": "pay1", "orderId": "o1", "customerId": "u1", "orderNumber": "QT-123",'
      '"customerName": "Amara", "amount": 52500, "method": "paybill", "status": "pending_verification",'
      '"reference": "MP-1", "paymentDate": "2026-08-17", "confirmationMessage": "Confirmed",'
      '"note": null, "verifiedAt": null, "verifiedBy": null, "rejectedAt": null, "rejectedBy": null,'
      '"rejectReason": null, "duplicateOf": null, "createdAt": "2026-08-17T10:00:00Z"}';

  const installmentJson = '{"id": "i1", "orderId": "o1", "orderNumber": "QT-123", "customerId": "u1",'
      '"customerName": "Amara", "totalAmount": 52500, "amountPaid": 0, "status": "pending_approval",'
      '"termMonths": 3, "createdAt": "2026-08-17T10:00:00Z", "payments": [],'
      '"approvedBy": null, "approvedAt": null, "rejectedBy": null, "rejectedAt": null, "rejectReason": null}';

  test('submitPayment posts to /api/payments and maps the payment', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/payments');
      expect(request.method, 'POST');
      expect(request.body, contains('"orderId":"o1"'));
      expect(request.body, contains('"amount":52500'));
      expect(request.body, contains('"paymentDate":"2026-08-17"'));
      expect(request.body, contains('"confirmationMessage":"Confirmed"'));
      return http.Response('{"success": true, "data": $paymentJson}', 201,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final p = await repo.submitPayment(const SubmitPaymentPayload(
      orderId: 'o1',
      amount: 52500,
      paymentDate: '2026-08-17',
      reference: 'MP-1',
      confirmationMessage: 'Confirmed',
    ));
    expect(p.status, PaymentStatus.pendingVerification);
    expect(p.confirmationMessage, 'Confirmed');
  });

  test('getTransferDetails returns the paybill details', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/payments/transfer-details');
      return http.Response(
          '{"success": true, "data": {"bankName": "Family Bank", "paybillNumber": "222111", "accountNumber": "65727"}}',
          200, headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final t = await repo.getTransferDetails();
    expect(t.bankName, 'Family Bank');
    expect(t.paybillNumber, '222111');
    expect(t.accountNumber, '65727');
  });

  test('getPayments calls /api/payments and maps the list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/payments');
      return http.Response('{"success": true, "data": {"rows": [$paymentJson], "total": 1}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final payments = await repo.getPayments();
    expect(payments, hasLength(1));
    expect(payments.first.id, 'pay1');
  });

  test('verifyPayment and rejectPayment call the right endpoints', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      if (request.url.path == '/api/payments/pay1/verify') {
        return http.Response('{"success": true, "data": $paymentJson}', 200,
            headers: {'content-type': 'application/json'});
      }
      expect(request.url.path, '/api/payments/pay1/reject');
      expect(request.body, contains('"reason":"fraud"'));
      return http.Response('{"success": true, "data": $paymentJson}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.verifyPayment('pay1');
    await repo.rejectPayment('pay1', reason: 'fraud');
  });

  test('getInstallments calls /api/installments and maps the list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/installments');
      return http.Response('{"success": true, "data": {"rows": [$installmentJson], "total": 1}}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final plans = await repo.getInstallments();
    expect(plans, hasLength(1));
    expect(plans.first.status, InstallmentStatus.pendingApproval);
  });

  test('approveInstallment and rejectInstallment call the right endpoints', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      if (request.url.path == '/api/installments/i1/approve') {
        return http.Response('{"success": true, "data": $installmentJson}', 200,
            headers: {'content-type': 'application/json'});
      }
      expect(request.url.path, '/api/installments/i1/reject');
      expect(request.body, contains('"reason":"No"'));
      return http.Response('{"success": true, "data": $installmentJson}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.approveInstallment('i1');
    await repo.rejectInstallment('i1', reason: 'No');
  });
}