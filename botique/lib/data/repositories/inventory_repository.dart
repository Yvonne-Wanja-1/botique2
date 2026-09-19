abstract class InventoryRepository {
  Future<List<VariantStock>> list({String? stock});
  Future<AdjustResult?> adjust(String variantId, {required int quantity, required String reason, required String changeType});
}

class VariantStock {
  const VariantStock({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.sku,
    this.size,
    this.color,
    this.shade,
    required this.stockQty,
    required this.stockThreshold,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  factory VariantStock.fromJson(Map<String, dynamic> json) {
    return VariantStock(
      variantId: json['variantId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      size: json['size'] as String?,
      color: json['color'] as String?,
      shade: json['shade'] as String?,
      stockQty: (json['stockQty'] as num?)?.toInt() ?? 0,
      stockThreshold: (json['stockThreshold'] as num?)?.toInt() ?? 1,
      isLowStock: json['isLowStock'] as bool? ?? false,
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
    );
  }

  final String variantId;
  final String productId;
  final String productName;
  final String sku;
  final String? size;
  final String? color;
  final String? shade;
  final int stockQty;
  final int stockThreshold;
  final bool isLowStock;
  final bool isOutOfStock;

  String get label {
    final parts = [size, color, shade].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? sku : parts.join(' / ');
  }
}

class AdjustResult {
  const AdjustResult({required this.newQuantity, required this.previousQuantity});

  final int newQuantity;
  final int previousQuantity;
}
