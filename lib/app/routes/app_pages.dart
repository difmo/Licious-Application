import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../modules/splash/splash_page.dart';
import '../modules/auth/deals_page.dart';
import '../modules/auth/onboarding_page.dart';
import '../modules/auth/welcome_page.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/auth/forgot_password_page.dart';
import '../modules/home/view/main_page.dart';
import '../modules/categories/view/categories_page.dart';
import '../modules/categories/view/vegetables_page.dart';
import '../modules/cart/view/cart_page.dart';
import '../modules/cart/view/shipping_address_page.dart';
import '../modules/cart/view/payment_method_page.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash: (context) => const SplashPage(),
    AppRoutes.initialRoute: (context) => const OnboardingPage(),
    AppRoutes.deals: (context) => const DealsPage(),
    AppRoutes.welcome: (context) => const WelcomePage(),
    AppRoutes.login: (context) => const LoginPage(),
    AppRoutes.signup: (context) => const RegisterPage(),
    AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
    AppRoutes.home: (context) => const MainPage(),
    AppRoutes.categories: (context) => const CategoriesPage(),
    AppRoutes.vegetables: (context) => const VegetablesPage(),
    AppRoutes.cart: (context) => const CartPage(),
    AppRoutes.shippingAddress: (context) => const ShippingAddressPage(),
    AppRoutes.paymentMethod: (context) => const PaymentMethodPage(),
  };
}
