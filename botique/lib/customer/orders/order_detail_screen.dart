import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animated_counter.dart';
import '../../core/animations/order_timeline.dart';
import '../../core/animations/qts_animation.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order?> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = context.read<OrderRepository>().getById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<Order?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final order = snapshot.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Order not found',
            );
          }
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusHeaderCard(order: order),
        const SizedBox(height: 16),
        _PaymentSummaryCard(order: order),
        if (order.installmentRequested) ...[
          const SizedBox(height: 16),
          _InstallmentCard(order: order),
        ],
        const SizedBox(height: 16),
        _ItemsCard(order: order),
        const SizedBox(height: 16),
        _PaymentHistoryCard(order: order),
      ],
    );
  }
}

class _StatusHeaderCard extends StatelessWidget {
  const _StatusHeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: QueensTouchColors.plum,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(
                  label: order.status.label,
                  color: order.status == OrderStatus.cancelled
                      ? QueensTouchColors.danger
                      : QueensTouchColors.success,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: order.paymentStatus.label,
                  color: _paymentStatusColor(order.paymentStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OrderTimeline(status: order.status),
            const SizedBox(height: 12),
            PaymentStatusFlow(status: order.paymentStatus),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: QueensTouchColors.textMuted),
                ),
                Text(
                  formatKsh(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final summary = order.paymentSummary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Verified',
              value: AnimatedCounter(
                value: summary.verified,
                format: formatKsh,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: QueensTouchColors.success,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Pending',
              value: AnimatedCounter(
                value: summary.pending,
                format: formatKsh,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: QueensTouchColors.warning,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Remaining',
              value: AnimatedCounter(
                value: summary.remaining,
                format: formatKsh,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: QueensTouchColors.plum,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: QueensTouchColors.textMuted)),
        value,
      ],
    );
  }
}

class _InstallmentCard extends StatefulWidget {
  const _InstallmentCard({required this.order});

  final Order order;

  @override
  State<_InstallmentCard> createState() => _InstallmentCardState();
}

class _InstallmentCardState extends State<_InstallmentCard> {
  late final Future<List<Installment>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().getInstallments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Installment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final plans = (snapshot.data ?? const <Installment>[])
            .where((i) => i.orderId == widget.order.id)
            .toList();
        final plan = plans.isNotEmpty ? plans.first : null;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installment Plan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (plan == null)
                  const Text(
                    'Awaiting approval',
                    style: TextStyle(color: QueensTouchColors.warning),
                  )
                else ...[
                  _StatusChip(
                    label: _installmentStatusLabel(plan.status),
                    color: _installmentStatusColor(plan.status),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        end: plan.totalAmount <= 0
                            ? 0.0
                            : (plan.amountPaid / plan.totalAmount)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                      ),
                      duration: QtMotion.normal,
                      curve: QtMotion.signature,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8DED7),
                        color: QueensTouchColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total ${formatKsh(plan.totalAmount)}  •  Paid ${formatKsh(plan.amountPaid)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  for (final payment in plan.schedule)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            payment.isPaid
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: payment.isPaid
                                ? QueensTouchColors.success
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(payment.dueDate),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            formatKsh(payment.amount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} × ${item.quantity}',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatKsh(item.lineTotal),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

class _PaymentHistoryCard extends StatefulWidget {
  const _PaymentHistoryCard({required this.order});

  final Order order;

  @override
  State<_PaymentHistoryCard> createState() => _PaymentHistoryCardState();
}

class _PaymentHistoryCardState extends State<_PaymentHistoryCard> {
  late final Future<List<Payment>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().getPaymentsForOrder(widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final payments = snapshot.data ?? const <Payment>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (payments.isEmpty)
                  const Text(
                    'No payments yet',
                    style: TextStyle(color: QueensTouchColors.textMuted),
                  )
                else
                  for (final payment in payments) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatKsh(payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (payment.confirmationMessage != null)
                                Text(
                                  payment.confirmationMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: QueensTouchColors.textMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: payment.status.label,
                          color: _paymentStatusColor(payment.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _paymentStatusColor(PaymentStatus status) => switch (status) {
  PaymentStatus.successful => QueensTouchColors.success,
  PaymentStatus.pendingVerification => QueensTouchColors.warning,
  PaymentStatus.rejected => QueensTouchColors.danger,
  _ => QueensTouchColors.textMuted,
};

String _installmentStatusLabel(InstallmentStatus status) => switch (status) {
  InstallmentStatus.pendingApproval => 'Pending Approval',
  InstallmentStatus.approved => 'Approved',
  InstallmentStatus.active => 'Active',
  InstallmentStatus.completed => 'Completed',
  InstallmentStatus.rejected => 'Rejected',
  InstallmentStatus.overdue => 'Overdue',
};

Color _installmentStatusColor(InstallmentStatus status) => switch (status) {
  InstallmentStatus.pendingApproval => QueensTouchColors.warning,
  InstallmentStatus.approved => QueensTouchColors.plumLight,
  InstallmentStatus.active => QueensTouchColors.success,
  InstallmentStatus.completed => QueensTouchColors.success,
  InstallmentStatus.rejected => QueensTouchColors.danger,
  InstallmentStatus.overdue => QueensTouchColors.danger,
};

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
