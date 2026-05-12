import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './profile_detail_page.dart';
import './edit_profile_page.dart';
import '../../auth/provider/auth_provider.dart' as auth;
import '../../../data/models/auth_models.dart' as models;
import '../../../data/services/db_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/favorites_service.dart';
import './my_orders_page.dart';
import '../../subscriptions/view/subscription_dashboard_page.dart';
import '../../home/view/favorites_page.dart';
import '../../../data/services/subscription_service.dart';
import '../../../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import './address_management_page.dart';

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
                name.toLowerCase() == 'shrimpbite user'
                    ? 'Hello, Shrimpbite User'
                    : 'Hello, ${name.split(' ').first}!',
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
                        ? const Color(0xFF68B92E).withOpacity(0.2)
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
                          color: user.isShopActive
                              ? const Color(0xFF68B92E)
                              : Colors.red,
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
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFEBFFD7), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Color(0xFF114F3B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveOrdersAndSubscriptions extends ConsumerWidget {
  const _ActiveOrdersAndSubscriptions();

  void _navigateToDetail(BuildContext context, String title) {
    if (title == 'One-Time (Active)') {
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

    final subscriptionsAsync = ref.watch(mySubscriptionsProvider);
    final activeSubscriptionsCount = subscriptionsAsync.maybeWhen(
      data: (subs) => subs.where((s) {
        final st = s.status.toLowerCase();
        return st == 'active' || st == 'paused';
      }).length,
      orElse: () => 0,
    );

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToDetail(context, 'One-Time (Active)'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEBFFD7),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              height: 150,
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
                    'One-Time\n(Active)',
                    style: TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 16,
                      height: 1.1,
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
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              height: 150,
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
                  Text(
                    activeSubscriptionsCount > 0
                        ? '$activeSubscriptionsCount Active Plan${activeSubscriptionsCount > 1 ? 's' : ''}'
                        : 'No Active Plans',
                    style: const TextStyle(
                      color: Color(0xFFA5C9AD),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
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
        const _QuickActionBtn(
          title: 'Manage\nAddresses',
          navigateTo: 'My Address',
        ),
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
            MaterialPageRoute(builder: (context) => FavoritesPage()),
          );
        } else if (navigateTo == 'My Address') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddressManagementPage()),
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(minHeight: 85),
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
                  fontSize: 11,
                  height: 1.2,
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
        _ListTileItem(
            icon: Icons.article_outlined, title: 'Subscription Details'),
        SizedBox(height: 12),
        _ListTileItem(icon: Icons.notifications_none, title: 'Notifications'),
        SizedBox(height: 12),
        _ListTileItem(
            icon: Icons.star_outline_rounded, title: 'Give us rating'),
        SizedBox(height: 12),
        _ListTileItem(
            icon: Icons.support_agent_rounded, title: 'Help and Support'),
        SizedBox(height: 12),
        _ListTileItem(icon: Icons.info_outline_rounded, title: 'About section'),
        SizedBox(height: 12),
        _ListTileItem(icon: Icons.call_outlined, title: 'Contact us'),
        SizedBox(height: 12),
        _ListTileItem(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            isDestructive: true),
      ],
    );
  }
}

class _ListTileItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;

  const _ListTileItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
  });

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Color(0xFF114F3B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SupportItem(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'info@shrimpbite.in',
              onTap: () => launchUrl(Uri.parse('mailto:info@shrimpbite.in')),
            ),
            const SizedBox(height: 16),
            _SupportItem(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: '+91 9148949909',
              onTap: () => launchUrl(Uri.parse('tel:+919148949909')),
            ),
            const SizedBox(height: 16),
            const _SupportItem(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value:
                  'Aqua AVP Shrimp Farmers Pride Pvt Ltd IVRI Road, Yelahanka, Bangalore, Karnataka, India',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subscription Details',
                    style: TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Welcome to ShrimpBite! To ensure you get the freshest seafood exactly when you want it, please review how our scheduling and billing work.',
                      style: TextStyle(
                          color: Colors.grey, height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('🗓️ 1. Flexible Subscription Plans'),
                    _buildBullet('Daily: ', 'Fresh delivery every single day.'),
                    _buildBullet('Alternative Days: ',
                        'Delivery every other day (Gap of 1 day).'),
                    _buildBullet('Custom Weekdays: ',
                        'Pick specific days (e.g., only Mondays, Wednesdays, and Fridays).'),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        '🏖️ 2. Vacation Mode (Pause Delivery)'),
                    const Text(
                      'Going away? You can pause your deliveries without canceling your subscription.',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildBullet(
                        'Vacation ON: ', 'All upcoming deliveries are paused.'),
                    _buildBullet('Vacation OFF: ',
                        'Deliveries resume based on your original schedule.'),
                    const SizedBox(height: 20),
                    _buildSectionHeader('⏰ 3. The 8:00 PM "Cut-off" Rule'),
                    const Text(
                      'This is the most important rule for making changes. Our shop owners start prepping your fresh catch by 8:00 PM every night.',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEBFFD7).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBullet('Before 8:00 PM: ', 'Starts Tomorrow'),
                          _buildBullet(
                              'After 8:00 PM: ', 'Starts Day After Tomorrow'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Why the delay? To guarantee maximum freshness and stock availability, we finalize all orders by 8:00 PM. Late-night changes happen after the next day\'s prep is already complete.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    const Text('Real-World Examples:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildBullet('Morning: ',
                        '"10:00 AM Monday. I turn Vacation ON. My Tuesday delivery is paused."'),
                    _buildBullet('Night: ',
                        '"9:30 PM Monday. I turn Vacation ON. Since it\'s past 8:00 PM, my Tuesday delivery is already packed. My vacation starts Wednesday."'),
                    const SizedBox(height: 20),
                    _buildSectionHeader('💳 4. Wallet & Payments'),
                    const Text(
                      'We believe in a "No Delivery = No Charge" policy.',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildBullet('One-time Orders: ',
                        'Charged instantly when you checkout.'),
                    _buildBullet('Subscriptions: ',
                        'Money is deducted automatically from your wallet at 12:01 AM on the day of delivery.'),
                    _buildBullet('Vacation Rule: ',
                        'If Vacation Mode is active, no money is deducted.'),
                    const SizedBox(height: 12),
                    const Text('Refunds & Credits',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF114F3B))),
                    const SizedBox(height: 4),
                    _buildBullet('Weight Adjustments: ',
                        'If you pay for 1kg but we deliver 900g, the difference is credited back to your wallet instantly.'),
                    _buildBullet('Cancellations: ',
                        'Approved cancellations are refunded immediately to your Shrimpbite Wallet.'),
                    const SizedBox(height: 20),
                    _buildSectionHeader('⚠️ 5. Important Notes'),
                    _buildBullet('Low Balance: ',
                        'If your wallet doesn\'t have enough funds at midnight, the delivery will be skipped, and you’ll receive a "Low Balance" notification.',
                        isWarning: true),
                    _buildBullet('Missed Cut-off: ',
                        'If you forget to turn on Vacation Mode before 8:00 PM, the system will charge and deliver the next day\'s order as planned.',
                        isWarning: true),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF114F3B),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBullet(String title, String description,
      {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  fontSize: 16,
                  color: isWarning ? Colors.red : Colors.black87)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                      text: title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isWarning ? Colors.red : Colors.black)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (title == 'About me') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfilePage()),
          );
        } else if (title == 'My Address' || title == 'Saved Addresses') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddressManagementPage()),
          );
        } else if (title == 'Give us rating') {
          final url = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.shrimpbite.app');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } else if (title == 'About section') {
          final url = Uri.parse('https://shrimpbite.in/index.php/about-us/');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } else if (title == 'Contact us') {
          final url = Uri.parse('tel:+919148949909');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        } else if (title == 'Help and Support') {
          _showHelpSupportModal(context);
        } else if (title == 'Subscription Details') {
          _showSubscriptionGuideModal(context);
        } else if (title == 'Delete Account') {
          final user = ref.read(auth.currentUserProvider);
          if (user != null) {
            _showDeleteAccountDialog(context, user, ref);
          }
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
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive ? Colors.red : const Color(0xFF114F3B),
                size: 24),
            const SizedBox(width: 16),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: isDestructive
                            ? Colors.red
                            : const Color(0xFF114F3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded,
                color: isDestructive
                    ? Colors.red.withOpacity(0.5)
                    : const Color(0xFFA5C9AD),
                size: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, models.UserModel user, WidgetRef ref) {
    String? selectedReason;
    final List<String> reasons = [
      "I don't use this app anymore",
      "I found a better alternative",
      "Privacy concerns",
      "Too many notifications",
      "Account security issues",
      "Other",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We are sorry to see you go. Please let us know why you want to delete your account.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, 'Name', user.fullName),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.phone_android_outlined, 'Mobile',
                            user.phoneNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select a reason:',
                    style: TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((reason) => RadioListTile<String>(
                        title: Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setModalState(() {
                            selectedReason = value;
                          });
                        },
                      )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(auth.authProvider);
                        final isLoading = authState is auth.AuthLoading;

                        return ElevatedButton(
                          onPressed: selectedReason == null || isLoading
                              ? null
                              : () async {
                                  final confirm =
                                      await _showConfirmDialog(context);
                                  if (confirm == true) {
                                    final success = await ref
                                        .read(auth.authProvider.notifier)
                                        .deleteAccount(reason: selectedReason);

                                    if (success && context.mounted) {
                                      Navigator.pop(context); // Close modal
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.login,
                                        (route) => false,
                                      );
                                    } else if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Failed to delete account. Please try again.')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Delete',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF114F3B)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This action is irreversible. All your data, orders, and wallet balance will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SupportItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEBFFD7).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF114F3B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF114F3B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.open_in_new, color: Color(0xFF114F3B), size: 14),
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
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Are you sure?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Do you really want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            CartProviderScope.of(context).clearSession();
            await ref.read(auth.authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            }
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
