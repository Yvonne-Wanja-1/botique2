import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_star_rating.dart';
import 'package:botique/core/animations/shade_selector.dart';
import 'package:botique/core/animations/wishlist_heart.dart';

void main() {
  testWidgets('WishlistHeart fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WishlistHeart(
          isSelected: false,
          onPressed: () => tapped = true,
        ),
      ),
    ));
    await tester.tap(find.byType(WishlistHeart));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedStarRating reports the tapped rating', (tester) async {
    int? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedStarRating(rating: 3, onChanged: (v) => chosen = v),
      ),
    ));
    await tester.tap(find.byIcon(Icons.star).last);
    await tester.pump();
    expect(chosen, 5);
  });

  testWidgets('ShadeSelector shows shades and reports selection', (tester) async {
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShadeSelector(
          shades: const ['Rose', 'Plum'],
          selected: 'Rose',
          onSelected: (v) => chosen = v,
        ),
      ),
    ));
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Plum'), findsOneWidget);
    await tester.tap(find.text('Plum'));
    await tester.pump();
    expect(chosen, 'Plum');
  });
}
