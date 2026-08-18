import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/customer/orders/order_detail_screen.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/repositories/commerce_repository.dart';
import 'package:botique/models/order.dart';

void main() {
  testWidgets('order detail shows remaining balance in KSh and a Pay button', (tester) async {
    final repo = MockOrderRepository();
    final order = await repo.placeOrder(const CheckoutPayload(
      customerName: 'Amara',
      customerPhone: '080',
      customerEmail: 'a@b.c',
      shippingAddress: 'Lagos',
      paymentMethod: PaymentMethod.paybill,
      items: [OrderItem(productId: 'p1', productName: 'Dress', price: 50000, quantity: 1)],
      subtotal: 50000,
    ));
    await tester.pumpWidget(Provider<OrderRepository>(
      create: (_) => repo,
      child: MaterialApp(home: OrderDetailScreen(orderId: order.id)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('KSh'), findsWidgets);
    expect(find.text('Pay'), findsOneWidget);
  });
}