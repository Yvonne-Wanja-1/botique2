import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeName = TextEditingController(text: 'Queens\' Touch');
  final _storeEmail = TextEditingController(text: 'hello@queenstouch.com');
  final _whatsapp = TextEditingController(text: '+234 800 000 0000');
  final _lowStock = TextEditingController(text: '5');
  final _currency = TextEditingController(text: 'USD');
  final _taxRate = TextEditingController(text: '7.5');

  @override
  void dispose() {
    _storeName.dispose();
    _storeEmail.dispose();
    _whatsapp.dispose();
    _lowStock.dispose();
    _currency.dispose();
    _taxRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsSection(
          title: 'Store Information',
          icon: Icons.storefront,
          children: [
            TextField(controller: _storeName, decoration: const InputDecoration(labelText: 'Store name')),
            const SizedBox(height: 12),
            TextField(controller: _storeEmail, decoration: const InputDecoration(labelText: 'Store email')),
            const SizedBox(height: 12),
            TextField(controller: _whatsapp, decoration: const InputDecoration(labelText: 'WhatsApp contact')),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Commerce',
          icon: Icons.attach_money,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _taxRate,
                    decoration: const InputDecoration(labelText: 'Tax rate (%)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lowStock,
              decoration: const InputDecoration(labelText: 'Low-stock threshold'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Preferences',
          icon: Icons.tune,
          children: [
            SwitchListTile(
              title: const Text('Automatic installment approval'),
              subtitle: const Text('Approve installment requests without manual review'),
              value: false,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {}),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Notify staff on low stock'),
              value: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {}),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Send promotional emails'),
              value: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => showSuccessSnack(context, 'Settings saved'),
          child: const Text('Save Settings'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: QueensTouchColors.plum, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}