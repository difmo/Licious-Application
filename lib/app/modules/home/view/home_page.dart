import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/db_service.dart';
import '../widgets/home_header.dart';
import '../widgets/home_banner.dart';
import '../widgets/restaurant_list_section.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/shop_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(shopsListProvider.notifier).refresh();
              // Proactively refresh other related data if needed
              CartProviderScope.of(context).loadAddresses();
              CartProviderScope.of(context).syncWallet();
            },
            color: const Color(0xFF68B92E),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header: Location & Search
                const SliverToBoxAdapter(child: HomeHeader()),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Banner (Horizontal Scrolling Carousel)
                const SliverToBoxAdapter(child: HomeBanner()),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
        padding: EdgeInsets.symmetric(vertical: 0),
        child: Text(
          'With love,\nfrom Shrimp.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
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
