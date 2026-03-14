import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './profile_detail_page.dart';
import './edit_profile_page.dart';
import '../../../data/services/auth_service.dart' as auth;
import '../../../data/models/auth_models.dart' as models;
import '../../../data/services/db_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/favorites_service.dart';
import './my_orders_page.dart';
import '../../auth/provider/auth_provider.dart';
import '../../subscriptions/view/subscription_dashboard_page.dart';
import '../../home/view/favorites_page.dart';
import '../../../routes/app_routes.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(auth.userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(auth.userProfileProvider.future),
          color: const Color(0xFF114F3B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileAsync.when(
                  data: (user) => _ProfileHeader(user: user),
                  loading: () => const _ProfileHeaderSkeleton(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 30),
                const _ActiveOrdersAndSubscriptions(),
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
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 14, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 150, height: 28, color: Colors.white),
            ],
          ),
          const CircleAvatar(radius: 40, backgroundColor: Colors.white),
        ],
      ),
    );
  }
}

class Shimmer extends StatelessWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Opacity(opacity: 0.5, child: child);
}

class _ProfileHeader extends StatelessWidget {
  final models.UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName;
    final email = user.email;
    final phone = user.phoneNumber;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (user.role == 'retailer') ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isShopActive
                        ? const Color(0xFF68B92E).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isShopActive
                          ? const Color(0xFF68B92E)
                          : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              user.isShopActive ? const Color(0xFF68B92E) : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isShopActive ? 'SHOP OPEN' : 'SHOP CLOSED',
                        style: TextStyle(
                          color: user.isShopActive
                              ? const Color(0xFF114F3B)
                              : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                color: const Color(0xFFEBFFD7),
                border: Border.all(color: const Color(0xFF114F3B).withOpacity(0.1)),
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
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Arriving in 15 mins',
                        style: TextStyle(
                            color: Color(0xFF114F3B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
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
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    '2 Active Plans',
                    style: TextStyle(
                      color: Color(0xFFA5C9AD),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5C9AD).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Renewal Jun 11, 2023',
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
          title: 'Reorder\nFavorite',
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
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                            fontSize: 12,
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
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileDetailPage(title: title)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
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
          CartProviderScope.of(context).clearSession();
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
