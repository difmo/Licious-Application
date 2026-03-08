import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/db_service.dart';
import 'app/data/services/cart_service.dart';
import 'app/data/services/wallet_service.dart';
import 'app/data/services/address_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/location_tracking_service.dart';
import 'app/data/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocationTrackingService.init();
  NotificationService.init();
  runApp(
    // ProviderScope is required at the root so Riverpod providers are available
    // throughout the entire widget tree.
    const ProviderScope(
      child: ShrimpbiteApp(),
    ),
  );
}

class ShrimpbiteApp extends ConsumerWidget {
  const ShrimpbiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = ref.watch(cartServiceProvider);
    final walletService = ref.watch(walletServiceProvider);
    final addressService = ref.watch(addressServiceProvider);

    return CartProviderScope(
      provider: CartProvider(
        service: cartService,
        walletService: walletService,
        addressService: addressService,
      ),
      child: MaterialApp(
        title: 'Shrimpbite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppPages.routes,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
        ),
      ),
    );
  }
}
