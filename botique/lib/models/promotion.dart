enum PromotionType { percentage, fixed }

class Promotion {
  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.value,
    this.categoryId,
    this.productId,
    this.minimumOrderAmount,
    this.maximumDiscount,
    this.usageLimit,
    this.usageCount = 0,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String title;
  final String? description;
  final PromotionType type;
  final double value;
  final String? categoryId;
  final String? productId;
  final double? minimumOrderAmount;
  final double? maximumDiscount;
  final int? usageLimit;
  final int usageCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  bool get isPercentage => type == PromotionType.percentage;

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] == 'percentage' ? PromotionType.percentage : PromotionType.fixed,
      value: (json['value'] as num).toDouble(),
      categoryId: json['categoryId'] as String?,
      productId: json['productId'] as String?,
      minimumOrderAmount: json['minimumOrderAmount'] != null ? (json['minimumOrderAmount'] as num).toDouble() : null,
      maximumDiscount: json['maximumDiscount'] != null ? (json['maximumDiscount'] as num).toDouble() : null,
      usageLimit: json['usageLimit'] as int?,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'description': description,
    'type': type.name,
    'value': value,
    if (categoryId != null) 'categoryId': categoryId,
    if (productId != null) 'productId': productId,
    if (minimumOrderAmount != null) 'minimumOrderAmount': minimumOrderAmount,
    if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
    if (usageLimit != null) 'usageLimit': usageLimit,
    'usageCount': usageCount,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'isActive': isActive,
  };

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    PromotionType? type,
    double? value,
    String? categoryId,
    String? productId,
    double? minimumOrderAmount,
    double? maximumDiscount,
    int? usageLimit,
    int? usageCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      categoryId: categoryId ?? this.categoryId,
      productId: productId ?? this.productId,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  double discountFor(double subtotal) {
    double discount = isPercentage
        ? subtotal * (value / 100)
        : value;
    if (maximumDiscount != null && discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }
    return discount.clamp(0, subtotal);
  }
}