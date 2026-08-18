import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({this._repo, this._useMockFallback = true});

  final NotificationRepository? _repo;
  final bool _useMockFallback;
  List<StoreNotification> _notifications = [];

  List<StoreNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    if (_repo != null) {
      try {
        _notifications = await _repo.getNotifications();
        notifyListeners();
        return;
      } on Object {
        // fall back to mock seed below if the API is unreachable
      }
    }
    if (_useMockFallback) {
      _notifications = _seed;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _repo?.markAllRead();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repo?.markRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void push(StoreNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  static final List<StoreNotification> _seed = [
    StoreNotification(
      id: 'n1',
      type: NotificationType.promotion,
      title: 'Welcome to Queens\' Touch',
      body: 'Enjoy 10% off your first order with code QUEEN10.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreNotification(
      id: 'n2',
      type: NotificationType.order,
      title: 'Your order is being prepared',
      body: 'We are carefully packaging your order. You will be notified when it ships.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreNotification(
      id: 'n3',
      type: NotificationType.payment,
      title: 'Payment confirmed',
      body: 'Thank you! Your payment was received successfully.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];
}
