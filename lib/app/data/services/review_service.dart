import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ReviewService
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(client: ref.watch(apiClientProvider));
});

/// Service layer for submitting customer reviews.
class ReviewService {
  final ApiClient _client;

  ReviewService({required ApiClient client}) : _client = client;

  /// Submit a new review
  Future<bool> submitReview({
    required String productId,
    required String retailerId,
    required int rating,
    required String comment,
    required List<String> tags,
  }) async {
    try {
      final json = await _client.post(
        '${ApiClient.reviewBaseUrl}/reviews',
        data: {
          'product': productId,
          'retailer': retailerId,
          'rating': rating,
          'comment': comment,
          'tags': tags,
        },
      );
      return json['success'] == true;
    } catch (e) {
      debugPrint('Review submit error: $e');
      return false;
    }
  }
}
