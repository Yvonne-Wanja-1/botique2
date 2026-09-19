import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _statusFilter = 0;

  static const _statusTabs = ['All', 'Pending', 'Processing', 'Ready', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<OrderRepository>();
      final orders = await repo.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load orders: $e';
        _loading = false;
      });
    }
  }

  List<Order> get _filtered {
    var list = _orders;
    if (_statusFilter > 0) {
      final targetStatus = OrderStatus.values[_statusFilter - 1];
      list = list.where((o) => o.status == targetStatus).toList();
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: QueensTouchColors.danger)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: _filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No orders found')),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final order = _filtered[index];
                                return _OrderCard(
                                  order: order,
                                  onStatusUpdated: _loadOrders,
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onStatusUpdated});

  final Order order;
  final VoidCallback onStatusUpdated;

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
            order.customerName.isNotEmpty ? order.customerName[0] : '?',
            style: const TextStyle(color: QueensTouchColors.plum),
          ),
        ),
        title: Text(
          '${order.orderNumber} \u00b7 ${order.customerName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.items.length} items \u00b7 ${formatKsh(order.total)}'),
            Text(
              '${order.status.label} \u00b7 ${order.paymentStatus.label}',
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
          const Divider(height: 20),
          if (order.items.isNotEmpty) ...[
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '  ${item.productName}${item.variantLabel != null ? ' (${item.variantLabel})' : ''} x${item.quantity} \u2014 ${formatKsh(item.lineTotal)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const Divider(height: 20),
          ],
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
                          try {
                            final repo = context.read<OrderRepository>();
                            await repo.updateOrderStatus(order.id, status.name);
                            if (!context.mounted) return;
                            showSuccessSnack(context, 'Order marked as ${status.label}');
                            onStatusUpdated();
                          } catch (e) {
                            if (!context.mounted) return;
                            showErrorSnack(context, 'Failed to update status: $e');
                          }
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
        OrderStatus.processing => QueensTouchColors.plumLight,
        OrderStatus.ready => QueensTouchColors.gold,
        OrderStatus.cancelled => QueensTouchColors.danger,
        OrderStatus.paid => QueensTouchColors.success,
      };
}
