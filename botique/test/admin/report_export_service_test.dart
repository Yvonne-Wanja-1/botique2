import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/admin/reports/report_export_service.dart';

void main() {
  const data = ReportExportData(
    reportName: 'Sales Report',
    period: 'All Time',
    columns: ['Order', 'Customer', 'Total'],
    rows: [
      ['QT-2026-1041', 'Amara Okafor', 'KSh 150'],
    ],
    totalsNote: 'Orders: 1',
  );

  final service = ReportExportService();

  test('CSV contains headers, row data and totals', () {
    final csv = service.buildCsv(data);
    expect(csv, contains('Order,Customer,Total'));
    expect(csv, contains('QT-2026-1041'));
    expect(csv, contains('Amara Okafor'));
    expect(csv, contains('KSh 150'));
  });

  test('Excel file contains the report data', () {
    final bytes = service.buildExcel(data);
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Queens Touch'];
    final joined = sheet.rows
        .map((r) => r.map((c) => c?.value.toString()).join(','))
        .join('\n');
    expect(joined, contains('Order'));
    expect(joined, contains('QT-2026-1041'));
    expect(joined, contains('Amara Okafor'));
  });

  test('PDF file starts with PDF magic bytes and is non-trivial', () async {
    final bytes = await service.buildPdf(data);
    final prefix = utf8.decode(bytes.take(5).toList());
    expect(prefix, '%PDF-');
    expect(bytes.length, greaterThan(500));
  });
}