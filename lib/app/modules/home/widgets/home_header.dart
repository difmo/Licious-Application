import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/main_controller.dart';
import '../../../widgets/bounce_widget.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/notification_api_service.dart';
import '../../../routes/app_routes.dart';
import './location_bottom_sheet.dart';
import '../../location/widgets/location_permission_sheet.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar (Profile & Wallet) ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Wallet Placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.purple.shade300),
                    const SizedBox(width: 4),
                    const Text('₹0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              // Profile
              BounceWidget(
                onTap: () {
                  MainControllerScope.of(context).changePage(4);
                },
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFF3F4F6),
                  child: Icon(Icons.person_outline, color: Color(0xFF1A1A1A), size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // ── Location Selector ───────────────────────────────────────────
          InkWell(
            onTap: () {
              if (selectedAddress == null) {
                LocationPermissionSheet.show(context);
              } else {
                LocationBottomSheet.show(context);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Color(0xFF38B24D)),
                    const SizedBox(width: 4),
                    Text(
                      selectedAddress?.title ?? 'Set Location',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF1A1A1A)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    selectedAddress?.street ?? 'Add your delivery address to start shopping',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Search Bar Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
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
                          color: Color(0xFF38B24D),
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF38B24D),
                      ),
                      suffixIcon: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VerticalDivider(indent: 10, endIndent: 10),
                          Icon(Icons.mic, color: Color(0xFF38B24D)),
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
