import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/services/db_service.dart';
import '../../cart/view/cart_page.dart';
import '../controller/main_controller.dart';
import '../../../widgets/bounce_widget.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                    Text(
                      'Vibhav Khand, Gomti Nagar, L...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Header Buttons
              const SizedBox(width: 8),

              // Cart Icon with Badge
              BounceWidget(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
                child: Stack(
                  children: [
                    if (cart.itemCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BounceWidget(
                onTap: () {
                  final mainController = MainControllerScope.of(context);
                  mainController.changePage(4);
                },
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color.fromARGB(255, 199, 250, 104),
                  child: Text(
                    'R',
                    style: TextStyle(color: Colors.black, fontSize: 14),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, duration: 400.ms, curve: Curves.easeOut);
  }

}
