import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import '../../cart/view/cart_page.dart';
import '../../profile/view/profile_page.dart';
import '../../subscription/subscription_page.dart';
import '../../wallet/view/wallet_page.dart';
import '../controller/main_controller.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/socket_service.dart';
import '../../../data/services/order_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../profile/widgets/order_review_dialog.dart';
import '../../../data/models/food_models.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_api_service.dart';
import '../widgets/cart_summary_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final MainController _controller = MainController();
  DateTime? _lastPressedAt;

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
      _initSocketListeners();
    });
  }

  void _initSocketListeners() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final socket = ref.read(socketServiceProvider);
    final userId = authState.user.id;

    // Join the user's personal room to receive order updates
    socket.joinUserRoom(userId);

    // Listen for order status changes
    socket.onOrderUpdate((data) {
      if (!mounted) return;

      debugPrint('🔔 Order update in MainPage: $data');

      // Determine if the order has been delivered
      final status = (data['status']?.toString() ?? '').toLowerCase();
      if (status == 'delivered' || status == 'completed') {
        _handleOrderDelivered(data);

        // Add to notifications list locally for persistent history
        final orderId = data['orderId']?.toString() ?? 'Order';
        ref.read(notificationsProvider.notifier).addNotification(
              NotificationModel(
                id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
                title: 'Order Delivered! 🎉',
                body:
                    'Package #$orderId has been delivered successfully. Enjoy!',
                type: 'order',
                isRead: false,
                createdAt: DateTime.now(),
              ),
            );
      }
    });
  }

  Future<void> _handleOrderDelivered(dynamic data) async {
    // If we have orderId, fetch full details for the dialog
    final orderId = data['orderId']?.toString();
    if (orderId == null) return;

    try {
      final orderService = ref.read(orderServiceProvider);
      final rawOrder = await orderService.getOrderById(orderId);

      if (rawOrder.isNotEmpty && mounted) {
        final order = UserOrder.fromJson(rawOrder);

        // Show the review dialog automatically
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OrderReviewDialog(order: order),
        );
      }
    } catch (e) {
      debugPrint('Error fetching order for review dialog: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(socketServiceProvider).offOrderUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final bool showSummary =
        cart.itemCount > 0 && _controller.currentIndex != 2;

    return MainControllerScope(
      controller: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;

          if (_controller.currentIndex != 0) {
            _controller.changePage(0);
            return;
          }

          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Press back again to exit the app.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: Color(0xFF114F3B),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            );
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBody: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _controller.currentIndex,
                  children: _pages,
                ),
              ),
              if (showSummary)
                Positioned(
                  bottom: 110, // Just above the custom bottom bar (height ~100)
                  left: 0,
                  right: 0,
                  child: CartSummaryBar(cart: cart),
                ),
            ],
          ),
          bottomNavigationBar: _buildCustomBottomBar(),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                  color: const Color(0xFF68B92E).withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, 'Home'),
                _buildNavItem(1, Icons.local_shipping_outlined, 'Daily'),
                const SizedBox(width: 68), // Space for FAB
                _buildNavItem(3, Icons.wallet_rounded, 'Wallet'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
          // Central FAB (Cart)
          Positioned(
            top: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF68B92E)
                  : const Color(0xFF4A4A4A),
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
      ),
    );
  }
}
