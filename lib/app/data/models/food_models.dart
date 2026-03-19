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
      colorValue: json['colorValue'] != null ? int.tryParse(json['colorValue'].toString()) ?? 0xFFF7F8FA : 0xFFF7F8FA,
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
  final String restaurantName;
  final String date;
  final String? deliveryDate; // For upcoming subscription deliveries
  final double total;
  final String status;
  final List<String> items;
  final bool isSubscription;

  const UserOrder({
    required this.id,
    required this.restaurantName,
    required this.date,
    this.deliveryDate,
    required this.total,
    required this.status,
    required this.items,
    this.isSubscription = false,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    // Backend returns orderId, createdAt, totalAmount, status, items
    return UserOrder(
      id: json['orderId'] ?? '',
      restaurantName: 'Shrimpbite Retailer', // Placeholder as it's not directly in Order model top level
      date: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal().toString().split('.').first
          : '',
      total: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: json['paymentStatus'] == 'Paid' ? 'Accepted' : 'Pending',
      items: (json['items'] as List<dynamic>?)?.map((item) => 
          "${item['quantity']}x ${item['product']?['name'] ?? 'Product'}"
      ).toList() ?? [],
    );
  }
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

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String weight;
  final String category;
  final String badgeText;
  final bool isFavorite;
  final String description;
  final List<String> whyChoose;
  final bool isShopActive;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.weight,
    required this.category,
    this.badgeText = '',
    this.isFavorite = false,
    this.description = '',
    this.whyChoose = const [],
    this.isShopActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      weight: json['weight']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      badgeText: json['badgeText']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true || json['isFavorite'] == 'true',
      description: json['description']?.toString() ?? '',
      whyChoose: (json['whyChoose'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
    );
  }
}

class WalletTransaction {
  final String id;
  final String orderId;
  final String type; // 'Credit' or 'Debit'
  final String category; // 'Payment', 'Top-up', 'Refund'
  final double amount;
  final double balanceAfter;
  final String description;
  final String status; // 'Success', 'Failed', 'Pending'
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.orderId,
    required this.type,
    required this.category,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['transactionId']?.toString() ?? json['_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Debit',
      category: json['category']?.toString() ?? 'Payment',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balanceAfter: double.tryParse(json['balanceAfter']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Success',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
