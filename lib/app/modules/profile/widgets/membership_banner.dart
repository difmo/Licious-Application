import 'package:flutter/material.dart';

class MembershipBanner extends StatelessWidget {
  final VoidCallback onTap;

  const MembershipBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:  0.3),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gold Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFE6B347),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            // Text
            const Expanded(
              child: Text(
                'Join Zomato Gold',
                style: TextStyle(
                  color: Color(0xFFE6B347),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right, color: Color(0xFFE6B347), size: 24),
          ],
        ),
      ),
    );
  }
}


