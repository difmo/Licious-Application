import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_product_model.dart';
import '../network/api_client.dart';

/// Provider for ShopService
final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService(client: ref.watch(apiClientProvider));
});

/// Fallback shop shown when the backend list endpoint is unavailable.
const ShopModel _fallbackShop = ShopModel(
  id: '699ff3d316b54348792bf3bf',
  name: 'ShrimpBite Shop',
  businessName: 'Fresh Shrimp · Karnataka Special',
  location: 'Karnataka, India',
);

class ShopService {
  final ApiClient _client;

  ShopService({required ApiClient client}) : _client = client;

  // ── Fetch all shops ────────────────────────────────────────────────────────
  /// GET /api/app/shops  (requires auth token)
  /// Response: { "success": true, "data": [...] }
  ///
  /// If the backend returns an error or the list is empty, falls back to
  /// [_fallbackShop] containing the single known shop ID.
  Future<List<ShopModel>> getShops() async {
    try {
      final json = await _client.get(
        '${ApiClient.baseUrl}/shops',
        requiresAuth: true,
      );

      // Backend may return "data", "shops", or "retailers" key
      final raw = json['data'] ?? json['shops'] ?? json['retailers'];
      if (raw is List && raw.isNotEmpty) {
        final shops = raw
            .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return shops.isNotEmpty ? shops : [_fallbackShop];
      }
      // Backend responded success:true but with empty/null list
      return [_fallbackShop];
    } on ApiException catch (e) {
      // If the list endpoint doesn't exist (404) or fails, return fallback
      if (e.statusCode == 404 || e.statusCode == null) {
        return [_fallbackShop];
      }
      rethrow;
    } catch (_) {
      return [_fallbackShop];
    }
  }

  // ── Fetch products for a specific shop ────────────────────────────────────
  /// GET /api/app/shops/:shopId/products  (requires auth token)
  /// Response: { "success": true, "data": [...] }
  Future<List<ShopProduct>> getShopProducts(String shopId) async {
    try {
      final json = await _client.get(
        '${ApiClient.baseUrl}/shops/$shopId/products',
        requiresAuth: true,
      );
      final data = (json['data'] ?? json['products']) as List<dynamic>? ?? [];
      return data
          .map((e) => ShopProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          message:
              'Failed to fetch products for shop $shopId: ${e.toString()}');
    }
  }
}
