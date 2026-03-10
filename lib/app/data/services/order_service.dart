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
        '${ApiClient.baseUrl}/orders/history',
        requiresAuth: true,
      );
      
      debugPrint('OrderHistory Response Type: ${response.runtimeType}');
      
      if (response is List) {
        return response;
      }
      
      if (response is Map) {
        debugPrint('OrderHistory Keys: ${response.keys.toList()}');
        
        // Check various common keys
        final directList = response['orders'] ?? response['data'] ?? response['history'] ?? response['items'];
        if (directList is List) return directList;
        
        // Handle nested data: { "data": { "orders": [...] } }
        if (response['data'] is Map) {
          final nestedList = response['data']['orders'] ?? response['data']['history'] ?? response['data']['items'];
          if (nestedList is List) return nestedList;
        }
        
        // If the map itself looks like a single order or doesn't have list keys
        return [];
      }
      
      return [];
    } catch (e, stack) {
      debugPrint('Error fetching orders from /orders/history: $e');
      debugPrint('Stack trace: $stack');
      
      // Attempt fallback to /orders/my if /orders/history failed or was empty
      try {
        final fallback = await _apiClient.get(
          '${ApiClient.baseUrl}/orders/my',
          requiresAuth: true,
        );
        if (fallback is List) return fallback;
        if (fallback is Map) return fallback['orders'] ?? fallback['data'] ?? fallback['history'] ?? [];
      } catch (e2) {
        debugPrint('Fallback /orders/my also failed: $e2');
      }
      
      return [];
    }
  }

  Future<Map<String, dynamic>> placeSpotOrder({
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiClient.baseUrl}/orders/spot-order',
        data: {
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'orderType': 'One-time',
        },
        requiresAuth: true,
      );

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
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});

final myOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(orderServiceProvider).getMyOrders();
});
