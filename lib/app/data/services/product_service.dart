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
  Future<List<FoodCategory>> getCategories() async {
    try {
      final json = await _client.get('${ApiClient.baseUrl}/categories');
      final data = json['data'] as List<dynamic>? ?? [];
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
  Future<List<Product>> getProducts({String? category}) async {
    try {
      final queryParams = category != null ? {'category': category} : null;
      final json = await _client.get(
        '${ApiClient.baseUrl}/products',
        queryParameters: queryParams,
      );
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}
