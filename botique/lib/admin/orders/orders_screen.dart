import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Order> _orders = _seedOrders;
  String _query = '';
  int _statusFilter = 0;

  static const _statusTabs = ['All', 'Pending', 'Processing', 'Ready', 'Delivered', 'Cancelled'];

  List<Order> get _filtered {
    var list = _orders;
    if (_statusFilter > 0) {
      list = list.where((o) => o.status.index == _statusFilter - 1).toList();
    }
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.orderNumber.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by order number or customer...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _statusTabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_statusTabs[i]),
                          selected: _statusFilter == i,
                          onSelected: (_) => setState(() => _statusFilter = i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final order = _filtered[index];
              return _OrderCard(
                order: order,
                onUpdateStatus: (status) => setState(() {
                  final i = _orders.indexWhere((o) => o.id == order.id);
                  _orders[i] = _replaceStatus(_orders[i], status);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Order _replaceStatus(Order order, OrderStatus status) {
    return Order(
      id: order.id,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerEmail: order.customerEmail,
      shippingAddress: order.shippingAddress,
      items: order.items,
      subtotal: order.subtotal,
      discount: order.discount,
      shippingFee: order.shippingFee,
      status: status,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      installmentRequested: order.installmentRequested,
      createdAt: order.createdAt,
    );
  }

  static final List<Order> _seedOrders = [
    Order(
      id: 'o1',
      orderNumber: 'QT-2026-1041',
      customerId: 'c1',
      customerName: 'Amara Okafor',
      customerPhone: '+234 801 234 5678',
      customerEmail: 'amara@example.com',
      shippingAddress: '12 Victoria Island, Lagos',
      items: const [],
      subtotal: 149.97,
      status: OrderStatus.delivered,
      paymentStatus: PaymentStatus.successful,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Order(
      id: 'o2',
      orderNumber: 'QT-2026-1042',
      customerId: 'c2',
      customerName: 'Zainab Bello',
      customerPhone: '+234 803 555 1212',
      customerEmail: 'zainab@example.com',
      shippingAddress: '4 Garki, Abuja',
      items: const [],
      subtotal: 89.99,
      status: OrderStatus.processing,
      paymentStatus: PaymentStatus.successful,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Order(
      id: 'o3',
      orderNumber: 'QT-2026-1043',
      customerId: 'c3',
      customerName: 'Chioma Eze',
      customerPhone: '+234 806 777 8899',
      customerEmail: 'chioma@example.com',
      shippingAddress: '8 Ikot Ekpene, Uyo',
      items: const [],
      subtotal: 229.98,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.pending,
      paymentMethod: PaymentMethod.cashOnDelivery,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Order(
      id: 'o4',
      orderNumber: 'QT-2026-1044',
      customerId: 'c4',
      customerName: 'Tina Adeyemi',
      customerPhone: '+234 805 444 3333',
      customerEmail: 'tina@example.com',
      shippingAddress: '22 Lekki Phase 1, Lagos',
      items: const [],
      subtotal: 64.99,
      status: OrderStatus.ready,
      paymentStatus: PaymentStatus.successful,
      paymentMethod: PaymentMethod.bankTransfer,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onUpdateStatus});

  final Order order;
  final ValueChanged<OrderStatus> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final canUpdate = auth.role == Role.superAdmin ||
        auth.role == Role.storeManager ||
        auth.role == Role.salesStaff;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: QueensTouchColors.blushLight,
          child: Text(
            order.customerName.characters.first,
            style: const TextStyle(color: QueensTouchColors.plum),
          ),
        ),
        title: Text(
          '${order.orderNumber} · ${order.customerName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.items.length} items · \$${order.total.toStringAsFixed(2)}'),
            Text(
              '${order.status.label} · ${order.paymentStatus.label}',
              style: TextStyle(
                color: _statusColor(order.status),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer: ${order.customerName} (${order.customerEmail})'),
          Text('Phone: ${order.customerPhone}'),
          Text('Address: ${order.shippingAddress}'),
          Text('Payment: ${order.paymentMethod.label}'),
          const Divider(height: 20),
          if (canUpdate)
            Wrap(
              spacing: 8,
              children: [
                for (final status in OrderStatus.values)
                  if (status != order.status)
                    ActionChip(
                      label: Text(status.label),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Update order status?',
                          message: 'Mark ${order.orderNumber} as ${status.label}?',
                        );
                        if (ok) {
                          onUpdateStatus(status);
                          if (!context.mounted) return;
                          showSuccessSnack(context, 'Order marked as ${status.label}');
                        }
                      },
                    ),
              ],
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.delivered => QueensTouchColors.success,
        OrderStatus.pending => QueensTouchColors.warning,
        OrderStatus.processing => Colors.blue.shade700,
        OrderStatus.ready => QueensTouchColors.gold,
        OrderStatus.cancelled => QueensTouchColors.danger,
        OrderStatus.paid => QueensTouchColors.success,
      };
}