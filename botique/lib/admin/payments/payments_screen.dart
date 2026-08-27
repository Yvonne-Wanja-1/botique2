import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<Payment>> _future;

  String _query = '';
  int _filter = 0;

  static const _filters = ['All', 'Pending Verification', 'Successful', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().getPayments();
  }

  void _reload() {
    setState(() {
      _future = context.read<OrderRepository>().getPayments();
    });
  }

  List<Payment> _filtered(List<Payment> payments) {
    final PaymentStatus? target = switch (_filter) {
      1 => PaymentStatus.pendingVerification,
      2 => PaymentStatus.successful,
      3 => PaymentStatus.rejected,
      _ => null,
    };
    var list = target == null ? payments : payments.where((p) => p.status == target).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.reference?.toLowerCase().contains(q) == true ||
            p.orderId.toLowerCase().contains(q) ||
            p.orderNumber?.toLowerCase().contains(q) == true ||
            p.customerName?.toLowerCase().contains(q) == true;
      }).toList();
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
                  hintText: 'Search by reference, order or customer...',
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
                    for (var i = 0; i < _filters.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filters[i]),
                          selected: _filter == i,
                          onSelected: (_) => setState(() => _filter = i),
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
          child: FutureBuilder<List<Payment>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load payments.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: QueensTouchColors.danger),
                    ),
                  ),
                );
              }
              final payments = snapshot.data ?? const <Payment>[];
              final filtered = _filtered(payments);
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('No payments found')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _PaymentCard(
                          payment: filtered[index],
                          onVerify: () => _verifyPayment(filtered[index]),
                          onReject: () => _rejectPayment(filtered[index]),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _verifyPayment(Payment p) async {
    final ok = await confirmDialog(
      context,
      title: 'Verify payment?',
      message: 'Confirm this payment as successful?',
    );
    if (!ok || !mounted) return;
    final repo = context.read<OrderRepository>();
    try {
      await repo.verifyPayment(p.id);
      if (!mounted) return;
      _reload();
      showSuccessSnack(context, 'Payment verified');
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Verification failed: $e');
    }
  }

  Future<void> _rejectPayment(Payment p) async {
    final reason = await _promptReason(context);
    if (reason == null || reason.isEmpty || !mounted) return;
    final repo = context.read<OrderRepository>();
    try {
      await repo.rejectPayment(p.id, reason: reason);
      if (!mounted) return;
      _reload();
      showSuccessSnack(context, 'Payment rejected');
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Rejection failed: $e');
    }
  }

  Future<String?> _promptReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.onVerify, required this.onReject});

  final Payment payment;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.orderNumber ?? p.orderId,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                _statusChip(p.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(_methodIcon(p.method), size: 16, color: QueensTouchColors.plum),
                const SizedBox(width: 6),
                Text(
                  p.customerName ?? 'Unknown customer',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  p.method.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatKsh(p.amount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: QueensTouchColors.plum),
            ),
            if (p.confirmationMessage != null && p.confirmationMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                p.confirmationMessage!,
                style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Paid on ${p.paymentDate ?? p.createdAt?.toIso8601String().split('T').first ?? '—'}'
              '${p.reference != null && p.reference!.isNotEmpty ? ' · Ref ${p.reference}' : ''}',
              style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
            ),
            if (p.rejectReason != null && p.rejectReason!.isNotEmpty)
              Text(
                'Rejected: ${p.rejectReason}',
                style: const TextStyle(fontSize: 12, color: QueensTouchColors.danger),
              ),
            if (p.status == PaymentStatus.pendingVerification) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(foregroundColor: QueensTouchColors.danger),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onVerify,
                      child: const Text('Verify'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(PaymentMethod m) => switch (m) {
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.bankTransfer => Icons.account_balance,
        PaymentMethod.paybill => Icons.qr_code,
        PaymentMethod.cashOnDelivery => Icons.payments,
        PaymentMethod.installment => Icons.calendar_month,
      };

  Widget _statusChip(PaymentStatus status) {
    final (label, color) = switch (status) {
      PaymentStatus.successful => ('Successful', QueensTouchColors.success),
      PaymentStatus.pending => ('Pending', QueensTouchColors.warning),
      PaymentStatus.pendingVerification => ('Pending Verification', QueensTouchColors.warning),
      PaymentStatus.partiallyPaid => ('Partially Paid', QueensTouchColors.gold),
      PaymentStatus.failed => ('Failed', QueensTouchColors.danger),
      PaymentStatus.refunded => ('Refunded', QueensTouchColors.plumLight),
      PaymentStatus.rejected => ('Rejected', QueensTouchColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}