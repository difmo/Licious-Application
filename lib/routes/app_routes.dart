import 'package:flutter/material.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/welcome_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/signup_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/categories_screen.dart';
import '../ui/screens/vegetables_screen.dart';
import '../ui/screens/cart_screen.dart';
import '../ui/screens/shipping_address_screen.dart';
import '../ui/screens/payment_method_screen.dart';

class AppRoutes {
  static const String initialRoute = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String productDetails = '/product_details';
  static const String categories = '/categories';
  static const String vegetables = '/vegetables';
  static const String cart = '/cart';
  static const String shippingAddress = '/shipping_address';
  static const String paymentMethod = '/payment_method';

  static Map<String, WidgetBuilder> get routes => {
        initialRoute: (context) => const OnboardingScreen(),
        welcome: (context) => const WelcomeScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        home: (context) => const HomeScreen(),
        categories: (context) => const CategoriesScreen(),
        vegetables: (context) => const VegetablesScreen(),
        cart: (context) => const CartScreen(),
        AppRoutes.shippingAddress: (context) => const ShippingAddressScreen(),
        AppRoutes.paymentMethod: (context) => const PaymentMethodScreen(),
      };
}
