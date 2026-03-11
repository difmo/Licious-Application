/// Model for an API-fetched product category (embedded inside a product).
class ShopProductCategory {
  final String id;
  final String name;

  const ShopProductCategory({required this.id, required this.name});

  factory ShopProductCategory.fromJson(Map<String, dynamic> json) {
    return ShopProductCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

/// Model for an API-fetched product belonging to a shop.
class ShopProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final ShopProductCategory? category;
  final List<String> images;
  final int stock;
  final String stockStatus; // "In Stock" | "Out of Stock"
  final String retailerId;
  final String status; // "Published" | "Draft"
  final DateTime createdAt;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    required this.images,
    required this.stock,
    required this.stockStatus,
    required this.retailerId,
    required this.status,
    required this.createdAt,
  });

  bool get isAvailable =>
      status == 'Published' && stockStatus == 'In Stock' && stock > 0;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    ShopProductCategory? category;
    if (json['category'] is Map<String, dynamic>) {
      category = ShopProductCategory.fromJson(
          json['category'] as Map<String, dynamic>);
    }

    return ShopProduct(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: category,
      images: images,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      stockStatus: (json['stockStatus'] ?? 'Out of Stock').toString(),
      retailerId: (json['retailer'] ?? '').toString(),
      status: (json['status'] ?? 'Draft').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Model representing a Shop (shown as a restaurant card on the home screen).
class ShopModel {
  final String id;
  final String name;
  final String businessName;
  final String image;
  final String location;
  final double rating;
  final String deliveryTime;
  final bool isShopActive;

  const ShopModel({
    required this.id,
    required this.name,
    this.businessName = '',
    this.image = '',
    this.location = '',
    this.rating = 4.5,
    this.deliveryTime = '30-45 mins',
    this.isShopActive = true,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Shrimp Shop').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      image: (json['image'] ?? json['logo'] ?? json['banner'] ?? '').toString(),
      location: (json['location'] ?? json['address'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      deliveryTime: (json['deliveryTime'] ?? '30-45 mins').toString(),
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
    );
  }
}
