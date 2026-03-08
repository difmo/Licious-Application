import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '/app/orders',
        data: {
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
        },
        requiresAuth: true,
      );

      // ApiClient returns the response body as a Map.
      // If paymentStatus is Paid, or success is true, we consider it successful.
      return {
        'success': response['success'] ?? true,
        'order': response['order'] ?? response['data'],
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await _apiClient.get(
        '/app/orders/my',
        requiresAuth: true,
      );
      // The backend returns { "success": true, "orders": [...] }
      return response['orders'] ?? response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});
