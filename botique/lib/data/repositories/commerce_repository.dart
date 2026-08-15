import '../../models/cart.dart';
import '../../models/order.dart';

class CheckoutPayload {
  const CheckoutPayload({
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.items,
    this.subtotal = 0,
    this.discount = 0,
    this.promotionCode,
    this.installmentRequested = false,
  });

  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String shippingAddress;
  final PaymentMethod paymentMethod;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final String? promotionCode;
  final bool installmentRequested;
}

abstract class CartRepository {
  Future<List<CartItem>> getItems();
  Future<void> add(CartItem item);
  Future<void> remove(String productId, {String? variantId});
  Future<void> updateQuantity(String productId, int quantity, {String? variantId});
  Future<void> clear();
}

abstract class WishlistRepository {
  Future<List<WishlistItem>> getItems();
  Future<void> add(String productId);
  Future<void> remove(String productId);
  Future<bool> contains(String productId);
}

abstract class OrderRepository {
  Future<List<Order>> getOrders({String? customerId});
  Future<Order?> getById(String id);
  Future<Order> placeOrder(CheckoutPayload payload);
  Future<List<Payment>> getPayments({String? customerId});
  Future<List<Installment>> getInstallments({String? customerId});
}