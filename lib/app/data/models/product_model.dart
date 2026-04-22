import 'food_models.dart';

class CartItem {
  final String id;
  final String title;
  final double unitPrice;
  final String subtitle;
  final String image;
  final String category;
  final String? shopId;
  final String? shopName;
  final String? variantId;
  final String? weightLabel;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.unitPrice,
    required this.subtitle,
    required this.image,
    required this.category,
    this.shopId,
    this.shopName,
    this.variantId,
    this.weightLabel,
    this.quantity = 1,
  });

  factory CartItem.fromProduct(Product product, {int variantIndex = -1}) {
    final v = (variantIndex >= 0 && variantIndex < product.variants.length)
        ? product.variants[variantIndex]
        : null;
    return CartItem(
      id: product.id,
      title: product.name,
      unitPrice: v?.price ?? product.price,
      subtitle: v?.weightLabel ?? product.weight,
      image: product.image,
      category: product.category,
      variantId: v?.id,
      weightLabel: v?.weightLabel,
    );
  }

  double get totalPrice => unitPrice * quantity;
}

/// Alias for future migration clarity.
typedef ProductModel = CartItem;
