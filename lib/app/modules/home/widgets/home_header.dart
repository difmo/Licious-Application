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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth > 700;
        final double horizontalPadding = isTablet ? 32.0 : 16.0;
        final cart = CartProviderScope.of(context);
        final selectedAddress = cart.selectedAddress;

        return Container(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar (Location & Profile) ──────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location Selector
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (selectedAddress == null) {
                          LocationPermissionSheet.show(context);
                        } else {
                          LocationBottomSheet.show(context);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 22, color: Color(0xFF38B24D)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    selectedAddress?.title ?? 'Set Location',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 24, color: Color(0xFF1A1A1A)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
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
                  ),
                  const SizedBox(width: 16),
                  // Profile
                  BounceWidget(
                    onTap: () {
                      MainControllerScope.of(context).changePage(4);
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFF3F4F6),
                      child: Icon(Icons.person_outline, color: Color(0xFF1A1A1A), size: 24),
                    ),
                  ),
                ],
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
                          hintText: 'Search Shrimp type...',
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
      },
    );
  }
}
