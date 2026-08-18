double _num(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

class PaymentMethodStat {
  const PaymentMethodStat({required this.paymentMethod, required this.orders, required this.revenue});

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) => PaymentMethodStat(
        paymentMethod: json['paymentMethod'] as String,
        orders: _int(json['orders']),
        revenue: _num(json['revenue']),
      );

  final String paymentMethod;
  final int orders;
  final double revenue;
}

class DailyStat {
  const DailyStat({required this.day, required this.orders, required this.revenue});

  factory DailyStat.fromJson(Map<String, dynamic> json) => DailyStat(
        day: json['day'] as String,
        orders: _int(json['orders']),
        revenue: _num(json['revenue']),
      );

  final String day;
  final int orders;
  final double revenue;
}

class PaymentStatusStat {
  const PaymentStatusStat({required this.paymentStatus, required this.orders});

  factory PaymentStatusStat.fromJson(Map<String, dynamic> json) => PaymentStatusStat(
        paymentStatus: json['paymentStatus'] as String,
        orders: _int(json['orders']),
      );

  final String paymentStatus;
  final int orders;
}

class SalesSummary {
  const SalesSummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.verifiedRevenue,
    required this.outstandingBalance,
    required this.avgOrderValue,
    required this.pendingOrders,
    required this.todayRevenue,
    required this.todayOrders,
    required this.byPaymentMethod,
    required this.ordersByPaymentStatus,
    required this.daily,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) => SalesSummary(
        totalOrders: _int(json['totalOrders']),
        totalRevenue: _num(json['totalRevenue']),
        verifiedRevenue: _num(json['verifiedRevenue']),
        outstandingBalance: _num(json['outstandingBalance']),
        avgOrderValue: _num(json['avgOrderValue']),
        pendingOrders: _int(json['pendingOrders']),
        todayRevenue: _num(json['todayRevenue']),
        todayOrders: _int(json['todayOrders']),
        byPaymentMethod: (json['byPaymentMethod'] as List<dynamic>? ?? [])
            .map((e) => PaymentMethodStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        ordersByPaymentStatus: (json['ordersByPaymentStatus'] as List<dynamic>? ?? [])
            .map((e) => PaymentStatusStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        daily: (json['daily'] as List<dynamic>? ?? [])
            .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int totalOrders;
  final double totalRevenue;
  final double verifiedRevenue;
  final double outstandingBalance;
  final double avgOrderValue;
  final int pendingOrders;
  final double todayRevenue;
  final int todayOrders;
  final List<PaymentMethodStat> byPaymentMethod;
  final List<PaymentStatusStat> ordersByPaymentStatus;
  final List<DailyStat> daily;
}

class SalesRow {
  const SalesRow({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.customerName,
    required this.total,
    required this.verified,
    required this.remainingBalance,
    required this.orderStatus,
    required this.paymentStatus,
  });

  factory SalesRow.fromJson(Map<String, dynamic> json) => SalesRow(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        customerName: json['customerName'] as String? ?? '',
        total: _num(json['total']),
        verified: _num(json['verified']),
        remainingBalance: _num(json['remainingBalance']),
        orderStatus: json['orderStatus'] as String,
        paymentStatus: json['paymentStatus'] as String,
      );

  final String id;
  final String orderNumber;
  final DateTime? date;
  final String customerName;
  final double total;
  final double verified;
  final double remainingBalance;
  final String orderStatus;
  final String paymentStatus;
}

class TopProduct {
  const TopProduct({
    required this.id,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        quantitySold: _int(json['quantitySold']),
        revenue: _num(json['revenue']),
      );

  final String id;
  final String name;
  final int quantitySold;
  final double revenue;
}

class InventoryRow {
  const InventoryRow({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.variantLabel,
    required this.stockQty,
    required this.stockThreshold,
    required this.stockStatus,
  });

  factory InventoryRow.fromJson(Map<String, dynamic> json) => InventoryRow(
        variantId: json['variantId'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        sku: json['sku'] as String,
        variantLabel: json['variantLabel'] as String? ?? '',
        stockQty: _int(json['stockQty']),
        stockThreshold: _int(json['stockThreshold']),
        stockStatus: json['stockStatus'] as String,
      );

  final String variantId;
  final String productId;
  final String productName;
  final String sku;
  final String variantLabel;
  final int stockQty;
  final int stockThreshold;
  final String stockStatus;

  bool get isOut => stockStatus == 'out';
  bool get isLow => stockStatus == 'low';
}

class InventorySummary {
  const InventorySummary({
    required this.totalVariants,
    required this.outOfStock,
    required this.lowStock,
    required this.inStock,
    required this.totalUnits,
    required this.totalProducts,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) => InventorySummary(
        totalVariants: _int(json['totalVariants']),
        outOfStock: _int(json['outOfStock']),
        lowStock: _int(json['lowStock']),
        inStock: _int(json['inStock']),
        totalUnits: _int(json['totalUnits']),
        totalProducts: _int(json['totalProducts']),
      );

  final int totalVariants;
  final int outOfStock;
  final int lowStock;
  final int inStock;
  final int totalUnits;
  final int totalProducts;
}

class TopCustomer {
  const TopCustomer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.orders,
    required this.spend,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) => TopCustomer(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String? ?? '',
        orders: _int(json['orders']),
        spend: _num(json['spend']),
      );

  final String id;
  final String fullName;
  final String email;
  final int orders;
  final double spend;
}

class CustomerSummary {
  const CustomerSummary({
    required this.totalCustomers,
    required this.newCustomers,
    required this.customersWithOrders,
    required this.avgOrdersPerCustomer,
    required this.topCustomers,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) => CustomerSummary(
        totalCustomers: _int(json['totalCustomers']),
        newCustomers: _int(json['newCustomers']),
        customersWithOrders: _int(json['customersWithOrders']),
        avgOrdersPerCustomer: _num(json['avgOrdersPerCustomer']),
        topCustomers: (json['topCustomers'] as List<dynamic>? ?? [])
            .map((e) => TopCustomer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int totalCustomers;
  final int newCustomers;
  final int customersWithOrders;
  final double avgOrdersPerCustomer;
  final List<TopCustomer> topCustomers;
}

class OrderStatusStat {
  const OrderStatusStat({required this.status, required this.count, required this.revenue});

  factory OrderStatusStat.fromJson(Map<String, dynamic> json) => OrderStatusStat(
        status: json['status'] as String,
        count: _int(json['count']),
        revenue: _num(json['revenue']),
      );

  final String status;
  final int count;
  final double revenue;
}

class OrdersSummary {
  const OrdersSummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.byStatus,
    required this.byPaymentStatus,
  });

  factory OrdersSummary.fromJson(Map<String, dynamic> json) => OrdersSummary(
        totalOrders: _int(json['totalOrders']),
        totalRevenue: _num(json['totalRevenue']),
        byStatus: (json['byStatus'] as List<dynamic>? ?? [])
            .map((e) => OrderStatusStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        byPaymentStatus: (json['byPaymentStatus'] as List<dynamic>? ?? [])
            .map((e) => PaymentStatusStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int totalOrders;
  final double totalRevenue;
  final List<OrderStatusStat> byStatus;
  final List<PaymentStatusStat> byPaymentStatus;
}

class PaymentsSummary {
  const PaymentsSummary({
    required this.successful,
    required this.totalProcessed,
    required this.pendingVerification,
    required this.pendingVerificationAmount,
    required this.rejected,
    required this.rejectedAmount,
    required this.failed,
    required this.refunded,
    required this.refundedAmount,
  });

  factory PaymentsSummary.fromJson(Map<String, dynamic> json) => PaymentsSummary(
        successful: _int(json['successful']),
        totalProcessed: _num(json['totalProcessed']),
        pendingVerification: _int(json['pendingVerification']),
        pendingVerificationAmount: _num(json['pendingVerificationAmount']),
        rejected: _int(json['rejected']),
        rejectedAmount: _num(json['rejectedAmount']),
        failed: _int(json['failed']),
        refunded: _int(json['refunded']),
        refundedAmount: _num(json['refundedAmount']),
      );

  final int successful;
  final double totalProcessed;
  final int pendingVerification;
  final double pendingVerificationAmount;
  final int rejected;
  final double rejectedAmount;
  final int failed;
  final int refunded;
  final double refundedAmount;
}

class InstallmentsSummary {
  const InstallmentsSummary({
    required this.active,
    required this.completed,
    required this.pendingApproval,
    required this.approved,
    required this.rejected,
    required this.overdue,
    required this.totalValue,
    required this.totalPaid,
    required this.outstandingBalance,
  });

  factory InstallmentsSummary.fromJson(Map<String, dynamic> json) => InstallmentsSummary(
        active: _int(json['active']),
        completed: _int(json['completed']),
        pendingApproval: _int(json['pendingApproval']),
        approved: _int(json['approved']),
        rejected: _int(json['rejected']),
        overdue: _int(json['overdue']),
        totalValue: _num(json['totalValue']),
        totalPaid: _num(json['totalPaid']),
        outstandingBalance: _num(json['outstandingBalance']),
      );

  final int active;
  final int completed;
  final int pendingApproval;
  final int approved;
  final int rejected;
  final int overdue;
  final double totalValue;
  final double totalPaid;
  final double outstandingBalance;
}