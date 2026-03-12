import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../models/product_model.dart';

/// Provider for CartService
final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(client: ref.watch(apiClientProvider));
});

class CartService {
  final ApiClient _client;

  CartService({required ApiClient client}) : _client = client;

  // ── Fetch Cart ───────────────────────────────────────────────────────────
  /// GET /api/app/cart (requires auth token)
  Future<List<CartItem>> getCart() async {
    try {
      final json = await _client.get(
        '${ApiClient.baseUrl}/cart',
        requiresAuth: true,
      );

      List<dynamic> data = [];
      if (json is List) {
        data = json;
      } else if (json is Map) {
        final directList = json['cart'] ?? json['items'] ?? json['data'];
        if (directList is List) {
          data = directList;
        } else if (directList is Map && directList['items'] is List) {
          data = directList['items'];
        } else if (json['data'] is Map && json['data']['items'] is List) {
          data = json['data']['items'];
        }
      }

      return data
          .map((e) => _mapToCartItem(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, stack) {
      print('Cart sync error: $e\\n$stack');
      // If endpoint doesn't exist yet, return empty list
      return [];
    }
  }

  // ── Add to Cart ──────────────────────────────────────────────────────────
  /// POST /api/app/cart/add (requires auth token)
  Future<void> addToCart(String productId, int quantity) async {
    try {
      await _client.post(
        '${ApiClient.baseUrl}/cart/add',
        data: {
          'productId': productId,
          'quantity': quantity,
        },
        requiresAuth: true,
      );
    } catch (e) {
      // SILENT FAIL for now, as UI might be using optimistic updates
    }
  }

  // ── Update Cart Item ─────────────────────────────────────────────────────
  /// PUT /api/app/cart/update (requires auth token)
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      await _client.put(
        '${ApiClient.baseUrl}/cart/update',
        data: {
          'productId': productId,
          'quantity': quantity,
        },
        requiresAuth: true,
      );
    } catch (e) {
      // SILENT FAIL
    }
  }

  // ── Remove from Cart ─────────────────────────────────────────────────────
  /// DELETE /api/app/cart/remove/:productId (requires auth token)
  Future<void> removeFromCart(String productId) async {
    try {
      await _client.delete(
        '${ApiClient.baseUrl}/cart/remove/$productId',
        requiresAuth: true,
      );
    } catch (e) {
      // SILENT FAIL
    }
  }

  // ── Clear Cart ───────────────────────────────────────────────────────────
  /// DELETE /api/app/cart/clear (requires auth token)
  Future<void> clearCart() async {
    try {
      await _client.delete(
        '${ApiClient.baseUrl}/cart/clear',
        requiresAuth: true,
      );
    } catch (e) {
      // SILENT FAIL
    }
  }

  // ── Mapper ───────────────────────────────────────────────────────────────
  CartItem _mapToCartItem(Map<String, dynamic> json) {
    // Backend may return nested product details or flat structure
    final Map<String, dynamic> p =
        json['product'] is Map ? json['product'] : json;

    return CartItem(
      id: (p['_id'] ?? p['id'] ?? json['productId'] ?? '').toString(),
      title: (p['name'] ?? p['productName'] ?? json['productName'] ?? '')
          .toString(),
      unitPrice: (json['price'] as num?)?.toDouble() ??
          (p['price'] as num?)?.toDouble() ??
          0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtitle:
          (p['category'] is Map ? p['category']['name'] : (p['category'] ?? ''))
              .toString(),
      image: (p['image'] ??
              p['imageUrl'] ??
              (p['images'] is List && p['images'].isNotEmpty
                  ? p['images'][0]
                  : ''))
          .toString(),
      category: (p['type'] ?? json['type'] ?? 'standard').toString(),
      shopId: (json['retailerId'] ??
              json['shopId'] ??
              p['retailerId'] ??
              p['retailer'] ??
              '')
          .toString(),
      shopName: (json['retailerName'] ?? json['shopName'] ?? '').toString(),
    );
  }
}
