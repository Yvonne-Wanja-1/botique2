enum PromotionType { percentage, fixed }

class Promotion {
  const Promotion({
    required this.id,
    required this.code,
    required this.title,
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