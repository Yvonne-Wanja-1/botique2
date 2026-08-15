import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/mock/mock_dashboard_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockDashboardData();

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
        _StatsGrid(stats: data.statCards),
        const SizedBox(height: 20),
        if (data.lowStock.isNotEmpty) ...[
          _AlertCard(
            title: 'Low Stock Alerts',
            icon: Icons.warning_amber,
            color: QueensTouchColors.warning,
            items: data.lowStock,
          ),
          const SizedBox(height: 16),
        ],
        if (data.pendingInstallments > 0) ...[
          _PendingCard(
            count: data.pendingInstallments,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _SalesTrendChart(trend: data.salesTrend),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BestSellers(products: data.bestSellers),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RecentOrders(orders: data.recentOrders),
      ],
    );
  }
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
            Text(
              stat.value,
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
  const _PendingCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: QueensTouchColors.blushLight,
      child: ListTile(
        leading: const Icon(Icons.pending_actions, color: QueensTouchColors.plum),
        title: Text(
          '$count installment request${count == 1 ? '' : 's'} awaiting approval',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.trend});

  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    final max = trend.isEmpty ? 1.0 : trend.reduce((a, b) => a > b ? a : b);
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
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < trend.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                height: trend[i] / max * 100,
                                decoration: BoxDecoration(
                                  color: i == trend.length - 1
                                      ? QueensTouchColors.plum
                                      : QueensTouchColors.plumLight.withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${i + 1}',
                              style: TextStyle(fontSize: 10, color: QueensTouchColors.textMuted),
                            ),
                          ],
                        ),
                      ),
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

class BestSellers extends StatelessWidget {
  const BestSellers({required this.products});

  final List<BestSeller> products;

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
                      '${products[i].sold} sold',
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
  const RecentOrders({required this.orders});

  final List<RecentOrder> orders;

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
                      order.customer.characters.first,
                      style: const TextStyle(color: QueensTouchColors.plum, fontSize: 14),
                    ),
                  ),
                  title: Text(
                    '${order.orderNumber} · ${order.customer}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(order.status),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'Delivered' => QueensTouchColors.success,
        'Pending' => QueensTouchColors.warning,
        'Processing' => Colors.blue.shade700,
        _ => QueensTouchColors.textMuted,
      };
}