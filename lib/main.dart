import 'package:flutter/material.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/db_service.dart';
import 'app/core/theme/app_theme.dart';

void main() {
  runApp(const ShrimpbiteApp());
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
      ),
    );
  }
}
