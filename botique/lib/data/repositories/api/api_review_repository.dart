import '../../api/api_client.dart';
import '../../../models/review.dart';
import '../review_repository.dart';

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._client);

  final ApiClient _client;

  @override
  Future<ReviewEligibility> getEligibility(String productId) async {
    final data = await _client.get('/api/reviews/products/$productId/eligibility');
    return ReviewEligibility.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Review> submit(String productId, {required int rating, required String comment}) async {
    final data = await _client.post(
      '/api/reviews/products/$productId/reviews',
      body: {'rating': rating, 'comment': comment},
    );
    return Review.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Review>> getPending() async {
    final data = await _client.get('/api/reviews/pending');
    return (data as List<dynamic>)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Review> moderate(String id, {required bool approved}) async {
    final data = await _client.patch('/api/reviews/$id/moderate', body: {'approved': approved});
    return Review.fromJson(data as Map<String, dynamic>);
  }
}