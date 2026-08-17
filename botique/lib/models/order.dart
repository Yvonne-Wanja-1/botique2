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

enum PaymentStatus { pending, pendingVerification, successful, partiallyPaid, failed, refunded, rejected }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'Pending',
        PaymentStatus.pendingVerification => 'Pending Verification',
        PaymentStatus.successful => 'Successful',
        PaymentStatus.partiallyPaid => 'Partially Paid',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.refunded => 'Refunded',
        PaymentStatus.rejected => 'Rejected',
      };
}

enum PaymentMethod { cashOnDelivery, bankTransfer, paybill, card, installment }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cashOnDelivery => 'Cash on Delivery',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.paybill => 'Paybill',
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
    this.variantId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.variantLabel,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      productName: json['productName'] as String? ?? '',
      price: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      variantLabel: json['variantLabel'] as String?,
      productImage: json['productImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        if (variantId != null) 'variantId': variantId,
        'productName': productName,
        'unitPrice': price,
        'quantity': quantity,
        if (variantLabel != null) 'variantLabel': variantLabel,
      };

  final String productId;
  final String? variantId;
  final String productName;
  final double price;
  final int quantity;
  final String? variantLabel;
  final String? productImage;

  double get lineTotal => price * quantity;
}

class OrderPaymentSummary {
  const OrderPaymentSummary({required this.total, required this.verified, required this.pending, required this.remaining});

  factory OrderPaymentSummary.fromJson(Map<String, dynamic> json) => OrderPaymentSummary(
        total: (json['total'] as num?)?.toDouble() ?? 0,
        verified: (json['verified'] as num?)?.toDouble() ?? 0,
        pending: (json['pending'] as num?)?.toDouble() ?? 0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      );

  final double total;
  final double verified;
  final double pending;
  final double remaining;
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
    this.paymentSummary = const OrderPaymentSummary(total: 0, verified: 0, pending: 0, remaining: 0),
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'paid' => OrderStatus.paid,
      'processing' => OrderStatus.processing,
      'ready' => OrderStatus.ready,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
    final paymentStatusRaw = (json['paymentStatus'] as String?) ?? 'pending';
    final paymentStatus = switch (paymentStatusRaw) {
      'successful' || 'paid' => PaymentStatus.successful,
      'pending_verification' => PaymentStatus.pendingVerification,
      'partially_paid' => PaymentStatus.partiallyPaid,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      'rejected' => PaymentStatus.rejected,
      _ => PaymentStatus.pending,
    };
    final paymentMethodRaw = (json['paymentMethod'] as String?) ?? 'cash_on_delivery';
    final paymentMethod = switch (paymentMethodRaw) {
      'bank_transfer' => PaymentMethod.bankTransfer,
      'paybill' => PaymentMethod.paybill,
      'card' => PaymentMethod.card,
      'installment' => PaymentMethod.installment,
      _ => PaymentMethod.cashOnDelivery,
    };
    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (json['discount'] as num?)?.toDouble() ?? 0;
    final shippingFee = (json['shippingFee'] as num?)?.toDouble() ?? 0;
    final orderTotal = subtotal - discount + shippingFee;
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      items: (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(OrderItem.fromJson)
              .toList() ??
          const [],
      subtotal: subtotal,
      discount: discount,
      shippingFee: shippingFee,
      paymentSummary: json['paymentSummary'] is Map<String, dynamic>
          ? OrderPaymentSummary.fromJson(json['paymentSummary'] as Map<String, dynamic>)
          : OrderPaymentSummary(total: orderTotal, verified: 0, pending: 0, remaining: orderTotal),
      status: status,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      installmentRequested: json['installmentRequested'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

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
  final OrderPaymentSummary paymentSummary;

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
    this.orderNumber,
    this.customerName,
    this.paymentDate,
    this.confirmationMessage,
    this.note,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectReason,
    this.duplicateOf,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final method = switch (json['method'] as String?) {
      'bank_transfer' => PaymentMethod.bankTransfer,
      'paybill' => PaymentMethod.paybill,
      'card' => PaymentMethod.card,
      'installment' => PaymentMethod.installment,
      _ => PaymentMethod.cashOnDelivery,
    };
    final status = switch (json['status'] as String?) {
      'successful' || 'paid' => PaymentStatus.successful,
      'pending_verification' => PaymentStatus.pendingVerification,
      'partially_paid' => PaymentStatus.partiallyPaid,
      'rejected' => PaymentStatus.rejected,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
    return Payment(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: method,
      status: status,
      reference: json['reference'] as String?,
      orderNumber: json['orderNumber'] as String?,
      customerName: json['customerName'] as String?,
      paymentDate: json['paymentDate'] as String?,
      confirmationMessage: json['confirmationMessage'] as String?,
      note: json['note'] as String?,
      verifiedAt: json['verifiedAt'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      rejectedBy: json['rejectedBy'] as String?,
      rejectReason: json['rejectReason'] as String?,
      duplicateOf: json['duplicateOf'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? orderNumber;
  final String? customerName;
  final String? paymentDate;
  final String? confirmationMessage;
  final String? note;
  final String? verifiedAt;
  final String? verifiedBy;
  final String? rejectedAt;
  final String? rejectedBy;
  final String? rejectReason;
  final String? duplicateOf;
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

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) {
    return InstallmentPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      isPaid: json['isPaid'] == true,
    );
  }

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
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectReason,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'pending_approval' => InstallmentStatus.pendingApproval,
      'approved' => InstallmentStatus.approved,
      'active' => InstallmentStatus.active,
      'completed' => InstallmentStatus.completed,
      'rejected' => InstallmentStatus.rejected,
      'overdue' => InstallmentStatus.overdue,
      _ => InstallmentStatus.pendingApproval,
    };
    return Installment(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      schedule: (json['payments'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(InstallmentPayment.fromJson)
              .toList() ??
          const [],
      status: status,
      termMonths: (json['termMonths'] as num?)?.toInt() ?? 3,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] as String?,
      rejectedBy: json['rejectedBy'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      rejectReason: json['rejectReason'] as String?,
    );
  }

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
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectedBy;
  final String? rejectedAt;
  final String? rejectReason;

  double get remainingBalance => totalAmount - amountPaid;

  bool get isOverdue =>
      schedule.any((p) => !p.isPaid && p.dueDate.isBefore(DateTime.now()));
}

class TransferDetails {
  const TransferDetails({required this.bankName, required this.paybillNumber, required this.accountNumber});

  factory TransferDetails.fromJson(Map<String, dynamic> json) => TransferDetails(
        bankName: json['bankName'] as String? ?? '',
        paybillNumber: json['paybillNumber'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
      );

  final String bankName;
  final String paybillNumber;
  final String accountNumber;
}
