import 'package:flutter/material.dart';
import '../../../data/models/food_models.dart';

class CategoryCircles extends StatelessWidget {
  final List<FoodCategory> categories;
  final Function(String) onCategorySelected;

  const CategoryCircles({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        // Distributed Categories Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: categories
                .map((category) => _buildCategoryItem(category))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(FoodCategory category) {
    return GestureDetector(
      onTap: () => onCategorySelected(category.name),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(category.colorValue),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                category.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.category, size: 32, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
