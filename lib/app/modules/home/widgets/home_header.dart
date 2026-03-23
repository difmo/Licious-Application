import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/main_controller.dart';
import '../../../widgets/bounce_widget.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/notification_api_service.dart';
import '../../../routes/app_routes.dart';
import './location_bottom_sheet.dart';
import '../../profile/view/profile_detail_page.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final selectedAddress = cart.selectedAddress;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Picker Row
          InkWell(
            onTap: () => LocationBottomSheet.show(context),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF1A1A1A), size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              selectedAddress?.title ?? 'Set Location',
                              style: const TextStyle(
                                fontSize: 17.6,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                        ],
                      ),
                      Text(
                        selectedAddress != null
                            ? '${selectedAddress.street}\n${selectedAddress.details}'
                            : 'Add address to start ordering',
                        style: const TextStyle(
                            fontSize: 15.2, color: Colors.grey, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Header Buttons
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final notificationsAsync = ref.watch(notificationsProvider);
                    final unreadCount = notificationsAsync.maybeWhen(
                      data: (list) => list.where((n) => !n.isRead).length,
                      orElse: () => 0,
                    );

                    return BounceWidget(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileDetailPage(title: 'Notifications'),
                          ),
                        ).then((_) {
                          // Refresh when coming back in case marks were made
                          ref.invalidate(notificationsProvider);
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_outlined,
                            color: Color(0xFF1A1A1A),
                            size: 26,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE54141),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 8,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),

                BounceWidget(
                  onTap: () {
                    MainControllerScope.of(context).changePage(4);
                  },
                  child: Hero(
                    tag: 'profile_pic',
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.shade200,
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFE54141),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                    decoration: InputDecoration(
                      hintText: 'Search "curries"',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF68B92E),
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFE54141),
                      ),
                      suffixIcon: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VerticalDivider(indent: 10, endIndent: 10),
                          Icon(Icons.mic, color: Color(0xFFE54141)),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, duration: 400.ms, curve: Curves.easeOut);
  }
}
