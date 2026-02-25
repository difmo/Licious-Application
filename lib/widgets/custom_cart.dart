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
  final VoidCallback? onTap;
  
  // New properties for badges and favorites
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final bool isFavorite;

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
    this.onTap,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0), // Removed corner radius to match design closely 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section (Badge & Favorite)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFFFE0B2), // default light orange
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor ?? const Color(0xFFF57C00), // default dark orange
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Favorite Icon
                  GestureDetector(
                    onTap: onFavoriteTap,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color(0xFFF44336) : Colors.grey, // Red if favorite
                      size: 20,
                    ),
                  ),
                ],
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
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 16.0),
              child: Column(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF68B92E), // Green price
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
                      color: Colors.black,
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
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
            
            // Bottom Action (Cart or Counter)
            hasCounter
                ? SizedBox(
                    height: 44, // Fixed height for bottom row
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onDecrement,
                            behavior: HitTestBehavior.opaque,
                            child: const Center(
                              child: Icon(Icons.remove, color: Color(0xFF68B92E), size: 18),
                            ),
                          ),
                        ),
                        const Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Expanded(
                          child: GestureDetector(
                            onTap: onIncrement,
                            behavior: HitTestBehavior.opaque,
                            child: const Center(
                              child: Icon(Icons.add, color: Color(0xFF68B92E), size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onAddToCart,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44, // Fixed height for bottom row
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
                  ),
          ],
        ),
      ),
    );
  }
}
