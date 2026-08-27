import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/core/widgets/product_card.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/models/product.dart';
import 'package:botique/services/wishlist_service.dart';

void main() {
  testWidgets('product card shows name, price and image placeholder', (
    tester,
  ) async {
    final product = Product(
      id: 'p1',
      name: 'Rosé Dress',
      description: 'd',
      price: 50,
      categoryId: 'clothing-dresses',
      brandId: 'b1',
      images: const [],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WishlistService(MockWishlistRepository()),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 250,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rosé Dress'), findsOneWidget);
    expect(find.text('KSh 50'), findsOneWidget);
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });
}
