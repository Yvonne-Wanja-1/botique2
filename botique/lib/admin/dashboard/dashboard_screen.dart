import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animated_bar_chart.dart';
import '../../core/animations/animated_counter.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardData {
  const _DashboardData({
    required this.sales,
    required this.customers,
    required this.inventory,
    required this.inventoryRows,
    required this.bestSellers,
    required this.recentOrders,
    required this.installments,
    required this.payments,
  });

  final SalesSummary sales;
  final CustomerSummary customers;
  final InventorySummary inventory;
  final List<InventoryRow> inventoryRows;
  final List<TopProduct> bestSellers;
  final List<SalesRow> recentOrders;
  final InstallmentsSummary installments;
  final PaymentsSummary payments;
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final repo = context.read<ReportRepository>();
    final results = await Future.wait([
      repo.getSalesSummary(),
      repo.getCustomerSummary(),
      repo.getInventorySummary(),
      repo.getInventoryReport(),
      repo.getTopProducts(),
      repo.getSalesReport(),
      repo.getInstallmentsSummary(),
      repo.getPaymentsSummary(),
    ]);
    return _DashboardData(
      sales: results[0] as SalesSummary,
      customers: results[1] as CustomerSummary,
      inventory: results[2] as InventorySummary,
      inventoryRows: results[3] as List<InventoryRow>,
      bestSellers: results[4] as List<TopProduct>,
      recentOrders: results[5] as List<SalesRow>,
      installments: results[6] as InstallmentsSummary,
      payments: results[7] as PaymentsSummary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load dashboard',
            message: snapshot.error.toString(),
            action: OutlinedButton(
              onPressed: () => setState(() => _future = _load()),
              child: const Text('Retry'),
            ),
          );
        }
        return _buildBody(snapshot.data!);
      },
    );
  }

  Widget _buildBody(_DashboardData data) {
    final sales = data.sales;
    final statCards = [
      StatCard(
        label: 'Total Revenue',
        value: sales.totalRevenue,
        format: formatKsh,
        icon: Icons.attach_money,
        color: QueensTouchColors.success,
      ),
      StatCard(label: "Today's Sales", value: sales.todayRevenue, format: formatKsh, icon: Icons.today, color: QueensTouchColors.plum),
      StatCard(label: 'Total Orders', value: sales.totalOrders.toDouble(), format: (v) => v.round().toString(), icon: Icons.receipt_long, color: QueensTouchColors.plumLight),
      StatCard(label: 'Total Customers', value: data.customers.totalCustomers.toDouble(), format: (v) => v.round().toString(), icon: Icons.people, color: QueensTouchColors.warning),
      StatCard(label: 'Total Products', value: data.inventory.totalProducts.toDouble(), format: (v) => v.round().toString(), icon: Icons.inventory_2, color: QueensTouchColors.gold),
      StatCard(label: 'Pending Orders', value: sales.pendingOrders.toDouble(), format: (v) => v.round().toString(), icon: Icons.pending_actions, color: QueensTouchColors.warning),
      StatCard(label: 'Low Stock', value: data.inventory.lowStock.toDouble(), format: (v) => v.round().toString(), icon: Icons.warning_amber, color: QueensTouchColors.danger),
      StatCard(label: 'Out of Stock', value: data.inventory.outOfStock.toDouble(), format: (v) => v.round().toString(), icon: Icons.block, color: QueensTouchColors.danger),
    ];

    final lowStockItems = <String>[
      for (final row in data.inventoryRows)
        if (row.isOut)
          '${row.productName} — out of stock'
        else if (row.isLow)
          '${row.productName} — only ${row.stockQty} left',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Welcome back!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Here is what\'s happening at Queens\' Touch today.',
          style: TextStyle(color: QueensTouchColors.textMuted),
        ),
        const SizedBox(height: 20),
        _StatsGrid(stats: statCards),
        const SizedBox(height: 20),
        if (lowStockItems.isNotEmpty) ...[
          _AlertCard(
            title: 'Low Stock Alerts',
            icon: Icons.warning_amber,
            color: QueensTouchColors.warning,
            items: lowStockItems,
          ),
          const SizedBox(height: 16),
        ],
        if (data.installments.pendingApproval > 0) ...[
          _PendingCard(count: data.installments.pendingApproval, onTap: () {}),
          const SizedBox(height: 16),
        ],
        if (data.payments.pendingVerification > 0) ...[
          _PendingCard(
            count: data.payments.pendingVerification,
            message: 'payment',
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _SalesTrendChart(daily: sales.daily),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: data.bestSellers.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: EmptyState(icon: Icons.star_outline, title: 'No best sellers yet'),
                      ),
                    )
                  : BestSellers(products: data.bestSellers),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RecentOrders(orders: data.recentOrders),
      ],
    );
  }
}

class StatCard {
  const StatCard({
    required this.label,
    required this.value,
    required this.format,
    required this.icon,
    required this.color,
    this.trend,
  });

  final String label;
  final double value;
  final String Function(double) format;
  final IconData icon;
  final Color color;
  final String? trend;
}

class BestSeller {
  const BestSeller({required this.name, required this.sold});

  final String name;
  final int sold;
}

class RecentOrder {
  const RecentOrder({
    required this.orderNumber,
    required this.customer,
    required this.total,
    required this.status,
  });

  final String orderNumber;
  final String customer;
  final double total;
  final String status;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<StatCard> stats;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.isMobile(context) ? 2 : (Responsive.isDesktop(context) ? 4 : 3);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cardWidth,
                child: _StatTile(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final StatCard stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 20),
                ),
                const Spacer(),
                if (stat.trend != null)
                  Text(
                    stat.trend!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: stat.trend!.startsWith('+')
                          ? QueensTouchColors.success
                          : QueensTouchColors.danger,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCounter(
              value: stat.value,
              format: stat.format,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              stat.label,
              style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${items.length}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $item', style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.count, required this.onTap, this.message = 'installment request'});

  final int count;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plural = count == 1 ? '' : 's';
    return Card(
      color: QueensTouchColors.blushLight,
      child: ListTile(
        leading: const Icon(Icons.pending_actions, color: QueensTouchColors.plum),
        title: Text(
          '$count $message$plural awaiting ${message == 'payment' ? 'verification' : 'approval'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.daily});

  final List<DailyStat> daily;

  @override
  Widget build(BuildContext context) {
    final recent = daily.length > 7 ? daily.sublist(0, 7).reversed.toList() : daily.reversed.toList();
    final trend = recent.map((d) => d.revenue).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Last 7 days', style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            if (trend.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'No sales yet',
                    style: TextStyle(color: QueensTouchColors.textMuted, fontSize: 12),
                  ),
                ),
              )
            else
              AnimatedBarChart(
                values: trend,
                labels: [for (var i = 1; i <= trend.length; i++) '$i'],
                height: 120,
                barRadius: 4,
              ),
          ],
        ),
      ),
    );
  }
}

class BestSellers extends StatelessWidget {
  const BestSellers({super.key, required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best Sellers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
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
                      '${products[i].quantitySold} sold',
                      style: TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RecentOrders extends StatelessWidget {
  const RecentOrders({super.key, required this.orders});

  final List<SalesRow> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const EmptyState(icon: Icons.receipt_long, title: 'No recent orders')
            else
              for (final order in orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: QueensTouchColors.blushLight,
                    child: Text(
                      order.customerName.isNotEmpty ? order.customerName[0] : '?',
                      style: const TextStyle(color: QueensTouchColors.plum, fontSize: 14),
                    ),
                  ),
                  title: Text(
                    '${order.orderNumber} · ${order.customerName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    formatKsh(order.total),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    _titleCase(order.orderStatus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(order.orderStatus),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String _titleCase(String status) =>
      status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);

  static Color _statusColor(String status) => switch (status) {
        'delivered' => QueensTouchColors.success,
        'pending' => QueensTouchColors.warning,
        'processing' => QueensTouchColors.plumLight,
        'cancelled' => QueensTouchColors.danger,
        _ => QueensTouchColors.textMuted,
      };
}