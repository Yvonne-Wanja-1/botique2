import 'product.dart';

class CartItem {
  const CartItem({
    required this.product,
    this.variant,
    required this.quantity,
  });

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
