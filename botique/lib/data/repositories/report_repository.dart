import '../../models/report.dart';

/// A selected date range. The backend applies these to its aggregation queries.
class ReportRange {
  const ReportRange({this.from, this.to, required this.label});

  final DateTime? from;
  final DateTime? to;
  final String label;

  /// ISO values sent to the backend as `from`/`to` query params.
  /// `to` is exclusive on the backend (`created_at < to`).
  Map<String, dynamic> toQuery() => {
        if (from != null) 'from': from!.toIso8601String(),
        if (to != null) 'to': to!.toIso8601String(),
      };

  static ReportRange today([DateTime? now]) {
    final start = _dayStart(now ?? DateTime.now());
    return ReportRange(from: start, to: start.add(const Duration(days: 1)), label: 'Today');
  }

  static ReportRange thisWeek([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = _dayStart(n).subtract(Duration(days: n.weekday - 1));
    return ReportRange(from: start, to: start.add(const Duration(days: 7)), label: 'This Week');
  }

  static ReportRange thisMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, 1);
    return ReportRange(
      from: start,
      to: DateTime(n.year, n.month + 1, 1),
      label: 'This Month',
    );
  }

  static const allTime = ReportRange(label: 'All Time');

  static ReportRange custom(DateTime from, DateTime to) {
    final start = _dayStart(from);
    return ReportRange(
      from: start,
      to: _dayStart(to).add(const Duration(days: 1)),
      label: 'Custom',
    );
  }

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
}

abstract class ReportRepository {
  Future<SalesSummary> getSalesSummary({String? from, String? to});
  Future<List<SalesRow>> getSalesReport({String? from, String? to});
  Future<List<TopProduct>> getTopProducts({String? from, String? to});
  Future<InventorySummary> getInventorySummary();
  Future<List<InventoryRow>> getInventoryReport();
  Future<CustomerSummary> getCustomerSummary({String? from, String? to});
  Future<OrdersSummary> getOrdersSummary({String? from, String? to});
  Future<PaymentsSummary> getPaymentsSummary({String? from, String? to});
  Future<InstallmentsSummary> getInstallmentsSummary();
}