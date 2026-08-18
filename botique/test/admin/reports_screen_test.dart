import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/reports/reports_screen.dart';
import 'package:botique/data/mock/mock_report_repository.dart';
import 'package:botique/data/repositories/report_repository.dart';
import 'package:botique/models/report.dart';

MockReportRepository _seededRepo() {
  final repo = MockReportRepository();
  repo.seedSalesSummary(SalesSummary(
    totalOrders: 5,
    totalRevenue: 48290,
    verifiedRevenue: 45000,
    outstandingBalance: 3290,
    avgOrderValue: 9658,
    pendingOrders: 2,
    todayRevenue: 1840,
    todayOrders: 3,
    byPaymentMethod: const [],
    ordersByPaymentStatus: const [],
    daily: const [],
  ));
  repo.seedSalesRows([
    SalesRow(
      id: 'o1',
      orderNumber: 'QT-2026-1041',
      date: DateTime(2026, 1, 10),
      customerName: 'Amara Okafor',
      total: 149.97,
      verified: 149.97,
      remainingBalance: 0,
      orderStatus: 'delivered',
      paymentStatus: 'paid',
    ),
  ]);
  repo.seedTopProducts([
    TopProduct(id: 'p1', name: 'Velvet Matte Lipstick', quantitySold: 1500, revenue: 150000),
  ]);
  repo.seedCustomerSummary(const CustomerSummary(
    totalCustomers: 42,
    newCustomers: 5,
    customersWithOrders: 20,
    avgOrdersPerCustomer: 2.5,
    topCustomers: [],
  ));
  repo.seedOrdersSummary(OrdersSummary(
    totalOrders: 5,
    totalRevenue: 48290,
    byStatus: const [OrderStatusStat(status: 'delivered', count: 3, revenue: 30000)],
    byPaymentStatus: const [PaymentStatusStat(paymentStatus: 'paid', orders: 4)],
  ));
  repo.seedPaymentsSummary(const PaymentsSummary(
    successful: 10,
    totalProcessed: 10000,
    pendingVerification: 2,
    pendingVerificationAmount: 500,
    rejected: 1,
    rejectedAmount: 100,
    failed: 1,
    refunded: 1,
    refundedAmount: 50,
  ));
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
  return repo;
}

Widget _wrap(ReportRepository repo) {
  return Provider<ReportRepository>.value(
    value: repo,
    child: const MaterialApp(home: Scaffold(body: ReportsScreen())),
  );
}

void main() {
  testWidgets('Sales tab shows real metrics and order rows', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_seededRepo()));
    await tester.pumpAndSettle();

    expect(find.text('KSh 48,290.00'), findsOneWidget);
    expect(find.text('Total Orders'), findsOneWidget);
    expect(find.text('QT-2026-1041 · Amara Okafor'), findsOneWidget);
  });

  testWidgets('switching to Products tab shows real top products', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_seededRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    expect(find.text('Top Selling Products'), findsOneWidget);
    expect(find.text('Velvet Matte Lipstick'), findsOneWidget);
    expect(find.text('1500 sold · KSh 150,000.00'), findsOneWidget);
  });

  testWidgets('Installments tab hides date filter and shows real values', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_seededRepo()));
    await tester.pumpAndSettle();

    expect(find.text('All Time'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Installments'),
      find.byType(ListView).first,
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Installments'));
    await tester.pumpAndSettle();

    expect(find.text('All Time'), findsNothing);
    expect(find.text('KSh 20,000.00'), findsOneWidget);
    expect(find.text('Outstanding Balance'), findsOneWidget);
  });

  testWidgets('date filter chips reload data when a range is selected', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_seededRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('This Month'));
    await tester.pumpAndSettle();

    expect(find.text('KSh 48,290.00'), findsOneWidget);
  });

  testWidgets('shows empty state when there is no data', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(MockReportRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No data available for this period.'), findsOneWidget);
  });
}