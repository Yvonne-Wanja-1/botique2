import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/payments/payments_screen.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/repositories/commerce_repository.dart';
import 'package:botique/models/order.dart';

void main() {
  testWidgets('payments screen lists submissions and shows verify/reject actions', (tester) async {
    final repo = MockOrderRepository();
    final order = await repo.placeOrder(const CheckoutPayload(
      customerName: 'Amara', customerPhone: '080', customerEmail: 'a@b.c',
      shippingAddress: 'Lagos', paymentMethod: PaymentMethod.paybill,
      items: [OrderItem(productId: 'p1', productName: 'Dress', price: 100, quantity: 1)],
      subtotal: 100,
    ));
    await repo.submitPayment(SubmitPaymentPayload(
      orderId: order.id, amount: 100, paymentDate: '2026-08-17',
      confirmationMessage: 'Confirmed',
    ));

    await tester.pumpWidget(Provider<OrderRepository>(
      create: (_) => repo,
      child: const MaterialApp(home: Scaffold(body: PaymentsScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Paybill'), findsWidgets);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}