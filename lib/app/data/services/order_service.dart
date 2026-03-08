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
      final response = await _apiClient.post('/app/orders', {
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
      });

      if (response.statusCode == 201) {
        return {
          'success': true,
          'order': response.data['order'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await _apiClient.get('/app/orders/my');
      if (response.statusCode == 200) {
        return response.data['orders'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});
