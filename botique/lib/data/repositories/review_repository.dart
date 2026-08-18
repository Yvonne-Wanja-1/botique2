import '../../models/review.dart';

/// Whether the current customer may review a product and the status of any
/// review they have already submitted for it.
class ReviewEligibility {
  const ReviewEligibility({
    required this.productId,
    required this.purchased,
    required this.canReview,
    this.review,
  });

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    return ReviewEligibility(
      productId: json['productId'] as String,
      purchased: json['purchased'] == true,
      canReview: json['canReview'] == true,
      review: json['review'] is Map<String, dynamic>
          ? Review.fromJson(json['review'] as Map<String, dynamic>)
          : null,
    );
  }

  final String productId;
  final bool purchased;
  final bool canReview;
  final Review? review;
}

abstract class ReviewRepository {
  Future<ReviewEligibility> getEligibility(String productId);
  Future<Review> submit(String productId, {required int rating, required String comment});
  Future<List<Review>> getPending();
  Future<Review> moderate(String id, {required bool approved});
}