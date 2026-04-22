import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductFilter {
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? hasDiscount;
  final bool? freeShipping;
  final bool? sameDayDelivery;
  final String? category;
  final String? sortBy;
  final String? search;

  const ProductFilter({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.hasDiscount,
    this.freeShipping,
    this.sameDayDelivery,
    this.category,
    this.sortBy,
    this.search,
  });

  ProductFilter copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? hasDiscount,
    bool? freeShipping,
    bool? sameDayDelivery,
    String? category,
    String? sortBy,
    String? search,
  }) {
    return ProductFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      freeShipping: freeShipping ?? this.freeShipping,
      sameDayDelivery: sameDayDelivery ?? this.sameDayDelivery,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      search: search ?? this.search,
    );
  }

  bool get isEmpty =>
      minPrice == null &&
      maxPrice == null &&
      minRating == null &&
      hasDiscount == null &&
      freeShipping == null &&
      sameDayDelivery == null &&
      category == null &&
      sortBy == null &&
      search == null;
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() {
    return const ProductFilter();
  }

  void update(ProductFilter newFilter) {
    state = newFilter;
  }

  void reset() {
    state = const ProductFilter();
  }
}

final productFilterProvider = NotifierProvider<ProductFilterNotifier, ProductFilter>(ProductFilterNotifier.new);
