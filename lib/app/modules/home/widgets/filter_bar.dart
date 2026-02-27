import 'package:flutter/material.dart';
import '../view/filter_page.dart';

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
          const SizedBox(width: 8),
          _buildFilterChip(
            Icons.bolt,
            'Near & Fast',
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
            color: isSelected
                ? const Color(0xFF68B92E)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF68B92E).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
