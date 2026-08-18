class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.orderId,
    this.productName,
    this.isVerifiedPurchase = false,
    this.isApproved = false,
    this.isRejected = false,
    this.isReported = false,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      productId: json['productId'] as String,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Customer',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      orderId: json['orderId'] as String?,
      productName: json['productName'] as String?,
      isVerifiedPurchase: json['isVerifiedPurchase'] == true,
      isApproved: json['isApproved'] == true,
      isRejected: json['isRejected'] == true,
      isReported: json['isReported'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String productId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final String? orderId;
  final String? productName;
  final bool isVerifiedPurchase;
  final bool isApproved;
  final bool isRejected;
  final bool isReported;
  final DateTime createdAt;

  String get statusLabel => switch ((isApproved, isRejected)) {
        (true, _) => 'Approved',
        (_, true) => 'Rejected',
        _ => 'Pending Approval',
      };
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final bool isDefault;
}