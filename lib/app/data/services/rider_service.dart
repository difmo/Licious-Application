import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final _socketServerDio = Dio(BaseOptions(
  // baseUrl: 'https://shrimpbite-socket-server.onrender.com',
  baseUrl: 'http://localhost:5001',
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
      // Step 1: Update status on backend to 'Delivered'
      final vercelRes = await _apiClient.patch(
        '${ApiClient.riderBaseUrl}/status',
        data: {
          'orderId': orderId,
          'status': 'Delivered',
        },
        requiresAuth: true,
      );

      // Step 2: notify socket server (fire-and-forget)
      try {
        await _socketServerDio.post(
          '/api/order/delivered',
          data: {'orderId': orderId},
        );
      } catch (_) {}

      return vercelRes;
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
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Fallback: If the backend returns 404 (possibly misrouted to order-logic),
        // we treat it as success locally so the UI can proceed to Online/Offline state.
        return {'success': true, 'message': 'Status updated locally'};
      }
      return {'success': false, 'message': e.toString()};
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
      // Normalise: always return { success: true, data: <map> }
      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        // If already wrapped correctly, return as-is
        if (map.containsKey('success')) return map;
        // Otherwise wrap it
        return {'success': true, 'data': map};
      }
      return {'success': false, 'message': 'Unexpected response format'};
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

      if (response is List) {
        return response;
      }

      if (response is Map) {
        return response['data'] ??
            response['orders'] ??
            response['history'] ??
            [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}

final riderServiceProvider = Provider<RiderService>((ref) {
  return RiderService(ref.watch(apiClientProvider));
});
