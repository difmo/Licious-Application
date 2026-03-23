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

  Future<List<ShopModel>> getShops() async {
    try {
      final json = await _client.get(
        '${ApiClient.baseUrl}/shops',
        requiresAuth: true,
      );

      final raw = json['data'] ?? json['shops'] ?? json['retailers'];
      if (raw is List && raw.isNotEmpty) {
        final shops = raw
            .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return shops.isNotEmpty ? shops : [_fallbackShop];
      }
      return [_fallbackShop];
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == null) {
        return [_fallbackShop];
      }
      rethrow;
    } catch (_) {
      return [_fallbackShop];
    }
  }

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

  /// Fetches products based on filters. 
  /// Returns a Map containing 'total' count and 'products' list.
  Future<Map<String, dynamic>> getFilteredProducts({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? hasDiscount,
    bool? freeShipping,
    bool? sameDayDelivery,
    String? category,
    String? sortBy,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (hasDiscount != null) queryParams['hasDiscount'] = hasDiscount.toString();
      if (freeShipping != null) queryParams['freeShipping'] = freeShipping.toString();
      if (sameDayDelivery != null) queryParams['sameDayDelivery'] = sameDayDelivery.toString();
      if (category != null) queryParams['category'] = category;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (search != null) queryParams['search'] = search;

      final queryString = Uri(queryParameters: queryParams).query;
      final url = '${ApiClient.baseUrl}/products${queryString.isNotEmpty ? '?$queryString' : ''}';

      final json = await _client.get(url, requiresAuth: true);
      
      final List<dynamic> rawList = (json['data'] ?? []) as List<dynamic>;
      final products = rawList
          .map((e) => ShopProduct.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return {
        'total': json['total'] ?? products.length,
        'products': products,
      };
    } catch (e) {
      throw ApiException(message: 'Failed to fetch filtered products: $e');
    }
  }
}

