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
        '${ApiClient.baseUrl}/orders',
        data: {
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
        },
        requiresAuth: true,
      );

      // ApiClient returns the response body as a Map.gterg
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
        '${ApiClient.baseUrl}/orders/my',
        requiresAuth: true,
      );
      debugPrint('[OrderService] getMyOrders response: $response');

      // Backend may return:
      // { "success": true, "orders": [...] }
      // { "success": true, "data": [...] }
      // { "success": true, "data": { "orders": [...] } }
      // { "orders": [...] }   (no success wrapper)
      if (response['orders'] is List) {
        return response['orders'] as List;
      }
      if (response['data'] is List) {
        return response['data'] as List;
      }
      if (response['data'] is Map) {
        final inner = (response['data'] as Map);
        if (inner['orders'] is List) return inner['orders'] as List;
        if (inner['data'] is List) return inner['data'] as List;
      }
      return [];
    } catch (e) {
      debugPrint('[OrderService] Error fetching orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.baseUrl}/orders/$orderId',
        requiresAuth: true,
      );
      if (response['success'] == true) {
        return response['data'] ?? response['order'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order $orderId: $e');
      return null;
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});
