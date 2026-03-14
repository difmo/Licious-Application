import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/categories_controller.dart';
import '../../../data/models/food_models.dart';
import 'category_items_page.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const _LoadingGrid(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) => categories.isEmpty
            ? const _EmptyView()
            : _CategoriesGrid(categories: categories),
      ),
    );
  }
}

// ── Grid ────────────────────────────────────────────────────────────────────

class _CategoriesGrid extends StatelessWidget {
  final List<FoodCategory> categories;

  const _CategoriesGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(category: category, index: index);
      },
    );
  }
}

/// Palette used when the API doesn't supply a colorValue.
const List<Color> _kCategoryPalette = [
  Color(0xFFFFF3E0), // amber
  Color(0xFFE8F5E9), // green
  Color(0xFFE3F2FD), // blue
  Color(0xFFF3E5F5), // purple
  Color(0xFFE0F7FA), // cyan
  Color(0xFFFCE4EC), // pink
  Color(0xFFF9FBE7), // lime
  Color(0xFFFFF8E1), // yellow
];

class _CategoryCard extends StatelessWidget {
  final FoodCategory category;
  final int index;

  const _CategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryItemsPage(
                categoryName: category.name, categoryId: category.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                // Use API color if set, otherwise pick from palette by index
                color: category.colorValue != 0xFFF7F8FA
                    ? Color(category.colorValue)
                    : _kCategoryPalette[index % _kCategoryPalette.length],
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _CategoryImage(imageUrl: category.image),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (60 * index).ms)
        .scale(duration: 350.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }
}

/// Shows a network image, falls back to a local asset icon on error.
class _CategoryImage extends StatelessWidget {
  final String imageUrl;
  const _CategoryImage({required this.imageUrl});

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.category_outlined,
          size: 30,
          color: Colors.grey,
        ),
      );
    }
    // local asset
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.category_outlined,
        size: 30,
        color: Colors.grey,
      ),
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemCount: 9,
      itemBuilder: (_, index) => _SkeletonCard()
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: Colors.grey.shade200),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 56, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load categories',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined,
                size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          const Text(
            'No categories yet',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Categories will appear here once added.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
