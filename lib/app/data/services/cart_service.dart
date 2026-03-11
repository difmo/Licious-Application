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
      final data = json['data'] as List<dynamic>? ?? [];
      return data.map((e) => _mapToCartItem(e)).toList();
    } catch (e) {
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
    final product = json['product'] as Map<String, dynamic>?;
    final retailer = json['retailer'] as Map<String, dynamic>?;

    final id = json['productId'] ??
        json['id'] ??
        product?['_id'] ??
        product?['id'] ??
        '';
    final name = json['name'] ??
        json['productName'] ??
        product?['name'] ??
        product?['title'] ??
        'Unknown Product';
    final price = (json['price'] as num?)?.toDouble() ??
        (product?['price'] as num?)?.toDouble() ??
        0.0;
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final image =
        json['image'] ?? product?['image'] ?? product?['imageUrl'] ?? '';
    final category = json['category'] ?? product?['category'] ?? 'standard';

    final rId = retailer?['_id'] ?? retailer?['id'] ?? json['shopId'];
    final rName = retailer?['businessDetails']?['storeDisplayName'] ??
        retailer?['businessName'] ??
        json['shopName'];
    final rLocation = retailer?['businessDetails']?['location']?['address'] ??
        json['shopLocation'];

    return CartItem(
      id: id.toString(),
      title: name.toString(),
      unitPrice: price,
      quantity: qty,
      subtitle: category.toString(),
      image: image.toString(),
      category: category.toString(),
      shopId: rId?.toString(),
      shopName: rName?.toString(),
      shopLocation: rLocation?.toString(),
    );
  }
}
