import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/db_service.dart';
import '../widgets/home_header.dart';
import '../widgets/category_circles.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_banner.dart';
import '../widgets/restaurant_list_section.dart';
import '../../categories/view/category_items_page.dart';
import 'restaurant_menu_page.dart';
import '../../../data/models/shop_product_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final categories = cart.foodCategories;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          bottom: false,
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

              // Favorite Restaurants (Horizontal tray)
              SliverToBoxAdapter(child: _buildFavoriteTray(context, cart)),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Restaurants Section
              const SliverToBoxAdapter(child: RestaurantListSection()),

              // Footer
              const SliverToBoxAdapter(child: AnimatedFooterText()),

              // Bottom Spacing for Navigation Bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteTray(BuildContext context, CartProvider provider) {
    final favorites = provider.favRestaurants;
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Your Favorites',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final restaurant = favorites[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantMenuPage(
                        shop: ShopModel(
                          id: restaurant.id,
                          name: restaurant.name,
                          image: restaurant.image,
                          businessName: restaurant.name,
                          rating: restaurant.rating,
                          deliveryTime: restaurant.deliveryTime,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          restaurant.image,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
            color: Color(0xFFB4B4B4),
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
      ),
    );
  }
}
