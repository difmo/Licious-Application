import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Defines the categories based on the image provided
    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.energy_savings_leaf, 'label': 'Vegetables', 'bgColor': const Color(0xFFE8F5E9), 'iconColor': Colors.green, 'route': '/vegetables'},
      {'icon': Icons.apple, 'label': 'Fruits', 'bgColor': const Color(0xFFFFEBEE), 'iconColor': Colors.red},
      {'icon': Icons.local_drink, 'label': 'Beverages', 'bgColor': const Color(0xFFFFF8E1), 'iconColor': Colors.orangeAccent},
      {'icon': Icons.shopping_basket, 'label': 'Grocery', 'bgColor': const Color(0xFFF3E5F5), 'iconColor': Colors.purpleAccent},
      {'icon': Icons.opacity, 'label': 'Edible oil', 'bgColor': const Color(0xFFE0F7FA), 'iconColor': Colors.cyan},
      {'icon': Icons.cleaning_services, 'label': 'Household', 'bgColor': const Color(0xFFFCE4EC), 'iconColor': Colors.pinkAccent},
      {'icon': Icons.child_care, 'label': 'Babycare', 'bgColor': const Color(0xFFE3F2FD), 'iconColor': Colors.blue},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                if (category.containsKey('route')) {
                  Navigator.pushNamed(context, category['route']);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: category['bgColor'],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'],
                        color: category['iconColor'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category['label'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
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
