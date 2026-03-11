import 'package:flutter/material.dart';
import 'package:licius_application/app/routes/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ---------- page data ----------
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Get Discounts\nOn All Products',
      'subtitle': 'Fresh shrimp, fish & premium seafood at\nunbeatable prices.',
      'image': 'assets/images/logowithoutback.png',
      'layout': 'standard', // title top, image center
    },
    {
      'title': 'Premium Quality\nFarm Fresh',
      'subtitle':
          'Freshly sourced, hygienically cleaned, and\npacked to preserve natural taste.',
      'image': 'assets/images/image copy 2.png',
      'layout': 'card', // title top, image in rounded card
    },
    {
      'title': 'Best Deals on\nAll Seafood',
      'subtitle': 'Get amazing discounts on shrimp, prawns &\nmore every day.',
      'image': 'assets/images/image copy 5.png',
      'layout': 'fullimage', // image fills top, curved white bottom
    },
    {
      'title': 'Fast Delivery',
      'subtitle': 'From ocean to your kitchen in record time,\nfresh and safe.',
      'image': 'assets/images/image copy 4.png',
      'layout': 'bottom', // image top half, title+subtitle bottom, skip/next
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, AppRoutes.login);

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final layout = page['layout'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (ctx, i) {
              final p = _pages[i];
              switch (p['layout']) {
                case 'card':
                  return _buildCardLayout(p);
                case 'fullimage':
                  return _buildFullImageLayout(p);
                case 'bottom':
                  return _buildBottomLayout(p);
                default:
                  return _buildStandardLayout(p);
              }
            },
          ),

          // Bottom controls (dots + button)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child:
                layout == 'bottom' ? _buildSkipNextNav() : _buildSkipNextNav(),
          ),
        ],
      ),
    );
  }

  // ─── Layout 1: Standard (title top, logo center) ──────────────────────────
  Widget _buildStandardLayout(Map<String, dynamic> page) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.55,
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  page['image'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Layout 2: Card (title top, image in rounded card) ───────────────────
  Widget _buildCardLayout(Map<String, dynamic> page) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  page['image'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Layout 3: Full image top, curved white bottom ────────────────────────
  Widget _buildFullImageLayout(Map<String, dynamic> page) {
    return Stack(
      children: [
        // Full-bleed image
        Positioned.fill(
          child: Image.asset(
            page['image'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey.shade300),
          ),
        ),
        // Curved white card at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page['title'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  page['subtitle'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Layout 4: Image top half, text bottom, Skip/Next ────────────────────
  Widget _buildBottomLayout(Map<String, dynamic> page) {
    return Column(
      children: [
        // Top image (50%)
        Expanded(
          child: Image.asset(
            page['image'],
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey.shade300),
          ),
        ),
        // Bottom white area
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                page['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                page['subtitle'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Nav: Skip · dots · Next ──────────────────────────────────────────────
  Widget _buildSkipNextNav() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildDots(),
          GestureDetector(
            onTap: _next,
            child: const Text(
              'Next',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dots ─────────────────────────────────────────────────────────────────
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == i ? 20 : 8,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
