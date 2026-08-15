import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: QueensTouchColors.plum,
                    child: Text(
                      user.name.characters.first,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(color: QueensTouchColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/account/profile'),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const _MenuSection(
          title: 'My Orders',
          items: [
            _MenuItem(icon: Icons.receipt_long, label: 'Order History'),
            _MenuItem(icon: Icons.track_changes, label: 'Track Orders'),
          ],
        ),
        const _MenuSection(
          title: 'Payments',
          items: [
            _MenuItem(icon: Icons.payment, label: 'Payment History'),
            _MenuItem(icon: Icons.calendar_month, label: 'Installments'),
          ],
        ),
        const _MenuSection(
          title: 'Account',
          items: [
            _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses'),
            _MenuItem(icon: Icons.lock_outline, label: 'Change Password'),
            _MenuItem(icon: Icons.favorite_outline, label: 'My Wishlist'),
            _MenuItem(icon: Icons.settings_outlined, label: 'Preferences'),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: QueensTouchColors.danger),
            title: const Text('Log Out', style: TextStyle(color: QueensTouchColors.danger)),
            onTap: () async {
              await auth.logout();
              context.go('/login');
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: QueensTouchColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  ListTile(
                    leading: Icon(items[i].icon, color: QueensTouchColors.plum),
                    title: Text(items[i].label),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _openMenu(context, items[i].label),
                  ),
                  if (i != items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context, String label) {
    switch (label) {
      case 'Order History':
        context.push('/account/orders');
      case 'Payment History':
        context.push('/account/payments');
      case 'Installments':
        context.push('/account/installments');
      case 'Notifications':
        context.push('/account/notifications');
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon')),
        );
    }
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: const EmptyState(
        icon: Icons.receipt_long,
        title: 'No orders yet',
        message: 'When you place an order, it will appear here.',
      ),
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: const EmptyState(
        icon: Icons.payment,
        title: 'No payments yet',
      ),
    );
  }
}

class InstallmentsScreen extends StatelessWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installments')),
      body: const EmptyState(
        icon: Icons.calendar_month,
        title: 'No installments',
        message: 'Installment payment plans will appear here once approved.',
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ns = context.watch<NotificationService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ns.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ns.notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'No notifications')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ns.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = ns.notifications[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      _typeIcon(n.type),
                      color: QueensTouchColors.plum,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(n.body),
                    trailing: n.isRead ? null : const Icon(Icons.circle, size: 8, color: QueensTouchColors.plum),
                    onTap: () => ns.markRead(n.id),
                  ),
                );
              },
            ),
    );
  }

  IconData _typeIcon(NotificationType type) => switch (type) {
        NotificationType.account => Icons.person_outline,
        NotificationType.order => Icons.receipt_long,
        NotificationType.payment => Icons.payment,
        NotificationType.installment => Icons.calendar_month,
        NotificationType.promotion => Icons.local_offer,
        NotificationType.announcement => Icons.campaign,
      };
}

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                auth.updateProfile(
                  name: nameController.text,
                  phone: phoneController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}