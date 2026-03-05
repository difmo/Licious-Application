import '../models/subscription_model.dart';
import '../network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(client: ref.watch(apiClientProvider));
});

/// FutureProvider for fetching subscription plans
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  return ref.watch(subscriptionServiceProvider).getSubscriptions();
});

/// Service layer for subscriptions.
///
/// Fetches available subscription plans from the backend.
class SubscriptionService {
  final ApiClient _client;

  SubscriptionService({ApiClient? client}) : _client = client ?? ApiClient();

  // Endpoint:  GET /api/app/subscriptions
  static const String _endpoint =
      '${ApiClient.baseUrl}/subscriptions';

  /// Fetch all available subscription plans.
  Future<List<SubscriptionPlan>> getSubscriptions() async {
    try {
      final json = await _client.get(_endpoint, requiresAuth: true);
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw ApiException(
          message: json['message']?.toString() ?? 'Failed to load subscriptions',
        );
      }
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}
