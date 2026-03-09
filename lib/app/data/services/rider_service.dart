import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final _socketServerDio = Dio(BaseOptions(
  baseUrl: 'https://shrimpbite-socket-server.onrender.com',
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  contentType: Headers.jsonContentType,
));

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
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      final res = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/location',
        data: {
          'latitude': lat,
          'longitude': lng,
        },
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDeliveryStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final res = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/status',
        data: {
          'orderId': orderId,
          'status': status,
        },
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeOrder({
    required String orderId,
  }) async {
    try {
      final res = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/complete',
        data: {'orderId': orderId},
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Marks the order as delivered by:
  /// 1. Calling the Vercel API PATCH /rider/complete
  /// 2. Notifying the Socket/Render server via POST /api/order/delivered
  Future<Map<String, dynamic>> markAsDelivered({
    required String orderId,
  }) async {
    try {
      // Step 1: complete on Vercel API
      final vercelRes = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/complete',
        data: {'orderId': orderId},
        requiresAuth: true,
      );

      // Step 2: notify socket server (fire-and-forget, don't block on failure)
      try {
        await _socketServerDio.post(
          '/api/order/delivered',
          data: {'orderId': orderId},
        );
      } catch (_) {
        // Socket server notification is best-effort
      }

      return vercelRes is Map<String, dynamic>
          ? vercelRes
          : {'success': true, 'message': 'Order marked as delivered'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateStatus(String status) async {
    try {
      final res = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/status',
        data: {'status': status},
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String id) async {
    try {
      final res = await _apiClient.get(
        '${ApiClient.riderBaseUrl}/orders/$id',
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final res = await _apiClient.get(
        '${ApiClient.riderBaseUrl}/earnings',
        requiresAuth: true,
      );
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getDeliveryHistory() async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.riderBaseUrl}/history',
        requiresAuth: true,
      );
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}

final riderServiceProvider = Provider<RiderService>((ref) {
  return RiderService(ref.watch(apiClientProvider));
});
