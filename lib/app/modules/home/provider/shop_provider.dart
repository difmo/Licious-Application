import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/services/shop_service.dart';

// ── Shops async provider ─────────────────────────────────────────────────────
/// Fetches all shops from the API. Requires a logged-in user (token).
/// If the endpoint fails or is missing, it falls back to the hardcoded default.
final shopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final service = ref.watch(shopServiceProvider);
  return service.getShops();
});

// ── Shop products async provider ─────────────────────────────────────────────
/// Fetches products for the given shop [shopId].
/// Calls: GET /api/app/shops/:shopId/products  (requires auth token)
final shopProductsProvider =
    FutureProvider.family<List<ShopProduct>, String>((ref, shopId) async {
  final service = ref.watch(shopServiceProvider);
  return service.getShopProducts(shopId);
});
