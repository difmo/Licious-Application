import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import '../widgets/home_header.dart';
import '../widgets/category_circles.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_banner.dart';
import '../widgets/restaurant_list_section.dart';
import '../../categories/view/category_items_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final categories = cart.foodCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header: Location & Search
            const SliverToBoxAdapter(child: HomeHeader()),

            // Categories
            SliverPadding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              sliver: SliverToBoxAdapter(
                child: CategoryCircles(
                  categories: categories,
                  onCategorySelected: (name) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryItemsPage(categoryName: name),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Filters
            const SliverToBoxAdapter(child: FilterBar()),

            // Divider
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
            ),

            // Banner (Horizontal Scrolling Carousel)
            const SliverToBoxAdapter(child: HomeBanner()),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Restaurants Section ─────────────────────────────────────
            const SliverToBoxAdapter(child: RestaurantListSection()),

            // Footer
            const SliverToBoxAdapter(child: AnimatedFooterText()),

            // Bottom Spacing for Navigation Bar
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

class AnimatedFooterText extends StatefulWidget {
  const AnimatedFooterText({super.key});

  @override
  State<AnimatedFooterText> createState() => _AnimatedFooterTextState();
}

class _AnimatedFooterTextState extends State<AnimatedFooterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text(
          'With love,\nfrom Shrimp.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB4B4B4), // light grey matching the image
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
      ),
    );
  }
}
