import 'package:flutter/material.dart';

class InfoCards extends StatelessWidget {
  final double money;
  final int couponCount;
  final VoidCallback onMoneyTap;
  final VoidCallback onCouponsTap;

  const InfoCards({
    super.key,
    required this.money,
    required this.couponCount,
    required this.onMoneyTap,
    required this.onCouponsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Money Card
          Expanded(
            child: _buildCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Zomato Money',
              subtitle: '₹${money.toInt()}',
              iconColor: Colors.blueGrey,
              onTap: onMoneyTap,
            ),
          ),
          const SizedBox(width: 12),
          // Coupons Card
          Expanded(
            child: _buildCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Your coupons',
              subtitle: '$couponCount coupons', // Placeholder text logic
              iconColor: Colors.purple.shade300,
              isCoupons: true,
              onTap: onCouponsTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isCoupons = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCoupons ? 'Your coupons' : subtitle,
                    style: isCoupons
                        ? const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          )
                        : const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


