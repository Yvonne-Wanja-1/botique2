import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../admin/dashboard/dashboard_screen.dart';
import '../admin/products/products_screen.dart';
import '../admin/inventory/inventory_screen.dart';
import '../admin/orders/orders_screen.dart';
import '../admin/payments/payments_screen.dart';
import '../admin/installments/installments_screen.dart';
import '../admin/customers/customers_screen.dart';
import '../admin/reviews/reviews_screen.dart';
import '../admin/promotions/promotions_screen.dart';
import '../admin/notifications/admin_notifications_screen.dart';
import '../admin/reports/reports_screen.dart';
import '../admin/staff/staff_screen.dart';
import '../admin/audit/audit_screen.dart';
import '../admin/settings/settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  List<_AdminSection> _sections(Role role) {
    final all = _AdminSection.all;
    return all.where((s) => s.allowedRoles.any((r) => r == role)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final sections = _sections(auth.role);
    final section = sections[_index.clamp(0, sections.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          section.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.push('/');
            },
            icon: const Icon(Icons.storefront),
            label: const Text('Storefront'),
          ),
          _UserMenu(),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: const SizedBox(height: 8),
            destinations: [
              for (final s in sections)
                NavigationRailDestination(
                  icon: Icon(s.icon),
                  label: Text(s.label),
                ),
            ],
          ),
          VerticalDivider(width: 1),
          Expanded(child: section.builder(context)),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: QueensTouchColors.plum,
        child: Text(
          user?.name.characters.first ?? '?',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          auth.logout();
          context.go('/login');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Log out'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.label,
    required this.icon,
    required this.allowedRoles,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final List<Role> allowedRoles;
  final Widget Function(BuildContext) builder;

  static final List<_AdminSection> all = [
    _AdminSection(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.salesStaff, Role.inventoryStaff],
      builder: (_) => const DashboardScreen(),
    ),
    _AdminSection(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.inventoryStaff],
      builder: (_) => const ProductsScreen(),
    ),
    _AdminSection(
      label: 'Inventory',
      icon: Icons.warehouse_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.inventoryStaff],
      builder: (_) => const InventoryScreen(),
    ),
    _AdminSection(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.salesStaff],
      builder: (_) => const OrdersScreen(),
    ),
    _AdminSection(
      label: 'Payments',
      icon: Icons.payments_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.salesStaff],
      builder: (_) => const PaymentsScreen(),
    ),
    _AdminSection(
      label: 'Installments',
      icon: Icons.calendar_month_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager, Role.salesStaff],
      builder: (_) => const InstallmentsScreen(),
    ),
    _AdminSection(
      label: 'Customers',
      icon: Icons.people_outline,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const CustomersScreen(),
    ),
    _AdminSection(
      label: 'Reviews',
      icon: Icons.rate_review_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const ReviewsScreen(),
    ),
    _AdminSection(
      label: 'Promotions',
      icon: Icons.local_offer_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const PromotionsScreen(),
    ),
    _AdminSection(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const AdminNotificationsScreen(),
    ),
    _AdminSection(
      label: 'Reports',
      icon: Icons.bar_chart,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const ReportsScreen(),
    ),
    _AdminSection(
      label: 'Staff',
      icon: Icons.badge_outlined,
      allowedRoles: [Role.superAdmin],
      builder: (_) => const StaffScreen(),
    ),
    _AdminSection(
      label: 'Audit Logs',
      icon: Icons.history,
      allowedRoles: [Role.superAdmin],
      builder: (_) => const AuditScreen(),
    ),
    _AdminSection(
      label: 'Settings',
      icon: Icons.settings_outlined,
      allowedRoles: [Role.superAdmin, Role.storeManager],
      builder: (_) => const SettingsScreen(),
    ),
  ];
}