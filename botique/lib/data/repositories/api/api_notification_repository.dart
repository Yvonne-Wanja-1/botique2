import '../../../models/notification.dart';
import '../../api/api_client.dart';
import '../notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false}) async {
    final data = await _client.get('/api/notifications', query: {
      if (unreadOnly) 'unread': 'true',
    });
    return (data as List<dynamic>)
        .map((e) => StoreNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.patch('/api/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    await _client.patch('/api/notifications/read-all');
  }
}