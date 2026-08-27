import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animated_counter.dart';
import '../../core/animations/qts_animation.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/report.dart';
import 'report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _SalesData {
  const _SalesData(this.summary, this.rows);

  final SalesSummary summary;
  final List<SalesRow> rows;
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _sections = [
    'Sales',
    'Products',
    'Customers',
    'Orders',
    'Payments',
    'Installments',
  ];

  static const _rangeLabels = ['All Time', 'Today', 'This Week', 'This Month', 'Custom'];

  int _selected = 0;
  int _rangeIndex = 0;
  DateTime? _customFrom;
  DateTime? _customTo;
  late Future<Object> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  ReportRange get _range {
    switch (_rangeIndex) {
      case 1:
        return ReportRange.today();
      case 2:
        return ReportRange.thisWeek();
      case 3:
        return ReportRange.thisMonth();
      case 4:
        return ReportRange.custom(_customFrom ?? DateTime.now(), _customTo ?? DateTime.now());
      default:
        return ReportRange.allTime;
    }
  }

  bool get _supportsDateRange => _selected != 5;

  String get _customLabel {
    if (_customFrom == null || _customTo == null) return 'Custom';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(_customFrom!.month)}/${two(_customFrom!.day)} – ${two(_customTo!.month)}/${two(_customTo!.day)}';
  }

  Future<Object> _load() async {
    final repo = context.read<ReportRepository>();
    final query = _range.toQuery();
    final from = query['from'] as String?;
    final to = query['to'] as String?;
    switch (_selected) {
      case 0:
        final summary = await repo.getSalesSummary(from: from, to: to);
        final rows = await repo.getSalesReport(from: from, to: to);
        return _SalesData(summary, rows);
      case 1:
        return repo.getTopProducts(from: from, to: to);
      case 2:
        return repo.getCustomerSummary(from: from, to: to);
      case 3:
        return repo.getOrdersSummary(from: from, to: to);
      case 4:
        return repo.getPaymentsSummary(from: from, to: to);
      default:
        return repo.getInstallmentsSummary();
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customFrom ?? now.subtract(const Duration(days: 30)),
        end: _customTo ?? now,
      ),
    );
    if (picked == null) return;
    setState(() {
      _customFrom = picked.start;
      _customTo = picked.end;
      _rangeIndex = 4;
      _future = _load();
    });
  }

  Future<void> _export(String format) async {
    final service = ReportExportService();
    late final ReportExportData data;
    try {
      final loaded = await _future;
      switch (_selected) {
        case 0:
          final sales = loaded as _SalesData;
          data = service.salesData(sales.summary, sales.rows, _range.label);
        case 1:
          data = service.productsData(loaded as List<TopProduct>, _range.label);
        case 2:
          data = service.customersData(loaded as CustomerSummary, _range.label);
        case 3:
          data = service.ordersData(loaded as OrdersSummary, _range.label);
        case 4:
          data = service.paymentsData(loaded as PaymentsSummary, _range.label);
        default:
          data = service.installmentsData(loaded as InstallmentsSummary, _range.label);
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Report data could not be loaded.');
      return;
    }

    final extension = format.toLowerCase();
    final fileName = 'queens-touch-${_sections[_selected].toLowerCase()}-report';
    final List<int> bytes;
    final MimeType mimeType;
    try {
      switch (format) {
        case 'CSV':
          bytes = const Utf8Encoder().convert(service.buildCsv(data));
          mimeType = MimeType.csv;
          break;
        case 'Excel':
          bytes = service.buildExcel(data);
          mimeType = MimeType.microsoftExcel;
          break;
        default:
          bytes = await service.buildPdf(data);
          mimeType = MimeType.pdf;
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Failed to generate $format file.');
      return;
    }

    try {
      final path = await service.save(
        fileName: fileName,
        fileExtension: extension,
        bytes: bytes,
        mimeType: mimeType,
      );
      if (mounted) showSuccessSnack(context, '$format saved to $path');
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not save $format file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _sections.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_sections[i]),
                            selected: _selected == i,
                            onSelected: (_) {
                              setState(() => _selected = i);
                              _reload();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Export',
                onSelected: _export,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
                  PopupMenuItem(value: 'Excel', child: Text('Export as Excel')),
                  PopupMenuItem(value: 'CSV', child: Text('Export as CSV')),
                ],
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ),
        if (_supportsDateRange)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < _rangeLabels.length; i++)
                    ChoiceChip(
                      label: Text(i == 4 ? _customLabel : _rangeLabels[i]),
                      selected: _rangeIndex == i,
                      onSelected: (_) {
                        if (i == 4) {
                          _pickCustomRange();
                        } else {
                          setState(() => _rangeIndex = i);
                          _reload();
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: QtMotion.reduceMotion(context) ? Duration.zero : QtMotion.normal,
            child: KeyedSubtree(
              key: ValueKey('$_selected-$_rangeIndex'),
              child: _buildBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<Object>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load report',
            message: snapshot.error.toString(),
            action: OutlinedButton(onPressed: _reload, child: const Text('Retry')),
          );
        }
        final data = snapshot.data;
        switch (_selected) {
          case 0:
            return _salesBody((data as _SalesData));
          case 1:
            return _productsBody(data as List<TopProduct>);
          case 2:
            return _customersBody(data as CustomerSummary);
          case 3:
            return _ordersBody(data as OrdersSummary);
          case 4:
            return _paymentsBody(data as PaymentsSummary);
          default:
            return _installmentsBody(data as InstallmentsSummary);
        }
      },
    );
  }

  Widget _salesBody(_SalesData data) {
    final summary = data.summary;
    if (summary.totalOrders == 0 && data.rows.isEmpty) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid([
          ('Total Revenue', AnimatedCounter(value: summary.totalRevenue, format: formatKsh)),
          ('Verified Revenue', AnimatedCounter(value: summary.verifiedRevenue, format: formatKsh)),
          ('Total Orders', AnimatedCounter(value: summary.totalOrders.toDouble(), format: (v) => v.round().toString())),
          ('Outstanding Balance', AnimatedCounter(value: summary.outstandingBalance, format: formatKsh)),
          ('Avg Order Value', AnimatedCounter(value: summary.avgOrderValue, format: formatKsh)),
          ('Pending Orders', AnimatedCounter(value: summary.pendingOrders.toDouble(), format: (v) => v.round().toString())),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Sales',
          subtitle: '${_range.label} orders',
          child: data.rows.isEmpty
              ? const EmptyState(icon: Icons.receipt_long, title: 'No data available for this period.')
              : Column(
                  children: [
                    for (final row in data.rows)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${row.orderNumber} · ${row.customerName}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${row.orderStatus} · ${row.paymentStatus}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          formatKsh(row.total),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _productsBody(List<TopProduct> products) {
    if (products.isEmpty) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Top Selling Products',
          subtitle: '${_range.label} — by quantity sold',
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: QueensTouchColors.blushLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          products[i].name,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${products[i].quantitySold} sold · ${formatKsh(products[i].revenue)}',
                        style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customersBody(CustomerSummary summary) {
    if (summary.totalCustomers == 0) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid([
          ('Total Customers', summary.totalCustomers.toString()),
          ('New Customers', summary.newCustomers.toString()),
          ('Customers With Orders', summary.customersWithOrders.toString()),
          ('Avg Orders / Customer', summary.avgOrdersPerCustomer.toStringAsFixed(1)),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Top Customers',
          subtitle: '${_range.label} — by spend',
          child: summary.topCustomers.isEmpty
              ? const EmptyState(icon: Icons.people_outline, title: 'No data available for this period.')
              : Column(
                  children: [
                    for (final c in summary.topCustomers)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: QueensTouchColors.blushLight,
                          child: Text(
                            c.fullName.isNotEmpty ? c.fullName[0] : '?',
                            style: const TextStyle(color: QueensTouchColors.plum, fontSize: 14),
                          ),
                        ),
                        title: Text(
                          c.fullName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(c.email, style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${c.orders} orders · ${formatKsh(c.spend)}',
                          style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _ordersBody(OrdersSummary summary) {
    if (summary.totalOrders == 0) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid([
          ('Total Orders', summary.totalOrders.toString()),
          ('Total Revenue', formatKsh(summary.totalRevenue)),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Orders by Status',
          subtitle: _range.label,
          child: Column(
            children: [
              for (final s in summary.byStatus)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Text(
                    '${s.count} · ${formatKsh(s.revenue)}',
                    style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Orders by Payment Status',
          subtitle: _range.label,
          child: Column(
            children: [
              for (final s in summary.byPaymentStatus)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.paymentStatus, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Text('${s.orders}', style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentsBody(PaymentsSummary summary) {
    final hasData = summary.successful != 0 ||
        summary.pendingVerification != 0 ||
        summary.rejected != 0 ||
        summary.failed != 0 ||
        summary.refunded != 0;
    if (!hasData) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid([
          ('Successful', summary.successful.toString()),
          ('Processed Amount', formatKsh(summary.totalProcessed)),
          ('Pending Verification', summary.pendingVerification.toString()),
          ('Pending Amount', formatKsh(summary.pendingVerificationAmount)),
          ('Rejected', summary.rejected.toString()),
          ('Failed', summary.failed.toString()),
        ]),
        const SizedBox(height: 16),
        _MetricGrid([
          ('Refunded', summary.refunded.toString()),
          ('Refunded Amount', formatKsh(summary.refundedAmount)),
        ]),
      ],
    );
  }

  Widget _installmentsBody(InstallmentsSummary summary) {
    final hasData = summary.totalValue != 0 || summary.active != 0;
    if (!hasData) {
      return const _NoData();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid([
          ('Active', summary.active.toString()),
          ('Completed', summary.completed.toString()),
          ('Pending Approval', summary.pendingApproval.toString()),
          ('Approved', summary.approved.toString()),
          ('Rejected', summary.rejected.toString()),
          ('Overdue', summary.overdue.toString()),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Balances',
          subtitle: 'Across all installment plans',
          child: Column(
            children: [
              for (final (label, value) in [
                ('Total Value', formatKsh(summary.totalValue)),
                ('Paid So Far', formatKsh(summary.totalPaid)),
                ('Outstanding Balance', formatKsh(summary.outstandingBalance)),
              ])
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Text(
                    value,
                    style: TextStyle(fontSize: 13, color: QueensTouchColors.plum, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.insert_chart_outlined,
      title: 'No data available for this period.',
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid(this.metrics);

  final List<(String, Object)> metrics;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: QueensTouchColors.plum,
        );
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final (label, value) = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: valueStyle ?? const TextStyle(),
                  child: value is Widget ? value : Text(value.toString()),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: QueensTouchColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}