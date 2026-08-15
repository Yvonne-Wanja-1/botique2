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

  factory StoreNotification.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String?) {
      'account' => NotificationType.account,
      'order' => NotificationType.order,
      'payment' => NotificationType.payment,
      'installment' => NotificationType.installment,
      'promotion' => NotificationType.promotion,
      _ => NotificationType.announcement,
    };
    return StoreNotification(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

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