import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../models/food_models.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(client: ref.watch(apiClientProvider));
});

final productReviewsProvider = FutureProvider.family<List<Review>, String>((ref, productId) async {
  return ref.watch(reviewServiceProvider).getProductReviews(productId);
});

class ReviewService {
  final ApiClient _client;

  ReviewService({required ApiClient client}) : _client = client;

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final response = await _client.get('/reviews/$productId');
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> postReview({
    required String productId,
    required double rating,
    required String comment,
    String? retailerId,
    List<String>? tags,
  }) async {
    try {
      final response = await _client.post(
        '${ApiClient.reviewBaseUrl}',
        data: {
          'product': productId,
          'rating': rating,
          'comment': comment,
          if (retailerId != null) 'retailer': retailerId,
          if (tags != null) 'tags': tags,
        },
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /api/reviews/submit-order-review
  Future<Map<String, dynamic>> submitOrderReview({
    required String orderId,
    required int orderRating,
    String? orderComment,
    int? riderRating,
    List<Map<String, dynamic>>? productReviews,
  }) async {
    try {
      final response = await _client.post(
        '${ApiClient.reviewBaseUrl}/submit-order-review',
        data: {
          'orderId': orderId,
          'orderRating': orderRating,
          if (orderComment != null) 'orderComment': orderComment,
          if (riderRating != null) 'riderRating': riderRating,
          if (productReviews != null) 'productReviews': productReviews,
        },
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// GET /api/reviews/rider/:riderId
  Future<Map<String, dynamic>> getRiderRating(String riderId) async {
    try {
      final response = await _client.get(
        '${ApiClient.reviewBaseUrl}/rider/$riderId',
        requiresAuth: true,
      );
      if (response != null && response['success'] == true) {
        final data = response['data'] is Map ? response['data'] as Map<String, dynamic> : response;
        return {
          'averageRating': (data['averageRating'] ?? data['rating'] ?? 0.0),
          'totalReviews': (data['totalReviews'] ?? data['total_reviews'] ?? data['count'] ?? 0),
        };
      }
      return {'averageRating': 0.0, 'totalReviews': 0};
    } catch (e) {
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }
}

