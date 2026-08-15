enum OrderStatus { pending, paid, processing, ready, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.paid => 'Paid',
        OrderStatus.processing => 'Processing',
        OrderStatus.ready => 'Ready',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}

enum PaymentStatus { pending, successful, failed, refunded }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'Pending',
        PaymentStatus.successful => 'Successful',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.refunded => 'Refunded',
      };
}

enum PaymentMethod { cashOnDelivery, bankTransfer, card, installment }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cashOnDelivery => 'Cash on Delivery',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.card => 'Card',
        PaymentMethod.installment => 'Installment',
      };
}

enum InstallmentStatus {
  pendingApproval,
  approved,
  active,
  completed,
  rejected,
  overdue,
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.variantLabel,
    this.productImage,
  });

  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? variantLabel;
  final String? productImage;

  double get lineTotal => price * quantity;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.shippingAddress,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.shippingFee = 0,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.installmentRequested = false,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String shippingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final bool installmentRequested;
  final DateTime createdAt;

  double get total => subtotal - discount + shippingFee;
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final DateTime? createdAt;
}

class InstallmentPayment {
  const InstallmentPayment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    this.isPaid = false,
  });

  final String id;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final bool isPaid;
}

class Installment {
  const Installment({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.amountPaid,
    required this.schedule,
    required this.status,
    this.termMonths = 3,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final double amountPaid;
  final List<InstallmentPayment> schedule;
  final InstallmentStatus status;
  final int termMonths;
  final DateTime createdAt;

  double get remainingBalance => totalAmount - amountPaid;

  bool get isOverdue =>
      schedule.any((p) => !p.isPaid && p.dueDate.isBefore(DateTime.now()));
}
