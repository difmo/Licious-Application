import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/services/shop_service.dart';
import '../../../data/services/socket_service.dart';

final shopsListProvider =
    AsyncNotifierProvider<ShopsNotifier, List<ShopModel>>(ShopsNotifier.new);

class ShopsNotifier extends AsyncNotifier<List<ShopModel>> {
  @override
  Future<List<ShopModel>> build() async {
    final service = ref.watch(shopServiceProvider);
    final shops = await service.getShops();

    // Listen for real-time shop status updates
    final socket = ref.watch(socketServiceProvider);
    socket.onShopStatusUpdate((data) {
      _handleShopStatusUpdate(data);
    });

    ref.onDispose(() {
      socket.offShopStatusUpdate();
    });

    return shops;
  }

  void _handleShopStatusUpdate(dynamic data) {
    if (data is Map<String, dynamic>) {
      final String? shopId = data['shopId']?.toString();
      final bool? isShopActive = data['isShopActive'] as bool?;

      if (shopId != null && isShopActive != null) {
        state.whenData((shops) {
          final updatedShops = shops.map((s) {
            if (s.id == shopId) {
              return s.copyWith(isShopActive: isShopActive);
            }
            return s;
          }).toList();
          state = AsyncData(updatedShops);
        });
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => ref.read(shopServiceProvider).getShops());
  }
}

final shopProductsProvider =
    FutureProvider.family<List<ShopProduct>, String>((ref, shopId) async {
  final service = ref.watch(shopServiceProvider);
  return service.getShopProducts(shopId);
});
