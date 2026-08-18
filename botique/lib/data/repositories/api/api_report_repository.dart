import '../../api/api_client.dart';
import '../../../models/report.dart';
import '../report_repository.dart';

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._client);

  final ApiClient _client;

  @override
  Future<SalesSummary> getSalesSummary({String? from, String? to}) async {
    final data = await _client.get('/api/reports/sales-summary', query: {'from': from, 'to': to});
    return SalesSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<SalesRow>> getSalesReport({String? from, String? to}) async {
    final data = await _client.get('/api/reports/sales', query: {'from': from, 'to': to});
    return (data as List<dynamic>)
        .map((e) => SalesRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TopProduct>> getTopProducts({String? from, String? to}) async {
    final data = await _client.get('/api/reports/top-products', query: {'from': from, 'to': to});
    return (data as List<dynamic>)
        .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InventorySummary> getInventorySummary() async {
    final data = await _client.get('/api/reports/inventory-summary');
    return InventorySummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<InventoryRow>> getInventoryReport() async {
    final data = await _client.get('/api/reports/inventory');
    return (data as List<dynamic>)
        .map((e) => InventoryRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CustomerSummary> getCustomerSummary({String? from, String? to}) async {
    final data = await _client.get('/api/reports/customer-summary', query: {'from': from, 'to': to});
    return CustomerSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<OrdersSummary> getOrdersSummary({String? from, String? to}) async {
    final data = await _client.get('/api/reports/orders', query: {'from': from, 'to': to});
    return OrdersSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PaymentsSummary> getPaymentsSummary({String? from, String? to}) async {
    final data = await _client.get('/api/reports/payments', query: {'from': from, 'to': to});
    return PaymentsSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<InstallmentsSummary> getInstallmentsSummary() async {
    final data = await _client.get('/api/reports/installments');
    return InstallmentsSummary.fromJson(data as Map<String, dynamic>);
  }
}