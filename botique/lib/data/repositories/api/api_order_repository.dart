import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../../models/order.dart';
import '../commerce_repository.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._client);

  final ApiClient _client;

  @override
  Future<Order> placeOrder(CheckoutPayload payload) async {
    final data = await _client.post('/api/orders', body: {
      'customerName': payload.customerName,
      'customerPhone': payload.customerPhone,
      'customerEmail': payload.customerEmail,
      'shippingAddress': payload.shippingAddress,
      'paymentMethod': _methodToApi(payload.paymentMethod),
      if (payload.promotionCode != null) 'promotionCode': payload.promotionCode,
      'installmentRequested': payload.installmentRequested,
      'items': [
        for (final item in payload.items)
          {
            'productId': item.productId,
            if (item.variantId != null) 'variantId': item.variantId,
            'quantity': item.quantity,
          },
      ],
    });
    return Order.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Order>> getOrders({String? customerId}) async {
    final data = await _client.get('/api/orders');
    if (data is Map<String, dynamic> && data['rows'] is List<dynamic>) {
      return (data['rows'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return (data as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Order?> getById(String id) async {
    final data = await _client.get('/api/orders/$id');
    return data == null ? null : Order.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Payment>> getPayments({String? customerId}) async {
    final orders = await getOrders(customerId: customerId);
    final payments = <Payment>[];
    for (final order in orders) {
      try {
        final data = await _client.get('/api/payments/${order.id}');
        if (data is Map<String, dynamic>) {
          final payment = Payment.fromJson(data);
          if (payment.id.isNotEmpty) payments.add(payment);
        }
      } on ApiException {
        // No payment yet for this order.
      }
    }
    return payments;
  }

  @override
  Future<List<Installment>> getInstallments({String? customerId}) async {
    final orders = await getOrders(customerId: customerId);
    final installments = <Installment>[];
    for (final order in orders) {
      try {
        final data = await _client.get('/api/installments/orders/${order.id}/plans');
        if (data is Map<String, dynamic>) {
          final plan = Installment.fromJson(data);
          installments.add(_withOrderMeta(plan, order));
        }
      } on ApiException catch (e) {
        if (e.code != 'NOT_FOUND') rethrow;
      }
    }
    return installments;
  }

  Installment _withOrderMeta(Installment plan, Order order) {
    return Installment(
      id: plan.id,
      orderId: plan.orderId,
      orderNumber: order.orderNumber,
      customerId: plan.customerId,
      customerName: order.customerName,
      totalAmount: plan.totalAmount,
      amountPaid: plan.amountPaid,
      schedule: plan.schedule,
      status: plan.status,
      termMonths: plan.termMonths,
      createdAt: plan.createdAt,
    );
  }

  String _methodToApi(PaymentMethod method) => switch (method) {
        PaymentMethod.cashOnDelivery => 'cash_on_delivery',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.paybill => 'paybill',
        PaymentMethod.card => 'card',
        PaymentMethod.installment => 'installment',
      };
}