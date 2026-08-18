import '../../models/notification.dart';

abstract class NotificationRepository {
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}