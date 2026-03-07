import 'package:flutter/material.dart';
import 'category_items_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'icon': Icons.set_meal,
        'label': 'White Shrimp',
        'bgColor': const Color(0xFFFFF8E1),
        'iconColor': Colors.orangeAccent,
      },
      {
        'icon': Icons.water,
        'label': 'Tiger Shrimp',
        'bgColor': const Color(0xFFE8F5E9),
        'iconColor': Colors.green,
      },
      {
        'icon': Icons.restaurant_menu,
        'label': 'Peeled Shrimp',
        'bgColor': const Color(0xFFF3E5F5),
        'iconColor': Colors.purpleAccent,
      },
      {
        'icon': Icons.opacity,
        'label': 'Edible oil',
        'bgColor': const Color(0xFFE0F7FA),
        'iconColor': Colors.cyan,
      },
      {
        'icon': Icons.cleaning_services,
        'label': 'Household',
        'bgColor': const Color(0xFFFCE4EC),
        'iconColor': Colors.pinkAccent,
      },
      {
        'icon': Icons.child_care,
        'label': 'Babycare',
        'bgColor': const Color(0xFFE3F2FD),
        'iconColor': Colors.blue,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            icon: const Icon(Icons.tune, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
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
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryItemsPage(categoryName: category['label']),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: category['bgColor'],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'],
                        color: category['iconColor'],
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category['label'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
