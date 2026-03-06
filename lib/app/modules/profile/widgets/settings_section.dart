import 'package:flutter/material.dart';

class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class SettingsSection extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isFirst = entry.key == 0;
          final isLast = entry.key == items.length - 1;
          return ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(20) : Radius.zero,
              bottom: isLast ? const Radius.circular(20) : Radius.zero,
            ),
            child: Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  leading: Icon(
                    item.icon,
                    color: const Color(0xFF68B92E),
                    size: 24,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFD1D1D1),
                    size: 24,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.withValues(alpha:  0.15),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


