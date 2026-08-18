import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/reviews/reviews_screen.dart';
import 'package:botique/data/mock/mock_review_repository.dart';
import 'package:botique/data/repositories/review_repository.dart';
import 'package:botique/models/review.dart';

void main() {
  testWidgets('shows pending reviews and approves one', (tester) async {
    final reviewRepo = MockReviewRepository();
    reviewRepo.seedReview(Review(
      id: 'r1',
      productId: 'p1',
      customerId: 'u1',
      customerName: 'Amara Okafor',
      rating: 5,
      comment: 'Love this dress!',
      isVerifiedPurchase: true,
      isApproved: false,
      isRejected: false,
      createdAt: DateTime(2026, 1, 10),
    ));

    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: reviewRepo,
        child: const MaterialApp(home: Scaffold(body: ReviewsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amara Okafor'), findsOneWidget);
    expect(find.text('Love this dress!'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, approve'));
    await tester.pumpAndSettle();

    expect(find.text('No reviews pending approval'), findsOneWidget);
    final moderated = await reviewRepo.moderate('r1', approved: true);
    expect(moderated.isApproved, isTrue);
  });

  testWidgets('shows empty state when nothing is pending', (tester) async {
    final reviewRepo = MockReviewRepository();

    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: reviewRepo,
        child: const MaterialApp(home: Scaffold(body: ReviewsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No reviews pending approval'), findsOneWidget);
  });
}