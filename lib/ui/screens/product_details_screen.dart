import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String? title;
  final String? price;
  final String? subtitle;
  final String? image;

  const ProductDetailsScreen({
    super.key,
    this.title,
    this.price,
    this.subtitle,
    this.image,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  String get productTitle => widget.title ?? 'Fresh Shrimps';
  String get productPrice => widget.price ?? '\$2.22';
  String get productSubtitle => widget.subtitle ?? '1.50 lbs';
  String get productImage => widget.image ?? 'lib/ui/themes/images/image copy 2.png';

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final inCart = cart.isInCart(productTitle);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cart'),
              child: Stack(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 28),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF38B24D),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background decorative shapes
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8EB),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Image Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Hero(
                    tag: 'product_image_$productTitle',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        productImage,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 240,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Details Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F6F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price and Favorite
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              productPrice,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38B24D),
                              ),
                            ),
                            Icon(Icons.favorite_border, color: Colors.grey.shade400, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          productTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          productSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Rating
                        Row(
                          children: [
                            const Text(
                              '4.5',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < 4 ? Icons.star : Icons.star_half,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(89 reviews)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Expanded(
                          child: SingleChildScrollView(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.6,
                                ),
                                children: const [
                                  TextSpan(
                                    text:
                                        "Organic Mountain works as a seller for many organic growers of organic lemons. Organic lemons are easy to spot in your produce aisle. They are just like regular lemons, but they will usually have a few more scars on the outside of the lemon skin. Organic lemons are considered to be the world's finest lemon for juicing ",
                                  ),
                                  TextSpan(
                                    text: 'more',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom Actions (Quantity & Cart)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              // Quantity Selector (hidden when already in cart)
                              if (!inCart) ...[
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (quantity > 1) {
                                            setState(() => quantity--);
                                          }
                                        },
                                        icon: const Icon(Icons.remove, color: Color(0xFF38B24D)),
                                      ),
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '$quantity',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() => quantity++);
                                        },
                                        icon: const Icon(Icons.add, color: Color(0xFF38B24D)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],

                              // Add to Cart / Go to Cart Button
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (inCart) {
                                        Navigator.pushNamed(context, '/cart');
                                      } else {
                                        cart.addToCart(CartItem(
                                          title: productTitle,
                                          price: productPrice,
                                          subtitle: productSubtitle,
                                          image: productImage,
                                          quantity: quantity,
                                        ));
                                        setState(() {});
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: inCart
                                          ? const Color(0xFF1565C0)
                                          : const Color(0xFF38B24D),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          inCart ? 'Go to Cart' : 'Add to cart',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          inCart
                                              ? Icons.shopping_cart_outlined
                                              : Icons.shopping_bag_outlined,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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
