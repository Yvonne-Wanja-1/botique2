import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selected = 0;

  static const _sections = [
    'Sales',
    'Products',
    'Customers',
    'Orders',
    'Payments',
    'Installments',
  ];

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
                            onSelected: (_) => setState(() => _selected = i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Export',
                onSelected: (format) {
                  showSuccessSnack(context, 'Exporting as $format (demo)');
                },
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
        Expanded(child: _buildSection(_selected)),
      ],
    );
  }

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return _MetricGrid([
          ('Daily Sales', '\$1,840'),
          ('Weekly Sales', '\$11,320'),
          ('Monthly Sales', '\$48,290'),
          ('Yearly Sales', '\$512,400'),
          ('Average Order Value', '\$64.20'),
          ('Revenue Trend', '+12%'),
        ]);
      case 1:
        return _MetricGrid([
          ('Best Seller', 'Velvet Matte Lipstick'),
          ('Most Viewed', 'Signature Silk Scarf'),
          ('Low Stock Items', '5'),
          ('Out of Stock', '3'),
          ('Total Products', '86'),
          ('Avg. Rating', '4.6'),
        ]);
      case 2:
        return _MetricGrid([
          ('Total Customers', '642'),
          ('New (30d)', '48'),
          ('Returning (30d)', '132'),
          ('Active Accounts', '618'),
          ('Avg. Spend', '\$214.30'),
        ]);
      case 3:
        return _MetricGrid([
          ('Total Orders', '1,024'),
          ('Completed', '768'),
          ('Pending', '12'),
          ('Cancelled', '24'),
          ('Processing', '18'),
        ]);
      case 4:
        return _MetricGrid([
          ('Successful', '982'),
          ('Failed', '18'),
          ('Pending', '14'),
          ('Refunded', '10'),
          ('Total Processed', '\$48,290'),
        ]);
      case 5:
        return _MetricGrid([
          ('Active', '12'),
          ('Completed', '34'),
          ('Pending Approval', '3'),
          ('Overdue', '2'),
          ('Outstanding Balance', '\$1,860'),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid(this.metrics);

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: QueensTouchColors.plum,
                      ),
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