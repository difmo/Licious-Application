import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'providers/cart_provider.dart';
import 'ui/screens/product_details_screen.dart';

class ShrimpbiteApp extends StatelessWidget {
  const ShrimpbiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CartProviderScope(
      provider: CartProvider(),
      child: MaterialApp(
        title: 'Shrimpbite',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.initialRoute,
        routes: AppRoutes.routes,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.productDetails) {
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                title: args?['title'],
                price: args?['price'],
                subtitle: args?['subtitle'],
                image: args?['image'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
