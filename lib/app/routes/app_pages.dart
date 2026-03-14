import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../modules/splash/splash_page.dart';
import '../modules/auth/deals_page.dart';


import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/auth/forgot_password_page.dart';
import '../modules/home/view/main_page.dart';
import '../modules/categories/view/categories_page.dart';
import '../modules/categories/view/vegetables_page.dart';
import '../modules/cart/view/cart_page.dart';
import '../modules/cart/view/shipping_address_page.dart';
import '../modules/cart/view/payment_method_page.dart';
import '../modules/subscription/subscription_page.dart';
import '../modules/wallet/view/wallet_page.dart';
import '../modules/rider/view/rider_main_page.dart';

import '../modules/wallet/view/top_up_page.dart';
import '../modules/wallet/view/wallet_statement_screen.dart';
import '../modules/orders/view/active_orders_page.dart';
import '../modules/orders/view/track_order_page.dart';
import '../modules/location/view/location_picker_screen.dart';
import '../modules/home/view/search_page.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.initialRoute: (context) => const LoginPage(),
        AppRoutes.deals: (context) => const DealsPage(),
        AppRoutes.welcome: (context) => const LoginPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.signup: (context) => const RegisterPage(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
        AppRoutes.home: (context) => const MainPage(),
        AppRoutes.subscriptions: (context) => const SubscriptionPage(),
        AppRoutes.wallet: (context) => const WalletPage(),
        AppRoutes.categories: (context) => const CategoriesPage(),
        AppRoutes.vegetables: (context) => const VegetablesPage(),
        AppRoutes.cart: (context) => const CartPage(),
        AppRoutes.shippingAddress: (context) => const ShippingAddressPage(),
        AppRoutes.paymentMethod: (context) => const PaymentMethodPage(),
        AppRoutes.riderHome: (context) => const RiderMainPage(),
        AppRoutes.topUp: (context) => const TopUpPage(),
        AppRoutes.walletStatement: (context) => const WalletStatementScreen(),
        AppRoutes.activeOrders: (context) => const ActiveOrdersPage(),
        AppRoutes.trackOrder: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return TrackOrderPage(
            orderId: args?['orderId'] ?? '',
            deliveryAddress: args?['address'],
            status: args?['status'],
          );
        },
        AppRoutes.locationPicker: (context) => const LocationPickerScreen(),
        AppRoutes.search: (context) => const SearchPage(),
      };
}
