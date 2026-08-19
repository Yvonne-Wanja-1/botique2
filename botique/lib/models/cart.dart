import 'product.dart';

class CartItem {
  const CartItem({
    required this.product,
    this.variant,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final variant = json['variantId'] == null
        ? null
        : ProductVariant(
            id: json['variantId'] as String,
            size: json['size'] as String?,
            color: json['color'] as String?,
            shade: json['shade'] as String?,
            quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
          );
    final imageUrl = json['imageUrl'] as String?;
    final unitPrice = json['unitPrice'] is num
        ? (json['unitPrice'] as num).toDouble()
        : double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0;
    return CartItem(
      product: Product(
        id: json['productId'] as String,
        name: json['name'] as String? ?? '',
        description: '',
        price: unitPrice,
        categoryId: json['categoryId'] as String? ?? '',
        brandId: json['brandId'] as String? ?? '',
        images: [?imageUrl],
      ),
      variant: variant,
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
    );
  }

  final Product product;
  final ProductVariant? variant;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }

  double get lineTotal => product.effectivePrice * quantity;
}

class WishlistItem {
  const WishlistItem({
    required this.product,
    this.addedAt,
  });

  final Product product;
  final DateTime? addedAt;
}