import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/customer/catalog/write_review_screen.dart';
import 'package:botique/data/mock/mock_review_repository.dart';
import 'package:botique/data/repositories/review_repository.dart';

void main() {
  testWidgets('selects stars, submits a review and confirms pending status', (tester) async {
    final reviewRepo = MockReviewRepository();

    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: reviewRepo,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WriteReviewScreen(
                        productId: 'p1',
                        productName: 'Silk Dress',
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.text('5 out of 5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star).at(2));
    await tester.pump();
    expect(find.text('3 out of 5'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Beautiful fit and fabric.');
    await tester.tap(find.text('Submit Review'));
    await tester.pumpAndSettle();

    expect(find.text('Thank you! Your review was submitted and is awaiting approval.'), findsOneWidget);

    final pending = await reviewRepo.getPending();
    expect(pending, hasLength(1));
    expect(pending.single.rating, 3);
    expect(pending.single.comment, 'Beautiful fit and fabric.');
  });
}