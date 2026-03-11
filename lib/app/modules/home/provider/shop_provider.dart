import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/services/shop_service.dart';

final shopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final service = ref.watch(shopServiceProvider);
  return service.getShops();
});

final shopProductsProvider =
    FutureProvider.family<List<ShopProduct>, String>((ref, shopId) async {
  final service = ref.watch(shopServiceProvider);
  return service.getShopProducts(shopId);
});
