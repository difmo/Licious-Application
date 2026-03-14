/// Model for a shop returned in global search results.
class SearchShop {
  final String id;
  final String name;
  final String businessName;
  final String image;
  final String location;
  final bool isShopActive;
  final double rating;
  final String deliveryTime;

  const SearchShop({
    required this.id,
    required this.name,
    this.businessName = '',
    this.image = '',
    this.location = '',
    this.isShopActive = true,
    this.rating = 4.5,
    this.deliveryTime = '30-45 mins',
  });

  factory SearchShop.fromJson(Map<String, dynamic> json) {
    return SearchShop(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      image: (json['image'] ?? json['logo'] ?? json['banner'] ?? '').toString(),
      location: (json['location'] ?? json['address'] ?? '').toString(),
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      deliveryTime: (json['deliveryTime'] ?? '30-45 mins').toString(),
    );
  }
}

/// Model for a product returned in global search results.
class SearchProduct {
  final String id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String stockStatus;
  final String shopId;
  final String shopName;
  final bool isShopActive;

  const SearchProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image = '',
    this.description = '',
    this.stockStatus = 'In Stock',
    required this.shopId,
    required this.shopName,
    this.isShopActive = true,
  });

  bool get isAvailable => stockStatus == 'In Stock';

  String get displayImage {
    if (image.length > 5) return image;
    final lower = name.toLowerCase();
    if (lower.contains('tiger') || lower.contains('shrimp') || lower.contains('prawn')) {
      return 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?q=80&w=800&auto=format&fit=crop';
    }
    if (lower.contains('fish') || lower.contains('rohu')) {
      return 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?q=80&w=800&auto=format&fit=crop';
    }
    return '';
  }

  factory SearchProduct.fromJson(Map<String, dynamic> json) {
    final shopData = json['shop'];
    String shopId = '';
    String shopName = '';
    bool isShopActiveRetailer = true;

    if (shopData is Map<String, dynamic>) {
      shopId = (shopData['id'] ?? shopData['_id'] ?? '').toString();
      shopName = (shopData['name'] ?? '').toString();
      isShopActiveRetailer = shopData['isShopActive'] ?? true;
    }

    // Resolve image from various possible fields
    String image = '';
    final rawImages = json['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      image = rawImages.first.toString();
    }
    final singleImage = json['image'] ?? json['imageUrl'] ?? json['productImage'];
    if (image.isEmpty && singleImage != null && singleImage.toString().isNotEmpty) {
      image = singleImage.toString();
    }

    return SearchProduct(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: image,
      description: (json['description'] ?? '').toString(),
      stockStatus: (json['stockStatus'] ?? 'In Stock').toString(),
      shopId: shopId,
      shopName: shopName,
      isShopActive: isShopActiveRetailer,
    );
  }
}

/// Combined search results container.
class SearchResult {
  final List<SearchShop> shops;
  final List<SearchProduct> products;

  const SearchResult({
    this.shops = const [],
    this.products = const [],
  });

  bool get isEmpty => shops.isEmpty && products.isEmpty;
  int get totalCount => shops.length + products.length;
}
