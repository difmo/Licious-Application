import 'food_models.dart';

class CartItem {
  final String id;
  final String title;
  final double unitPrice;
  final String subtitle;
  final String image;
  final String category;
  int quantity;
  final String? shopId;
  final String? shopName;
  final String? shopLocation;

  CartItem({
    required this.id,
    required this.title,
    required this.unitPrice,
    required this.subtitle,
    required this.image,
    required this.category,
    this.quantity = 1,
    this.shopId,
    this.shopName,
    this.shopLocation,
  });

  factory CartItem.fromProduct(Product product) {
    return CartItem(
      id: product.id,
      title: product.name,
      unitPrice: product.price,
      subtitle: product.weight,
      image: product.image,
      category: product.category,
      shopId: product.shopId,
      shopName: product.shopName,
      shopLocation: product.shopLocation,
    );
  }

  double get totalPrice => unitPrice * quantity;
}

/// Alias for future migration clarity.
typedef ProductModel = CartItem;
