import '../../models/cart.dart';
import '../../models/order.dart';
import '../../models/promotion.dart';

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
    this.confirmationMessage,
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
  final String? confirmationMessage;
}

class SubmitPaymentPayload {
  const SubmitPaymentPayload({
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    required this.confirmationMessage,
    this.reference,
    this.note,
  });

  final String orderId;
  final double amount;
  final String paymentDate;
  final String confirmationMessage;
  final String? reference;
  final String? note;
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
  Future<List<Payment>> getPaymentsForOrder(String orderId);
  Future<TransferDetails> getTransferDetails();
  Future<Payment> submitPayment(SubmitPaymentPayload payload);
  Future<Payment> verifyPayment(String id);
  Future<Payment> rejectPayment(String id, {required String reason});
  Future<List<Installment>> getInstallments({String? customerId});
  Future<Installment> approveInstallment(String id);
  Future<Installment> rejectInstallment(String id, {required String reason});
}

abstract class PromotionRepository {
  Future<List<Promotion>> getAll();
  Future<List<Promotion>> getActive();
  Future<Promotion> create(Promotion promo);
  Future<Promotion> update(Promotion promo);
  Future<void> delete(String id);
  Future<Map<String, dynamic>?> validate(String code, double subtotal);
}