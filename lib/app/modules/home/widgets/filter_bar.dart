import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../view/filter_page.dart';
import '../../../widgets/bounce_widget.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  String _selectedFilter = 'Near & Fast';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip(
            Icons.tune,
            'Filters',
            hasDropdown: true,
            index: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilterPage()),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            Icons.bolt,
            'Near & Fast',
            index: 1,
            isSelected: _selectedFilter == 'Near & Fast',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'Near & Fast'
                    ? ''
                    : 'Near & Fast';
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            null,
            'Under ₹150',
            index: 2,
            isSelected: _selectedFilter == 'Under ₹150',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'Under ₹150'
                    ? ''
                    : 'Under ₹150';
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            null,
            'Schedule',
            index: 3,
            isSelected: _selectedFilter == 'Schedule',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'Schedule'
                    ? ''
                    : 'Schedule';
              });
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
    required int index,
    VoidCallback? onTap,
  }) {
    return BounceWidget(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF68B92E)
                : Colors.grey.withValues(alpha:  0.2),
            width: 1,
          ),
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
    ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}


