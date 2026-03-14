import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/food_models.dart';
import '../../../widgets/bounce_widget.dart';

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
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, duration: 400.ms),
        // Distributed Categories Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: categories
                .asMap()
                .entries
                .map((entry) => _buildCategoryItem(entry.value, entry.key))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(FoodCategory category, int index) {
    return BounceWidget(
      onTap: () => onCategorySelected(category.name),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
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
    )
        .animate(delay: (50 * index).ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms);
  }
}
