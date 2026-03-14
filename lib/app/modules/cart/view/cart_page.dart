import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/food_models.dart';
import '../../home/view/product_details_page.dart';
import '../../home/controller/main_controller.dart';
import '../../home/widgets/quantity_selector.dart';
import 'shipping_address_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ... items ...
    final cart = CartProviderScope.of(context);
    final items = cart.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // ... appBar ...
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            try {
              MainControllerScope.of(context).changePage(0);
            } catch (_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? _buildEmptyCart(context)
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 400),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItem(context, cart, item);
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildSummarySection(context, cart),
                ),
              ],
            ),
    );
  }

  // ... _buildEmptyCart remains same ...
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Color(0xFF68B92E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add some delicious items to your\ncart to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                try {
                  MainControllerScope.of(context)
                      .changePage(0); // Go to Home tab
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF439462),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Shop Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart, dynamic item) {
    return GestureDetector(
      onTap: () {
        // Find the full product object to pass to details page
        final product = cart.recommendedProducts.firstWhere(
          (p) => p.id == item.id,
          orElse: () => Product(
            id: item.id,
            name: item.title,
            image: item.image,
            price: item.unitPrice,
            weight: item.subtitle,
            category: '', // Assuming a default empty category if not found
            description: '',
            whyChoose: [],
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF7F8FA),
                  child: item.image.startsWith('http')
                      ? Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.set_meal_outlined,
                            color: Colors.grey,
                            size: 30,
                          ),
                        )
                      : Image.asset(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.set_meal_outlined,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF68B92E),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  QuantitySelector(
                    quantity: item.quantity,
                    onIncrement: () => cart.increment(item.title),
                    onDecrement: () => cart.decrement(item.title),
                    size: 34, // Slightly smaller for list view
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      final product = cart.recommendedProducts.firstWhere(
                        (p) => p.id == item.id,
                        orElse: () => Product(
                          id: item.id,
                          name: item.title,
                          image: item.image,
                          price: item.unitPrice,
                          weight: item.subtitle,
                          category: '',
                          description: '',
                          whyChoose: [],
                        ),
                      );
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            SubscriptionConfigDrawer(product: product),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Schedule',
                      style: TextStyle(
                        color: Color(0xFF68B92E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Shipping',
            '₹${cart.shippingCharges.toStringAsFixed(0)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '₹${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF68B92E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ShippingAddressPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF439462),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${cart.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
