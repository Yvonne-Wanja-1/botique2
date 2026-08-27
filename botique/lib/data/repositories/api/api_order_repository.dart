import '../../api/api_client.dart';
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
      if (payload.confirmationMessage != null)
        'confirmationMessage': payload.confirmationMessage,
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
    final data = await _client.get('/api/payments');
    return _paymentsFromData(data);
  }

  List<Payment> _paymentsFromData(dynamic data) {
    if (data is Map<String, dynamic> && data['rows'] is List<dynamic>) {
      return (data['rows'] as List<dynamic>)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return (data as List<dynamic>)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Payment>> getPaymentsForOrder(String orderId) async {
    final data = await _client.get('/api/payments/orders/$orderId');
    return _paymentsFromData(data);
  }

  @override
  Future<TransferDetails> getTransferDetails() async {
    final data = await _client.get('/api/payments/transfer-details');
    return TransferDetails.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> submitPayment(SubmitPaymentPayload payload) async {
    final data = await _client.post('/api/payments', body: {
      'orderId': payload.orderId,
      'amount': payload.amount,
      'paymentDate': payload.paymentDate,
      'confirmationMessage': payload.confirmationMessage,
      if (payload.reference != null) 'reference': payload.reference,
      if (payload.note != null) 'note': payload.note,
    });
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> verifyPayment(String id) async {
    final data = await _client.post('/api/payments/$id/verify');
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> rejectPayment(String id, {required String reason}) async {
    final data = await _client.post('/api/payments/$id/reject', body: {'reason': reason});
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Installment>> getInstallments({String? customerId}) async {
    final data = await _client.get('/api/installments');
    final List<Installment> plans;
    if (data is Map<String, dynamic> && data['rows'] is List<dynamic>) {
      plans = (data['rows'] as List<dynamic>)
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      plans = (data as List<dynamic>)
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return plans;
  }

  @override
  Future<Installment> approveInstallment(String id) async {
    final data = await _client.post('/api/installments/$id/approve');
    return Installment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Installment> rejectInstallment(String id, {required String reason}) async {
    final data = await _client.post('/api/installments/$id/reject', body: {'reason': reason});
    return Installment.fromJson(data as Map<String, dynamic>);
  }

  String _methodToApi(PaymentMethod method) => switch (method) {
        PaymentMethod.cashOnDelivery => 'cash_on_delivery',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.paybill => 'paybill',
        PaymentMethod.card => 'card',
        PaymentMethod.installment => 'installment',
      };
}