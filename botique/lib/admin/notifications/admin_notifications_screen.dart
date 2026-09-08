import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/notification.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final List<StoreNotification> _sent = [];
  bool _sending = false;

  Future<void> _compose() async {
    final repo = context.read<NotificationRepository>();
    final result = await showModalBottomSheet<StoreNotification>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ComposeNotification(
        sending: _sending,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final created = await repo.create(result);
      if (!mounted) return;
      setState(() {
        _sent.insert(0, created);
        _sending = false;
      });
      showSuccessSnack(context, 'Notification sent');
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showErrorSnack(context, 'Failed to send: $e');
    }
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
  const _ComposeNotification({required this.sending});

  final bool sending;

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
  static const _notificationTypes = [
    NotificationType.promotion,
    NotificationType.announcement,
    NotificationType.promotion,
    NotificationType.order,
  ];

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
              onPressed: widget.sending
                  ? null
                  : () {
                      if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
                      Navigator.pop(
                        context,
                        StoreNotification(
                          id: '',
                          type: _notificationTypes[_type],
                          title: _title.text.trim(),
                          body: _body.text.trim(),
                          createdAt: DateTime.now(),
                        ),
                      );
                    },
              child: widget.sending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Notification'),
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