import '../../models/report.dart';
import '../repositories/report_repository.dart';

class MockReportRepository implements ReportRepository {
  SalesSummary _salesSummary = SalesSummary(
    totalOrders: 0,
    totalRevenue: 0,
    verifiedRevenue: 0,
    outstandingBalance: 0,
    avgOrderValue: 0,
    pendingOrders: 0,
    todayRevenue: 0,
    todayOrders: 0,
    byPaymentMethod: const [],
    ordersByPaymentStatus: const [],
    daily: const [],
  );
  List<SalesRow> _salesRows = const [];
  List<TopProduct> _topProducts = const [];
  InventorySummary _inventorySummary = const InventorySummary(
    totalVariants: 0,
    outOfStock: 0,
    lowStock: 0,
    inStock: 0,
    totalUnits: 0,
    totalProducts: 0,
  );
  List<InventoryRow> _inventoryRows = const [];
  CustomerSummary _customerSummary = const CustomerSummary(
    totalCustomers: 0,
    newCustomers: 0,
    customersWithOrders: 0,
    avgOrdersPerCustomer: 0,
    topCustomers: [],
  );
  OrdersSummary _ordersSummary = const OrdersSummary(
    totalOrders: 0,
    totalRevenue: 0,
    byStatus: [],
    byPaymentStatus: [],
  );
  PaymentsSummary _paymentsSummary = const PaymentsSummary(
    successful: 0,
    totalProcessed: 0,
    pendingVerification: 0,
    pendingVerificationAmount: 0,
    rejected: 0,
    rejectedAmount: 0,
    failed: 0,
    refunded: 0,
    refundedAmount: 0,
  );
  InstallmentsSummary _installmentsSummary = const InstallmentsSummary(
    active: 0,
    completed: 0,
    pendingApproval: 0,
    approved: 0,
    rejected: 0,
    overdue: 0,
    totalValue: 0,
    totalPaid: 0,
    outstandingBalance: 0,
  );

  void seedSalesSummary(SalesSummary summary) => _salesSummary = summary;
  void seedSalesRows(List<SalesRow> rows) => _salesRows = rows;
  void seedTopProducts(List<TopProduct> products) => _topProducts = products;
  void seedInventorySummary(InventorySummary summary) => _inventorySummary = summary;
  void seedInventoryRows(List<InventoryRow> rows) => _inventoryRows = rows;
  void seedCustomerSummary(CustomerSummary summary) => _customerSummary = summary;
  void seedOrdersSummary(OrdersSummary summary) => _ordersSummary = summary;
  void seedPaymentsSummary(PaymentsSummary summary) => _paymentsSummary = summary;
  void seedInstallmentsSummary(InstallmentsSummary summary) => _installmentsSummary = summary;

  @override
  Future<SalesSummary> getSalesSummary({String? from, String? to}) async => _salesSummary;

  @override
  Future<List<SalesRow>> getSalesReport({String? from, String? to}) async => _salesRows;

  @override
  Future<List<TopProduct>> getTopProducts({String? from, String? to}) async => _topProducts;

  @override
  Future<InventorySummary> getInventorySummary() async => _inventorySummary;

  @override
  Future<List<InventoryRow>> getInventoryReport() async => _inventoryRows;

  @override
  Future<CustomerSummary> getCustomerSummary({String? from, String? to}) async => _customerSummary;

  @override
  Future<OrdersSummary> getOrdersSummary({String? from, String? to}) async => _ordersSummary;

  @override
  Future<PaymentsSummary> getPaymentsSummary({String? from, String? to}) async => _paymentsSummary;

  @override
  Future<InstallmentsSummary> getInstallmentsSummary() async => _installmentsSummary;
}