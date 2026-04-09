class FoodCategory {
  final String id;
  final String name;
  final String image;
  final int colorValue; // Hex color for the circular background
  final String? iconPath; // Optional path for thematic icons

  const FoodCategory({
    required this.id,
    required this.name,
    required this.image,
    this.colorValue = 0xFFF7F8FA,
    this.iconPath,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      colorValue: json['colorValue'] != null
          ? int.tryParse(json['colorValue'].toString()) ?? 0xFFF7F8FA
          : 0xFFF7F8FA,
      iconPath: json['iconPath']?.toString(),
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String deliveryTime;
  final String discount;
  final String minOrder;
  final List<String> categories;
  final bool isPromoted;

  const Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.deliveryTime,
    required this.discount,
    required this.minOrder,
    this.categories = const [],
    this.isPromoted = false,
  });
}

class UserOrder {
  final String id;
  final String orderNumber; // Human-readable order #
  final String restaurantName;
  final String date;
  final String? deliveryDate; // For upcoming subscription deliveries
  final double total;
  final String status;
  final List<OrderItem> items;
  final bool isSubscription;

  const UserOrder({
    required this.id,
    required this.orderNumber,
    required this.restaurantName,
    required this.date,
    this.deliveryDate,
    required this.total,
    required this.status,
    required this.items,
    this.isSubscription = false,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    // Technical ID is for API calls (must be MongoDB ObjectId)
    final String technicalId =
        (json['_id'] ?? json['id'] ?? json['orderId'] ?? '').toString();
    // Human ID is for Display (#-...)
    final String humanId =
        (json['orderId'] ?? json['id'] ?? json['_id'] ?? '').toString();

    return UserOrder(
      id: technicalId,
      orderNumber: humanId,
      restaurantName: 'Shrimpbite Retailer', // Placeholder
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString().endsWith('Z') ? json['createdAt'].toString() : '${json['createdAt']}Z')
              .toLocal()
              .toString()
              .split('.')
              .first
          : '',
      total: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ??
          (json['paymentStatus'] == 'Paid' ? 'Accepted' : 'Pending'),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String weightLabel;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.weightLabel = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map ? json['product'] : {};
    return OrderItem(
      productId: (product['_id'] ?? product['id'] ?? '').toString(),
      name: (product['name'] ?? 'Product').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      weightLabel: (json['weightLabel'] ?? '').toString(),
    );
  }

  @override
  String toString() => '${quantity}x $name${weightLabel.isNotEmpty ? " ($weightLabel)" : ""}';
}

class UserAddress {
  final String id;
  final String title;
  final String street;
  final String details;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.title,
    required this.street,
    required this.details,
    this.isDefault = false,
  });
}

class UserPaymentMethod {
  final String id;
  final String type;
  final String lastFour;
  final String expiry;

  const UserPaymentMethod({
    required this.id,
    required this.type,
    required this.lastFour,
    required this.expiry,
  });
}

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String? walletId;
  final List<UserAddress> addresses;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    this.walletId,
    this.addresses = const [],
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? walletId,
    List<UserAddress>? addresses,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      walletId: walletId ?? this.walletId,
      addresses: addresses ?? this.addresses,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String weight;
  final List<ProductVariant> variants;
  final String category;
  final String badgeText;
  final bool isFavorite;
  final String description;
  final List<String> whyChoose;
  final bool isShopActive;
  final String? shopId;
  final String? shopName;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.weight,
    this.variants = const [],
    required this.category,
    this.badgeText = '',
    this.isFavorite = false,
    this.description = '',
    this.whyChoose = const [],
    this.isShopActive = true,
    this.shopId,
    this.shopName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      weight: json['weight']?.toString() ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          const [],
      category: json['category']?.toString() ?? '',
      badgeText: json['badgeText']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true || json['isFavorite'] == 'true',
      description: json['description']?.toString() ?? '',
      whyChoose: (json['whyChoose'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
      shopId: (json['retailer'] ?? json['retailerId'] ?? json['shopId'])?.toString(),
      shopName: (json['retailerName'] ?? json['shopName'])?.toString(),
    );
  }
}

class ProductVariant {
  final String id;
  final String label;
  final double weightInKg;
  final double price;
  final int stock;
  final double weightValue;
  final String weightUnit;

  const ProductVariant({
    required this.id,
    required this.label,
    required this.weightInKg,
    required this.price,
    required this.stock,
    required this.weightValue,
    required this.weightUnit,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      label: (json['label'] ?? json['weightLabel'] ?? '').toString(),
      weightInKg: (json['weightInKg'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      weightValue: (json['weightValue'] as num?)?.toDouble() ?? 0.0,
      weightUnit: (json['weightUnit'] ?? '').toString(),
    );
  }

  // Helper getter to match what some components expect
  String get weightLabel => label;
}

class WalletTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String type;
  final String status;
  final DateTime createdAt;
  final String category;
  final double balanceAfter;

  WalletTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.category,
    this.balanceAfter = 0.0,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderId: (json['orderId'] ?? json['referenceId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'Debit',
      status: json['status'] ?? 'Success',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString().endsWith('Z')
                  ? json['createdAt'].toString()
                  : '${json['createdAt']}Z')
              .toLocal()
          : DateTime.now(),
      category: json['category'] ?? 'Transaction',
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    return Review(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      userName: (user['name'] ?? 'Guest User').toString(),
      userImage: (user['image'] ?? user['profileImage'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString().endsWith('Z')
                  ? json['createdAt'].toString()
                  : '${json['createdAt']}Z')
              .toLocal()
          : DateTime.now(),
    );
  }
}
