import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_report_repository.dart';

void main() {
  const summaryJson = '{'
      '"totalOrders": 5, "totalRevenue": 48290, "verifiedRevenue": 45000,'
      '"outstandingBalance": 3290, "avgOrderValue": 9658, "pendingOrders": 2,'
      '"todayRevenue": 1840, "todayOrders": 3,'
      '"byPaymentMethod": [{"paymentMethod": "mpesa", "orders": 4, "revenue": 40000}],'
      '"ordersByPaymentStatus": [{"paymentStatus": "paid", "orders": 4}],'
      '"daily": [{"day": "2026-08-18", "orders": 3, "revenue": 1840}]}';

  test('getSalesSummary parses the full summary and sends range query params', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reports/sales-summary');
      expect(request.url.queryParameters['from'], '2026-08-01T00:00:00.000');
      expect(request.url.queryParameters['to'], '2026-09-01T00:00:00.000');
      return http.Response(
        '{"success": true, "data": $summaryJson}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReportRepository(
      ApiClient(baseUrl: 'http://localhost:8080', client: mock),
    );
    final summary = await repo.getSalesSummary(from: '2026-08-01T00:00:00.000', to: '2026-09-01T00:00:00.000');
    expect(summary.totalOrders, 5);
    expect(summary.totalRevenue, 48290);
    expect(summary.verifiedRevenue, 45000);
    expect(summary.outstandingBalance, 3290);
    expect(summary.byPaymentMethod.single.paymentMethod, 'mpesa');
    expect(summary.ordersByPaymentStatus.single.paymentStatus, 'paid');
    expect(summary.daily.single.revenue, 1840);
  });

  test('getSalesReport maps per-order rows', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reports/sales');
      return http.Response(
        '{"success": true, "data": [{'
        '"id": "o1", "orderNumber": "QT-2026-1041", "date": "2026-08-18T10:00:00.000Z",'
        '"customerName": "Amara Okafor", "total": 149.97, "verified": 100,'
        '"remainingBalance": 49.97, "orderStatus": "delivered", "paymentStatus": "partially_paid"}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReportRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final rows = await repo.getSalesReport();
    expect(rows, hasLength(1));
    expect(rows.single.orderNumber, 'QT-2026-1041');
    expect(rows.single.customerName, 'Amara Okafor');
    expect(rows.single.remainingBalance, 49.97);
    expect(rows.single.paymentStatus, 'partially_paid');
  });

  test('getInventoryReport maps stock status per variant', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reports/inventory');
      return http.Response(
        '{"success": true, "data": [{'
        '"variantId": "v1", "productId": "p1", "productName": "Velvet Blush Blazer",'
        '"sku": "QT-502-S", "variantLabel": "S", "stockQty": 3, "stockThreshold": 5,'
        '"stockStatus": "low"}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReportRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final rows = await repo.getInventoryReport();
    expect(rows.single.sku, 'QT-502-S');
    expect(rows.single.stockQty, 3);
    expect(rows.single.stockThreshold, 5);
    expect(rows.single.isLow, isTrue);
    expect(rows.single.isOut, isFalse);
  });

  test('getCustomerSummary parses customer stats', () async {
    final mock = MockClient((request) async {
      return http.Response(
        '{"success": true, "data": {"totalCustomers": 42, "newCustomers": 5,'
        '"customersWithOrders": 20, "avgOrdersPerCustomer": 2.5,'
        '"topCustomers": [{"id": "u1", "fullName": "Amara Okafor", "email": "a@b.c",'
        '"orders": 3, "spend": 450.5}]}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReportRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final summary = await repo.getCustomerSummary();
    expect(summary.totalCustomers, 42);
    expect(summary.topCustomers.single.fullName, 'Amara Okafor');
    expect(summary.topCustomers.single.spend, 450.5);
  });

  test('getPaymentsSummary and getInstallmentsSummary parse verification data', () async {
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/reports/payments') {
        return http.Response(
          '{"success": true, "data": {"successful": 10, "totalProcessed": 10000,'
          '"pendingVerification": 2, "pendingVerificationAmount": 500, "rejected": 1,'
          '"rejectedAmount": 100, "failed": 1, "refunded": 1, "refundedAmount": 50}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(path, '/api/reports/installments');
      return http.Response(
        '{"success": true, "data": {"active": 3, "completed": 5, "pendingApproval": 2,'
        '"approved": 1, "rejected": 1, "overdue": 1, "totalValue": 30000,'
        '"totalPaid": 10000, "outstandingBalance": 20000}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReportRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final payments = await repo.getPaymentsSummary();
    expect(payments.pendingVerification, 2);
    expect(payments.pendingVerificationAmount, 500);
    final installments = await repo.getInstallmentsSummary();
    expect(installments.pendingApproval, 2);
    expect(installments.outstandingBalance, 20000);
  });
}