import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_bar_chart.dart';
import 'package:botique/core/animations/order_timeline.dart';
import 'package:botique/models/order.dart';

void main() {
  testWidgets('OrderTimeline renders labels for a delivered order', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderTimeline(status: OrderStatus.delivered),
      ),
    ));
    await tester.pumpAndSettle();
    for (final label in ['Pending', 'Paid', 'Processing', 'Ready', 'Delivered']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('PaymentStatusFlow shows verified state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaymentStatusFlow(status: PaymentStatus.successful),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('AnimatedBarChart renders all bars and labels', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedBarChart(values: const [10, 20], labels: const ['Mon', 'Tue']),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    final firstHeight = tester.getSize(find.byType(FractionallySizedBox).at(0)).height;
    final secondHeight = tester.getSize(find.byType(FractionallySizedBox).at(1)).height;
    expect(firstHeight, lessThan(secondHeight));
  });
}