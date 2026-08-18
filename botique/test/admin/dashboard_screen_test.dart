import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/dashboard/dashboard_screen.dart';
import 'package:botique/data/mock/mock_report_repository.dart';
import 'package:botique/data/repositories/report_repository.dart';
import 'package:botique/models/report.dart';

MockReportRepository _seededRepo() {
  final repo = MockReportRepository();
  repo.seedSalesSummary(SalesSummary(
    totalOrders: 120,
    totalRevenue: 48290,
    verifiedRevenue: 45000,
    outstandingBalance: 3290,
    avgOrderValue: 402,
    pendingOrders: 2,
    todayRevenue: 1840,
    todayOrders: 3,
    byPaymentMethod: const [],
    ordersByPaymentStatus: const [],
    daily: const [DailyStat(day: '2026-08-18', orders: 3, revenue: 1840)],
  ));
  repo.seedCustomerSummary(const CustomerSummary(
    totalCustomers: 42,
    newCustomers: 5,
    customersWithOrders: 20,
    avgOrdersPerCustomer: 2.5,
    topCustomers: [],
  ));
  repo.seedInventorySummary(const InventorySummary(
    totalVariants: 5,
    outOfStock: 1,
    lowStock: 2,
    inStock: 2,
    totalUnits: 50,
    totalProducts: 16,
  ));
  repo.seedInventoryRows([
    InventoryRow(
      variantId: 'v1',
      productId: 'p1',
      productName: 'Velvet Blush Blazer',
      sku: 'QT-502-S',
      variantLabel: 'S',
      stockQty: 3,
      stockThreshold: 5,
      stockStatus: 'low',
    ),
    InventoryRow(
      variantId: 'v2',
      productId: 'p2',
      productName: 'Silk Garden Maxi Dress',
      sku: 'QT-503-M',
      variantLabel: 'M',
      stockQty: 0,
      stockThreshold: 4,
      stockStatus: 'out',
    ),
  ]);
  repo.seedTopProducts([
    TopProduct(id: 'p1', name: 'Velvet Matte Lipstick', quantitySold: 1500, revenue: 150000),
  ]);
  repo.seedSalesRows([
    SalesRow(
      id: 'o1',
      orderNumber: 'QT-2026-1041',
      date: DateTime(2026, 8, 18),
      customerName: 'Amara Okafor',
      total: 149.97,
      verified: 149.97,
      remainingBalance: 0,
      orderStatus: 'delivered',
      paymentStatus: 'paid',
    ),
  ]);
  repo.seedInstallmentsSummary(const InstallmentsSummary(
    active: 3,
    completed: 5,
    pendingApproval: 2,
    approved: 1,
    rejected: 1,
    overdue: 1,
    totalValue: 30000,
    totalPaid: 10000,
    outstandingBalance: 20000,
  ));
  repo.seedPaymentsSummary(const PaymentsSummary(
    successful: 10,
    totalProcessed: 10000,
    pendingVerification: 1,
    pendingVerificationAmount: 500,
    rejected: 1,
    rejectedAmount: 100,
    failed: 1,
    refunded: 1,
    refundedAmount: 50,
  ));
  return repo;
}

void main() {
  testWidgets('dashboard shows real metrics, alerts, pending cards and lists', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<ReportRepository>.value(
        value: _seededRepo(),
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KSh 48,290.00'), findsOneWidget);
    expect(find.text("KSh 1,840.00"), findsOneWidget);
    expect(find.text('Total Orders'), findsOneWidget);
    expect(find.text('Total Products'), findsOneWidget);

    expect(find.text('Low Stock Alerts'), findsOneWidget);
    expect(find.textContaining('Velvet Blush Blazer — only 3 left'), findsOneWidget);
    expect(find.textContaining('Silk Garden Maxi Dress — out of stock'), findsOneWidget);

    expect(find.text('2 installment requests awaiting approval'), findsOneWidget);
    expect(find.text('1 payment awaiting verification'), findsOneWidget);

    expect(find.text('Best Sellers'), findsOneWidget);
    expect(find.text('Velvet Matte Lipstick'), findsOneWidget);

    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('QT-2026-1041 · Amara Okafor'), findsOneWidget);
  });

  testWidgets('dashboard shows empty state when repo has no data', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<ReportRepository>.value(
        value: MockReportRepository(),
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KSh 0.00'), findsWidgets);
    expect(find.text('Low Stock Alerts'), findsNothing);
    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('No recent orders'), findsOneWidget);
  });
}