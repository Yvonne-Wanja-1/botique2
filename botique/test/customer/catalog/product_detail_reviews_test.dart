import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/customer/catalog/product_detail_screen.dart';
import 'package:botique/data/mock/mock_catalog_repositories.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/mock/mock_review_repository.dart';
import 'package:botique/data/repositories/review_repository.dart';
import 'package:botique/models/product.dart';
import 'package:botique/models/review.dart';
import 'package:botique/services/catalog_service.dart';
import 'package:botique/services/cart_service.dart';
import 'package:botique/services/wishlist_service.dart';

void main() {
  final product = Product(
    id: 'p1',
    name: 'Silk Dress',
    description: 'A lovely dress',
    price: 100,
    categoryId: 'c1',
    brandId: 'b1',
    images: const [],
    variants: const [],
    rating: 4.8,
    reviewCount: 132,
    soldCount: 540,
  );

  final approvedReview = Review(
    id: 'r1',
    productId: 'p1',
    customerId: 'u1',
    customerName: 'Amara Okafor',
    rating: 5,
    comment: 'Absolutely gorgeous!',
    isVerifiedPurchase: true,
    isApproved: true,
    isRejected: false,
    createdAt: DateTime(2026, 1, 10),
  );

  final pendingReview = Review(
    id: 'r2',
    productId: 'p1',
    customerId: 'u1',
    customerName: 'Amara Okafor',
    rating: 4,
    comment: 'Waiting for approval...',
    isVerifiedPurchase: true,
    isApproved: false,
    isRejected: false,
    createdAt: DateTime(2026, 1, 11),
  );

  Widget buildApp(MockProductRepository productRepo, MockReviewRepository reviewRepo) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogService(productRepo, MockCategoryRepository())),
        ChangeNotifierProvider(create: (_) => CartService(MockCartRepository())),
        ChangeNotifierProvider(create: (_) => WishlistService(MockWishlistRepository())),
        Provider<ReviewRepository>(create: (_) => reviewRepo),
      ],
      child: MaterialApp(
        home: ProductDetailScreen(productId: 'p1'),
      ),
    );
  }

  MockProductRepository seededProductRepo() {
    final repo = MockProductRepository();
    repo.seedProduct(product);
    return repo;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(finder, find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
  }

  testWidgets('shows approved reviews and real average rating/count', (tester) async {
    final productRepo = seededProductRepo();
    productRepo.seedReviews(approvedReview);
    final reviewRepo = MockReviewRepository()..seedReview(approvedReview);

    await tester.pumpWidget(buildApp(productRepo, reviewRepo));
    await tester.pumpAndSettle();

    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('(1 reviews)'), findsOneWidget);

    await scrollTo(tester, find.text('Absolutely gorgeous!'));
    expect(find.text('Absolutely gorgeous!'), findsOneWidget);
    expect(find.text('Amara Okafor'), findsWidgets);
  });

  testWidgets('shows empty state when a product has no reviews', (tester) async {
    final productRepo = seededProductRepo();
    final reviewRepo = MockReviewRepository();

    await tester.pumpWidget(buildApp(productRepo, reviewRepo));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('No reviews yet'));
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('shows Write a Review for an eligible buyer', (tester) async {
    final productRepo = seededProductRepo();
    final reviewRepo = MockReviewRepository()..seedEligible('p1');

    await tester.pumpWidget(buildApp(productRepo, reviewRepo));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Write a Review'));
    expect(find.text('Write a Review'), findsOneWidget);
  });

  testWidgets('shows own pending review status for a customer who already reviewed', (tester) async {
    final productRepo = seededProductRepo();
    final reviewRepo = MockReviewRepository()..seedReview(pendingReview);

    await tester.pumpWidget(buildApp(productRepo, reviewRepo));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Your review: Pending Approval'));
    expect(find.text('Your review: Pending Approval'), findsOneWidget);
    expect(find.text('Write a Review'), findsNothing);
  });
}