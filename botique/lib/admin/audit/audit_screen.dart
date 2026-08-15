import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../models/audit.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final List<AuditLog> _logs = [
    AuditLog(
      id: 'a1',
      staffName: 'Queen Ebele',
      action: AuditAction.approve,
      resource: 'Installment',
      description: 'Approved installment request QT-2026-1045',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    AuditLog(
      id: 'a2',
      staffName: 'Doris Achebe',
      action: AuditAction.update,
      resource: 'Order',
      description: 'Changed order QT-2026-1042 to Processing',
      previousValue: 'Pending',
      newValue: 'Processing',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AuditLog(
      id: 'a3',
      staffName: 'Chidi Nwosu',
      action: AuditAction.adjust,
      resource: 'Inventory',
      description: 'Adjusted stock for Plush Velvet Mascara',
      previousValue: '2',
      newValue: '20',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AuditLog(
      id: 'a4',
      staffName: 'Sarah Mensah',
      action: AuditAction.update,
      resource: 'Product',
      description: 'Changed price of Silk Garden Maxi Dress',
      previousValue: '129.99',
      newValue: '109.99',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AuditLog(
      id: 'a5',
      staffName: 'Queen Ebele',
      action: AuditAction.create,
      resource: 'Staff',
      description: 'Created staff account for Doris Achebe',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(_iconFor(log.action), color: QueensTouchColors.plum),
            title: Text(
              '${log.staffName} ${_verbFor(log.action)} ${log.resource}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.description, style: const TextStyle(fontSize: 13)),
                if (log.previousValue != null)
                  Text(
                    '${log.previousValue} → ${log.newValue}',
                    style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                  ),
                Text(
                  '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} ${log.createdAt.hour}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(AuditAction action) => switch (action) {
        AuditAction.create => Icons.add_circle_outline,
        AuditAction.update => Icons.edit_outlined,
        AuditAction.delete => Icons.delete_outline,
        AuditAction.approve => Icons.check_circle_outline,
        AuditAction.reject => Icons.cancel_outlined,
        AuditAction.adjust => Icons.tune,
        AuditAction.login => Icons.login,
        AuditAction.logout => Icons.logout,
      };

  String _verbFor(AuditAction action) => switch (action) {
        AuditAction.create => 'created',
        AuditAction.update => 'updated',
        AuditAction.delete => 'deleted',
        AuditAction.approve => 'approved',
        AuditAction.reject => 'rejected',
        AuditAction.adjust => 'adjusted',
        AuditAction.login => 'logged in',
        AuditAction.logout => 'logged out',
      };
}