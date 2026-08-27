import 'package:flutter_test/flutter_test.dart';

import 'package:botique/models/order.dart';
import 'package:botique/core/utils/currency.dart';

void main() {
  test('Order parses paymentSummary and paymentStatus', () {
    final order = Order.fromJson(const {
      'id': 'o1',
      'orderNumber': 'QT-1',
      'customerId': 'u1',
      'customerName': 'A',
      'customerPhone': '080',
      'customerEmail': 'a@b.c',
      'shippingAddress': 's',
      'subtotal': 1000,
      'discount': 0,
      'shippingFee': 0,
      'status': 'pending',
      'paymentStatus': 'partially_paid',
      'paymentMethod': 'paybill',
      'installmentRequested': false,
      'createdAt': '2026-01-01T00:00:00Z',
      'items': [],
      'paymentSummary': {'total': 1000, 'verified': 400, 'pending': 300, 'remaining': 600},
    });
    expect(order.paymentStatus, PaymentStatus.partiallyPaid);
    expect(order.paymentMethod, PaymentMethod.paybill);
    expect(order.paymentSummary.verified, 400);
    expect(order.paymentSummary.pending, 300);
    expect(order.paymentSummary.remaining, 600);
  });

  test('Payment parses verification and rejection fields', () {
    final p = Payment.fromJson(const {
      'id': 'pay1',
      'orderId': 'o1',
      'customerId': 'u1',
      'amount': 100,
      'method': 'paybill',
      'status': 'pending_verification',
      'reference': 'MP-1',
      'paymentDate': '2026-08-17',
      'confirmationMessage': 'Confirmed',
      'note': null,
      'verifiedAt': null,
      'verifiedBy': null,
      'rejectedAt': null,
      'rejectedBy': null,
      'rejectReason': null,
      'duplicateOf': null,
      'createdAt': '2026-01-01T00:00:00Z',
    });
    expect(p.status, PaymentStatus.pendingVerification);
    expect(p.method, PaymentMethod.paybill);
    expect(p.paymentDate, '2026-08-17');
    expect(p.confirmationMessage, 'Confirmed');
  });

  test('Installment parses rejection fields', () {
    final plan = Installment.fromJson(const {
      'id': 'i1',
      'orderId': 'o1',
      'orderNumber': 'QT-1',
      'customerId': 'u1',
      'customerName': 'A',
      'totalAmount': 900,
      'amountPaid': 0,
      'status': 'rejected',
      'termMonths': 3,
      'createdAt': '2026-01-01T00:00:00Z',
      'payments': [],
      'approvedBy': null,
      'approvedAt': null,
      'rejectedBy': 'u203',
      'rejectedAt': '2026-01-02T00:00:00Z',
      'rejectReason': 'No',
    });
    expect(plan.status, InstallmentStatus.rejected);
    expect(plan.rejectReason, 'No');
  });

  test('TransferDetails parses paybill details', () {
    final t = TransferDetails.fromJson(const {
      'bankName': 'Family Bank',
      'paybillNumber': '222111',
      'accountNumber': '65727',
    });
    expect(t.paybillNumber, '222111');
  });

  test('formatKsh formats with thousands separator', () {
    expect(formatKsh(52500), 'KSh 52,500');
    expect(formatKsh(0), 'KSh 0');
  });
}