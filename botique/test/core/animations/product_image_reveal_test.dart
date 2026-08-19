import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/product_image_reveal.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: SizedBox(width: 120, height: 120, child: child));

  testWidgets('shows premium placeholder when no image', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });

  testWidgets('falls back gracefully on image error', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '/nope.png')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });

  testWidgets('wraps in Hero when heroTag provided', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '', heroTag: 'tag-1')));
    await tester.pumpAndSettle();
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'tag-1');
  });
}
