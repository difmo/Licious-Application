class CartItem {
  final String title;
  final String price;
  final String subtitle;
  final String image;
  int quantity;

  CartItem({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.image,
    this.quantity = 1,
  });

  double get unitPrice {
    return double.tryParse(price.replaceAll('\$', '')) ?? 0.0;
  }

  double get totalPrice => unitPrice * quantity;
}
