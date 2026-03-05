import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/db_service.dart';
import 'app/core/theme/app_theme.dart';

void main() {
  runApp(
    // ProviderScope is required at the root so Riverpod providers are available
    // throughout the entire widget tree.
    const ProviderScope(
      child: ShrimpbiteApp(),
    ),
  );
}

class ShrimpbiteApp extends StatelessWidget {
  const ShrimpbiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CartProviderScope(
      provider: CartProvider(),
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
