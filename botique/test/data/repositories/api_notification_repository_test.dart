import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_notification_repository.dart';
import 'package:botique/models/notification.dart';

void main() {
  test('getNotifications maps the API list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/notifications');
      return http.Response('{"success": true, "data": ['
          '{"id": "n1", "userId": "u1", "type": "payment", "title": "Paid", "body": "ok",'
          '"isRead": false, "createdAt": "2026-08-17T10:00:00Z"}]}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiNotificationRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final list = await repo.getNotifications();
    expect(list, hasLength(1));
    expect(list.first.type, NotificationType.payment);
  });

  test('markRead patches the notification', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/notifications/n1/read');
      return http.Response('{"success": true, "data": null}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiNotificationRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.markRead('n1');
  });
}