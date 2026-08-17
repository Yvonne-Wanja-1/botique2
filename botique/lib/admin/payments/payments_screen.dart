import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/order.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<Payment> _payments = [
    const Payment(
      id: 'pay1',
      orderId: 'o1',
      customerId: 'c1',
      amount: 149.97,
      method: PaymentMethod.card,
      status: PaymentStatus.successful,
      reference: 'PAY-REF-88231',
    ),
    const Payment(
      id: 'pay2',
      orderId: 'o2',
      customerId: 'c2',
      amount: 89.99,
      method: PaymentMethod.card,
      status: PaymentStatus.successful,
      reference: 'PAY-REF-88245',
    ),
    const Payment(
      id: 'pay3',
      orderId: 'o3',
      customerId: 'c3',
      amount: 229.98,
      method: PaymentMethod.cashOnDelivery,
      status: PaymentStatus.pending,
      reference: null,
    ),
    const Payment(
      id: 'pay4',
      orderId: 'o4',
      customerId: 'c4',
      amount: 64.99,
      method: PaymentMethod.bankTransfer,
      status: PaymentStatus.failed,
      reference: 'PAY-REF-88201',
    ),
  ];

  String _query = '';
  int _filter = 0;

  static const _filters = ['All', 'Successful', 'Pending', 'Failed', 'Refunded'];

  List<Payment> get _filtered {
    var list = _payments;
    if (_filter > 0) {
      final target = PaymentStatus.values[_filter - 1];
      list = list.where((p) => p.status == target).toList();
    }
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.reference?.toLowerCase().contains(q) == true ||
          p.orderId.toLowerCase().contains(q)).toList();
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
                  hintText: 'Search by reference or order...',
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final p = _filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    _methodIcon(p.method),
                    color: QueensTouchColors.plum,
                  ),
                  title: Text(
                    '${p.method.label} · ${p.reference ?? 'No reference'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text('Order ${p.orderId} · \$${p.amount.toStringAsFixed(2)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusChip(p.status),
                      if (p.status == PaymentStatus.pending)
                        TextButton(
                          onPressed: () async {
                            final ok = await confirmDialog(
                              context,
                              title: 'Verify payment?',
                              message: 'Confirm this payment as successful?',
                            );
                            if (ok) {
                              _markVerified(p.id);
                              showSuccessSnack(context, 'Payment verified');
                            }
                          },
                          child: const Text('Verify'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _markVerified(String id) {
    final idx = _payments.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _payments[idx] = Payment(
        id: _payments[idx].id,
        orderId: _payments[idx].orderId,
        customerId: _payments[idx].customerId,
        amount: _payments[idx].amount,
        method: _payments[idx].method,
        status: PaymentStatus.successful,
        reference: _payments[idx].reference,
        createdAt: DateTime.now(),
      );
    }
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
      PaymentStatus.refunded => ('Refunded', Colors.blue.shade700),
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