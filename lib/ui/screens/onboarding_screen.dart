import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Get Discounts\nOn All Products',
      'subtitle': 'Fresh shrimp, fish & premium seafood at unbeatable prices.',
      'image':'lib/ui/themes/images/logowithoutback.png',
      'isAsset': true,
    },
    {
      'title': 'Premium Quality • Farm Fresh • 100% Safe',
      'subtitle': 'Freshly sourced, hygienically cleaned, and \npacked to preserve natural taste.',
      'image': 'lib/ui/themes/images/image copy 10.png',
      'isAsset': true,
    },
    {
      'title': 'Best Deals on All Seafood',
      'subtitle': 'Get amazing discounts on shrimp, prawns & more.',
      'image': 'lib/ui/themes/images/image copy 9.png', 
      'isAsset': true,
    },
    {
      'title': 'Same-Day Delivery • Secure Packaging • Track Your Order',
      'subtitle': 'From ocean to your kitchen in record time',
      'image': 'lib/ui/themes/images/image copy 11.png', 
      'isAsset': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _getStarted() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            page['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            page['subtitle'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          
          // Image
          Expanded(
            child: Center(
              child: page['isAsset']
                  ? Image.asset(
                      page['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                      },
                    )
                  : Text(
                      page['image'],
                      style: const TextStyle(fontSize: 150),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      // We purposefully use a Column here to always show the dots and the Get Started button,
      // exactly as the user requested for ALL splash screens.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDot(index: index),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Get started',
            onPressed: _getStarted,
            backgroundColor: const Color(0xFF2E7D32),
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
