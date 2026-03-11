import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './profile_detail_page.dart';
import './edit_profile_page.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/favorites_service.dart';
import './my_orders_page.dart';
import './transactions_page.dart';
import './saved_cards_page.dart';
import '../../auth/provider/auth_provider.dart';
import '../../home/controller/main_controller.dart';
import '../../subscriptions/view/subscription_dashboard_page.dart';
import '../../home/view/favorites_page.dart';
import '../../../routes/app_routes.dart';
import '../../wallet/view/wallet_page.dart' show walletBalanceProvider;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Sync wallet balance whenever the profile tab is visited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CartProviderScope.of(context).syncWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = CartProviderScope.of(context);
    final profile = provider.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4EC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(user: profile),
              const SizedBox(height: 30),
              const _ActiveOrdersAndSubscriptions(),
              const SizedBox(height: 24),
              const _WalletSection(),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                    color: Color(0xFF114F3B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _QuickActionsRow(),
              const SizedBox(height: 24),
              const _ListTilesSection(),
              const SizedBox(height: 32),
              const _SignOutButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user; // UserModel or null

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Dashboard',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              Text(
                'Hello, ${name.split(' ').first}!',
                style: const TextStyle(
                  color: Color(0xFF114F3B),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                  ),
                ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF114F3B).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFEBFFD7),
              radius: 40,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF114F3B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveOrdersAndSubscriptions extends ConsumerWidget {
  const _ActiveOrdersAndSubscriptions();

  void _navigateToDetail(BuildContext context, String title) {
    if (title == 'Active Orders') {
      Navigator.pushNamed(context, AppRoutes.activeOrders);
    } else if (title == 'My Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyOrdersPage()),
      );
    } else if (title == 'Subscriptions') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SubscriptionDashboardPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfileDetailPage(title: title)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    // Count active orders from the dedicated provider
    final activeOrdersCount = activeOrdersAsync.maybeWhen(
      data: (orders) => orders.length,
      orElse: () => 0,
    );

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToDetail(context, 'Active Orders'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFA5C9AD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF114F3B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Active Orders',
                    style: TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    activeOrdersCount > 0
                        ? '$activeOrdersCount Active Order${activeOrdersCount > 1 ? 's' : ''}'
                        : 'No Active Orders',
                    style: const TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 12,
                    ),
                    // loading: () => const SizedBox(
                    //   height: 12,
                    //   width: 80,
                    //   child: LinearProgressIndicator(
                    //     backgroundColor: Color(0xFF7BAE87),
                    //     color: Color(0xFF114F3B),
                    //   ),
                    // ),
                    // error: (_, __) => const Text('—',
                    //     style:
                    //         TextStyle(color: Color(0xFF114F3B), fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  if (activeOrdersCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              size: 10, color: Color(0xFF114F3B)),
                          const SizedBox(width: 4),
                          const Text('Live Tracking ON',
                              style: TextStyle(
                                  color: Color(0xFF114F3B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToDetail(context, 'Subscriptions'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF114F3B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5C9AD).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_membership_outlined,
                        color: Color(0xFFA5C9AD), size: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Subscriptions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'View your plans',
                    style: TextStyle(
                      color: Color(0xFFA5C9AD),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5C9AD).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Manage Plans',
                        style:
                            TextStyle(color: Color(0xFFA5C9AD), fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletSection extends ConsumerWidget {
  const _WalletSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);

    return GestureDetector(
      onTap: () {
        MainControllerScope.of(context).changePage(3);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4EC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(-4, -4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF114F3B), size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Wallet',
                      style: TextStyle(
                          color: Color(0xFF114F3B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('Check balance & statements',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Balance',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
                balanceAsync.when(
                  data: (balance) => Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFF114F3B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  loading: () => const SizedBox(
                    width: 70,
                    height: 18,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFDEEDD4),
                      color: Color(0xFF114F3B),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  error: (_, __) => const Text('—',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFA5C9AD), size: 14),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favCount = ref.watch(favoriteProductsProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionBtn(
          title: 'Favorite\nProducts',
          navigateTo: 'My Favorites',
          badgeCount: favCount,
        ),
        const _QuickActionBtn(
            title: 'View All\nOrders', navigateTo: 'My Orders'),
        const _QuickActionBtn(title: 'Edit\nAddress', navigateTo: 'My Address'),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String title;
  final String navigateTo;
  final int badgeCount;

  const _QuickActionBtn({
    required this.title,
    required this.navigateTo,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFavBtn = navigateTo == 'My Favorites';

    return GestureDetector(
      onTap: () {
        if (navigateTo == 'My Orders') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyOrdersPage()),
          );
        } else if (isFavBtn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfileDetailPage(title: navigateTo)),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4EC),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(-4, -4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(4, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isFavBtn
                      ? (badgeCount > 0
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded)
                      : navigateTo == 'My Orders'
                          ? Icons.receipt_long_rounded
                          : Icons.location_on_rounded,
                  color: isFavBtn && badgeCount > 0
                      ? Colors.red
                      : const Color(0xFF114F3B),
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF114F3B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTilesSection extends StatelessWidget {
  const _ListTilesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ListTileItem(icon: Icons.notifications_none, title: 'Notifications'),
      ],
    );
  }
}

class _ListTileItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ListTileItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'Transaction History') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsPage()),
          );
        } else if (title == 'Credit/Debit Card') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavedCardsPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfileDetailPage(title: title)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4EC),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(-4, -4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF114F3B), size: 24),
            const SizedBox(width: 16),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Color(0xFF114F3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFA5C9AD), size: 16),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Sign Out',
                style: TextStyle(
                    color: Color(0xFF114F3B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(width: 8),
            Icon(Icons.logout, color: Color(0xFF114F3B)),
          ],
        ),
      ),
    );
  }
}
