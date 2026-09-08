import '../../models/notification.dart';

abstract class NotificationRepository {
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false});
  Future<StoreNotification> create(StoreNotification notification);
  Future<void> markRead(String id);
  Future<void> markAllRead();
}