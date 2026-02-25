import 'package:flutter/material.dart';
import '../../widgets/custom_cart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header / Search Bar
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search keywords..',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Icon(Icons.tune, color: Colors.grey), // Filter icon
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
            
            // Banner
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.asset(
                        'lib/ui/themes/images/image copy.png', // Main banner image
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey.shade300,
                            child: const Center(child: Text('Banner Image Missing')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Categories Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/categories');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            
            // Categories List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildCategoryItem(Icons.energy_savings_leaf, 'Vegetables', const Color(0xFFE8F5E9), Colors.green),
                    const SizedBox(width: 16),
                    _buildCategoryItem(Icons.apple, 'Fruits', const Color(0xFFFFEBEE), Colors.red),
                    const SizedBox(width: 16),
                    _buildCategoryItem(Icons.local_drink, 'Beverages', const Color(0xFFFFF8E1), Colors.orange),
                    const SizedBox(width: 16),
                    _buildCategoryItem(Icons.shopping_basket, 'Grocery', const Color(0xFFF3E5F5), Colors.purple),
                    const SizedBox(width: 16),
                    _buildCategoryItem(Icons.opacity, 'Edible oil', const Color(0xFFE0F7FA), Colors.cyan),
                  ],
                ),
              ),
            ),
            
            // Featured Products Header
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured products',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            
            // Featured Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return CustomCart(
                      title: ['Fresh Shrimps', 'Avacoda', 'White Shrimps', 'Pomegranate', 'Fresh Broccoli'][index % 5],
                      price: ['\$8.00', '\$7.00', '\$9.90', '\$2.09', '\$3.00'][index % 5],
                      subtitle: ['dozen', '2.0 lbs', '1.50 lbs', '1.50 lbs', '1 kg'][index % 5],
                      image: 'lib/ui/themes/images/image copy 2.png',
                      hasCounter: index == 1 || index == 3,
                      onTap: () {
                        Navigator.pushNamed(context, '/product_details');
                      },
                      onAddToCart: () {
                        Navigator.pushNamed(context, '/product_details');
                      },
                    );
                  },
                  childCount: 5,
                ),
              ),
            ),
            
            // Bottom padding for fab
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF68B92E),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {},
            ),
            // Empty space for the floating action button
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color bgColor, Color iconColor) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

}

