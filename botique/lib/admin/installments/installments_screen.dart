import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/order.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  late Future<List<Installment>> _future;

  int _filter = 0;
  static const _filters = ['All', 'Pending', 'Active', 'Completed', 'Rejected', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().getInstallments();
  }

  Future<void> _reload() async {
    final future = context.read<OrderRepository>().getInstallments();
    setState(() => _future = future);
    await future;
  }

  List<Installment> _filtered(List<Installment> plans) {
    var list = plans;
    if (_filter == 1) list = list.where((i) => i.status == InstallmentStatus.pendingApproval).toList();
    if (_filter == 2) list = list.where((i) => i.status == InstallmentStatus.active).toList();
    if (_filter == 3) list = list.where((i) => i.status == InstallmentStatus.completed).toList();
    if (_filter == 4) list = list.where((i) => i.status == InstallmentStatus.rejected).toList();
    if (_filter == 5) list = list.where((i) => i.isOverdue).toList();
    return list;
  }

  Future<void> _approve(Installment installment) async {
    final ok = await confirmDialog(
      context,
      title: 'Approve installment?',
      message: 'This will activate the payment schedule for the customer.',
    );
    if (!ok || !mounted) return;
    final repo = context.read<OrderRepository>();
    try {
      await repo.approveInstallment(installment.id);
      if (!mounted) return;
      showSuccessSnack(context, 'Installment approved');
      _reload();
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not approve installment');
    }
  }

  Future<void> _reject(Installment installment) async {
    final reason = await _promptReason(context);
    if (reason == null || reason.isEmpty || !mounted) return;
    final repo = context.read<OrderRepository>();
    try {
      await repo.rejectInstallment(installment.id, reason: reason);
      if (!mounted) return;
      showSuccessSnack(context, 'Installment rejected');
      _reload();
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not reject installment');
    }
  }

  Future<String?> _promptReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject installment'),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Installment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final plans = snapshot.data ?? const <Installment>[];
        final filtered = _filtered(plans);
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
              child: RefreshIndicator(
                onRefresh: _reload,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.calendar_month,
                            title: 'No installment plans found',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final inst = filtered[index];
                          return _InstallmentCard(
                            installment: inst,
                            onApprove: () => _approve(inst),
                            onReject: () => _reject(inst),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
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
              '${formatKsh(installment.totalAmount)} total · ${formatKsh(installment.amountPaid)} paid',
            ),
            Text(
              'Remaining: ${formatKsh(installment.remainingBalance)} · ${installment.termMonths} months',
            ),
            if (installment.status == InstallmentStatus.rejected &&
                installment.rejectReason != null &&
                installment.rejectReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Rejected: ${installment.rejectReason}',
                  style: const TextStyle(fontSize: 12, color: QueensTouchColors.danger),
                ),
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
                formatKsh(p.amount),
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
      InstallmentStatus.approved => ('Approved', QueensTouchColors.plumLight),
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