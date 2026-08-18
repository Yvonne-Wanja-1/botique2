import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/currency.dart';
import '../../models/report.dart';

/// Generic tabular data that can be rendered to CSV, Excel, or PDF.
class ReportExportData {
  const ReportExportData({
    required this.reportName,
    required this.period,
    required this.columns,
    required this.rows,
    this.totalsNote,
  });

  final String reportName;
  final String period;
  final List<String> columns;
  final List<List<Object?>> rows;
  final String? totalsNote;
}

/// Builds real CSV / Excel / PDF export files from report data and saves
/// them through the platform save dialog.
class ReportExportService {
  String buildCsv(ReportExportData data) {
    return const CsvEncoder().convert([
      data.columns,
      for (final row in data.rows) row.map((cell) => cell?.toString() ?? '').toList(),
    ]);
  }

  List<int> buildExcel(ReportExportData data) {
    final excel = Excel.createExcel();
    final sheet = excel['Queens Touch'];
    sheet.appendRow([for (final c in data.columns) TextCellValue(c)]);
    for (final row in data.rows) {
      sheet.appendRow([for (final cell in row) _excelCell(cell)]);
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook');
    }
    return bytes;
  }

  Future<Uint8List> buildPdf(ReportExportData data) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            "Queens' Touch",
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.reportName,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Period: ${data.period}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Generated: ${_nowString()}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: data.columns,
            data: [
              for (final row in data.rows) row.map((cell) => cell?.toString() ?? '').toList(),
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellPadding: const pw.EdgeInsets.all(4),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
          if (data.totalsNote != null) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              data.totalsNote!,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  /// Saves [bytes] via the platform file picker and returns the chosen path.
  Future<String> save({
    required String fileName,
    required String fileExtension,
    required List<int> bytes,
    required MimeType mimeType,
  }) {
    return FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }

  static CellValue? _excelCell(Object? value) {
    if (value == null) return null;
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value.toString());
  }

  static String _nowString() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.year)}-${two(n.month)}-${two(n.day)} ${two(n.hour)}:${two(n.minute)}';
  }

  static String _money(double v) => formatKsh(v);

  static String _date(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.year)}-${two(d.month)}-${two(d.day)}';
  }

  static String _int(int v) => v.toString();

  ReportExportData salesData(SalesSummary summary, List<SalesRow> rows, String period) {
    return ReportExportData(
      reportName: 'Sales Report',
      period: period,
      columns: const ['Order', 'Date', 'Customer', 'Total', 'Verified', 'Balance', 'Order Status', 'Payment Status'],
      rows: [
        for (final r in rows)
          [
            r.orderNumber,
            _date(r.date),
            r.customerName,
            _money(r.total),
            _money(r.verified),
            _money(r.remainingBalance),
            r.orderStatus,
            r.paymentStatus,
          ],
      ],
      totalsNote: 'Orders: ${_int(summary.totalOrders)} · Total: ${_money(summary.totalRevenue)} · '
          'Verified: ${_money(summary.verifiedRevenue)} · Outstanding: ${_money(summary.outstandingBalance)}',
    );
  }

  ReportExportData productsData(List<TopProduct> products, String period) {
    return ReportExportData(
      reportName: 'Top Products Report',
      period: period,
      columns: const ['Product', 'Quantity Sold', 'Revenue'],
      rows: [
        for (final p in products) [p.name, _int(p.quantitySold), _money(p.revenue)],
      ],
      totalsNote: '${_int(products.length)} products shown for $period.',
    );
  }

  ReportExportData customersData(CustomerSummary summary, String period) {
    return ReportExportData(
      reportName: 'Customers Report',
      period: period,
      columns: const ['Customer', 'Email', 'Orders', 'Total Spend'],
      rows: [
        for (final c in summary.topCustomers)
          [c.fullName, c.email, _int(c.orders), _money(c.spend)],
      ],
      totalsNote: 'Customers: ${_int(summary.totalCustomers)} · With orders: '
          '${_int(summary.customersWithOrders)} · Avg orders/customer: '
          '${summary.avgOrdersPerCustomer.toStringAsFixed(2)}',
    );
  }

  ReportExportData ordersData(OrdersSummary summary, String period) {
    final paymentBreakdown = summary.byPaymentStatus
        .map((s) => '${s.paymentStatus}: ${_int(s.orders)}')
        .join(', ');
    return ReportExportData(
      reportName: 'Orders Report',
      period: period,
      columns: const ['Status', 'Orders', 'Revenue'],
      rows: [
        for (final s in summary.byStatus) [s.status, _int(s.count), _money(s.revenue)],
      ],
      totalsNote: 'Orders: ${_int(summary.totalOrders)} · Revenue: ${_money(summary.totalRevenue)}'
          '${paymentBreakdown.isEmpty ? '' : '\nPayment status — $paymentBreakdown'}',
    );
  }

  ReportExportData paymentsData(PaymentsSummary summary, String period) {
    return ReportExportData(
      reportName: 'Payments Report',
      period: period,
      columns: const ['Status', 'Count', 'Amount'],
      rows: [
        ['Successful', _int(summary.successful), _money(summary.totalProcessed)],
        ['Pending Verification', _int(summary.pendingVerification), _money(summary.pendingVerificationAmount)],
        ['Rejected', _int(summary.rejected), _money(summary.rejectedAmount)],
        ['Failed', _int(summary.failed), _money(0)],
        ['Refunded', _int(summary.refunded), _money(summary.refundedAmount)],
      ],
      totalsNote: 'Processed: ${_money(summary.totalProcessed)} · Pending verification: '
          '${_money(summary.pendingVerificationAmount)}',
    );
  }

  ReportExportData installmentsData(InstallmentsSummary summary, String period) {
    return ReportExportData(
      reportName: 'Installments Report',
      period: period,
      columns: const ['Status', 'Count'],
      rows: [
        ['Pending Approval', _int(summary.pendingApproval)],
        ['Approved', _int(summary.approved)],
        ['Active', _int(summary.active)],
        ['Completed', _int(summary.completed)],
        ['Rejected', _int(summary.rejected)],
        ['Overdue', _int(summary.overdue)],
      ],
      totalsNote: 'Total value: ${_money(summary.totalValue)} · Paid: ${_money(summary.totalPaid)} · '
          'Outstanding: ${_money(summary.outstandingBalance)}',
    );
  }
}