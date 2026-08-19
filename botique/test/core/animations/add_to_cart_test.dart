import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/add_to_cart_fly.dart';

void main() {
  testWidgets('AddToCartButton fires onPressed and confirms', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddToCartButton(
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(pressed, isTrue);
    expect(find.text('Added to Bag'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Add to Cart'), findsOneWidget);
  });

  testWidgets('AddToCartFly inserts and removes an overlay entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    AddToCartFly.show(tester.element(find.byType(Scaffold)), imageUrl: '');
    await tester.pump();
    expect(find.byType(Overlay), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
  });
}
