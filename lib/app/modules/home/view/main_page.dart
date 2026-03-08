import 'package:flutter/material.dart';
import 'home_page.dart';
import 'favorites_page.dart';
import '../../cart/view/cart_page.dart';
import '../../profile/view/profile_page.dart';
import '../../orders/view/orders_page.dart';
import '../../subscription/subscription_page.dart';
import '../../wallet/view/wallet_page.dart';
import '../controller/main_controller.dart';
import '../../../data/services/db_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainController _controller = MainController();

  final List<Widget> _pages = [
    const HomePage(),
    const SubscriptionPage(),
    const CartPage(), // Central FAB
    const WalletPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    // Initial cart sync from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CartProviderScope.of(context).loadCartFromApi();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final bool showSummary =
        cart.itemCount > 0 && _controller.currentIndex != 2;

    return MainControllerScope(
      controller: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFFEBFFD7),
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: _pages[_controller.currentIndex]),
            if (showSummary)
              Positioned(
                bottom: 110, // Just above the custom bottom bar (height ~100)
                left: 16,
                right: 16,
                child: _buildCartSummaryBar(cart),
              ),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomBar(),
      ),
    );
  }

  Widget _buildCartSummaryBar(CartProvider cart) {
    return GestureDetector(
      onTap: () => _controller.changePage(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark premium bar
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF68B92E).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_rounded,
                color: Color(0xFF68B92E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${cart.itemCount} ITEM${cart.itemCount > 1 ? 'S' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '₹${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'VIEW CART',
              style: TextStyle(
                color: Color(0xFF68B92E),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF68B92E),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    bool isCartSelected = _controller.currentIndex == 2;
    return Container(
      height: 100,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Bar
          Container(
            height: 70,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEBFFD7),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                  color: const Color(0xFF68B92E).withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, 'Home'),
                _buildNavItem(1, Icons.favorite_rounded, 'My Favorite'),
                const SizedBox(width: 68), // Space for FAB
                _buildNavItem(3, Icons.receipt_long_rounded, 'Orders'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
          // Central FAB (Cart)
          Positioned(
            top: 5,
            child: GestureDetector(
              onTap: () => _controller.changePage(2),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCartSelected
                        ? const Color(0xFF68B92E)
                        : const Color(0xFF68B92E).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: isCartSelected
                        ? const Color(0xFF68B92E)
                        : const Color(0xFFE6B347),
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _controller.currentIndex == index;
    return GestureDetector(
      onTap: () => _controller.changePage(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected ? const Color(0xFF68B92E) : const Color(0xFF4A4A4A),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF68B92E)
                  : const Color(0xFF4A4A4A),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
