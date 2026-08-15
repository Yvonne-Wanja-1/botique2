import '../../core/theme/theme.dart';
import 'package:flutter/material.dart';

class StatCard {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  final String label;
  final String value;
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

class MockDashboardData {
  final List<StatCard> statCards = [
    const StatCard(label: 'Total Revenue', value: '\$48,290', icon: Icons.attach_money, color: QueensTouchColors.success, trend: '+12%'),
    const StatCard(label: "Today's Sales", value: '\$1,840', icon: Icons.today, color: QueensTouchColors.plum),
    const StatCard(label: 'Total Orders', value: '1,024', icon: Icons.receipt_long, color: Colors.blue),
    const StatCard(label: 'Total Customers', value: '642', icon: Icons.people, color: QueensTouchColors.warning),
    const StatCard(label: 'Total Products', value: '86', icon: Icons.inventory_2, color: QueensTouchColors.gold),
    const StatCard(label: 'Pending Orders', value: '12', icon: Icons.pending_actions, color: QueensTouchColors.warning),
    const StatCard(label: 'Low Stock', value: '5', icon: Icons.warning_amber, color: QueensTouchColors.danger),
    const StatCard(label: 'Out of Stock', value: '3', icon: Icons.block, color: QueensTouchColors.danger),
  ];

  final List<String> lowStock = [
    'Plush Velvet Mascara — only 2 left',
    'Silk Garden Maxi Dress — only 3 left',
    'Corset-Style Jumpsuit — only 4 left',
    'Velvet Blush Blazer — only 5 left',
  ];

  final int pendingInstallments = 3;

  final List<double> salesTrend = [1200, 1500, 1100, 1800, 1600, 2100, 2400];

  final List<BestSeller> bestSellers = const [
    BestSeller(name: 'Velvet Matte Lipstick - Queen', sold: 1500),
    BestSeller(name: 'Signature Silk Scarf', sold: 980),
    BestSeller(name: 'Luminous Foundation', sold: 760),
    BestSeller(name: 'Hydra Glow Serum', sold: 620),
    BestSeller(name: 'Everyday Straight-Leg Jeans', sold: 460),
  ];

  final List<RecentOrder> recentOrders = const [
    RecentOrder(orderNumber: 'QT-2026-1041', customer: 'Amara Okafor', total: 149.97, status: 'Delivered'),
    RecentOrder(orderNumber: 'QT-2026-1042', customer: 'Zainab Bello', total: 89.99, status: 'Processing'),
    RecentOrder(orderNumber: 'QT-2026-1043', customer: 'Chioma Eze', total: 229.98, status: 'Pending'),
    RecentOrder(orderNumber: 'QT-2026-1044', customer: 'Tina Adeyemi', total: 64.99, status: 'Delivered'),
  ];
}
