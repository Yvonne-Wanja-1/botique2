import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';

class _Customer {
  const _Customer({
    required this.name,
    required this.email,
    required this.phone,
    required this.joined,
    required this.totalSpent,
    required this.orders,
  });

  final String name;
  final String email;
  final String phone;
  final String joined;
  final double totalSpent;
  final int orders;
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final List<_Customer> _customers = const [
    _Customer(name: 'Amara Okafor', email: 'amara@example.com', phone: '+234 801 234 5678', joined: 'Mar 2026', totalSpent: 1240.50, orders: 12),
    _Customer(name: 'Zainab Bello', email: 'zainab@example.com', phone: '+234 803 555 1212', joined: 'Feb 2026', totalSpent: 890.00, orders: 8),
    _Customer(name: 'Chioma Eze', email: 'chioma@example.com', phone: '+234 806 777 8899', joined: 'Apr 2026', totalSpent: 540.75, orders: 5),
    _Customer(name: 'Tina Adeyemi', email: 'tina@example.com', phone: '+234 805 444 3333', joined: 'Jan 2026', totalSpent: 2100.00, orders: 20),
    _Customer(name: 'Funke Adetola', email: 'funke@example.com', phone: '+234 807 222 1100', joined: 'May 2026', totalSpent: 320.00, orders: 2),
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final c = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: QueensTouchColors.blushLight,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0] : '?',
                      style: const TextStyle(color: QueensTouchColors.plum),
                    ),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.email} · ${c.phone}\nJoined ${c.joined}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKsh(c.totalSpent),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: QueensTouchColors.plum),
                      ),
                      Text('${c.orders} orders', style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted)),
                    ],
                  ),
                  onTap: () => _showDetails(context, c),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, _Customer c) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Email: ${c.email}'),
            Text('Phone: ${c.phone}'),
            Text('Joined: ${c.joined}'),
            Text('Total spent: ${formatKsh(c.totalSpent)}'),
            Text('Orders: ${c.orders}'),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Deactivate account?',
                        message: '${c.name} will no longer be able to log in.',
                        isDanger: true,
                      );
                      if (ok) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        showSuccessSnack(context, 'Account deactivated');
                      }
                    },
                    child: const Text('Deactivate'),
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