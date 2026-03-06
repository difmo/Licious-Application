import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/product_service.dart';

// ── Categories state ─────────────────────────────────────────────────────────

/// Async provider that fetches category list from the API.
final categoriesProvider = FutureProvider<List<FoodCategory>>((ref) async {
  final service = ref.watch(productServiceProvider);
  return service.getCategories();
});

// ── Products by category state ───────────────────────────────────────────────

/// Async provider that fetches products filtered by a given category name.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final service = ref.watch(productServiceProvider);
  return service.getProducts(category: category);
});
