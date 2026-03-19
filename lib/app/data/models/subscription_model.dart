class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int price;
  final String billingCycle;
  final List<String> features;
  final int maxOrderQuantity;
  final int discountPercentage;
  final bool bulkOrdersAllowed;
  final int freeDeliveries;
  final bool priorityDelivery;
  final String? badge;
  final String status;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.maxOrderQuantity,
    required this.discountPercentage,
    required this.bulkOrdersAllowed,
    required this.freeDeliveries,
    required this.priorityDelivery,
    this.badge,
    required this.status,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      billingCycle: json['billingCycle']?.toString() ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maxOrderQuantity: (json['maxOrderQuantity'] as num?)?.toInt() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toInt() ?? 0,
      bulkOrdersAllowed: json['bulkOrdersAllowed'] as bool? ?? false,
      freeDeliveries: (json['freeDeliveries'] as num?)?.toInt() ?? 0,
      priorityDelivery: json['priorityDelivery'] as bool? ?? false,
      badge: json['badge']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class UserSubscription {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final String frequency;
  final int quantity;
  final List<String> customDays;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String retailerName;
  final List<DateTime> vacationDates;

  UserSubscription({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    this.retailerName = '',
    required this.frequency,
    required this.quantity,
    required this.customDays,
    required this.status,
    required this.startDate,
    this.endDate,
    this.vacationDates = const [],
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String imageUrl = '';
    if (product is Map) {
      // Backend returns 'images' as an array
      final images = product['images'] as List<dynamic>?;
      imageUrl = (images != null && images.isNotEmpty)
          ? images.first.toString()
          : product['image']?.toString() ?? '';
    }

    final retailer = json['retailer'] ?? (product is Map ? product['retailer'] : null);
    String retailerName = '';
    if (retailer is Map) {
      final biz = retailer['businessDetails'];
      if (biz is Map) {
        retailerName = biz['storeDisplayName']?.toString() ??
            biz['businessName']?.toString() ??
            '';
      } else {
        retailerName = retailer['name']?.toString() ?? '';
      }
    }

    return UserSubscription(
      id: json['_id']?.toString() ?? '',
      productId: product is Map ? product['_id']?.toString() ?? '' : '',
      productName:
          product is Map ? product['name']?.toString() ?? 'Product' : 'Product',
      productImage: imageUrl,
      retailerName: retailerName,
      frequency: json['frequency']?.toString() ?? 'Daily',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      customDays: (json['customDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'Active',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      vacationDates: (json['vacationDates'] as List<dynamic>?)
              ?.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
              .toList() ??
          [],
    );
  }
}
