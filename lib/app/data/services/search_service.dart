import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_model.dart';
import '../network/api_client.dart';

/// Provider for SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(client: ref.watch(apiClientProvider));
});

class SearchService {
  final ApiClient _client;

  SearchService({required ApiClient client}) : _client = client;

  /// Calls GET /api/app/search?query={query}
  /// Returns combined shops + products matching the query.
  Future<SearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      return const SearchResult();
    }

    try {
      final json = await _client.get(
        '${ApiClient.baseUrl}/search',
        queryParameters: {'query': query.trim()},
        requiresAuth: false,
      );

      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        return const SearchResult();
      }

      final rawShops = data['shops'];
      final rawProducts = data['products'];

      final shops = rawShops is List
          ? rawShops
              .map((e) => SearchShop.fromJson(e as Map<String, dynamic>))
              .toList()
          : <SearchShop>[];

      final products = rawProducts is List
          ? rawProducts
              .map((e) => SearchProduct.fromJson(e as Map<String, dynamic>))
              .toList()
          : <SearchProduct>[];

      return SearchResult(shops: shops, products: products);
    } on ApiException catch (e) {
      throw ApiException(
          message: 'Search failed: ${e.message}', statusCode: e.statusCode);
    } catch (e) {
      throw ApiException(message: 'Search failed: ${e.toString()}');
    }
  }
}
