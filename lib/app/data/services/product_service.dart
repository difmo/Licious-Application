import '../models/food_models.dart';
import '../network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ProductService
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(client: ref.watch(apiClientProvider));
});

/// Service layer for products and categories.
class ProductService {
  final ApiClient _client;

  ProductService({required ApiClient client}) : _client = client;

  /// Fetch all product categories.
  /// Response shape: { "success": true, "categories": [...] }
  Future<List<FoodCategory>> getCategories() async {
    try {
      final json = await _client.get('${ApiClient.baseUrl}/categories');
      // Backend returns "categories" key (not "data")
      final data = (json['categories'] ?? json['data']) as List<dynamic>? ?? [];
      return data
          .map((e) => FoodCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch products, optionally filtered by category.
  /// Returns an empty list if the endpoint is not yet available (404),
  /// so the UI can fall back to local data silently.
  Future<List<Product>> getProducts({String? category}) async {
    try {
      final queryParams = category != null ? {'category': category} : null;
      final json = await _client.get(
        '${ApiClient.baseUrl}/products',
        queryParameters: queryParams,
      );
      // Support both "products" and "data" response keys
      final data = (json['products'] ?? json['data']) as List<dynamic>? ?? [];
      return data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      // 404 means endpoint not yet available — return empty so UI falls back
      if (e.statusCode == 404) return [];
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}
