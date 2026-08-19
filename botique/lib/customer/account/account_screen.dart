import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/animations/qts_animation.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/notification.dart';
import '../../models/order.dart';
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

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = context.read<OrderRepository>().getOrders();
  }

  Future<void> _reload() async {
    final future = context.read<OrderRepository>().getOrders();
    setState(() => _ordersFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'No orders yet',
              message: 'When you place an order, it will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    title: Text(order.orderNumber),
                    subtitle: Text('${order.status.label} • ${_formatDate(order.createdAt)}'),
                    trailing: Text(
                      formatKsh(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => context.push('/account/order/${order.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<Payment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = context.read<OrderRepository>().getPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: FutureBuilder<List<Payment>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final payments = snapshot.data ?? const <Payment>[];
          if (payments.isEmpty) {
            return const EmptyState(
              icon: Icons.payment,
              title: 'No payments yet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payment, color: QueensTouchColors.plum),
                  title: Text(payment.method.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.paymentDate ?? payment.orderNumber ?? ''),
                      if (payment.confirmationMessage != null)
                        Text(
                          payment.confirmationMessage!,
                          style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKsh(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      _PaymentStatusChip(status: payment.status),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  late Future<List<Installment>> _installmentsFuture;

  @override
  void initState() {
    super.initState();
    _installmentsFuture = context.read<OrderRepository>().getInstallments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installments')),
      body: FutureBuilder<List<Installment>>(
        future: _installmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final plans = snapshot.data ?? const <Installment>[];
          if (plans.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month,
              title: 'No installments',
              message: 'Installment payment plans will appear here once approved.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                child: ExpansionTile(
                  leading: _InstallmentStatusChip(status: plan.status),
                  title: Text(
                    plan.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AmountRow('Total', formatKsh(plan.totalAmount)),
                      _AmountRow('Paid', formatKsh(plan.amountPaid)),
                      _AmountRow('Remaining', formatKsh(plan.remainingBalance)),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    const Divider(height: 1),
                    for (final payment in plan.schedule)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              payment.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: payment.isPaid ? QueensTouchColors.success : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(_formatDate(payment.dueDate), style: const TextStyle(fontSize: 13)),
                            const Spacer(),
                            Text(
                              formatKsh(payment.amount),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentStatus.successful => ('Successful', QueensTouchColors.success),
      PaymentStatus.pendingVerification => ('Pending Verification', QueensTouchColors.warning),
      PaymentStatus.rejected => ('Rejected', QueensTouchColors.danger),
      _ => (status.label, Colors.blueGrey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InstallmentStatusChip extends StatelessWidget {
  const _InstallmentStatusChip({required this.status});

  final InstallmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InstallmentStatus.pendingApproval => ('Pending', QueensTouchColors.warning),
      InstallmentStatus.approved => ('Approved', Colors.blue.shade700),
      InstallmentStatus.active => ('Active', QueensTouchColors.success),
      InstallmentStatus.completed => ('Completed', QueensTouchColors.success),
      InstallmentStatus.rejected => ('Rejected', QueensTouchColors.danger),
      InstallmentStatus.overdue => ('Overdue', QueensTouchColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
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
                return TweenAnimationBuilder<double>(
                  key: ValueKey('notification-${n.id}'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: QtMotion.normal,
                  curve: QtMotion.signature,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - v)),
                      child: child,
                    ),
                  ),
                  child: Card(
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