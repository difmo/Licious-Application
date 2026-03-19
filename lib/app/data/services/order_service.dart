import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'socket_service.dart';

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
          'orderType': 'One-time',
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
        final directList = response['orders'] ??
            response['data'] ??
            response['history'] ??
            response['items'];
        if (directList is List) return directList;

        // Handle nested data: { "data": { "orders": [...] } }
        if (response['data'] is Map) {
          final nestedList = response['data']['orders'] ??
              response['data']['history'] ??
              response['data']['items'];
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
        if (fallback is Map)
          return fallback['orders'] ??
              fallback['data'] ??
              fallback['history'] ??
              [];
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

  Future<List<dynamic>> getActiveOrders() async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.baseUrl}/orders/active',
        requiresAuth: true,
      );

      if (response is List) {
        return response;
      }

      if (response is Map) {
        final directList = response['orders'] ??
            response['data'] ??
            response['activeOrders'] ??
            response['items'];
        if (directList is List) return directList;

        if (response['data'] is Map) {
          final nestedList =
              response['data']['orders'] ?? response['data']['activeOrders'];
          if (nestedList is List) return nestedList;
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching active orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> trackOrder(String orderIdOrMongId) async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.baseUrl}/orders/track/$orderIdOrMongId',
        requiresAuth: true,
      );
      if (response is Map && response['success'] == true) {
        return Map<String, dynamic>.from(
            response['order'] ?? response['data'] ?? {});
      }
      return {};
    } catch (e) {
      debugPrint('Error tracking order: $e');
      return {};
    }
  }

  /// Fetch the latest order associated with a subscription.
  /// The backend endpoint GET /app/orders/by-subscription/:subscriptionId
  /// should return the most recent order for that subscription.
  Future<Map<String, dynamic>> getOrderBySubscriptionId(
      String subscriptionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.baseUrl}/orders/by-subscription/$subscriptionId',
        requiresAuth: true,
      );
      if (response is Map) {
        if (response['success'] == true) {
          final order = response['order'] ?? response['data'];
          if (order is Map) return Map<String, dynamic>.from(order);
        }
        // Fallback: if the response itself looks like an order
        if (response['_id'] != null) {
          return Map<String, dynamic>.from(response);
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching order by subscription: $e');
      return {};
    }
  }

  /// Fetch a single order by its MongoDB _id
  Future<Map<String, dynamic>> getOrderById(String mongoId) async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.baseUrl}/orders/$mongoId',
        requiresAuth: true,
      );
      if (response is Map) {
        if (response['success'] == true) {
          final order = response['order'] ?? response['data'];
          if (order is Map) return Map<String, dynamic>.from(order);
        }
        if (response['_id'] != null) {
          return Map<String, dynamic>.from(response);
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching order by id: $e');
      return {};
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});

final myOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(orderServiceProvider).getMyOrders();
});

final activeOrdersProvider =
    AsyncNotifierProvider<ActiveOrdersNotifier, List<dynamic>>(
        ActiveOrdersNotifier.new);

class ActiveOrdersNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    // Listen for real-time order status updates from socket
    final socket = ref.watch(socketServiceProvider);
    socket.onOrderUpdate((data) {
      debugPrint('🔔 ActiveOrdersNotifier: Order update received, refreshing...');
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      socket.offOrderUpdate();
    });

    return _fetchActiveOrders();
  }

  Future<List<dynamic>> _fetchActiveOrders() async {
    final service = ref.read(orderServiceProvider);

    try {
      // Fetch full history to ensure we include everything "not delivered"
      final history = await service.getMyOrders();

      if (history.isEmpty) return [];

      return history.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        // The user specifically wants orders that are NOT "delivered"
        return status != 'delivered';
      }).toList();
    } catch (e) {
      debugPrint('Error in _fetchActiveOrders: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchActiveOrders());
  }
}

/// Provider that fetches a single order by subscription ID (latest order).
final orderBySubscriptionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, subscriptionId) {
  return ref
      .watch(orderServiceProvider)
      .getOrderBySubscriptionId(subscriptionId);
});

/// Provider that fetches a single order by its MongoDB _id.
final orderByIdProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, mongoId) {
  return ref.watch(orderServiceProvider).getOrderById(mongoId);
});
