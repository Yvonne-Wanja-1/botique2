import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/customer/catalog/product_detail_screen.dart';
import 'package:botique/data/mock/mock_catalog_repositories.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/mock/mock_review_repository.dart';
import 'package:botique/data/repositories/review_repository.dart';
import 'package:botique/models/product.dart';
import 'package:botique/services/catalog_service.dart';
import 'package:botique/services/cart_service.dart';
import 'package:botique/services/wishlist_service.dart';

void main() {
  Widget buildApp(MockProductRepository productRepo) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogService(productRepo, MockCategoryRepository())),
        ChangeNotifierProvider(create: (_) => CartService(MockCartRepository())),
        ChangeNotifierProvider(create: (_) => WishlistService(MockWishlistRepository())),
        Provider<ReviewRepository>(create: (_) => MockReviewRepository()),
      ],
      child: MaterialApp(
        home: ProductDetailScreen(productId: 'p-gallery'),
      ),
    );
  }

  testWidgets('gallery shows image counter and dots for multiple images', (tester) async {
    final productRepo = MockProductRepository();
    productRepo.seedProduct(Product(
      id: 'p-gallery',
      name: 'Gallery Dress',
      description: 'desc',
      price: 50,
      categoryId: 'c1',
      brandId: 'b1',
      images: ['/images/a.png', '/images/b.png'],
      variants: const [],
    ));

    await tester.pumpWidget(buildApp(productRepo));
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('gallery falls back to placeholder icon when no images', (tester) async {
    final productRepo = MockProductRepository();
    productRepo.seedProduct(Product(
      id: 'p-gallery',
      name: 'No Image Dress',
      description: 'desc',
      price: 50,
      categoryId: 'c1',
      brandId: 'b1',
      images: const [],
      variants: const [],
    ));

    await tester.pumpWidget(buildApp(productRepo));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.checkroom), findsOneWidget);
    expect(find.text('1/2'), findsNothing);
  });
}