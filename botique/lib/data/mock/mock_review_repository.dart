import '../../models/review.dart';
import '../repositories/review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  final List<Review> _reviews = [];
  int _seq = 0;

  void seedReview(Review review) => _reviews.add(review);

  void seedEligible(String productId) => _eligible.add(productId);

  final List<String> _eligible = [];

  @override
  Future<ReviewEligibility> getEligibility(String productId) async {
    final review = _reviews.where((r) => r.productId == productId).firstOrNull;
    return ReviewEligibility(
      productId: productId,
      purchased: _eligible.contains(productId) || review != null,
      canReview: _eligible.contains(productId) && review == null,
      review: review,
    );
  }

  @override
  Future<Review> submit(String productId, {required int rating, required String comment}) async {
    final review = Review(
      id: 'mock-review-${_seq++}',
      productId: productId,
      customerId: 'mock-customer',
      customerName: 'Amara Okafor',
      rating: rating.toDouble(),
      comment: comment,
      isApproved: false,
      isRejected: false,
      isReported: false,
      createdAt: DateTime.now(),
    );
    _reviews.add(review);
    return review;
  }

  @override
  Future<List<Review>> getPending() async {
    return _reviews
        .where((r) => !r.isApproved && !r.isRejected)
        .toList();
  }

  @override
  Future<Review> moderate(String id, {required bool approved}) async {
    final index = _reviews.indexWhere((r) => r.id == id);
    if (index < 0) throw StateError('Review $id not found');
    final updated = Review(
      id: _reviews[index].id,
      productId: _reviews[index].productId,
      customerId: _reviews[index].customerId,
      customerName: _reviews[index].customerName,
      rating: _reviews[index].rating,
      comment: _reviews[index].comment,
      orderId: _reviews[index].orderId,
      isVerifiedPurchase: _reviews[index].isVerifiedPurchase,
      isApproved: approved,
      isRejected: !approved,
      isReported: _reviews[index].isReported,
      createdAt: _reviews[index].createdAt,
    );
    _reviews[index] = updated;
    return updated;
  }
}