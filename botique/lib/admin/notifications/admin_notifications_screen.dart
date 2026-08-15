import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/notification.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final List<StoreNotification> _sent = [];

  void _compose() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ComposeNotification(
        onSend: (n) {
          setState(() => _sent.insert(0, n));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Send announcements and campaign notifications to customers.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _compose,
                icon: const Icon(Icons.send),
                label: const Text('Compose'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sent.isEmpty
              ? Center(
                  child: Text(
                    'No notifications sent yet',
                    style: TextStyle(color: QueensTouchColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sent.length,
                  itemBuilder: (context, index) {
                    final n = _sent[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.campaign, color: QueensTouchColors.plum),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${n.type.label} · ${n.body}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ComposeNotification extends StatefulWidget {
  const _ComposeNotification({required this.onSend});

  final ValueChanged<StoreNotification> onSend;

  @override
  State<_ComposeNotification> createState() => _ComposeNotificationState();
}

class _ComposeNotificationState extends State<_ComposeNotification> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _audience = 0;
  int _type = 0;

  static const _audiences = ['All customers', 'Selected customers', 'Purchasers of a product', 'Promo list'];
  static const _types = ['Promotion', 'Announcement', 'Sale', 'Order update'];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Notification', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [for (var i = 0; i < _types.length; i++) DropdownMenuItem(value: i, child: Text(_types[i]))],
              onChanged: (v) => setState(() => _type = v ?? 0),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: [for (var i = 0; i < _audiences.length; i++) DropdownMenuItem(value: i, child: Text(_audiences[i]))],
              onChanged: (v) => setState(() => _audience = v ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
                widget.onSend(StoreNotification(
                  id: 'n${DateTime.now().millisecondsSinceEpoch}',
                  type: NotificationType.values[_type],
                  title: _title.text.trim(),
                  body: _body.text.trim(),
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(context);
                showSuccessSnack(context, 'Notification sent to ${_audiences[_audience]}');
              },
              child: const Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on NotificationType {
  String get label => switch (this) {
        NotificationType.account => 'Account',
        NotificationType.order => 'Order',
        NotificationType.payment => 'Payment',
        NotificationType.installment => 'Installment',
        NotificationType.promotion => 'Promotion',
        NotificationType.announcement => 'Announcement',
      };
}