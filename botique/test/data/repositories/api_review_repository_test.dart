import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_review_repository.dart';

void main() {
  const reviewJson = '{'
      '"id": "r1", "productId": "p1", "customerId": "u1", "customerName": "Amara",'
      '"rating": 5, "comment": "great", "isVerifiedPurchase": true, "isApproved": false,'
      '"isRejected": false, "isReported": false, "createdAt": "2026-01-01T00:00:00Z"}';

  test('getEligibility hits the eligibility endpoint and maps status', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reviews/products/p1/eligibility');
      expect(request.headers['authorization'], 'Bearer tok-c');
      return http.Response(
        '{"success": true, "data": {"productId": "p1", "purchased": true, "canReview": false, '
        '"review": $reviewJson}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReviewRepository(ApiClient(
      baseUrl: 'http://localhost:8080',
      token: 'tok-c',
      client: mock,
    ));
    final eligibility = await repo.getEligibility('p1');
    expect(eligibility.purchased, isTrue);
    expect(eligibility.canReview, isFalse);
    expect(eligibility.review, isNotNull);
    expect(eligibility.review!.isApproved, isFalse);
  });

  test('submit posts rating and comment and maps the created review', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/reviews/products/p1/reviews');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['rating'], 4);
      expect(body['comment'], 'Nice dress');
      return http.Response(
        '{"success": true, "data": $reviewJson}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReviewRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final review = await repo.submit('p1', rating: 4, comment: 'Nice dress');
    expect(review.rating, 5);
    expect(review.isVerifiedPurchase, isTrue);
  });

  test('getPending lists reviews awaiting moderation', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/reviews/pending');
      return http.Response(
        '{"success": true, "data": [$reviewJson]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReviewRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final pending = await repo.getPending();
    expect(pending, hasLength(1));
    expect(pending.single.isApproved, isFalse);
  });

  test('moderate patches the approved flag', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/reviews/r1/moderate');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['approved'], true);
      return http.Response(
        '{"success": true, "data": {"id": "r1", "productId": "p1", "customerId": "u1",'
        '"customerName": "Amara", "rating": 5, "comment": "great", "isVerifiedPurchase": true,'
        '"isApproved": true, "isRejected": false, "isReported": false, "createdAt": "2026-01-01T00:00:00Z"}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = ApiReviewRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final review = await repo.moderate('r1', approved: true);
    expect(review.isApproved, isTrue);
    expect(review.isRejected, isFalse);
  });
}