import 'package:flutter/material.dart';

class CustomCart extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String image;
  final bool hasCounter;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CustomCart({
    super.key,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.image,
    required this.hasCounter,
    this.onFavoriteTap,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Favorite Icon
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onFavoriteTap,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.favorite_border, color: Colors.grey, size: 20),
              ),
            ),
          ),
          
          // Image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, color: Colors.grey, size: 50);
                },
              ),
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF68B92E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Add to cart or counter
                hasCounter
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: onDecrement,
                            child: const Icon(Icons.remove, color: Color(0xFF68B92E), size: 18),
                          ),
                          const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: onIncrement,
                            child: const Icon(Icons.add, color: Color(0xFF68B92E), size: 18),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: onAddToCart,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_bag_outlined, color: Color(0xFF68B92E), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Add to cart',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
