import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/db_service.dart';
import 'app/data/services/cart_service.dart';
import 'app/data/services/wallet_service.dart';
import 'app/data/services/address_service.dart';
import 'app/data/services/auth_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/notification_service.dart';
import 'app/data/services/fcm_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge display for Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate providers for App Check. Use debug provider for local development.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );
  await dotenv.load(fileName: ".env");
  NotificationService.init();
  await FCMService.init();
  FCMService.listenToTokenRefresh();
  runApp(
    // ProviderScope is required at the root so Riverpod providers are available
    // throughout the entire widget tree.
    const ProviderScope(
      child: ShrimpbiteApp(),
    ),
  );
}

class ShrimpbiteApp extends ConsumerStatefulWidget {
  const ShrimpbiteApp({super.key});

  @override
  ConsumerState<ShrimpbiteApp> createState() => _ShrimpbiteAppState();
}

class _ShrimpbiteAppState extends ConsumerState<ShrimpbiteApp> {
  late CartProvider _cartProvider;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final cartService = ref.watch(cartServiceProvider);
      final walletService = ref.watch(walletServiceProvider);
      final addressService = ref.watch(addressServiceProvider);
      final authService = ref.watch(authServiceProvider);

      _cartProvider = CartProvider(
        service: cartService,
        walletService: walletService,
        addressService: addressService,
        authService: authService,
      );
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CartProviderScope(
      provider: _cartProvider,
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
