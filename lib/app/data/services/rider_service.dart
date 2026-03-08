import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class RiderService {
  final ApiClient _apiClient;

  RiderService(this._apiClient);

  Future<List<dynamic>> getAssignedOrders() async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.riderBaseUrl}/orders',
        requiresAuth: true,
      );
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> respondToOrder({
    required String orderId,
    required String response, // 'Accepted' or 'Rejected'
  }) async {
    try {
      final res = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/order-response',
        data: {
          'orderId': orderId,
          'response': response,
        },
        requiresAuth: true,
      );

      if (res['success'] == true) {
        return {
          'success': true,
          'message': res['message'],
        };
      } else {
        return {
          'success': false,
          'message': res['message'] ?? 'Failed to respond to order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}

final riderServiceProvider = Provider<RiderService>((ref) {
  return RiderService(ref.watch(apiClientProvider));
});
