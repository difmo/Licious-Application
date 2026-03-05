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
  final double total;
  final String status;
  final List<String> items;

  const UserOrder({
    required this.id,
    required this.restaurantName,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
  });
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
    );
  }
}
