import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/order.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final List<Installment> _installments = [
    Installment(
      id: 'inst1',
      orderId: 'o5',
      orderNumber: 'QT-2026-1045',
      customerId: 'c5',
      customerName: 'Funke Adetola',
      totalAmount: 320.00,
      amountPaid: 0,
      termMonths: 4,
      status: InstallmentStatus.pendingApproval,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      schedule: [
        for (var m = 1; m <= 4; m++)
          InstallmentPayment(
            id: 'ip$m',
            amount: 80.00,
            dueDate: DateTime.now().add(Duration(days: 30 * m)),
          ),
      ],
    ),
    Installment(
      id: 'inst2',
      orderId: 'o6',
      orderNumber: 'QT-2026-1038',
      customerId: 'c6',
      customerName: 'Lola Johnson',
      totalAmount: 240.00,
      amountPaid: 120.00,
      termMonths: 3,
      status: InstallmentStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      schedule: [
        InstallmentPayment(id: 'ip1', amount: 80.00, dueDate: DateTime.now().subtract(const Duration(days: 15)), isPaid: true, paidAt: DateTime.now().subtract(const Duration(days: 14))),
        InstallmentPayment(id: 'ip2', amount: 80.00, dueDate: DateTime.now().add(const Duration(days: 15))),
        InstallmentPayment(id: 'ip3', amount: 80.00, dueDate: DateTime.now().add(const Duration(days: 45))),
      ],
    ),
    Installment(
      id: 'inst3',
      orderId: 'o7',
      orderNumber: 'QT-2026-1030',
      customerId: 'c7',
      customerName: 'Ngozi Okafor',
      totalAmount: 180.00,
      amountPaid: 180.00,
      termMonths: 3,
      status: InstallmentStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      schedule: [
        for (var m = 1; m <= 3; m++)
          InstallmentPayment(
            id: 'cp$m',
            amount: 60.00,
            dueDate: DateTime.now().subtract(Duration(days: 90 - 30 * (m - 1))),
            isPaid: true,
            paidAt: DateTime.now().subtract(Duration(days: 90 - 30 * (m - 1) + 2)),
          ),
      ],
    ),
  ];

  int _filter = 0;
  static const _filters = ['All', 'Pending', 'Active', 'Completed', 'Overdue'];

  List<Installment> get _filtered {
    var list = _installments;
    if (_filter == 1) list = list.where((i) => i.status == InstallmentStatus.pendingApproval).toList();
    if (_filter == 2) list = list.where((i) => i.status == InstallmentStatus.active).toList();
    if (_filter == 3) list = list.where((i) => i.status == InstallmentStatus.completed).toList();
    if (_filter == 4) list = list.where((i) => i.isOverdue).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
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
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final inst = _filtered[index];
              return _InstallmentCard(
                installment: inst,
                onApprove: () => _setStatus(inst.id, InstallmentStatus.active),
                onReject: () => _setStatus(inst.id, InstallmentStatus.rejected),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _setStatus(String id, InstallmentStatus status) async {
    final ok = await confirmDialog(
      context,
      title: status == InstallmentStatus.active ? 'Approve installment?' : 'Reject installment?',
      message: status == InstallmentStatus.active
          ? 'This will activate the payment schedule for the customer.'
          : 'This will decline the customer\'s installment request.',
      isDanger: status == InstallmentStatus.rejected,
    );
    if (!ok) return;
    setState(() {
      final idx = _installments.indexWhere((i) => i.id == id);
      final old = _installments[idx];
      _installments[idx] = Installment(
        id: old.id,
        orderId: old.orderId,
        orderNumber: old.orderNumber,
        customerId: old.customerId,
        customerName: old.customerName,
        totalAmount: old.totalAmount,
        amountPaid: old.amountPaid,
        schedule: old.schedule,
        termMonths: old.termMonths,
        status: status,
        createdAt: old.createdAt,
      );
    });
    showSuccessSnack(context, status == InstallmentStatus.active ? 'Installment approved' : 'Installment rejected');
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.installment,
    required this.onApprove,
    required this.onReject,
  });

  final Installment installment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = installment.status == InstallmentStatus.pendingApproval;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_month, color: QueensTouchColors.plum),
        title: Text(
          '${installment.orderNumber} · ${installment.customerName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${installment.totalAmount.toStringAsFixed(2)} total · \$${installment.amountPaid.toStringAsFixed(2)} paid',
            ),
            Text(
              'Remaining: \$${installment.remainingBalance.toStringAsFixed(2)} · ${installment.termMonths} months',
            ),
          ],
        ),
        trailing: _statusChip(installment.status),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final p in installment.schedule)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                p.isPaid ? Icons.check_circle : Icons.circle_outlined,
                color: p.isPaid ? QueensTouchColors.success : QueensTouchColors.textMuted,
                size: 18,
              ),
              title: Text(
                '\$${p.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                'Due: ${p.dueDate.day}/${p.dueDate.month}/${p.dueDate.year}'
                '${p.paidAt != null ? ' · Paid ${p.paidAt!.day}/${p.paidAt!.month}' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          if (isPending) ...[
            const Divider(height: 20),
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
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(InstallmentStatus status) {
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
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}