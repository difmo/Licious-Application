import 'package:flutter/material.dart';
import '../view/filter_page.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            Icons.tune,
            'Filters',
            hasDropdown: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilterPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    IconData? icon,
    String label, {
    bool isSelected = false,
    bool hasDropdown = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF68B92E) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF68B92E) : Colors.black,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
