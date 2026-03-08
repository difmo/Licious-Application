import 'package:flutter/material.dart';
import '../../../widgets/common_card.dart';

class VegetablesPage extends StatelessWidget {
  const VegetablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = [
      {
        'title': 'Fresh Shrimps',
        'price': '₹8.00',
        'subtitle': 'dozen',
        'image': 'assets/images/image copy 2.png',
        'hasCounter': false,
        'isFavorite': false,
        'badgeText': null,
      },
      {
        'title': 'Avacoda',
        'price': '₹7.00',
        'subtitle': '2.0 lbs',
        'image': 'assets/images/image copy 3.png',
        'hasCounter': true,
        'isFavorite': false,
        'badgeText': 'NEW',
        'badgeColor': const Color(0xFFFFECB3),
        'badgeTextColor': const Color(0xFFFF9800),
      },
      {
        'title': 'Pineapple',
        'price': '₹9.90',
        'subtitle': '1.50 lbs',
        'image': 'assets/images/image copy 4.png',
        'hasCounter': false,
        'isFavorite': true,
        'badgeText': null,
      },
      {
        'title': 'Black Grapes',
        'price': '₹7.05',
        'subtitle': '5.0 lbs',
        'image': 'assets/images/image copy 5.png',
        'hasCounter': false,
        'isFavorite': false,
        'badgeText': '-16%',
        'badgeColor': const Color(0xFFFFCDD2),
        'badgeTextColor': const Color(0xFFE53935),
      },
      {
        'title': 'Pomegranate',
        'price': '₹2.09',
        'subtitle': '1.50 lbs',
        'image': 'assets/images/image copy 6.png',
        'hasCounter': true,
        'isFavorite': false,
        'badgeText': 'NEW',
        'badgeColor': const Color(0xFFFFECB3),
        'badgeTextColor': const Color(0xFFFF9800),
      },
      {
        'title': 'Fresh B roccoli',
        'price': '₹3.00',
        'subtitle': '1 kg',
        'image': 'assets/images/image copy 7.png',
        'hasCounter': false,
        'isFavorite': true,
        'badgeText': null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vegetables',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return CommonCard(
              title: product['title'],
              price: product['price'],
              subtitle: product['subtitle'],
              image: product['image'],
              hasCounter: product['hasCounter'],
              isFavorite: product['isFavorite'],
              badgeText: product['badgeText'],
              badgeColor: product['badgeColor'],
              badgeTextColor: product['badgeTextColor'],
              onTap: () {
                Navigator.pushNamed(context, '/product_details');
              },
              onAddToCart: () {
                Navigator.pushNamed(context, '/product_details');
              },
            );
          },
        ),
      ),
    );
  }
}
