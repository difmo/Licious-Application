import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/main_controller.dart';
import '../../../widgets/bounce_widget.dart';
import '../../../routes/app_routes.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
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
                            fontSize: 14.6,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                    Text(
                      'Vibhav Khand, Gomti Nagar, L...',
                      style: TextStyle(fontSize: 10.2, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Header Buttons
              const SizedBox(width: 8),

              // Cart Icon removed from here
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
