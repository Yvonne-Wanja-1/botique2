import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({required NotificationRepository repo}) : _repo = repo;

  final NotificationRepository _repo;
  List<StoreNotification> _notifications = [];

  List<StoreNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    try {
      _notifications = await _repo.getNotifications();
    } on Object {
      _notifications = [];
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
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
}
