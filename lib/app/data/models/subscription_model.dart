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
