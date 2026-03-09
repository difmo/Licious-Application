import '../models/subscription_model.dart';
import '../network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(client: ref.watch(apiClientProvider));
});

/// FutureProvider for fetching user subscriptions
final mySubscriptionsProvider =
    FutureProvider<List<UserSubscription>>((ref) async {
  return ref.watch(subscriptionServiceProvider).getMySubscriptions();
});

/// Service layer for subscriptions.
class SubscriptionService {
  final ApiClient _client;

  SubscriptionService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetch all available subscription plans.
  Future<List<SubscriptionPlan>> getSubscriptions() async {
    try {
      final json = await _client.get('${ApiClient.subscriptionBaseUrl}/',
          requiresAuth: true);
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw ApiException(
            message:
                json['message']?.toString() ?? 'Failed to load subscriptions');
      }
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetch user's active subscriptions.
  Future<List<UserSubscription>> getMySubscriptions() async {
    try {
      final json = await _client.get('${ApiClient.subscriptionBaseUrl}/my',
          requiresAuth: true);
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw ApiException(
            message: json['message']?.toString() ??
                'Failed to load user subscriptions');
      }
      final data = json['subscriptions'] as List<dynamic>? ?? [];
      return data
          .map((e) => UserSubscription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Create a new subscription for a product.
  Future<Map<String, dynamic>> subscribeToProduct({
    required String productId,
    required String frequency,
    required int quantity,
    List<String> customDays = const [],
    DateTime? startDate,
  }) async {
    try {
      final payload = {
        'productId': productId,
        'frequency': frequency,
        'quantity': quantity,
        'customDays': customDays,
        'startDate': startDate?.toIso8601String(),
      };

      final json = await _client.post(
        '${ApiClient.subscriptionBaseUrl}/subscribe',
        data: payload,
        requiresAuth: true,
      );

      return {
        'success': json['success'] as bool? ?? false,
        'message': json['message']?.toString() ?? 'Subscription successful',
        'data': json['subscription'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Pause or Resume a subscription.
  Future<bool> updateStatus(String subscriptionId, String status) async {
    try {
      final json = await _client.patch(
        '${ApiClient.subscriptionBaseUrl}/status',
        data: {'subscriptionId': subscriptionId, 'status': status},
        requiresAuth: true,
      );
      return json['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Schedule vacation (pause delivery for a range).
  Future<Map<String, dynamic>> updateVacation({
    required String subscriptionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final json = await _client.post(
        '${ApiClient.subscriptionBaseUrl}/vacation',
        data: {
          'subscriptionId': subscriptionId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        requiresAuth: true,
      );
      return {
        'success': json['success'] as bool? ?? false,
        'message': json['message']?.toString() ?? 'Vacation updated',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
