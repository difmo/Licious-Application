import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/db_service.dart';
import '../controller/main_controller.dart';
import '../../../widgets/bounce_widget.dart';
import '../view/notifications_page.dart';
import 'voice_search_dialog.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      // decoration: const BoxDecoration(color: Color(0xFFF9FFF6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Picker Row
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF1A1A1A), size: 18),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Vibhav Khand -4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 15),
                      ],
                    ),
                    Text(
                      'Vibhav Khand, Gomti Nagar, L...',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Header Buttons
              const SizedBox(width: 8),

              // Notification Icon
              BounceWidget(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final notifications = ref.watch(notificationsProvider);
                      final hasUnread = notifications.any((n) => !n.isRead);
                      return Badge(
                        isLabelVisible: hasUnread,
                        smallSize: 8,
                        backgroundColor: const Color(0xFF68B92E),
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 22, color: Color(0xFF1A1A1A)),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),
              // Profile Icon
              BounceWidget(
                onTap: () {
                  MainControllerScope.of(context).changePage(4);
                },
                child: Hero(
                  tag: 'profile_pic',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(cart.userProfile.profileImage),
                  ),
                ),
              ),
            ],
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
                    controller: _searchController,
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
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VerticalDivider(indent: 10, endIndent: 10),
                          GestureDetector(
                            onTap: () async {
                              final result =
                                  await VoiceSearchDialog.show(context);
                              if (result != null && result.isNotEmpty) {
                                _searchController.text = result;
                              }
                            },
                            child: Container(
                              color:
                                  Colors.transparent, // Ensures easy tap target
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: const Icon(Icons.mic,
                                  color: Color(0xFFE54141)),
                            ),
                          ),
                          const SizedBox(width: 8),
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
