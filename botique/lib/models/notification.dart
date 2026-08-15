enum NotificationType {
  account,
  order,
  payment,
  installment,
  promotion,
  announcement,
}

class StoreNotification {
  const StoreNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  StoreNotification copyWith({bool? isRead}) {
    return StoreNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}