import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../widgets/home_header.dart';
import '../widgets/category_circles.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_banner.dart';
import '../widgets/product_card.dart';
import '../../categories/view/category_items_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final categories = cart.foodCategories;

    return Scaffold(
      backgroundColor: Colors.white,
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

            const SliverToBoxAdapter(child: SizedBox(height: 15)),

            // Banner (Horizontal Scrolling Carousel)
            const SliverToBoxAdapter(child: HomeBanner()),

            // Recommended Section Header
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'RECOMMENDED FOR YOU',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // Product Grid (Recommended)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // Adjusted for new card height
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final products = cart.recommendedProducts;
                  final product = products[index % products.length];

                  return ProductCard(
                    product: product,
                    onAdd: () {
                      cart.addToCart(CartItem.fromProduct(product));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    onFavorite: () {
                      cart.toggleFavorite(product.id);
                    },
                  );
                }, childCount: 14), // Showing 14 items now
              ),
            ),

            // Animated Footer
            const SliverToBoxAdapter(child: AnimatedFooterText()),

            // Bottom Spacing for Navigation Bar
            const SliverPadding(padding: EdgeInsets.only(bottom: 15)),
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
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Text(
          'With Love,\nFrom ShrimpBite.',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 60,
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
